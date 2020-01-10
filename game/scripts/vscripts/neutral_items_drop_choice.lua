function DropItem(data)
	local item = EntIndexToHScript( data.item )
	local player = PlayerResource:GetPlayer(data.PlayerID)

	local team = player:GetTeam()
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
	local pos_item = fountain_pos:Normalized() * multiplier + RandomVector( RandomFloat( 0, 200 ) ) + fountain_pos
	pos_item.z = fountain_pos.z

	CreateItemOnPositionSync(pos_item, item)
	item.neutralDropInBase = true
	for i = 0, 24 do
		if PlayerResource:GetTeam(i) == team then
			CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( i ), "neutral_item_dropped", { item = data.item } )
		end
	end
end

function NotificationToAllPlayerOnTeam(data)
	for id = 0, 24 do
		if PlayerResource:GetTeam( data.PlayerID ) == PlayerResource:GetTeam( id ) then
			CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "neutral_item_taked", { item = data.item, player = data.PlayerID } )
		end
	end
end

RegisterCustomEventListener( "neutral_item_keep", function( data )
	local item = EntIndexToHScript( data.item )
	local hero = PlayerResource:GetSelectedHeroEntity( data.PlayerID )
	local freeSlot = DoesHeroHasFreeSlot(hero)
	if freeSlot then
		hero:AddItem(item)
		NotificationToAllPlayerOnTeam(data)
	else
		DropItem(data)
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "display_custom_error", { message = "#inventory_full_custom_message" })
	end
end )

RegisterCustomEventListener( "neutral_item_take", function( data )
	local item = EntIndexToHScript( data.item )
	local hero = PlayerResource:GetSelectedHeroEntity( data.PlayerID )
	local freeSlot = DoesHeroHasFreeSlot(hero)

	if freeSlot then
		local container = item:GetContainer()
		UTIL_Remove( container )
		item.neutralDropInBase = false
		hero:AddItem( item )
		NotificationToAllPlayerOnTeam(data)
	else
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "display_custom_error", { message = "#inventory_full_custom_message" })
	end
end )

RegisterCustomEventListener( "neutral_item_drop", function( data )
	DropItem(data)
end )