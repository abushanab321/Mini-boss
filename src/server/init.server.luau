local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ragdoll = require(ReplicatedStorage.Packages.ragdoll)
local BossService = require(ReplicatedStorage.Shared.Services.BossService)

BossService:Init()
ragdoll.init()

BossService:StartFight(workspace.BossSpawn)
