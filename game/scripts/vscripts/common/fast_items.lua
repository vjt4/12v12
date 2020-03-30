--[[
	This items doens't fast travel
--]]
local notFastItems = {
	["item_ward_observer"] = true,
	["item_ward_sentry"] = true,
	["item_smoke_of_deceit"] = true,
	["item_clarity"] = true,
	["item_flask"] = true,
	["item_greater_mango"] = true,
	["item_enchanted_mango"] = true,
	["item_tango"] = true,
	["item_faerie_fire"] = true,
	["item_tpscroll"] = true,
	["item_dust"] = true,
}
--[[
	This items fast travel for ALL players
--]]
local fastItems = {
	["item_disable_help_custom"] = true,
	["item_mute_custom"] = true,
}

--[[
	You need pul all item that have stock value (for example, wards, smoke, kick troll item, gem etc.)
--]]
_G.stackedItems = {
	["item_ward_observer"] = true,
	["item_ward_sentry"] = true,
	["item_smoke_of_deceit"] = true,
	["item_tome_of_knowledge"] = true,
	["item_gem"] = true,
}

_G.itemsIsBuy = {}

function ItemIsFastBuying(itemName)
	return fastItems[itemName]
end

function DoesHeroHasFreeSlot(unit)
	for i = 0, 15 do
		if unit:GetItemInSlot(i) == nil then
			return i
		end
	end
	return false
end

function CDOTA_Item:SetCooldownStackedItem(itemName, buyer)
	if _G.itemsCooldownForPlayer[itemName] then
		local buyerEntIndex = buyer:GetEntityIndex()
		Timers:CreateTimer(0.04, function()
			local itemCost = self:GetCost()
			local item = self
			if not notFastItems[itemName] then
				UTIL_Remove(item)
				item = buyer:AddItemByName(itemName)
			end
			local unique_key_cd = itemName .. "_" .. buyerEntIndex
			if _G.lastTimeBuyItemWithCooldown[unique_key_cd] == nil or (_G.itemsCooldownForPlayer[itemName] and (GameRules:GetGameTime() - _G.lastTimeBuyItemWithCooldown[unique_key_cd]) >= _G.itemsCooldownForPlayer[itemName]) then
				_G.lastTimeBuyItemWithCooldown[unique_key_cd] = GameRules:GetGameTime()
			elseif _G.itemsCooldownForPlayer[itemName] then
				buyer:ModifyGold(itemCost, false, 0)
				MessageToPlayerItemCooldown(itemName, buyer:GetPlayerID())
				UTIL_Remove(item)
			end
		end)
	end
end

function CDOTA_Item:TransferToBuyer(unit)
	local buyer = self:GetPurchaser()
	local buyerEntIndex = buyer:GetEntityIndex()
	local itemName = self:GetName()
	if notFastItems[itemName] then
		self:SetCooldownStackedItem(itemName, buyer)
		return
	end
	local unique_key = itemName .. "_" .. buyerEntIndex

	if unit:IsIllusion() then
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
			self:SetCooldownStackedItem(itemName, buyer)
		end
	end
end