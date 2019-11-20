modifier_troll_debuff_stop_feed = class({})
--------------------------------------------------------------------------------
function modifier_troll_debuff_stop_feed:IsHidden()
    return false
end

--------------------------------------------------------------------------------
function modifier_troll_debuff_stop_feed:OnCreated(kv)
    self.addRespawnTime = kv.addRespawnTime
end

--------------------------------------------------------------------------------
function modifier_troll_debuff_stop_feed:GetModifierConstantRespawnTime()
    return self.addRespawnTime
end

--------------------------------------------------------------------------------
function modifier_troll_debuff_stop_feed:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
function modifier_troll_debuff_stop_feed:GetTexture()
    return "lion_voodoo_fish"
end

--------------------------------------------------------------------------------
function modifier_troll_debuff_stop_feed:RemoveOnDeath()
    return false
end

--------------------------------------------------------------------------------
function modifier_troll_debuff_stop_feed:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_RESPAWNTIME_STACKING,
    }
    return funcs
end

--------------------------------------------------------------------------------
function modifier_troll_debuff_stop_feed:GetModifierStackingRespawnTime()
    return self.addRespawnTime
end

--------------------------------------------------------------------------------
function modifier_troll_debuff_stop_feed:IsDebuff()
    return true
end

--------------------------------------------------------------------------------
