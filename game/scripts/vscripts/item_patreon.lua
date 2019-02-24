function OnSpellStart( event )
    local caster = event.caster
    local psets = Patreons:GetPlayerSettings(caster:GetPlayerID())
    if psets.level > 0 then
        local pa1 = caster:AddAbility("seasonal_summon_cny_balloon")
        pa1:SetLevel(1)
        pa1:CastAbility()
        caster:RemoveAbility("seasonal_summon_cny_balloon")
    else
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(caster:GetPlayerID()), "display_custom_error", { message = "Error Test" })--need error text
    end
end