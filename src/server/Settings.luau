local Settings = {}


Settings.TagName = "Destroyable" --[Any string] 
--The tag name that the module will check parts for.

Settings.RandomColors = true --[true OR false] [Default: false]
--Whether or not Voxels will be given random colors.

Settings.Visualizer = true --[true OR false] [Default: false]
--Whether or not you can see hitboxes visualized in the workspace.

Settings.DefaultMinimumVoxelSize = 3 --[Any number] [Default: 3]
--The default minimum voxel size that will be used if no minimum is specified.

Settings.DefaultResetTime = 10  --[Any number] [Default: 10]
--The default reset time that will be used if no time is specified.

Settings.DefaultHitboxShape = Enum.PartType.Block --[Any Enum.PartType]
--The default hitbox shape time that will be used if no shape is specified.

Settings.VoxelFolder = workspace --[Any Instance] [Default: workspace]
--Where Voxels will be parented to

Settings.AutoStartMoveable = true --[true OR false] [Default: false]
--Whether or not Moveable hitboxes will automatically start without having to call :Start()

Settings.UseCache = true --[true OR false] [Default: true]
--Whether or not the module will use ObjectCache to store parts. Reccommended to have on for performance.

Settings.Algorithm = "New" --["New" OR "Octrees"] [Default: "New"]
--The division algorithm that will be used. The two algorithms have different visual results and may have different performance loads

Settings.UseGreedyMeshing = true --[true OR false] [Default: true]
--Whether or not the module will greedy mesh voxels before constructing them. Note that this does not currently work with Octree division. Reccommended to have on for better performance.

Settings.UseRunService = true --[true OR false] [Default: true]
--Whether or not the module will use run service for spatial queries with moveable hitboxes. When set to false it will instead use while loops.

Settings.RelativityRatio = 1/3 --[Any number] [Default: 1/3]
--The ratio at which Voxels will be sized relative to a hitbox if the minimum voxel size is set to "Relative"

Settings.DefaultObjectCacheSize = 1000 --[Any number] [Default: 1000]
--The default amount of parts that will be instanced and stored in the cache if UseCache is set to true and Cache is set to ObjectCache.

Settings.DefaultPartCacheSize = 1000 --[Any number] [Default: 1000]
--The default amount of parts that will be instanced and stored in the cache if UseCache is set to true and Cache is set to PartCache.

Settings.DefaultHitboxSize = Vector3.new(5,5,5) --[Any Vector3] [Default: Vector3.new(5,5,5)]
--The default size of hitboxes that will be used if no size is specified.

Settings.DefaultOverlapParams = OverlapParams.new() --[Any OverlapParams] [Default: OverlapParams.new()]
--The default overlap params that will be used for spatial queries if no OverlapParams are specified.

Settings.IncludePartsBelowMinimum = false --[true OR false] [Default: false]
--Only applies when algorithm is set to "New". Makes it so that the algorithm will include side parts that are normally not constructed. Keep this off if you want all voxels to be perfectly cubic.

Settings.CacheExpansionSize = 100 --[Any number] [Default: 100]
--How much the cache will expand when there are no more free parts to use. Only applies when UseCache is set to true.


return Settings
