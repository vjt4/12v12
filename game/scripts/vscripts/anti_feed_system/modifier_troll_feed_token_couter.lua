modifier_troll_feed_token_couter = class({})

--------------------------------------------------------------------------------
function modifier_troll_feed_token_couter:IsHidden()
    return true
end

--------------------------------------------------------------------------------
function modifier_troll_feed_token_couter:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
function modifier_troll_feed_token_couter:GetTexture()
    return "shadow_shaman_voodoo"
end

--------------------------------------------------------------------------------
function modifier_troll_feed_token_couter:IsDebuff()
    return true
end

--------------------------------------------------------------------------------
function modifier_troll_feed_token_couter:RemoveOnDeath()
    return false
end

--------------------------------------------------------------------------------
function modifier_troll_feed_token_couter:OnCreated(kv)
end
--------------------------------------------------------------------------------