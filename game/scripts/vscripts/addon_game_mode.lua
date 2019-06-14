-- Rebalance the distribution of gold and XP to make for a better 10v10 game
local GOLD_SCALE_FACTOR_INITIAL = 1
local GOLD_SCALE_FACTOR_FINAL = 2.5
local GOLD_SCALE_FACTOR_FADEIN_SECONDS = (60 * 60) -- 60 minutes
local XP_SCALE_FACTOR_INITIAL = 2
local XP_SCALE_FACTOR_FINAL = 2
local XP_SCALE_FACTOR_FADEIN_SECONDS = (60 * 60) -- 60 minutes

require( 'timers' )
require("util")
require("statcollection/init")
require("patreons")
require("utility_functions")

require( "cosmetic_abilities" )

LinkLuaModifier("modifier_core_courier", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_donator", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silencer_new_int_steal", LUA_MODIFIER_MOTION_NONE)

if CMegaDotaGameMode == nil then
	_G.CMegaDotaGameMode = class({}) -- put CMegaDotaGameMode in the global scope
	--refer to: http://stackoverflow.com/questions/6586145/lua-require-with-global-local
end

function Activate()
	CMegaDotaGameMode:InitGameMode()
end

function CMegaDotaGameMode:InitGameMode()
	print( "10v10 Mode Loaded!" )

	-- Adjust team limits
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 12 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 12 )
	GameRules:SetStrategyTime( 0.0 )
	GameRules:SetShowcaseTime( 0.0 )

	-- Hook up gold & xp filters
    GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter( Dynamic_Wrap( CMegaDotaGameMode, "ItemAddedToInventoryFilter" ), self )
	GameRules:GetGameModeEntity():SetModifyGoldFilter( Dynamic_Wrap( CMegaDotaGameMode, "FilterModifyGold" ), self )
	GameRules:GetGameModeEntity():SetModifyExperienceFilter( Dynamic_Wrap(CMegaDotaGameMode, "FilterModifyExperience" ), self )
	GameRules:GetGameModeEntity():SetBountyRunePickupFilter( Dynamic_Wrap(CMegaDotaGameMode, "FilterBountyRunePickup" ), self )
	GameRules:GetGameModeEntity():SetModifierGainedFilter( Dynamic_Wrap( CMegaDotaGameMode, "ModifierGainedFilter" ), self )
	GameRules:GetGameModeEntity():SetRuneSpawnFilter( Dynamic_Wrap( CMegaDotaGameMode, "RuneSpawnFilter" ), self )
	GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap(CMegaDotaGameMode, 'ExecuteOrderFilter'), self)

	GameRules:GetGameModeEntity():SetTowerBackdoorProtectionEnabled( true )
	GameRules:GetGameModeEntity():SetPauseEnabled(IsInToolsMode())
	GameRules:SetGoldTickTime( 0.3 ) -- default is 0.6
	GameRules:LockCustomGameSetupTeamAssignment(true)
	GameRules:SetCustomGameSetupAutoLaunchDelay(1)
	GameRules:GetGameModeEntity():SetKillableTombstones( true )
	if IsInToolsMode() then
		GameRules:GetGameModeEntity():SetDraftingBanningTimeOverride(0)
	end

	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(CMegaDotaGameMode, 'OnGameRulesStateChange'), self)
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CMegaDotaGameMode, "OnNPCSpawned" ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CMegaDotaGameMode, 'OnEntityKilled' ), self )

	self.m_CurrentGoldScaleFactor = GOLD_SCALE_FACTOR_INITIAL
	self.m_CurrentXpScaleFactor = XP_SCALE_FACTOR_INITIAL
	self.couriers = {}
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 5 )

	local firstPlayerLoaded
	ListenToGameEvent("player_connect_full", function()
		if firstPlayerLoaded then return end
		firstPlayerLoaded = true

		local players = {}
		for i = 0, 23 do
			if PlayerResource:IsValidPlayerID(i) then
				table.insert(players, tostring(PlayerResource:GetSteamID(i)))
			end
		end

		SendWebApiRequest("before-match", { mapName = GetMapName(), players = players }, function(data)
			local publicStats = {}
			for _,player in ipairs(data.players) do
				local playerId = GetPlayerIdBySteamId(player.steamId)
				local colorNames = {
					"White",
					"Red",
					"Green",
					"Blue",
					"Cyan",
					"Yellow",
					"Pink",
					"Maroon",
					"Brown",
					"Olive",
					"Teal",
					"Navy",
					"Black",
					"Orange",
					"Lime",
					"Purple",
					"Magenta",
					"Grey",
					"Apricot",
					"Beige",
					"Mint",
					"Lavender",
				}
				player.patreon["emblemColor"] = colorNames[RandomInt(1, #colorNames)]
				Patreons:SetPlayerSettings(playerId, player.patreon)

				publicStats[playerId] = {
					streak = player.streak,
					bestStreak = player.bestStreak,
					averageKills = player.averageKills,
					averageDeaths = player.averageDeaths,
					averageAssists = player.averageAssists,
					wins = player.wins,
					loses = player.loses,
				}
			end

			CustomNetTables:SetTableValue("game_state", "player_stats", publicStats)
		end)
	end, nil)

	ListenToGameEvent("dota_player_used_ability", function(event)
		local hero = PlayerResource:GetSelectedHeroEntity(event.PlayerID)
		if not hero then return end
		if event.abilityname == "night_stalker_darkness" then
			local ability = hero:FindAbilityByName(event.abilityname)
			CustomGameEventManager:Send_ServerToAllClients("time_nightstalker_darkness", {
				duration = ability:GetSpecialValueFor("duration")
			})
		end
	end, nil)

	_G.kicks = {
		false,
		false,
		false,
		false,
		false
	}
	CustomGameEventManager:RegisterListener("GetKicks", Dynamic_Wrap(CMegaDotaGameMode, 'GetKicks'))
	CustomGameEventManager:RegisterListener("OnTimerClick", Dynamic_Wrap(CMegaDotaGameMode, 'OnTimerClick'))

	Timers:CreateTimer( 0.6, function()
		for i = 0, GameRules:NumDroppedItems() - 1 do
			local container = GameRules:GetDroppedItem( i )

			if container then
				local item = container:GetContainedItem()

				if item:GetAbilityName():find( "item_ward_" ) then
					local owner = item:GetOwner()

					if owner then
						local team = owner:GetTeam()
						local fountain
						local multiplier

						if team == DOTA_TEAM_GOODGUYS then
							multiplier = -350
							fountain = Entities:FindByName( nil, "ent_dota_fountain_good" )
						elseif team == DOTA_TEAM_BADGUYS then
							multiplier = -650
							fountain = Entities:FindByName( nil, "ent_dota_fountain_bad" )		
						end

						local fountain_pos = fountain:GetAbsOrigin()

						if ( fountain_pos - container:GetAbsOrigin() ):Length2D() > 1200 then
							local pos_item = fountain_pos:Normalized() * multiplier + RandomVector( RandomFloat( 0, 200 ) ) + fountain_pos
							pos_item.z = fountain_pos.z

							container:SetAbsOrigin( pos_item )
							CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( owner:GetPlayerID() ), "display_custom_error", { message = "#dropped_wards_return_error" } )
						end
					end
				end
			end
		end

		return 0.6
	end )
end

function GetActivePlayerCountForTeam(team)
    local number = 0
    for x=0,DOTA_MAX_TEAM do
        local pID = PlayerResource:GetNthPlayerIDOnTeam(team,x)
        if PlayerResource:IsValidPlayerID(pID) and (PlayerResource:GetConnectionState(pID) == 1 or PlayerResource:GetConnectionState(pID) == 2) then
            number = number + 1
        end
    end
    return number
end

function GetActiveHumanPlayerCountForTeam(team)
    local number = 0
    for x=0,DOTA_MAX_TEAM do
        local pID = PlayerResource:GetNthPlayerIDOnTeam(team,x)
        if PlayerResource:IsValidPlayerID(pID) and not self:isPlayerBot(pID) and (PlayerResource:GetConnectionState(pID) == 1 or PlayerResource:GetConnectionState(pID) == 2) then
            number = number + 1
        end
    end
    return number
end

function otherTeam(team)
    if team == DOTA_TEAM_BADGUYS then
        return DOTA_TEAM_GOODGUYS
    elseif team == DOTA_TEAM_GOODGUYS then
        return DOTA_TEAM_BADGUYS
    end
    return -1
end

---------------------------------------------------------------------------
-- Event: OnEntityKilled
---------------------------------------------------------------------------
function CMegaDotaGameMode:OnEntityKilled( event )
    local killedUnit = EntIndexToHScript( event.entindex_killed )
    local killedTeam = killedUnit:GetTeam()
    --print("fired")
    if killedUnit:IsRealHero() and not killedUnit:IsReincarnating() then
	    local dotaTime = GameRules:GetDOTATime(false, false)
	    local timeToStartReduction = 0 -- 20 minutes
	    local respawnReduction = 0.75 -- Original Reduction rate

	    -- Reducation Rate slowly increases after a certain time, eventually getting to original levels, this is to prevent games lasting too long
	    if dotaTime > timeToStartReduction then
	    	dotaTime = dotaTime - timeToStartReduction
	    	respawnReduction = respawnReduction + ((dotaTime / 60) / 100) -- 0.75 + Minutes of Game Time / 100 e.g. 25 minutes fo game time = 0.25
	    end

	    if respawnReduction > 1 then
	    	respawnReduction = 1
	    end

	    local timeLeft = killedUnit:GetRespawnTime()
	 	timeLeft = timeLeft * respawnReduction -- Respawn time reduced by a rate

	    -- Disadvantaged teams get 5 seconds less respawn time for every missing player
	    local herosTeam = GetActivePlayerCountForTeam(killedUnit:GetTeamNumber())
	    local opposingTeam = GetActivePlayerCountForTeam(otherTeam(killedUnit:GetTeamNumber()))
	    local difference = herosTeam - opposingTeam

	    local addedTime = 0
	    if difference < 0 then
	        addedTime = difference * 5
	        local RespawnReductionRate = string.format("%.2f", tostring(respawnReduction))
		    local OriginalRespawnTime = tostring(math.floor(timeLeft))
		    local TimeToReduce = tostring(math.floor(addedTime))
		    local NewRespawnTime = tostring(math.floor(timeLeft + addedTime))
	        --GameRules:SendCustomMessage( "ReductionRate:"  .. " " .. RespawnReductionRate .. " " .. "OriginalTime:" .. " " ..OriginalRespawnTime .. " " .. "TimeToReduce:" .. " " ..TimeToReduce .. " " .. "NewRespawnTime:" .. " " .. NewRespawnTime, 0, 0)
	    end

	    timeLeft = timeLeft + addedTime
	    --print(timeLeft)

	    if timeLeft < 1 then
	        timeLeft = 1
	    end

	    killedUnit:SetTimeUntilRespawn(timeLeft)
    end

end

function CMegaDotaGameMode:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )

	if spawnedUnit:IsRealHero() then
		-- Silencer Nerf
		Timers:CreateTimer(1, function()
			if spawnedUnit:HasModifier("modifier_silencer_int_steal") then
				spawnedUnit:RemoveModifierByName('modifier_silencer_int_steal')
				spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_silencer_new_int_steal", {})
			end
		end)

		if self.couriers[spawnedUnit:GetTeamNumber()] then
			self.couriers[spawnedUnit:GetTeamNumber()]:SetControllableByPlayer(spawnedUnit:GetPlayerID(), true)
		end

		if not spawnedUnit.firstTimeSpawned then
			spawnedUnit.firstTimeSpawned = true
			spawnedUnit:SetContextThink("HeroFirstSpawn", function()
				local playerId = spawnedUnit:GetPlayerID()
				if spawnedUnit == PlayerResource:GetSelectedHeroEntity(playerId) then
					Patreons:GiveOnSpawnBonus(playerId)
				end
			end, 2/30)
		end
	end
