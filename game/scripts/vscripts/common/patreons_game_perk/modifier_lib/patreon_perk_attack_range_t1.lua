patreon_perk_attack_range_t1 = class({})
--------------------------------------------------------------------------------

function patreon_perk_attack_range_t1:IsHidden()
	return true
end

--------------------------------------------------------------------------------

function patreon_perk_attack_range_t1:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_attack_range_t1:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_attack_range_t1:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_attack_range_t1:GetModifierAttackRangeBonus(params)
    return GetPerkValue(75, self, 1, 0)
end

--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------