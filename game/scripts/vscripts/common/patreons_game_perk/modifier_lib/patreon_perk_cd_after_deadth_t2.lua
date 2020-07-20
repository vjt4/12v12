patreon_perk_cd_after_deadth_t2 = class({})
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t2:IsHidden()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t2:GetTexture()
	return "perkIcons/patreon_perk_cd_after_deadth_t0"
end
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t2:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t2:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t2:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH
	}
end
--------------------------------------------------------------------------------
function patreon_perk_cd_after_deadth_t2:OnDeath(params)
	if not IsServer() then return end
	if not params.reincarnate then
		self:GetParent().reduceCooldownAfterRespawn = GetPerkValue(50, self, 1, 0)
	else
		self:GetParent().reduceCooldownAfterRespawn = false
	end
end
----------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl / levelCounter) * bonusPerLevel + const
end
--------------------------------------------------------------------------------
