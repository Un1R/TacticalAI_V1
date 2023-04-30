local HumanoidRootPart = script.Parent:WaitForChild("HumanoidRootPart")
local Humanoid = script.Parent:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FastCast = require(ReplicatedStorage:WaitForChild("FastCastRedux"))

local Gun = script.Parent:FindFirstChildWhichIsA("Tool")
local MainAnimations = script:WaitForChild("MainAnimations")

local Characters = workspace:WaitForChild("Characters")
local bulletsFolder = workspace:WaitForChild("BulletFolder")

local Handle = Gun:WaitForChild("Handle")
local firePoint = Handle:WaitForChild("FirePoint")

local NPC = script.Parent

local AnimationStorage = {
	GunIdleAnimation = MainAnimations:WaitForChild("IdleAnimation");
	GunAimAnimation = MainAnimations:WaitForChild("AimAnimation");
	GunShootAnimation = MainAnimations:WaitForChild("ShootAnimation");
}

local LoadedTracks = {
	GunIdleTrack = nil;
	GunAimTrack = nil;
	GunShootTrack = nil;
}

local AI_Stats = {
	Damage = {
		Torso = 20;
		Head = 32;
		Arm = 10;
		Leg = 12;
	};
	
	Health = 85;
	DetectionRange = 40;
	HearsLoudFire = true;
	CanRun = true;
	WalkSpeed = 11;
	RunSpeed = 17;	
	MaxInc = 5;
	FireRate = 0.28;
}

local RaycastParameters = RaycastParams.new()
RaycastParameters.FilterDescendantsInstances = {
	Characters,
	bulletsFolder,
	Gun,
	HumanoidRootPart.Parent
}

local function RayFront()
	local Ray1 = workspace:Raycast(HumanoidRootPart.Position,HumanoidRootPart.CFrame.LookVector * AI_Stats.DetectionRange,RaycastParameters)
	return Ray1
end

local function CanSee(Target)
	local viewDirection = HumanoidRootPart.CFrame.LookVector
	local directionToPlayer = (Target.Position - HumanoidRootPart.Position).Unit
	local viewP = viewDirection:Dot(directionToPlayer)
	
	local function Verify()
		if viewP > 0 then
			if viewP >= 0.7 then
				return true
			else
				return false
			end
		else
			return false
		end
	end	
	
	local function VerifyBlock()
		local Result = RayFront()
		if Result then
			if Result.Instance then
				if typeof(Result.Instance) == "Instance" then
					local a,b = pcall(function()
						local canCollide
						canCollide = Result.Instance.CanCollide
					end)
					if a == false then
						return true
					elseif a == true then
						if Result.Instance.CanCollide == false then
							return false
						end
					end
				else
					return false
				end
			elseif not Result.Instance then
				return false
			end
		else
			return false
		end
	end
	
	local StatusV = Verify()
	local StatusB = VerifyBlock()
	if StatusV == true and StatusB == false then
		return true
	else
		return false
	end
end

local function LoadStats()
	Humanoid.MaxHealth = AI_Stats.Health
	Humanoid.Health = AI_Stats.Health
	Humanoid.WalkSpeed = 11
end

local function LoadAnimation()
	LoadedTracks.GunAimTrack = Animator:LoadAnimation(AnimationStorage.GunAimAnimation)
	LoadedTracks.GunIdleTrack = Animator:LoadAnimation(AnimationStorage.GunIdleAnimation)
	LoadedTracks.GunShootTrack = Animator:LoadAnimation(AnimationStorage.GunShootAnimation)
end

local function Jump()
	Humanoid.Jump = true
end

local function GetDist(Part1,Part2)
	local Dist = (Part1.Position - Part2.Position).Magnitude
	return Dist
end

local function FindTargetModel()
	for i,v in ipairs(Characters:GetChildren()) do
		local HRP = v:FindFirstChild("HumanoidRootPart")
		local Humanoid = v:FindFirstChild("Humanoid")
		if HRP and Humanoid then
			if Humanoid.Health >= 0.001 and GetDist(HumanoidRootPart,HRP) <= AI_Stats.DetectionRange and CanSee(HRP) then
				return v
			else
				return nil
			end
		end
	end
	return nil
end

local function WalkTo(Vector3V)
	Humanoid:Move(Vector3V)