end

function CMegaDotaGameMode:ModifierGainedFilter(filterTable)
	if filterTable.name_const == "modifier_tiny_toss" then
		local parent = EntIndexToHScript(filterTable.entindex_parent_const)
		local caster = EntIndexToHScript(filterTable.entindex_caster_const)
		local ability = EntIndexToHScript(filterTable.entindex_ability_const)
 		if PlayerResource:IsDisableHelpSetForPlayerID(parent:GetPlayerOwnerID(), caster:GetPlayerOwnerID()) then
			ability:EndCooldown()
			ability:RefundManaCost()
			DisplayError(caster:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
			return false
		end
	end
 	return true
end

function DisplayError(playerId, message)
	local player = PlayerResource:GetPlayer(playerId)
	if player then
		CustomGameEventManager:Send_ServerToPlayer(player, "display_custom_error", { message = message })
	end
end

function CMegaDotaGameMode:RuneSpawnFilter(kv)
	local r = RandomInt( 0, 5 )

	if r == 5 then r = 6 end

	kv.rune_type = r

	return true
end

CustomGameEventManager:RegisterListener("set_disable_help", function(_, data)
	local to = data.to;
	if PlayerResource:IsValidPlayerID(to) then
		local playerId = data.PlayerID;
		local disable = data.disable == 1
		PlayerResource:SetUnitShareMaskForPlayer(playerId, to, 4, disable)
 		local disableHelp = CustomNetTables:GetTableValue("disable_help", tostring(playerId)) or {}
		disableHelp[tostring(to)] = disable
		CustomNetTables:SetTableValue("disable_help", tostring(playerId), disableHelp)
	end
end)

function CMegaDotaGameMode:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		-- update the scale factor:
	 	-- * SCALE_FACTOR_INITIAL at the start of the game
		-- * SCALE_FACTOR_FINAL after SCALE_FACTOR_FADEIN_SECONDS have elapsed
		local curTime = GameRules:GetDOTATime( false, false )
		local goldFracTime = math.min( math.max( curTime / GOLD_SCALE_FACTOR_FADEIN_SECONDS, 0 ), 1 )
		local xpFracTime = math.min( math.max( curTime / XP_SCALE_FACTOR_FADEIN_SECONDS, 0 ), 1 )
		self.m_CurrentGoldScaleFactor = GOLD_SCALE_FACTOR_INITIAL + (goldFracTime * ( GOLD_SCALE_FACTOR_FINAL - GOLD_SCALE_FACTOR_INITIAL ) )
		self.m_CurrentXpScaleFactor = XP_SCALE_FACTOR_INITIAL + (xpFracTime * ( XP_SCALE_FACTOR_FINAL - XP_SCALE_FACTOR_INITIAL ) )
--		print( "Gold scale = " .. self.m_CurrentGoldScaleFactor )
--		print( "XP scale = " .. self.m_CurrentXpScaleFactor )
	end
	return 5
end


function CMegaDotaGameMode:FilterBountyRunePickup( filterTable )
--	print( "FilterBountyRunePickup" )
--  for k, v in pairs( filterTable ) do
--  	print("MG: " .. k .. " " .. tostring(v) )
--  end
	filterTable["gold_bounty"] = self.m_CurrentGoldScaleFactor * filterTable["gold_bounty"]
	filterTable["xp_bounty"] = self.m_CurrentXpScaleFactor * filterTable["xp_bounty"]
	return true
end

function CMegaDotaGameMode:FilterModifyGold( filterTable )
--	print( "FilterModifyGold" )
--	print( self.m_CurrentGoldScaleFactor )
	filterTable["gold"] = self.m_CurrentGoldScaleFactor * filterTable["gold"]
	return true
end

function CMegaDotaGameMode:FilterModifyExperience( filterTable )
--	print( "FilterModifyExperience" )
--	print( self.m_CurrentXpScaleFactor )
	filterTable["experience"] = self.m_CurrentXpScaleFactor * filterTable["experience"]
	return true
end

function CMegaDotaGameMode:OnGameRulesStateChange(keys)
	print("[BAREBONES] GameRules State Changed")
	DeepPrintTable(keys)

	local newState = GameRules:State_Get()
    if newState == DOTA_GAMERULES_STATE_STRATEGY_TIME then
		local ggp = 0
		local bgp = 0
		local ggcolor = {
			{70,70,255},
			{0,255,255},
			{255,0,255},
			{255,255,0},
			{255,165,0},
			{0,255,0},
			{255,0,0},
			{75,0,130},
			{109,49,19},
			{255,20,147},
			{128,128,0},
			{255,255,255}
		}
		local bgcolor = {
			{255,135,195},
			{160,180,70},
			{100,220,250},
			{0,128,0},
			{165,105,0},
			{153,50,204},
			{0,128,128},
			{0,0,165},
			{128,0,0},
			{180,255,180},
			{255,127,80},
			{0,0,0}
		}
		for i=0, PlayerResource:GetPlayerCount()-1 do
			if PlayerResource:GetTeam(i) == DOTA_TEAM_GOODGUYS then
				ggp = ggp + 1
				PlayerResource:SetCustomPlayerColor(i,ggcolor[ggp][1],ggcolor[ggp][2],ggcolor[ggp][3])
			end
			if PlayerResource:GetTeam(i) == DOTA_TEAM_BADGUYS then
				bgp = bgp + 1
				PlayerResource:SetCustomPlayerColor(i,bgcolor[bgp][1],bgcolor[bgp][2],bgcolor[bgp][3])
			end
		end

        for i=0, DOTA_MAX_TEAM_PLAYERS do
            if PlayerResource:IsValidPlayer(i) then
                if PlayerResource:HasSelectedHero(i) == false then

                    local player = PlayerResource:GetPlayer(i)
                    player:MakeRandomHeroSelection()

                    local hero_name = PlayerResource:GetSelectedHeroName(i)
                end
            end
        end
	elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
        
        local toAdd = {
            luna_moon_glaive_fountain = 4,
            ursa_fury_swipes_fountain = 1,
        }

        local fountains = Entities:FindAllByClassname('ent_dota_fountain')
        -- Loop over all ents
        for k,fountain in pairs(fountains) do
            for skillName,skillLevel in pairs(toAdd) do
                fountain:AddAbility(skillName)
                local ab = fountain:FindAbilityByName(skillName)
                if ab then
                    ab:SetLevel(skillLevel)
                end
            end

            local item = CreateItem('item_monkey_king_bar_fountain', fountain, fountain)
            if item then
                fountain:AddItem(item)
            end

        end
 
		local courier_spawn = {}
		courier_spawn[2] = Entities:FindByClassname(nil, "info_courier_spawn_radiant")
		courier_spawn[3] = Entities:FindByClassname(nil, "info_courier_spawn_dire")

		for team = 2, 3 do
			self.couriers[team] = CreateUnitByName("npc_dota_courier", courier_spawn[team]:GetAbsOrigin(), true, nil, nil, team)
			self.couriers[team]:AddNewModifier(self.couriers[team], nil, "modifier_core_courier", {})
		end

--		Timers:CreateTimer(30, function()
--			for i=0,PlayerResource:GetPlayerCount() do
--				local hero = PlayerResource:GetSelectedHeroEntity(i)
--				if hero ~= nil then
--					if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
--						hero:AddItemByName("item_courier")
--						break
--					end
--				end
--			end
--			for i=0,PlayerResource:GetPlayerCount() do
--				local hero = PlayerResource:GetSelectedHeroEntity(i)
--				if hero ~= nil then
--					if hero:GetTeam() == DOTA_TEAM_BADGUYS then
--						hero:AddItemByName("item_courier")
--						break
--					end
--				end
--			end
--		end)
	end
end

function CMegaDotaGameMode:ItemAddedToInventoryFilter( filterTable )
	if filterTable["item_entindex_const"] == nil then
		return true
	end
 	if filterTable["inventory_parent_entindex_const"] == nil then
		return true
	end
	local hInventoryParent = EntIndexToHScript( filterTable["inventory_parent_entindex_const"] )
	local hItem = EntIndexToHScript( filterTable["item_entindex_const"] )
	if hItem ~= nil and hInventoryParent ~= nil then
		local itemName = hItem:GetName()
		if hInventoryParent:IsRealHero() then
			local plyID = hInventoryParent:GetPlayerID()
			if not plyID then return true end
			local pitems = {
			--	"item_patreon_1",
			--	"item_patreon_2",
			--	"item_patreon_3",
			--	"item_patreon_4",
			--	"item_patreon_5",
			--	"item_patreon_6",
			--	"item_patreon_7",
			--	"item_patreon_8",
				"item_patreonbundle_1",
				"item_patreonbundle_2"
			}
			local pitem = false
			for i=1,#pitems do
				if itemName == pitems[i] then
					pitem = true
					break
				end
			end
			if pitem == true then
				local psets = Patreons:GetPlayerSettings(plyID)
				if psets.level < 1 then
					CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(plyID), "display_custom_error", { message = "#nopatreonerror" })
					UTIL_Remove(hItem)
					return false
				end
			end
			if itemName == "item_banhammer" then
				local psets = Patreons:GetPlayerSettings(plyID)
				if psets.level < 2 then
					CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(plyID), "display_custom_error", { message = "#nopatreonerror2" })
					UTIL_Remove(hItem)
					return false
				else
					if GameRules:GetDOTATime(false,false) < 300 then
						CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(plyID), "display_custom_error", { message = "#notyettime" })
						UTIL_Remove(hItem)
						return false
					end
				end
			end
		else
			local pitems = {
				"item_patreonbundle_1",
				"item_patreonbundle_2",
				"item_banhammer"
			}
			for i=1,#pitems do
				if itemName == pitems[i] then
					local prsh = hItem:GetPurchaser()
					if prsh ~= nil then
						if prsh:IsRealHero() then
							local prshID = prsh:GetPlayerID()
							if not prshID then
								UTIL_Remove(hItem)
								return false
							end
							local psets = Patreons:GetPlayerSettings(prshID)
							if not psets then
								UTIL_Remove(hItem)
								return false
							end
							if itemName == "item_banhammer" then
								if psets.level < 2 then
									CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(prshID), "display_custom_error", { message = "#nopatreonerror2" })
									UTIL_Remove(hItem)
									return false
								else
									if GameRules:GetDOTATime(false,false) < 300 then
										CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(prshID), "display_custom_error", { message = "#notyettime" })
										UTIL_Remove(hItem)
										return false
									end
								end
							else
								if psets.level < 1 then
									CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(prshID), "display_custom_error", { message = "#nopatreonerror" })
									UTIL_Remove(hItem)
									return false
								end
							end
						else
							UTIL_Remove(hItem)
							return false
						end
					else
						UTIL_Remove(hItem)
						return false
					end
				end
			end
		end
	end

	return true
