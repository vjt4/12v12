function GPM_Init()
	local timeToBaseGPM = 1
	local baseGoldPerTick = 1

	Timers:CreateTimer(function()
		local all_heroes = HeroList:GetAllHeroes()
		--print("START GAME GPM")
		--for i,x in pairs(all_heroes) do print(i,x) end
		for _, hero in pairs(all_heroes) do
			if hero:IsRealHero() and hero:IsControllableByAnyPlayer() then
				--print("HERO: ", hero, " NAME: ", hero:GetName(), " GOLD: ", baseGoldPerTick)
				hero:ModifyGold(baseGoldPerTick, false, 0)
			end
		end
		return timeToBaseGPM
	end)
end
