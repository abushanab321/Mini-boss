local TweenService = game:GetService("TweenService")

local Gate = workspace:WaitForChild("FallenArena"):WaitForChild("Gatehouse"):WaitForChild("BossGate")
local Doors = { Gate:WaitForChild("LeftDoor"), Gate:WaitForChild("RightDoor") }

local BossGate = {}

local function Swing(Open: boolean, Time: number)
	for _, Door in Doors do
		local Hinge = Door.Hinge
		local Closed = Hinge:GetAttribute("ClosedCFrame")
		local Target = if Open then Closed * CFrame.Angles(0, math.rad(Door:GetAttribute("OpenYaw")), 0) else Closed

		TweenService
			:Create(Hinge, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = Target })
			:Play()
	end
end

function BossGate.Open(Time: number)
	Swing(true, Time)
end

function BossGate.Close(Time: number)
	Swing(false, Time)
end

return BossGate
