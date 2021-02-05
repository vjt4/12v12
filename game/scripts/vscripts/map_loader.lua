MapLoader = MapLoader or class({})


function MapLoader:Load(map_path)
	local origin = Vector(0, 0, 0)
	self.spawngroup = DOTA_SpawnMapAtPosition(
		map_path,
		origin,
		false,
		nil,
		function(handle)
			MapLoader:OnMapLoadingFinished(handle)
		end,
		nil
	)
	return self.spawngroup
end


function MapLoader:OnMapLoadingFinished(spawngroup_handle)
	print("[Map Loader] finished loading map with spawngroup", spawngroup_handle)
	-- if anything needs re-activating after map was loaded, it should go here
end
