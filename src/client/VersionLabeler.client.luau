local placeVersion = game.PlaceVersion
local fixedUpdate = 17
local fixedVersion = 547 -- Current as of last scripting this

script.Parent.Text ..= 'Build '..placeVersion

--placeVersion = 560

--local updateRaw = tostring(placeVersion - (fixedVersion - fixedUpdate))

--if string.len(updateRaw) < 3 then
--	updateRaw = '0'..updateRaw
--end

--if placeVersion == 0 then
--	fixedUpdate = tostring(fixedUpdate) :: string
--	local v1 = string.sub(fixedUpdate, 1,1)
--	local v2 = string.sub(fixedUpdate, 2,2)
--	script.Parent.Text = 'v0.'..v1..'.'..v2..' - '..placeVersion
--else
--	local v1 = string.sub(updateRaw, 1,1)
--	local v2 = string.sub(updateRaw, 2,2)
--	local v3 = string.sub(updateRaw, 3,3)
--	script.Parent.Text = 'v'..v1..'.'..v2..'.'..v3..' - '..placeVersion
--end
