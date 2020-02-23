patreon_perk_bonus_all_stats_t0 = class({})
--------------------------------------------------------------------------------

function patreon_perk_bonus_all_stats_t0:IsHidden()
	return true
end

--------------------------------------------------------------------------------

function patreon_perk_bonus_all_stats_t0:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_bonus_all_stats_t0:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_bonus_all_stats_t0:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_bonus_all_stats_t0:GetModifierBonusStats_Agility(params)
	return GetPerkValue(0, self, 1, 0.25)
end

--------------------------------------------------------------------------------
function patreon_perk_bonus_all_stats_t0:GetModifierBonusStats_Intellect(params)
	return GetPerkValue(0, self, 1, 0.25)
end

--------------------------------------------------------------------------------
function patreon_perk_bonus_all_stats_t0:GetModifierBonusStats_Strength(params)
	return GetPerkValue(0, self, 1, 0.25)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------