modifier_fix_neutral = {
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	RemoveOnDeath = function() return false end,

	CheckState = function()
		return {
			[MODIFIER_STATE_INVISIBLE] = true,
		}
	end,
}

function modifier_fix_neutral:OnDestroy()
	local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, self:GetCaster():GetAbsOrigin(), nil, 375, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	if #units ~= 0 then
		local spawn = true
		for i=1,#units do
			if units[i] ~= self:GetCaster() then
				if units[i]:GetTeam() == DOTA_TEAM_NEUTRALS then
					if GameRules:GetDOTATime(false,true)-units[i].mycreationtime > 3 then
						spawn = false
					end
				else
					spawn = false
				end
			end
		end
		if spawn == false then
			--print("remove")
			self:GetCaster():RemoveSelf()
		end
	end
end