local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local SwordImpactUtil = {}

local SINK = Vector3.new(0, 4, 0) -- How far slabs and rocks hide under the floor
local FADE_AT = 2.8 -- When the crater starts sinking back into the floor
local LIFETIME = 4.5 -- Everything is gone by then (the particle crack lasts 4s)

local function Tween(Object, Time, Style, Direction, Goal)
	TweenService:Create(Object, TweenInfo.new(Time, Style, Direction), Goal):Play()
end

-- Finds the floor under Position so the impact sits on the ground, skipping any characters in the way
local function GetGround(Position: Vector3): Vector3
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	local Ignore = {}

	for _ = 1, 6 do
		Params.FilterDescendantsInstances = Ignore
		local Result = workspace:Raycast(Position + Vector3.new(0, 5, 0), Vector3.new(0, -60, 0), Params)
		if not Result then
			return Position
		end

		local Model = Result.Instance:FindFirstAncestorOfClass("Model")
		if Model and Model:FindFirstChildOfClass("Humanoid") then
			table.insert(Ignore, Model)
		else
			return Result.Position
		end
	end

	return Position
end

function SwordImpactUtil.Play(Position: Vector3)
	local VFX = ServerStorage.VFX
	local Ground = GetGround(Position)
	local Pivot = CFrame.new(Ground)

	local Particles = VFX.SwordImpact:Clone()
	local Parts = VFX.SwordImpactParts:Clone()
	Particles:PivotTo(Pivot)
	Parts:PivotTo(Pivot)

	-- Remember the finished pose of every part, then move them to where they start
	local Final = {}
	for _, Part in Parts:GetDescendants() do
		if Part:IsA("BasePart") then
			Final[Part] = { CFrame = Part.CFrame, Transparency = Part.Transparency, Size = Part.Size, Color = Part.Color }
		end
	end

	local Flash = Parts.Shockwave.Flash
	local Rings = { Parts.Shockwave.FireRing, Parts.Shockwave.DustRing }
	local Slabs = Parts.Slabs:GetChildren()
	local Rocks = Parts.Rubble:GetChildren()
	local Pit, Molten = Parts.Crater.Pit, Parts.Crater.Molten
	local CrackParts = {}
	for _, Part in Parts.Cracks:GetDescendants() do
		if Part:IsA("BasePart") then
			table.insert(CrackParts, Part)
			Part.Transparency = 1
		end
	end

	Flash.Size = Vector3.one * 2
	Flash.Transparency = 0.1
	local Meshes = {}
	for Index, Ring in Rings do
		Meshes[Index] = Ring:FindFirstChildOfClass("SpecialMesh")
		Meshes[Index].Scale *= 0.15
	end
	for _, Slab in Slabs do
		Slab.CFrame = Final[Slab].CFrame - SINK
	end
	for _, Rock in Rocks do
		Rock.CFrame = CFrame.new(Ground + Vector3.new(0, 1.5, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
	end
	Molten.Color = Color3.fromRGB(255, 190, 110)

	Particles.Parent = workspace
	Parts.Parent = workspace

	for _, Emitter in Particles:GetDescendants() do
		if Emitter:IsA("ParticleEmitter") then
			Emitter:Emit(Emitter:GetAttribute("EmitCount"))
		end
	end

	-- Flash and shockwave rings
	Tween(Flash, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = Final[Flash].Size * 1.8, Transparency = 1 })
	for Index, Ring in Rings do
		local Time = if Index == 1 then 0.45 else 0.9
		Tween(Meshes[Index], Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = Meshes[Index].Scale / 0.15 * 2.4 })
		Tween(Ring, Time, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Transparency = 1 })
	end

	-- Floor slabs punch up out of the ground, rocks get thrown outward
	for _, Slab in Slabs do
		task.delay(math.random() * 0.06, function()
			Tween(Slab, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { CFrame = Final[Slab].CFrame })
		end)
	end
	for _, Rock in Rocks do
		Tween(Rock, 0.35 + math.random() * 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { CFrame = Final[Rock].CFrame })
	end

	-- Cracks race outward from the crater, then the molten glow cools down
	for _, Part in CrackParts do
		local Distance = (Final[Part].CFrame.Position - Ground).Magnitude
		task.delay(Distance / 45, function()
			Part.Transparency = Final[Part].Transparency
			if Part.Name == "Glow" then
				Tween(Part, 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Color = Color3.fromRGB(110, 20, 10) })
			end
		end)
	end
	Tween(Molten, 2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Color = Color3.fromRGB(120, 25, 10) })

	-- Everything sinks back into the floor and fades away
	task.delay(FADE_AT, function()
		for _, Part in Slabs do
			Tween(Part, 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { CFrame = Final[Part].CFrame - SINK, Transparency = 1 })
		end
		for _, Part in Rocks do
			Tween(Part, 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { CFrame = Final[Part].CFrame - SINK, Transparency = 1 })
		end
		for _, Part in { Pit, Molten } do
			Tween(Part, 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Transparency = 1 })
		end
		for Step = 1, 3 do -- Cracks fade in a few steps instead of one tween per part (there are a lot of them)
			task.delay(Step * 0.25, function()
				for _, Part in CrackParts do
					Part.Transparency = math.max(Part.Transparency, Step / 3)
				end
			end)
		end
	end)

	Debris:AddItem(Parts, LIFETIME)
	Debris:AddItem(Particles, LIFETIME)
end

return SwordImpactUtil
