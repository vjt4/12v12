_G.lastTimeBuyItemWithCooldown = {}
local infinityCooldown = 999999

_G.itemsCooldownForPlayer = {
	["item_disable_help_custom"] = 10,
	["item_mute_custom"] = 10,
	["item_tome_of_knowledge"] = 300,
	["item_banhammer"] = 600,
}

_G.maximumItemsForPlayers = { --how many items separate player can buy in game
	["item_banhammer"] = 2,
}
_G.maximumItemsForPlayersData = {}

function CDOTA_Item:HasPersonalCooldown()
	return itemsCooldownForPlayer[self:GetName()] and true
end

function MessageToPlayerItemCooldown(itemName, playerID)
	if _G.itemsCooldownForPlayer[itemName] and _G.itemsCooldownForPlayer[itemName] < infinityCooldown then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "#fast_buy_items" })
	else
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "#you_can_buy_only_one_item" })
	end
end

function CheckMaxItemCount(item, unique_key,playerID,checker)
	local itemName = item:GetAbilityName()
	if _G.maximumItemsForPlayers[itemName] then
		if not _G.maximumItemsForPlayersData[unique_key] then
			_G.maximumItemsForPlayersData[unique_key] = 1
		else
			if _G.maximumItemsForPlayersData[unique_key] >=  _G.maximumItemsForPlayers[itemName] then
				CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "you_cannot_buy_more_items_this_type" })
				return false
			elseif checker then
				_G.maximumItemsForPlayersData[unique_key] = _G.maximumItemsForPlayersData[unique_key]+1
			end
		end
	end
	return true
end

function CDOTA_BaseNPC:CheckPersonalCooldown(item)
	local buyerEntIndex = self:GetEntityIndex()
	local itemName = item:GetAbilityName()
	local unique_key = itemName .. "_" .. buyerEntIndex
	local playerID = self:GetPlayerID()
	local supporter_level = Supporters:GetLevel(playerID)

	if _G.lastTimeBuyItemWithCooldown[unique_key] == nil or (_G.itemsCooldownForPlayer[itemName] and (GameRules:GetGameTime() - _G.lastTimeBuyItemWithCooldown[unique_key]) >= _G.itemsCooldownForPlayer[itemName]) then
		if not _G.stackedItems[itemName] then
			_G.lastTimeBuyItemWithCooldown[unique_key] = GameRules:GetGameTime()
			local checkMaxCount = CheckMaxItemCount(item, unique_key, playerID, true)
			return (true and checkMaxCount)
		elseif not ItemIsFastBuying(itemName) and (not (supporter_level > 0)) then
			_G.lastTimeBuyItemWithCooldown[unique_key] = GameRules:GetGameTime()
			local checkMaxCount = CheckMaxItemCount(item, unique_key, playerID, true)
			return (true and checkMaxCount)
		end
	elseif _G.itemsCooldownForPlayer[itemName] then
		if _G.stackedItems[itemName] then
			if not ItemIsFastBuying(itemName) and (not (supporter_level > 0)) then
				local checkMaxCount = CheckMaxItemCount(item, unique_key, playerID, false)
				if checkMaxCount then
					MessageToPlayerItemCooldown(itemName, playerID)
				end
				return false
			end
		else
			local checkMaxCount = CheckMaxItemCount(item, unique_key, playerID, false)
			if checkMaxCount then
				MessageToPlayerItemCooldown(itemName, playerID)
			end
			return false
		end
	end
	return true
end