end

local function FindTargetRootPart()
	for i,v in ipairs(Characters:GetChildren()) do
		local HRP = v:FindFirstChild("HumanoidRootPart")
		local Humanoid = v:FindFirstChild("Humanoid")
		if HRP and Humanoid then
			if Humanoid.Health >= 0.001 and GetDist(HumanoidRootPart,HRP) <= AI_Stats.DetectionRange and CanSee(HRP) then
				return HRP
			else
				return nil
			end
		end
	end
	return nil
end

local function IsBlockedByPart()
	local Direction = HumanoidRootPart.CFrame.LookVector
	local Origin = HumanoidRootPart.Position
	local Ray1 = workspace:Raycast(Origin,Direction,RaycastParameters)
	if Ray1 then
		if Ray1.Instance then
			return true
		else
			return false
		end
	else
		return false
	end
end

local function WalkBackNC()
	Humanoid:MoveTo(HumanoidRootPart.CFrame.LookVector + Vector3.new(0,0,-0.1))
end

local function WalkBackC()
	Humanoid:MoveTo(HumanoidRootPart.CFrame.LookVector + Vector3.new(0,0,-0.1))
	Humanoid.MoveToFinished:Wait()
end

local function Stop()
	Humanoid.WalkSpeed = 0
	Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
end

local function Aim()
	LoadedTracks.GunIdleTrack:Stop()
	LoadedTracks.GunAimTrack:Play()
end

local function LookAt(Target)
	pcall(function()
		HumanoidRootPart.CFrame = CFrame.lookAt(HumanoidRootPart.Position, Target.Position)
	end)
end

local Torso = {
	["Torso"] = true;
	["HumanoidRootPart"] = true;
}

local Head = {
	["Head"] = true;
}

local Arm = {
	["Left Arm"] = true;
	["Right Arm"] = true;
}

local Leg = {
	["Left Leg"] = true;
	["Right Leg"] = true;
}

local bulletTemplate = game:GetService("ServerStorage"):FindFirstChild("Bullet"):Clone()
local caster = FastCast.new()

local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Blacklist
castParams.IgnoreWater = true

