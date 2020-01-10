NeutralItemsTransfer = NeutralItemsTransfer or {}

function NeutralItemsTransfer:Init()
	self.neutralItems = {}
	self.droppedNeutralItems = {}
	self.pickedUpNeutralItems = {}

	local neutral_items = LoadKeyValues("scripts/npc/neutral_items.txt")

	for _, data in pairs( neutral_items ) do
		for item, turn in pairs( data.items ) do
			if turn == 1 then
				self.neutralItems[item] = true
			end
		end
	end

	RegisterCustomEventListener( "neutral_item_drop", function( data )
		self:PlayerDropItem( data )
	end )

	RegisterCustomEventListener( "neutral_item_take", function( data )
		self:PlayerTakeItem( data )
	end )
end

function NeutralItemsTransfer:AddedItem( item, itemIndex, unit )
	local id = unit.GetPlayerID and unit:GetPlayerID() or unit:GetPlayerOwnerID()

	if id == -1 then
		return
	end

	if self.droppedNeutralItems[itemIndex] then
		self:ItemTaked( itemIndex, id, PlayerResource:GetTeam( id ) )
	elseif self.neutralItems[item:GetAbilityName()] and not self.pickedUpNeutralItems[itemIndex] then
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( id ), "neutral_item_picked_up", { item = itemIndex } )
		self.pickedUpNeutralItems[itemIndex] = true
	end
end

function NeutralItemsTransfer:PlayerDropItem( data )
	local item = EntIndexToHScript( data.item )
	local caster = item:GetCaster()
	local id = caster.GetPlayerID and caster:GetPlayerID() or caster:GetPlayerOwnerID()

	if id == data.PlayerID then
		local team = caster:GetTeam()
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

		caster:DropItemAtPositionImmediate( item, pos_item )
		item.team = team

		self.droppedNeutralItems[data.item] = true

		for i = 0, 24 do
			if --[[i ~= data.PlayerID and ]]PlayerResource:GetTeam( i ) == team then
				CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( i ), "neutral_item_dropped", { item = data.item } )
			end
		end
	end
end

function NeutralItemsTransfer:PlayerTakeItem( data )
	local item = EntIndexToHScript( data.item )
	local hero = PlayerResource:GetSelectedHeroEntity( data.PlayerID )
	local team = PlayerResource:GetTeam( data.PlayerID )

	if not item or not hero or not self.droppedNeutralItems[data.item] or item.team ~= team then
		return
	end

	for i = 0, 8 do
		local slot = hero:GetItemInSlot( i )

		if not slot then
			local container = item:GetContainer()
			UTIL_Remove( container )

			hero:AddItem( item )

			self:ItemTaked( data.item, data.PlayerID, team )

			break
		end
	end
end

function NeutralItemsTransfer:ItemTaked( itemIndex, id, team )
	self.droppedNeutralItems[itemIndex] = nil

	for i = 0, 24 do
		if team == PlayerResource:GetTeam( i ) then
			CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer( i ), "neutral_item_taked", { item = itemIndex, player = id } )
		end
	end
end