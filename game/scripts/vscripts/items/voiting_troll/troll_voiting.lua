troll_voiting = class({})
--------------------------------------------------------------------------------
function troll_voiting:IsHidden()
    return true --TODO set to true after testing (and set "CastFilterRejectCaster" in config to "1")
end
--------------------------------------------------------------------------------
function troll_voiting:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
function troll_voiting:GetTexture()
    return "shadow_shaman_voodoo"
end

--------------------------------------------------------------------------------
function troll_voiting:RemoveOnDeath()
    return false
end

--------------------------------------------------------------------------------
function troll_voiting:IsDebuff()
    return true
end

--------------------------------------------------------------------------------