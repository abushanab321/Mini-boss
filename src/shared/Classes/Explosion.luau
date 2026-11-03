local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SwordImpactUtil = require(ReplicatedStorage.Shared.Util.SwordImpactUtil)
local ExplosionClass = {}
ExplosionClass.__index = ExplosionClass

function ExplosionClass.NewExplosion(Radius)
	local self = setmetatable({}, ExplosionClass)
	self.PRadius = Radius or 10
	return self
end

function ExplosionClass:Explode(Position)
	local Explosion = Instance.new("Explosion")
	Explosion.BlastRadius = self.PRadius
	Explosion.DestroyJointRadiusPercent = 100
	Explosion.Visible = false
	Explosion.Position = Position

	local ImpactSound = ServerStorage.Sounds.sword_impact_explosion:Clone()
	ImpactSound.Parent = workspace

	ImpactSound:Play()

	SwordImpactUtil.Play(Position)
	Explosion.Parent = workspace

	Debris:AddItem(ImpactSound, 6)
end

return ExplosionClass