end

function CMegaDotaGameMode:GetKicks( data )
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.id), "setkicks", {kicks = _G.kicks})
end

function CMegaDotaGameMode:ExecuteOrderFilter(filterTable)
	local target = nil
	local order_type = filterTable.order_type
	local playerId = filterTable.issuer_player_id_const
	local ability = EntIndexToHScript(filterTable.entindex_ability)
	local unit = nil
	local abilityname = nil
	if ability and ability.GetAbilityName then
		abilityname = ability:GetAbilityName()
	end

	if filterTable.units ~= nil then
		if filterTable.units["0"] ~= nil then
			unit = EntIndexToHScript(filterTable.units["0"])
		end
	end
	if filterTable.entindex_target and filterTable.entindex_target ~= 0 then
		target = EntIndexToHScript(filterTable.entindex_target)
	end

	if order_type == DOTA_UNIT_ORDER_CAST_TARGET then
		if ability and target and unit then
			if PlayerResource:IsDisableHelpSetForPlayerID(target:GetPlayerOwnerID(), unit:GetPlayerOwnerID()) and (ability:GetName() == "oracle_fates_edict" or ability:GetName() == "oracle_purifying_flames" or ability:GetName() == "wisp_tether" or ability:GetName() == "earth_spirit_boulder_smash" or ability:GetName() == "earth_spirit_geomagnetic_grip" or ability:GetName() == "earth_spirit_petrify" or ability:GetName() == "troll_warlord_battle_trance") then
				DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
				return false
			end
		end
	end

	if order_type == DOTA_UNIT_ORDER_CAST_POSITION then
		if abilityname == "item_ward_dispenser" or abilityname == "item_ward_sentry" or abilityname == "item_ward_observer" then
			local list = Entities:FindAllByClassname("trigger_multiple")
			local orderVector = Vector(filterTable.position_x, filterTable.position_y, 0)
			local fs = {
				Vector(5000,6912,0),
				Vector(-5300,-6938,0)
			}
			if PlayerResource:GetTeam(playerId) == 2 then
				fs = {fs[2],fs[1]}
			end
			for i=1,#list do
				if list[i]:GetName():find("neutralcamp") ~= nil then
					if IsInTriggerBox(list[i], 12, orderVector) and ( fs[1] - orderVector ):Length2D() < ( fs[2] - orderVector ):Length2D() then
						CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "display_custom_error", { message = "#block_spawn_error" })
						return false
					end
				end
			end
		end
	end

	if unit then
		if unit:IsCourier() then
			if (order_type == DOTA_UNIT_ORDER_DROP_ITEM or order_type == DOTA_UNIT_ORDER_GIVE_ITEM) and ability and ability:IsItem() then
				local purchaser = ability:GetPurchaser()
				if purchaser and purchaser:GetPlayerID() ~= playerId then
					--CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "display_custom_error", { message = "#hud_error_courier_cant_order_item" })
					return false
				end
			end
		end
	end
	return true
end

msgtimer = {}
function CMegaDotaGameMode:OnTimerClick(keys)
	print(GameRules:GetGameTime())
	if msgtimer[keys.id] ~= nil then
		if GameRules:GetGameTime() - msgtimer[keys.id] > 3 then
			Say(PlayerResource:GetPlayer(keys.id), keys.time, true)
			msgtimer[keys.id] = GameRules:GetGameTime()
		end
	else
		Say(PlayerResource:GetPlayer(keys.id), keys.time, true)
		msgtimer[keys.id] = GameRules:GetGameTime()
	end
end