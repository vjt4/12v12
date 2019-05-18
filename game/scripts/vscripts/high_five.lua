ListenToGameEvent( "npc_spawned", function( keys )
	local npc = EntIndexToHScript( keys.entindex )

	if npc:IsRealHero() and not npc:FindAbilityByName( "high_five" ) then
		local high_five = npc:AddAbility( "high_five" )
		high_five:SetLevel( 1 )
		high_five:SetHidden( true )
	end
end, nil )

CustomGameEventManager:RegisterListener( "high_five_activate", function( id, keys )
	local npc = EntIndexToHScript( keys.unit )
	local high_five = npc:FindAbilityByName( "high_five" )

	if high_five then
		npc:CastAbilityNoTarget( high_five, id or -1 )
	end
end )