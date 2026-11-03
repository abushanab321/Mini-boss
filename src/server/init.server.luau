local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossService = require(ReplicatedStorage.Shared.Services.BossService)

BossService:Init()

BossService:StartFight(workspace.BossSpawn)
