local fastItems = {
	["item_disable_help_custom"] = true,
	["item_mute_custom"] = true,
	["item_voiting_troll"] = true,
}
_G.itemsIsBuy = {}

function CDOTA_Item:IsFastBuying()
	return fastItems[self:GetName()]
end

function DoesHeroHasFreeSlot(unit)
	for i = 0, 15 do
		if unit:GetItemInSlot(i) == nil then
			return true
		end
	end
	return false
end

function CDOTA_Item:TransferToBuyer()
	local buyer = self:GetPurchaser()
	local buyerEntIndex = buyer:GetEntityIndex()
	local itemName = self:GetName()
	local unique_key = itemName .. "_" .. buyerEntIndex
	local plyID = buyer:GetPlayerID()

	_G.itemsIsBuy[unique_key] = not _G.itemsIsBuy[unique_key]

	if DoesHeroHasFreeSlot(buyer) and (_G.itemsIsBuy[unique_key] == true) then
		UTIL_Remove(self)
		buyer:AddItemByName(itemName)
		return false
	elseif not DoesHeroHasFreeSlot(buyer) then
		buyer:ModifyGold(self:GetCost(), false, 0)
		UTIL_Remove(self)
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(plyID), "display_custom_error", { message = "#dota_hud_error_cant_purchase_inventory_full" })
		return false
	end
end
