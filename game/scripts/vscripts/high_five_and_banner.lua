ListenToGameEvent( "npc_spawned", function( keys )
	local npc = EntIndexToHScript( keys.entindex )

	if npc:IsRealHero() and not npc:FindAbilityByName( "high_five" ) then
		local high_five = npc:AddAbility( "high_five" )
		high_five:SetLevel( 1 )
		high_five:SetHidden( true )
		local banner = npc:AddAbility( "seasonal_ti9_banner" )
		banner:SetLevel( 1 )
		banner:SetHidden( true )
	end
end, nil )

CustomGameEventManager:RegisterListener( "cons_ability_activate", function( id, keys )
	local npc = EntIndexToHScript( keys.unit )
	if not npc then return end
	local ability = npc:FindAbilityByName( keys.ability )

	if ability then
		npc:SetCursorPosition( npc:GetAbsOrigin() )
		ability:CastAbility()
	end
end )