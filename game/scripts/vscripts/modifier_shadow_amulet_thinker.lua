modifier_shadow_amulet_thinker = class({})

function modifier_shadow_amulet_thinker:IsHidden() return true end
function modifier_shadow_amulet_thinker:IsPurgable() return false end
function modifier_shadow_amulet_thinker:IsPurgeException() return false end
function modifier_shadow_amulet_thinker:RemoveOnDeath() return false end

function modifier_shadow_amulet_thinker:OnCreated()
	if IsServer() then self:StartIntervalThink(0.5) end
end

function modifier_shadow_amulet_thinker:OnIntervalThink()
	local parent = self:GetParent()
	local shadow_modifier = parent:FindModifierByName("modifier_item_shadow_amulet_fade")

	if shadow_modifier then
		if parent:HasModifier("modifier_fountain_aura_buff") then
			shadow_modifier:SetDuration(15, true)
		end
	else
		self:Destroy()
	end
end