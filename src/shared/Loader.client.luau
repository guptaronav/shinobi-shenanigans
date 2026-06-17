local contentProvider = game:GetService("ContentProvider")
local Players = game.Players

game.Loaded:Wait()

local assets = game.ReplicatedStorage.Assets:GetDescendants()

local startTime = os.clock()

--for i=1, math.ceil(#assets/10) do
--	local chunk = {}
--	for n=0, 10 do
--		if not assets[i+n] then break end
--		table.insert(chunk, assets[i+n])
--	end
--	contentProvider:PreloadAsync(chunk)
--end
contentProvider:PreloadAsync(assets)

local timeItTook = os.clock() - startTime
print("Time it took to preload asset: "..timeItTook)