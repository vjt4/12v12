--[[
	This items fast travel for ALL players
--]]
local fastItems = {
	["item_disable_help_custom"] = true,
	["item_mute_custom"] = true,
	["item_voiting_troll"] = true,
}

--[[
	You need pul all item that have stock value (for example, wards, smoke, kick troll item, gem etc.)
--]]
_G.stackedItems = {
	["item_ward_observer"] = true,
	["item_ward_sentry"] = true,
	["item_smoke_of_deceit"] = true,
	["item_tome_of_knowledge"] = true,
	["item_banhammer"] = true,
	["item_gem"] = true,
}

_G.itemsIsBuy = {}

function CDOTA_Item:IsFastBuying()
	return fastItems[self:GetName()]
end

function DoesHeroHasFreeSlot(unit)
	for i = 0, 15 do
		if unit:GetItemInSlot(i) == nil then
			return i
		end
	end
	return false
end

function CDOTA_BaseNPC:GetItemByNameFromStash(itemName)
	for i = 9, 16 do
		local currentItem = self:GetItemInSlot(i)
		if currentItem then
			local currentName = currentItem:GetName()
			if currentName == itemName then
				return {
					["item"] = currentItem,
					["slot"] = i
				}
			end
		end
	end
	return nil
end

function CDOTA_Item:TransferToBuyer(unit)
	local buyer = self:GetPurchaser()
	local buyerEntIndex = buyer:GetEntityIndex()
	local itemName = self:GetName()
	local unique_key = itemName .. "_" .. buyerEntIndex

	if unit:IsIllusion() or unit:IsCourier() then
		return
	end
	if not DoesHeroHasFreeSlot(buyer) and not _G.stackedItems[itemName] then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(buyer:GetPlayerID()), "display_custom_error", { message = "#dota_hud_error_cant_purchase_inventory_full" })
		return false
	end

	_G.itemsIsBuy[unique_key] = not _G.itemsIsBuy[unique_key]

	if _G.itemsIsBuy[unique_key] == true then
		if not _G.stackedItems[itemName] then
			UTIL_Remove(self)
			buyer:AddItemByName(itemName)
			return false
		else
			Timers:CreateTimer(0.04, function()
				local item = buyer:GetItemByNameFromStash(itemName)
				if item and item["item"] == self then
					UTIL_Remove(self)
					buyer:AddItemByName(itemName)
				end
				local unique_key_cd = itemName .. "_" .. buyerEntIndex
				_G.lastTimeBuyItemWithCooldown[unique_key_cd] = GameRules:GetGameTime()
			end)
		end
	end
end