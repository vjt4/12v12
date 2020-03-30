_G.votingForKick = nil
local timeToVoting = 60
local votesToKick = 6
local reasonCheck = {
	["feeding"] = true,
	["ability_abuse"] = true,
	["hateful_talk"] = true,
}
RegisterCustomEventListener("voting_to_kick_reason_is_picked", function(data)
	if not _G.votingForKick then
		_G.votingForKick = {}
		local playerInit = PlayerResource:GetPlayer(data.PlayerID)
		local heroInit = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
		local heroTarget = heroInit.wantToKick

		if not heroTarget then return end
		if not reasonCheck[data.reason] then return end
		local playerTarget = heroTarget:GetPlayerOwner()

		_G.votingForKick.reason = data.reason
		_G.votingForKick.init = data.PlayerID
		_G.votingForKick.target = playerTarget:GetPlayerID()
		_G.votingForKick.votes = 1

		CustomGameEventManager:Send_ServerToTeam(playerInit:GetTeam(), "voting_to_kick_show_voting", { playerId = playerTarget:GetPlayerID(), reason = data.reason, playerIdInit = data.PlayerID})
		CustomGameEventManager:Send_ServerToPlayer(playerInit, "voting_to_kick_hide_reason", {})

		Timers:CreateTimer("start_voting_to_kick", {
			useGameTime = false,
			endTime = timeToVoting,
			callback = function()
				CustomGameEventManager:Send_ServerToTeam(playerInit:GetTeam(), "voting_to_kick_hide_voting", {})
				if _G.votingForKick.votes < votesToKick then
					GameRules:SendCustomMessageToTeam("#voting_to_kick_voting_failed", playerInit:GetTeam(), _G.votingForKick.target, 0)
				end
				_G.votingForKick = nil
				return nil
			end
		})

	else
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "display_custom_error", { message = "#voting_to_kick_voiting_for_now" })
	end
end)

RegisterCustomEventListener("voting_to_kick_vote_yes", function(data)
	if _G.votingForKick then
		_G.votingForKick = _G.votingForKick + 1
		if _G.votingForKick >= votesToKick then
			_G.kicks[_G.votingForKick.target+1] = true
			Timers:RemoveTimer("start_voting_to_kick")
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(_G.votingForKick.target), "setkicks", {kicks = _G.kicks})
			GameRules:SendCustomMessage("#voting_to_kick_player_kicked", _G.votingForKick.target, 0)
			_G.votingForKick = nil
		end
	end
end)

RegisterCustomEventListener("voting_to_kick_check_voting_state", function(data)
	if _G.votingForKick then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "voting_to_kick_show_voting", {
			playerId = _G.votingForKick.target,
			reason = _G.votingForKick.reason,
			playerIdInit = _G.votingForKick.init
		})
	end
end)