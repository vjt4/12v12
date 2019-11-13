_G.lastTimeBuyItemWithCooldown = {}

_G.itemsCooldownForPlayer = {
	["item_tome_of_knowledge"] = 300,
}

function CDOTA_BaseNPC:CheckPersonalCooldown(itemName)
	local buyerEntIndex = self:GetEntityIndex()
	local unique_key = itemName .. "_" .. buyerEntIndex

	if _G.lastTimeBuyItemWithCooldown[unique_key] == nil or (_G.itemsCooldownForPlayer[itemName] and (GameRules:GetGameTime() - _G.lastTimeBuyItemWithCooldown[unique_key]) >= _G.itemsCooldownForPlayer[itemName]) then
		_G.lastTimeBuyItemWithCooldown[unique_key] = GameRules:GetGameTime()
		return true
	elseif _G.itemsCooldownForPlayer[itemName] then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(self:GetPlayerID()), "display_custom_error", { message = "#fast_buy_items"})
		return false
	end

	return true
end