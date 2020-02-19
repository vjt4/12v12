DisableHelp = DisableHelp or {}

RegisterCustomEventListener("set_disable_help", function(data)
	local to = data.to;
	if PlayerResource:IsValidPlayerID(to) then
		local playerId = data.PlayerID;
		local disable = data.disable == 1
		PlayerResource:SetUnitShareMaskForPlayer(playerId, to, 4, disable)

		local disableHelp = CustomNetTables:GetTableValue("disable_help", tostring(playerId)) or {}
		disableHelp[tostring(to)] = disable
		CustomNetTables:SetTableValue("disable_help", tostring(playerId), disableHelp)
	end
end)

local disabledModifiers = {
	modifier_tiny_toss = true,
}

function DisableHelp.ModifierGainedFilter(filterTable)
	if disabledModifiers[filterTable.name_const] then
		local parent = EntIndexToHScript(filterTable.entindex_parent_const)
		local caster = EntIndexToHScript(filterTable.entindex_caster_const)
		local ability = EntIndexToHScript(filterTable.entindex_ability_const)

		if PlayerResource:IsDisableHelpSetForPlayerID(parent:GetPlayerOwnerID(), caster:GetPlayerOwnerID()) then
			ability:EndCooldown()
			ability:RefundManaCost()
			DisplayError(caster:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
			return false
		end
	end
end

local disabledAbilities = {
	oracle_fates_edict = true,
	oracle_purifying_flames = true,
	wisp_tether = true,
	earth_spirit_boulder_smash = true,
	earth_spirit_geomagnetic_grip = true,
	earth_spirit_petrify = true,
	troll_warlord_battle_trance = true,
	vengefulspirit_nether_swap = true,
	pugna_decrepify = true,
	furion_sprout = true,
	tiny_toss = true,
}

function DisableHelp.ExecuteOrderFilter(orderType, ability, target, unit, orderVector)
	if not unit or not ability then
		return
	end

	local caster_id = unit:GetPlayerOwnerID()

	if ability:GetAbilityName() == "furion_sprout" then
		if (
			orderType == DOTA_UNIT_ORDER_CAST_TARGET and
			target and
			target:IsRealHero() and
			target ~= unit and
			target:GetTeam() == unit:GetTeam()
		) then
			DisplayError(caster_id, "dota_hud_error_target_has_disable_help")
			return false
		else
			local enemies = FindUnitsInRadius(
				unit:GetTeam(),
				orderVector,
				nil,
				400, 
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO,
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_ANY_ORDER,
				false
			)

			if #enemies == 0 then
				local allies = FindUnitsInRadius(
					unit:GetTeam(),
					orderVector,
					nil,
					400, 
					DOTA_UNIT_TARGET_TEAM_FRIENDLY,
					DOTA_UNIT_TARGET_HERO,
					DOTA_UNIT_TARGET_FLAG_NONE,
					FIND_ANY_ORDER,
					false
				)

				for _, hero in pairs( allies ) do
					if PlayerResource:GetPartyID(hero:GetPlayerOwnerID()) ~= PlayerResource:GetPartyID(caster_id) then
						DisplayError(caster_id, "dota_hud_error_target_has_disable_help")
						return false
					end
				end
			end
		end
	elseif ability:GetAbilityName() == "tiny_toss" and orderType == DOTA_UNIT_ORDER_CAST_TARGET and target then
		local allies = FindUnitsInRadius(
			unit:GetTeam(),
			unit:GetAbsOrigin(),
			nil,
			275, 
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)

		for _, hero in pairs( allies ) do
			if PlayerResource:GetPartyID(hero:GetPlayerOwnerID()) ~= PlayerResource:GetPartyID(caster_id) then
				DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
				return false
			end
		end

		if target:GetTeam() == unit:GetTeam() then
			if PlayerResource:IsDisableHelpSetForPlayerID( target:GetPlayerOwnerID(), caster_id ) then
				DisplayError(caster_id, "dota_hud_error_target_has_disable_help")
				return false
			end
		end
	elseif (
		orderType == DOTA_UNIT_ORDER_CAST_TARGET and
		target and
		disabledAbilities[ability:GetAbilityName()] and
		PlayerResource:IsDisableHelpSetForPlayerID(target:GetPlayerOwnerID(), unit:GetPlayerOwnerID())
	) then
		DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
		return false
	end
end
