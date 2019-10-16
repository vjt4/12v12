modifier_troll_feed_token = class({})

--------------------------------------------------------------------------------
function modifier_troll_feed_token:IsHidden()
    return true
end

--------------------------------------------------------------------------------
function modifier_troll_feed_token:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
function modifier_troll_feed_token:IsDebuff()
    return true
end

--------------------------------------------------------------------------------
function modifier_troll_feed_token:RemoveOnDeath()
    return false
end

--------------------------------------------------------------------------------
function modifier_troll_feed_token:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

-----------------------------------------------------------------------------
function modifier_troll_feed_token:OnDestroy()
    local parent = self:GetParent()
    local tokenCouter = "modifier_troll_feed_token_couter"
    local currentStackTokenCouter = parent:GetModifierStackCount(tokenCouter, parent)
    if parent:HasModifier(tokenCouter) then
        if currentStackTokenCouter <= 1 then
            parent:RemoveModifierByName(tokenCouter)
        else
            local needToken = currentStackTokenCouter - 1
            parent:SetModifierStackCount(tokenCouter, parent, needToken)
        end
    end
end

-----------------------------------------------------------------------------