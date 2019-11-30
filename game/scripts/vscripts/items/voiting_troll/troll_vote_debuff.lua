troll_vote_debuff = class({})
--------------------------------------------------------------------------------
function troll_vote_debuff:IsHidden()
	return false
end

--------------------------------------------------------------------------------
function troll_vote_debuff:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
function troll_vote_debuff:GetTexture()
	return "shadow_shaman_voodoo"
end

--------------------------------------------------------------------------------
function troll_vote_debuff:RemoveOnDeath()
	return false
end

--------------------------------------------------------------------------------
function troll_vote_debuff:IsDebuff()
	return true
end

--------------------------------------------------------------------------------
function troll_vote_debuff:OnCreated()
	local parent = self:GetParent()

	local TROLL_FEED_BUFF_BASIC_TIME = (60 * 10) -- 10 minutes
	local TROLL_FEED_TOTAL_RESPAWN_TIME_MULTIPLE = 2.5 -- x2.5 respawn time. If you respawn 100sec, after debuff you respawn 250sec
	local TROLL_FEED_MIN_RESPAWN_TIME = 60 -- 1 minute
	if parent:HasModifier("modifier_troll_feed_token_couter") then
		parent:RemoveModifierByName("modifier_troll_feed_token_couter")
	end
	if IsServer() then
		local normalRespawnTime = parent:GetRespawnTime()
		local addRespawnTime = normalRespawnTime * (TROLL_FEED_TOTAL_RESPAWN_TIME_MULTIPLE - 1)
		if addRespawnTime + normalRespawnTime < TROLL_FEED_MIN_RESPAWN_TIME then
			addRespawnTime = TROLL_FEED_MIN_RESPAWN_TIME - normalRespawnTime
		end
		GameRules:SendCustomMessage("#anti_feed_system_add_debuff_message", parent:GetPlayerID(), 0)
		parent:AddNewModifier(parent, nil, "modifier_troll_debuff_stop_feed", { duration = TROLL_FEED_BUFF_BASIC_TIME, addRespawnTime = addRespawnTime })

		_G.trollList[self:GetParent():GetPlayerOwnerID()] = true
	end
end

--------------------------------------------------------------------------------