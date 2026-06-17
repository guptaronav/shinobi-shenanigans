local Types = {}



export type VoxelInfo = {
	AlreadyExistsInWorkspace:boolean,
	Size:Vector3,
	CFrame:CFrame,
	CanCollide:boolean,
	Parent:Instance,
	Color:Color3,
	Material:Enum.Material,
	Anchored:boolean,
	Transparency:number,
	AlreadyDivided:boolean,
	ResetTime:number,
	OriginalPart:Instance
}
export type VoxelInfoTable = {VoxelInfo}

export type PartTable = {Part}

export type MoveableHitbox = {
	WeldedTo:Part|nil,
	WeldOffset:CFrame|nil,
	MinimumVoxelSize:number,
	CurrentlyTouching:PartTable,
	Shape:Enum.PartType|BasePart,
	Active:boolean,
	Event:BindableEvent,
	HitboxPart:BasePart,
	Touched:RBXScriptSignal,
	DestroyEvent:BindableEvent,
	Destroyed:RBXScriptSignal,
}



return Types
