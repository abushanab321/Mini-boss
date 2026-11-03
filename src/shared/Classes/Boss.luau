local ServerStorage = game:GetService("ServerStorage")
local ExplosionClass = require(script.Parent.Explosion)

local ANIMATIONS = {
	Idle = "rbxassetid://70920809541955",
	Walk = "rbxassetid://101689275309936",
	Attack = "rbxassetid://124431204031196",
}

local WALK_ANIMATION_SPEED = 7.2 -- Studs per second the walk was made for

local Boss = {}
Boss.__index = Boss

function Boss.New()
	local self = setmetatable({}, Boss)
	self.Health = 10000
	self.Stage = 1
	self.Character = ServerStorage.Models.Boss:Clone()
	self.Tracks = nil

	return self
end

-- Call this after parenting the character to workspace
function Boss:LoadAnimations()
	local Humanoid: Humanoid = self.Character:FindFirstChild("Humanoid")
	local Animator = Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", Humanoid)

	self.Tracks = {}
	for Name, Id in ANIMATIONS do
		local Animation = Instance.new("Animation")
		Animation.AnimationId = Id
		self.Tracks[Name] = Animator:LoadAnimation(Animation)
	end

	local Idle, Walk = self.Tracks.Idle, self.Tracks.Walk
	Idle:Play()
	local SFX = ServerStorage.Sounds["Monster footstep"]:Clone()
	SFX.PlaybackSpeed = 0.6
	SFX.Parent = self.Character.PrimaryPart

	Humanoid.Running:Connect(function(Speed)
		if Speed > 0.5 then
			if not Walk.IsPlaying then
				Idle:Stop(0.3)
				Walk:Play(0.3)
				SFX:Play()
			end
			Walk:AdjustSpeed(Speed / WALK_ANIMATION_SPEED)
		elseif Walk.IsPlaying then
			SFX:Stop()
			Walk:Stop(0.3)
			Idle:Play(0.3)
		end
	end)
end

function Boss:Move(Position)
	local Character = self.Character
	local Humanoid: Humanoid = Character:FindFirstChild("Humanoid")

	Humanoid:MoveTo(Position)
end

function Boss:IsAttacking()
	return self.Tracks.Attack.IsPlaying
end

function Boss:Attack(Position)
	local Track = self.Tracks.Attack
	if Track.IsPlaying then
		return
	end

	-- Turn to face the target, but keep the look point at his own height.
	-- Looking straight at the player's lower position tilted him into the floor and got him stuck.
	local Root: BasePart = self.Character.HumanoidRootPart
	local LookAt = Vector3.new(Position.X, Root.Position.Y, Position.Z)
	if (LookAt - Root.Position).Magnitude > 0.1 then
		Root.CFrame = CFrame.lookAt(Root.Position, LookAt)
	end

	Track:Play(0.1)
	Track:GetMarkerReachedSignal("Impact"):Once(function()
		task.wait(0.22)
		local Explostion = ExplosionClass.NewExplosion(5)
		Explostion:Explode(Position)
	end)
end

return Boss