local castBehavior = FastCast.newBehavior()
castBehavior.RaycastParams = castParams
castBehavior.Acceleration = Vector3.new(0, -workspace.Gravity, 0)
castBehavior.AutoIgnoreContainer = false
castBehavior.CosmeticBulletContainer = bulletsFolder
castBehavior.CosmeticBulletTemplate = bulletTemplate
local function onLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then 
		local bulletLength = bullet.Size.Z/2
		local offset = CFrame.new(0, 0, -(length - bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
	end
end

local function GetHitDmg(Instanc)
	if Head[Instanc] then
		return AI_Stats.Damage.Head
	elseif Torso[Instanc] then
		return AI_Stats.Damage.Torso
	elseif Arm[Instanc] then
		return AI_Stats.Damage.Arm
	elseif Leg[Instanc] then
		return AI_Stats.Damage.Leg
	else
		return 20
	end
end

local function onRayHit(cast, result, velocity, bullet)
	local hit = result.Instance
	local character = hit:FindFirstAncestorWhichIsA("Model")
	if character and character:FindFirstChild("Humanoid") then
		local Damage = GetHitDmg(hit)
		character.Humanoid:TakeDamage(Damage)
	end

	game:GetService("Debris"):AddItem(bullet, 0.1)
end
caster.LengthChanged:Connect(onLengthChanged)
caster.RayHit:Connect(onRayHit)

local function Shoot(Target)
	LoadedTracks.GunShootTrack:Play()
	task.defer(function()
		Handle:FindFirstChild("Muzzle").Fire:Play()
		Handle:FindFirstChild("Muzzle")["FlashFX[Flash]"].Enabled = true
		Handle:FindFirstChild("Muzzle")["Smoke"].Enabled = true
		wait(0.12)
		Handle:FindFirstChild("Muzzle")["FlashFX[Flash]"].Enabled = false
		Handle:FindFirstChild("Muzzle")["Smoke"].Enabled = false
	end)
	pcall(function()
		local origin = firePoint.Position
		local direction = (Target.Position - origin).Unit*100 + (Vector3.new(
			math.random(-500,500),
			math.random(-300,300),
			math.random(-230,230)
		)/90)
		caster:Fire(origin, direction, 1000, castBehavior)
	end)
end

local CurrentTarget = nil
local Moving = false

local RunService = game:GetService("RunService")

local BREAKFULL = false
local function Main()
	LoadAnimation()
	LoadStats()
	wait(0.2)
	local Count = 0
	LoadedTracks.GunIdleTrack:Play()
	local Hostile = false
	local m = CurrentTarget	
	
	task.defer(function()
		local a = 0
		while wait() do
			if BREAKFULL then
				break
			end
			if CurrentTarget == nil then
				CurrentTarget = FindTargetRootPart()
				if a == 0 and CurrentTarget then
					a = 1
					local Humanoid = CurrentTarget.Parent:FindFirstChildWhichIsA("Humanoid")
					Humanoid.Died:Connect(function()
						Hostile = false
						CurrentTarget = nil
						m = nil
						LoadedTracks.GunIdleTrack:Play()
						LoadedTracks.GunAimTrack:Stop()
						LoadedTracks.GunShootTrack:Stop()
						Humanoid.WalkSpeed = 11
						Hostile = false
					end)
				end
			elseif CurrentTarget ~= nil and Hostile == false and CanSee(CurrentTarget) then
				if not CanSee(CurrentTarget) then 
					
				elseif CanSee(CurrentTarget) then
					Humanoid:MoveTo(CurrentTarget.Position)
					wait(1)				
					Stop()
					Aim()
					LookAt(CurrentTarget)
					Hostile = true
				end
			elseif Hostile == true then
				LookAt(CurrentTarget)
			end
		end
	end)
	
	local Pause = false
	
	task.defer(function()
		while task.wait() do
			if BREAKFULL then
				break
			end
			if Pause == true then
				repeat
					wait()
				until Pause == false
			end
			if Hostile == true and Pause == false then
				task.wait(AI_Stats.FireRate)
				Shoot(CurrentTarget)
			end
		end
	end)
	
	task.defer(function()
		local moving1 = false
		while task.wait() do
			if BREAKFULL then 
				break
			end
			if CurrentTarget ~= nil and moving1 == false then
				if CanSee(CurrentTarget) == false then
					Pause = true
					moving1 = true
					LoadedTracks.GunShootTrack:Stop()
					Handle:FindFirstChild("Muzzle").Fire:Stop()
					Humanoid.WalkSpeed = 11
					Handle:FindFirstChild("Muzzle")["FlashFX[Flash]"].Enabled = false
					Handle:FindFirstChild("Muzzle")["Smoke"].Enabled = false
					Humanoid:MoveTo(CurrentTarget.Position)
					Humanoid.MoveToFinished:Wait()
					wait(0.2)
					Pause = false
					moving1 = false	
				end
			end
		end
	end)
	
	task.defer(function()
		while wait(5) do
			if CurrentTarget == nil and Hostile == false or CanSee(CurrentTarget) == false and Hostile == false then
				Humanoid:MoveTo(HumanoidRootPart.Position + Vector3.new(math.random(-AI_Stats.MaxInc, AI_Stats.MaxInc), 0, math.random(-AI_Stats.MaxInc, AI_Stats.MaxInc)),CurrentTarget)
			end
		end
	end)
	
	task.defer(function()
		local Check = true
		while wait(1) do
			if BREAKFULL then
				break
			end
			local IsBlocked = IsBlockedByPart()
			if IsBlocked and Check == true then
				Jump()
				Count += 1
				if Count >= 2 then
					Check = false
					Count = 0
					Humanoid:MoveTo(Vector3.new(9,0,0))
					Check = true
				end
			end
		end
	end)
	if BREAKFULL then
		return
	end
end

task.defer(function()
	Main()
end)

ReplicatedStorage:WaitForChild("Distressed"):GetPropertyChangedSignal("Value"):Connect(function()
	if ReplicatedStorage:WaitForChild("Distressed").Value == true then
		LoadedTracks.GunAimTrack:Play()
		LoadedTracks.GunIdleTrack:Stop()
	end
end)

Humanoid.Died:Connect(function()
	local Blood = require(ReplicatedStorage:WaitForChild("Blood"))
	Blood.MakePuddle(HumanoidRootPart)
	BREAKFULL = true
end)
