ShuffleTeam = class({})
DEFAULT_MMR = 1500
BASE_BONUS = 10
MIN_DIFF = 500
BONUS_MMR_STEP = 100
BONUS_FOR_STEP = 3
MAX_BONUS = 100
MAX_PLAYERS_IN_TEAM = 12
LinkLuaModifier("modifier_bonus_for_weak_team_in_mmr", "modifier_bonus_for_weak_team_in_mmr", LUA_MODIFIER_MOTION_NONE)

function ShuffleTeam:SortInMMR()
	--if IsInToolsMode() then
	--	--TEST PART. NEED REMOVE IT AFTER TEST
	--	SendToServerConsole('dota_bot_populate')
	--	local publicStats = {}
	--	for playerId = 0, 23 do
	--		publicStats[playerId] = {
	--			rating = playerId == 0 and -20000 or RandomInt(500,4000),
	--		}
	--	end
	--	CustomNetTables:SetTableValue("game_state", "player_stats", publicStats)
	--end

	self.multGold = 1
	self.weakTeam = 0
	self.mmrDiff = 0
	local players = {}
	local playersStats = CustomNetTables:GetTableValue("game_state", "player_stats");
	if not playersStats then return end
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 24 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 24)

	local phantomPartyID = 456332
	for playerId = 0, 23 do
		if not playersStats[tostring(playerId)] then
			playersStats[tostring(playerId)] = {
				rating = DEFAULT_MMR
			}
		end
		local playerRating = playersStats[tostring(playerId)].rating and playersStats[tostring(playerId)].rating or 0
		local partyID =  tonumber(tostring(PlayerResource:GetPartyID(playerId)))
		if PlayerResource:GetConnectionState(playerId) == DOTA_CONNECTION_STATE_NOT_YET_CONNECTED or partyID <= 0 then
			phantomPartyID = phantomPartyID + 1
			partyID = phantomPartyID
		end
		players[playerId] = {
			partyID = partyID,
			mmr = playerRating
		}
	end

	local teams = { [2] = { players = {}, mmr = 0}, [3] = { players = {}, mmr = 0}}
	local partiesMMR = {}

	for playerId, data in pairs(players) do
		local partyID = data.partyID + 1
		partiesMMR[partyID] = partiesMMR[partyID] or {}
		partiesMMR[partyID].players = partiesMMR[partyID].players or {}
		partiesMMR[partyID].mmr = (partiesMMR[partyID].mmr or 0) + data.mmr
		table.insert(partiesMMR[partyID].players, playerId)
	end

	local sortedParties = {}
	for _, v in pairs(partiesMMR) do table.insert(sortedParties, v) end
	table.sort(sortedParties, function(a,b)
		return a.mmr > b.mmr
	end)

	local SortTeam = function(MIN_DIFFPlayerCount)
		for _, partyData in pairs(sortedParties) do
			if #partyData.players >= MIN_DIFFPlayerCount and not partyData.sorted then
				partyData.sorted = true
				local teamId = 2
				if teams[teamId].mmr > teams[3].mmr then
					teamId = 3
				end
				for _, playerId in pairs(partyData.players) do
					if #teams[teamId].players >= MAX_PLAYERS_IN_TEAM then
						teamId = teamId == 2 and 3 or 2
					end
					table.insert(teams[teamId].players, playerId)
					teams[teamId].mmr = (teams[teamId].mmr or 0) + players[playerId].mmr
					local player = PlayerResource:GetPlayer(playerId)
					if player then
						player:SetTeam(teamId)
					end
				end
			end
		end
	end
	SortTeam(2)
	SortTeam(1)
	self.weakTeam = teams[2].mmr < teams[3].mmr and 2 or 3
	self.mmrDiff = math.abs(math.floor(teams[2].mmr/MAX_PLAYERS_IN_TEAM) - math.floor(teams[3].mmr/MAX_PLAYERS_IN_TEAM))

	--DEBUG PRINT PART
	for teamId,teamData in pairs(teams) do
		AutoTeam:Debug("")
		AutoTeam:Debug("Team: ["..teamId.."]")
		for id, playerId in pairs(teamData.players) do
			AutoTeam:Debug(id .. " pid: "..playerId .. "	> "..playerId.." MMR: "..players[playerId].mmr .. " TEAM: "..players[playerId].partyID)
		end
	end
	AutoTeam:Debug("")
	AutoTeam:Debug("Team 2 averages MMR: " .. math.floor(teams[2].mmr/MAX_PLAYERS_IN_TEAM))
	AutoTeam:Debug("Team 3 averages MMR: " .. math.floor(teams[3].mmr/MAX_PLAYERS_IN_TEAM))
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 12)
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS,12)
end

function ShuffleTeam:SendNotificationForWeakTeam()
	if not self.bonusPct then return end
	CustomGameEventManager:Send_ServerToTeam(self.weakTeam, "WeakTeamNotification", { bonusPct = self.bonusPct, mmrDiff = self.mmrDiff})
end

function ShuffleTeam:GiveBonusToHero(player)
	local hero = player:GetAssignedHero()
	if hero then
		hero:AddNewModifier(hero, nil, "modifier_bonus_for_weak_team_in_mmr", { duration = -1, bonusPct = self.bonusPct })
	else
		Timers:CreateTimer(2, function()
			self:GiveBonusToHero(player)
		end)
	end
end

function ShuffleTeam:GiveBonusToWeakTeam()
	if self.mmrDiff < MIN_DIFF then return end
	self.bonusPct = math.min(BASE_BONUS + (math.floor((self.mmrDiff - MIN_DIFF) / BONUS_MMR_STEP)) * BONUS_FOR_STEP, MAX_BONUS)
	self.multGold = 1 + self.bonusPct / 100
	for playerId = 0, 23 do
		local player = PlayerResource:GetPlayer(playerId)
		if player and (player:GetTeam() == self.weakTeam) then
			self:GiveBonusToHero(player)
		end
	end
end
