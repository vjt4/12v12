patreon_perk_agi_for_kill_t1 = class({})
--------------------------------------------------------------------------------
function patreon_perk_agi_for_kill_t1:AllowIllusionDuplicate()
	return true
end

function patreon_perk_agi_for_kill_t1:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function patreon_perk_agi_for_kill_t1:GetTexture()
	return "perkIcons/patreon_perk_agi_for_kill_t0"
end

--------------------------------------------------------------------------------

function patreon_perk_agi_for_kill_t1:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
function patreon_perk_agi_for_kill_t1:RemoveOnDeath()
	return false
end
--------------------------------------------------------------------------------

function patreon_perk_agi_for_kill_t1:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_EVENT_ON_HERO_KILLED
	}
	return funcs
end
--------------------------------------------------------------------------------

function patreon_perk_agi_for_kill_t1:GetModifierBonusStats_Agility()
	if self:GetParent():HasModifier("modifier_meepo_divided_we_stand") then return end
	return GetPerkValue(2, self, 1, 0)*self:GetStackCount()
end


--------------------------------------------------------------------------------
function GetPerkValue(const, modifier, levelCounter, bonusPerLevel)
	local heroLvl = modifier:GetParent():GetLevel()
	return math.floor(heroLvl/levelCounter)*bonusPerLevel+const
end
--------------------------------------------------------------------------------
function patreon_perk_agi_for_kill_t1:OnHeroKilled(keys)
	if not IsServer() then return end
	local killerID = keys.attacker:GetPlayerOwnerID()
	
	if killerID and killerID == self:GetParent():GetPlayerOwnerID() and keys.attacker:GetTeam() ~= self:GetParent():GetTeam() then
		self:IncrementStackCount()
		self:GetParent():CalculateStatBonus(false)
	end
end
--------------------------------------------------------------------------------
