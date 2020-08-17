modifier_bonus_for_weak_team_in_mmr = class({})

--------------------------------------------------------------------------------
function modifier_bonus_for_weak_team_in_mmr:IsHidden()
	return false
end
--------------------------------------------------------------------------------
function modifier_bonus_for_weak_team_in_mmr:GetTexture()
	return "mmr_balance"
end
--------------------------------------------------------------------------------
function modifier_bonus_for_weak_team_in_mmr:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function modifier_bonus_for_weak_team_in_mmr:DestroyOnExpire()
	return false
end
--------------------------------------------------------------------------------
function modifier_bonus_for_weak_team_in_mmr:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------
function modifier_bonus_for_weak_team_in_mmr:OnCreated( params )
	if not IsServer() then return end
	self.bonusPct = params.bonusPct
end
--------------------------------------------------------------------------------
function modifier_bonus_for_weak_team_in_mmr:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_EXP_RATE_BOOST,
	}
	return funcs
end
--------------------------------------------------------------------------------
function modifier_bonus_for_weak_team_in_mmr:GetModifierPercentageExpRateBoost( params )
	if not IsServer() then return end
	return self.bonusPct
end
--------------------------------------------------------------------------------
