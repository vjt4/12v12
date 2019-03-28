-- credits: yahnich
function CDOTA_BaseNPC:IsFakeHero()
	if self:IsIllusion() or (self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_monkey_king_fur_army_soldier_hidden")) or self:IsTempestDouble() or self:IsClone() then
		return true
	else return false end
end

-- credits: yahnich
function CDOTA_BaseNPC:IsRealHero()
	if not self:IsNull() then
		return self:IsHero() and not (self:IsIllusion() or self:IsClone()) and not self:IsFakeHero()
	end
end

function math.sign(x)
	if x > 0 then
		return 1
	elseif x < 0 then
		return -1
	else
		return 0
	end
end

function ExpandVector(vec, by)
	return Vector(
		(math.abs(vec.x) + by) * math.sign(vec.x),
		(math.abs(vec.y) + by) * math.sign(vec.y),
		(math.abs(vec.z) + by) * math.sign(vec.z)
	)
end

function IsInBox(point, point1, point2)
	return point.x > point1.x and point.y > point1.y and point.x < point2.x and point.y < point2.y
end

function IsInTriggerBox(trigger, extension, vector)
	local origin = trigger:GetAbsOrigin()
	return IsInBox(
		vector,
		origin + ExpandVector(trigger:GetBoundingMins(), extension),
		origin + ExpandVector(trigger:GetBoundingMaxs(), extension)
	)
end
