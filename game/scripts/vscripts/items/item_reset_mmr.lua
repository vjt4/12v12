item_reset_mmr = item_reset_mmr or class({})

function item_reset_mmr:OnSpellStart(event)
	if not IsServer() then return end
	
	local playerId = self:GetCaster():GetPlayerOwnerID()
	if not playerId then return end
	
	local suppState = Supporters.playerState[playerId];
	local resetDate = ""
	if suppState and suppState.resetDate then
		resetDate = suppState.resetDate
	end

	CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerId), "show_reset_mmr", {
		resetDate = resetDate;
		suppLevel = Supporters:GetLevel(playerId);
	})
	self:RemoveSelf()
end
