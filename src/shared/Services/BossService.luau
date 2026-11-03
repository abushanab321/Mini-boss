local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local BossClass = require(ReplicatedStorage.Shared.Classes.Boss)
local BossGateUtil = require(ReplicatedStorage.Shared.Util.BossGateUtil)

local ATTACK_RANGE = 30
local ATTACK_COOLDOWN = 4 -- Must be longer than the attack animation (3.6s)

local HeartBeatConnection

local BossService = {}

function BossService.Init(self: BossService)
	local Boss = BossClass.New()
	self.Boss = Boss
end

local function StartControl(Boss)
	local Target = nil
	local CurrentDistance
	local LastAttack = 0

	HeartBeatConnection = RunService.Heartbeat:Connect(function()
		local TargetRoot = Target and Target:FindFirstChild("HumanoidRootPart")

		-- Stand still while the attack plays so he doesn't slide mid-swing
		if not TargetRoot or Boss:IsAttacking() then
			return
		end

		if CurrentDistance < ATTACK_RANGE then
			if os.clock() - LastAttack >= ATTACK_COOLDOWN then
				LastAttack = os.clock()
				Boss:Move(Boss.Character.PrimaryPart.Position)
				Boss:Attack(TargetRoot.Position)
			end
		else
			Boss:Move(TargetRoot.Position)
		end
	end)
	coroutine.wrap(function()
		while task.wait(0.1) do
			local ClosestDistance = math.huge
			local ClosestCharacter = nil

			for _, Player in Players:GetPlayers() do
				local Character = Player.Character
				local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
				local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

				if HumanoidRootPart and Humanoid and Humanoid.Health > 0 then
					local Distance = (HumanoidRootPart.Position - Boss.Character.PrimaryPart.Position).Magnitude

					if Distance < ClosestDistance then
						ClosestDistance = Distance
						ClosestCharacter = Character
					end
				end
			end

			Target = ClosestCharacter
			CurrentDistance = ClosestDistance
		end
	end)()
end

function BossService.StartFight(self: BossService, SpawnPoint)
	local Boss = self.Boss
	local Character: Model = Boss.Character
	local Root: BasePart = Character.HumanoidRootPart
	Character.Parent = workspace

	-- Stand him upright on the spawn point. Only its position and facing are used,
	-- so a tilted or flipped spawn part can't spawn him on his head.
	local SpawnCFrame: CFrame = if typeof(SpawnPoint) == "CFrame" then SpawnPoint else SpawnPoint.CFrame
	local StandHeight = Character["Left Leg"].Size.Y + Root.Size.Y / 2 + Character.Humanoid.HipHeight
	local Position = SpawnCFrame.Position + Vector3.new(0, StandHeight, 0)
	local Facing = SpawnCFrame.LookVector * Vector3.new(1, 0, 1)
	Character:PivotTo(CFrame.lookAt(Position, Position + Facing))

	-- Keep the boss's physics on the server, otherwise a player who gets close takes it over
	if Root:CanSetNetworkOwnership() then
		Root:SetNetworkOwner(nil)
	end

	Boss:LoadAnimations()

	local Sound = ServerStorage.Sounds["Big Gate Left-Side opening sound"]:Clone()
	Sound.Parent = workspace
	Sound:Play()
	BossGateUtil.Open(8)
	StartControl(self.Boss)
end

type BossService = typeof(BossService)

return BossService
