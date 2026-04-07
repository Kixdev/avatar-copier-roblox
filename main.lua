--==================================================
-- THEME
--==================================================
local BLACK       = Color3.fromRGB(15, 15, 15)
local DARK_GRAY   = Color3.fromRGB(35, 35, 35)
local MID_GRAY    = Color3.fromRGB(55, 55, 55)
local WHITE       = Color3.fromRGB(255, 255, 255)
local RED         = Color3.fromRGB(200, 50, 50)
local GREEN       = Color3.fromRGB(50, 180, 50)
local MENU_ALPHA  = 0.95

--==================================================
-- SERVICES
--==================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

--==================================================
-- STATE
--==================================================
local minimized = false
local draggingTitleBar = false
local dragStart, startPos = nil, nil

local searching = false
local applying = false
local resetting = false
local currentTarget = nil
local selectedPackName = nil

local ATTR_LAST = "MergedAnimPack_Last"

--==================================================
-- PACK DATABASE
--==================================================
local PACKS = {
	["Adidas Sports"] = {
		WalkAnim = 18537392113,
		RunAnim  = 18537384940,
		JumpAnim = 18537380791,
		FallAnim = 18537367238,
		SwimIdle = 18537387180,
		Swim     = 18537389531,
		Animation1 = 18537376492,
		Animation2 = 18537371272,
		ClimbAnim = 18537363391,
	},
	["Adidas Community"] = {
		WalkAnim = 122150855457006,
		RunAnim  = 82598234841035,
		JumpAnim = 75290611992385,
		FallAnim = 98600215928904,
		SwimIdle = 109346520324160,
		Swim     = 133308483266208,
		Animation1 = 122257458498464,
		Animation2 = 102357151005774,
		ClimbAnim = 88763136693023,
	},
	["Adidas Aura"] = {
		WalkAnim = 83842218823011,
		RunAnim  = 118320322718866,
		JumpAnim = 109996626521204,
		FallAnim = 95603166884636,
		SwimIdle = 94922130551805,
		Swim     = 134530128383903,
		Animation1 = 110211186840347,
		Animation2 = 114191137265065,
		ClimbAnim = 97824616490448,
	},
	Elder = {
		WalkAnim = 10921111375,
		RunAnim  = 10921104374,
		JumpAnim = 10921107367,
		FallAnim = 10921105765,
		SwimIdle = 10921110146,
		Swim     = 10921108971,
		ClimbAnim = 10921100400,
		Animation1 = 10921101664,
		Animation2 = 10921102574,
	},
	Zombie = {
		WalkAnim = 10921355261,
		RunAnim  = 616163682,
		JumpAnim = 10921351278,
		FallAnim = 10921350320,
		SwimIdle = 10921353442,
		Swim     = 10921352344,
		Animation1 = 10921344533,
		Animation2 = 10921345304,
		ClimbAnim = 10921343576,
	},
	Mage = {
		WalkAnim = 10921152678,
		RunAnim  = 10921148209,
		JumpAnim = 10921149743,
		FallAnim = 10921148939,
		SwimIdle = 10921151661,
		Swim     = 10921150788,
		ClimbAnim = 10921143404,
		Animation1 = 10921144709,
		Animation2 = 10921145797,
	},
	["Catwalk Glam"] = {
		WalkAnim = 109168724482748,
		RunAnim  = 81024476153754,
		JumpAnim = 116936326516985,
		FallAnim = 92294537340807,
		SwimIdle = 98854111361360,
		Swim     = 134591743181628,
		ClimbAnim = 119377220967554,
		Animation1 = 133806214992291,
		Animation2 = 94970088341563,
	},
	Astronaut = {
		WalkAnim = 10921046031,
		RunAnim  = 10921039308,
		JumpAnim = 10921042494,
		FallAnim = 10921040576,
		SwimIdle = 10921045006,
		Swim     = 10921044000,
		ClimbAnim = 10921032124,
		Animation1 = 10921034824,
		Animation2 = 10921036806,
	},
	['Wicked "Dancing Through Life"'] = {
		WalkAnim = 73718308412641,
		RunAnim  = 135515454877967,
		JumpAnim = 78508480717326,
		FallAnim = 78147885297412,
		SwimIdle = 129183123083281,
		Swim     = 110657013921774,
		ClimbAnim = 129447497744818,
		Animation1 = 92849173543269,
		Animation2 = 132238900951109,
	},
	Werewolf = {
		WalkAnim = 10921342074,
		RunAnim  = 10921336997,
		JumpAnim = nil,
		FallAnim = 10921337907,
		SwimIdle = 10921341319,
		Swim     = 10921340419,
		ClimbAnim = 10921329322,
		Animation1 = 10921330408,
		Animation2 = 10921333667,
	},
	Superhero = {
		WalkAnim = 10921298616,
		RunAnim  = 10921291831,
		JumpAnim = 10921294559,
		FallAnim = 10921293373,
		SwimIdle = 10921297391,
		Swim     = 10921295495,
		ClimbAnim = 10921286911,
		Animation1 = 10921288909,
		Animation2 = 10921290167,
	},
	Toy = {
		WalkAnim = 10921312010,
		RunAnim  = 10921306285,
		JumpAnim = 10921308158,
		FallAnim = 10921307241,
		SwimIdle = 10921310341,
		Swim     = 10921309319,
		ClimbAnim = 10921300839,
		Animation1 = 10921301576,
		Animation2 = nil,
	},
	["No Boundaries"] = {
		WalkAnim = 18747074203,
		RunAnim  = 18747070484,
		JumpAnim = 18747069148,
		FallAnim = 18747062535,
		SwimIdle = 18747071682,
		Swim     = 18747073181,
		ClimbAnim = 18747060903,
		Animation1 = 18747067405,
		Animation2 = 18747063918,
	},
	NFL = {
		WalkAnim = 110358958299415,
		RunAnim  = 117333533048078,
		JumpAnim = 119846112151352,
		FallAnim = 129773241321032,
		SwimIdle = 79090109939093,
		Swim     = 132697394189921,
		ClimbAnim = 134630013742019,
		Animation1 = 92080889861410,
		Animation2 = 74451233229259,
	},
	["Amazon Unboxed"] = {
		WalkAnim = 90478085024465,
		RunAnim  = 134824450619865,
		JumpAnim = 121454505477205,
		FallAnim = 94788218468396,
		SwimIdle = 129126268464847,
		Swim     = 105962919001086,
		ClimbAnim = 121145883950231,
		Animation1 = 98281136301627,
		Animation2 = nil,
	},
	Vampire = {
		WalkAnim = 10921326949,
		RunAnim  = 10921320299,
		JumpAnim = 10921322186,
		FallAnim = 10921321317,
		SwimIdle = 10921325443,
		Swim     = 10921324408,
		ClimbAnim = 10921314188,
		Animation1 = 10921315373,
		Animation2 = nil,
	},
	["Ninja"] = {
		Run=656118852, Walk=656121766, Jump=656117878, Fall=656115606,
		Swim=656119721, SwimIdle=656121397, Climb=656114359,
		Idle={656117400,656118341,886742569}
	},
	["Robot"] = {
		Run=616091570, Walk=616095330, Jump=616090535, Fall=616087089,
		Swim=616092998, SwimIdle=616094091, Climb=616086039,
		Idle={616088211,616089559,885531463}
	},
	["Levitation"] = {
		Run=616010382, Walk=616013216, Jump=616008936, Fall=616005863,
		Swim=616011509, SwimIdle=616012453, Climb=616003713,
		Idle={616006778,616008087,886862142}
	},
	["Stylish"] = {
		Run=616140816, Walk=616146177, Jump=616139451, Fall=616134815,
		Swim=616143378, SwimIdle=616144772, Climb=616133594,
		Idle={616136790,616138447,886888594}
	},
	["Bubbly"] = {
		Run=910025107, Walk=910034870, Jump=910016857, Fall=910001910,
		Swim=910028158, SwimIdle=910030921, Climb=909997997,
		Idle={910004836,910009958,1018536639}
	},
	["Cartoon"] = {
		Run=742638842, Walk=742640026, Jump=742637942, Fall=742637151,
		Swim=742639220, SwimIdle=742639812, Climb=742636889,
		Idle={742637544,742638445,885477856}
	},
}

local orderedPackNames = {}
for name in pairs(PACKS) do
	table.insert(orderedPackNames, name)
end
table.sort(orderedPackNames, function(a, b)
	return a:lower() < b:lower()
end)

--==================================================
-- UTILS
--==================================================
local function sendNotif(titleT, textT, image)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = titleT,
			Text = textT,
			Duration = 5,
			Icon = image or ""
		})
	end)
end

local function isAllDigits(str)
	return typeof(str) == "string" and str:match("^%d+$") ~= nil
end

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function hoverTween(btn, on)
	local goal = {}
	if on then
		goal.BackgroundColor3 = Color3.fromRGB(
			math.clamp(btn.BackgroundColor3.R * 255 + 15, 0, 255),
			math.clamp(btn.BackgroundColor3.G * 255 + 15, 0, 255),
			math.clamp(btn.BackgroundColor3.B * 255 + 15, 0, 255)
		)
	else
		goal.BackgroundColor3 = btn:GetAttribute("BaseColor") or btn.BackgroundColor3
	end
	TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function setButtonEnabled(btn, enabled)
	btn.AutoButtonColor = enabled
	btn.Active = enabled
	btn.BackgroundTransparency = enabled and 0 or 0.45
	btn.TextTransparency = enabled and 0 or 0.35
end

local function waitForAnimate(char)
	for _ = 1, 50 do
		local a = char:FindFirstChild("Animate")
		if a and a:FindFirstChild("idle") and a:FindFirstChild("run") and a:FindFirstChild("walk") then
			return a
		end
		task.wait(0.1)
	end
	return nil
end

local function setAnim(animObj, id)
	if animObj and id then
		animObj.AnimationId = "rbxassetid://" .. tostring(id)
	end
end

local function stopAllTracks(hum)
	if not hum then return end
	for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
		pcall(function() t:Stop(0) end)
	end
end

local function ensureAnim(folder, name)
	if not folder then return nil end
	local a = folder:FindFirstChild(name)
	if not a then
		a = Instance.new("Animation")
		a.Name = name
		a.Parent = folder
	end
	return a
end

local function ensureIdleSlots(idleFolder, n)
	if not idleFolder then return end
	n = n or 2
	for i = 1, n do
		ensureAnim(idleFolder, "Animation" .. i)
	end
end

local function pick(pack, ...)
	for i = 1, select("#", ...) do
		local k = select(i, ...)
		local v = pack[k]
		if v ~= nil then return v end
	end
	return nil
end

local function waitForCharacterReady()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return character, nil
	end

	for _ = 1, 30 do
		if character.Parent and humanoid.Parent then
			break
		end
		task.wait(0.1)
	end

	return character, humanoid
end

local function waitForPart(character, partName, timeout)
	timeout = timeout or 5
	local part = character:FindFirstChild(partName)
	if part then return part end

	local start = tick()
	while tick() - start < timeout do
		part = character:FindFirstChild(partName)
		if part then
			return part
		end
		task.wait(0.05)
	end
	return nil
end

local function captureRootState(character)
	if not character then return nil end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	return {
		CFrame = hrp.CFrame,
		AssemblyLinearVelocity = hrp.AssemblyLinearVelocity,
		AssemblyAngularVelocity = hrp.AssemblyAngularVelocity,
	}
end

local function restoreRootState(character, state)
	if not character or not state then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	pcall(function()
		hrp.Anchored = false
		hrp.CFrame = state.CFrame
		hrp.AssemblyLinearVelocity = state.AssemblyLinearVelocity or Vector3.zero
		hrp.AssemblyAngularVelocity = state.AssemblyAngularVelocity or Vector3.zero
	end)
end

local function forceRootFollowRestore(character, state)
	if not character or not state then return end

	restoreRootState(character, state)
	RunService.Heartbeat:Wait()
	restoreRootState(character, state)
	task.wait(0.05)
	restoreRootState(character, state)
	task.wait(0.1)
	restoreRootState(character, state)
end

local function restoreDisplayName(humanoid)
	if not humanoid then return end
	pcall(function()
		humanoid.DisplayName = player.DisplayName
	end)
	task.wait(0.03)
	pcall(function()
		humanoid.DisplayName = player.DisplayName
	end)
end

local function rebindCameraAndCharacter(character, humanoid)
	if not character or not humanoid then return end

	local hrp = waitForPart(character, "HumanoidRootPart", 5)
	local head = waitForPart(character, "Head", 5)

	if hrp then
		pcall(function()
			character.PrimaryPart = hrp
		end)
	end

	pcall(function()
		humanoid.AutoRotate = true
	end)

	if camera then
		pcall(function()
			camera.CameraSubject = humanoid
		end)
	end

	if head then
		pcall(function()
			head.CanCollide = false
		end)
	end
end

local function refreshSpatialPresence(character, humanoid, rootState)
	if not character or not humanoid then return end

	local hrp = waitForPart(character, "HumanoidRootPart", 5)
	local head = waitForPart(character, "Head", 5)

	rebindCameraAndCharacter(character, humanoid)

	if rootState and hrp then
		restoreRootState(character, rootState)
	end

	if hrp then
		local baseCF = hrp.CFrame
		local baseLV = hrp.AssemblyLinearVelocity
		local baseAV = hrp.AssemblyAngularVelocity

		pcall(function()
			hrp.CFrame = baseCF + Vector3.new(0, 0.025, 0)
		end)
		RunService.Heartbeat:Wait()
		pcall(function()
			hrp.CFrame = baseCF
			hrp.AssemblyLinearVelocity = baseLV
			hrp.AssemblyAngularVelocity = baseAV
		end)

		RunService.Heartbeat:Wait()
		pcall(function()
			hrp.CFrame = baseCF
			hrp.AssemblyLinearVelocity = baseLV
			hrp.AssemblyAngularVelocity = baseAV
		end)
	end

	if head then
		pcall(function()
			head.CFrame = head.CFrame
		end)
	end

	restoreDisplayName(humanoid)

	pcall(function()
		humanoid:Move(Vector3.zero, false)
	end)

	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
	RunService.Heartbeat:Wait()
	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end)

	rebindCameraAndCharacter(character, humanoid)
	restoreDisplayName(humanoid)
end

--==================================================
-- ANIMATION APPLY
--==================================================
local animApplying = false

local function applyPack(packName)
	if animApplying then return false end
	animApplying = true

	local pack = PACKS[packName]
	if not pack then
		animApplying = false
		return false
	end

	local char, hum = waitForCharacterReady()
	local animate = waitForAnimate(char)
	if not animate then
		animApplying = false
		return false
	end

	stopAllTracks(hum)

	local runObj   = ensureAnim(animate:FindFirstChild("run"), "RunAnim")
	local walkObj  = ensureAnim(animate:FindFirstChild("walk"), "WalkAnim")
	local jumpObj  = ensureAnim(animate:FindFirstChild("jump"), "JumpAnim")
	local fallObj  = ensureAnim(animate:FindFirstChild("fall"), "FallAnim")
	local climbObj = ensureAnim(animate:FindFirstChild("climb"), "ClimbAnim")
	local swimObj  = ensureAnim(animate:FindFirstChild("swim"), "Swim")
	local swimIdleObj = ensureAnim(animate:FindFirstChild("swimidle"), "SwimIdle")
	local idleFolder = animate:FindFirstChild("idle")

	setAnim(walkObj,  pick(pack, "WalkAnim", "Walk"))
	setAnim(runObj,   pick(pack, "RunAnim", "Run"))
	setAnim(jumpObj,  pick(pack, "JumpAnim", "Jump"))
	setAnim(fallObj,  pick(pack, "FallAnim", "Fall"))
	setAnim(climbObj, pick(pack, "ClimbAnim", "Climb"))
	setAnim(swimObj,  pick(pack, "Swim"))
	setAnim(swimIdleObj, pick(pack, "SwimIdle") or pick(pack, "Swim"))

	if idleFolder then
		local a1 = pick(pack, "Animation1")
		local a2 = pick(pack, "Animation2")

		if a1 or a2 then
			ensureIdleSlots(idleFolder, 2)
			local id1 = a1 or a2
			local id2 = a2 or a1 or id1
			setAnim(idleFolder:FindFirstChild("Animation1"), id1)
			setAnim(idleFolder:FindFirstChild("Animation2"), id2)
		elseif pack.Idle and #pack.Idle > 0 then
			ensureIdleSlots(idleFolder, math.max(2, #pack.Idle))
			setAnim(idleFolder:FindFirstChild("Animation1"), pack.Idle[1])
			setAnim(idleFolder:FindFirstChild("Animation2"), pack.Idle[2] or pack.Idle[1])
			for i = 3, #pack.Idle do
				local a = idleFolder:FindFirstChild("Animation" .. i)
				if a then
					setAnim(a, pack.Idle[i])
				end
			end
		end
	end

	animate.Disabled = true
	task.wait(0.06)
	animate.Disabled = false

	if hum then
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.Landed)
			task.wait(0.03)
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end

	selectedPackName = packName
	pcall(function()
		player:SetAttribute(ATTR_LAST, packName)
	end)

	animApplying = false
	return true
end

local function reapplySelectedPack()
	if selectedPackName and PACKS[selectedPackName] then
		task.delay(0.35, function()
			applyPack(selectedPackName)
		end)
	end
end

--==================================================
-- TARGET RESOLVE
--==================================================
local function resolveTarget(query)
	query = trim(query or "")
	if query == "" then
		return nil, "Please enter username atau userid."
	end

	local userId
	if isAllDigits(query) then
		userId = tonumber(query)
		if not userId or userId <= 0 then
			return nil, "Invalid UserId."
		end
	else
		local ok, uid = pcall(function()
			return Players:GetUserIdFromNameAsync(query)
		end)
		if not ok or not uid then
			return nil, "Username not found / lookup failed."
		end
		userId = uid
	end

	local name = "Unknown"
	do
		local ok, nm = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if ok and nm then
			name = nm
		end
	end

	local thumbnail = ""
	do
		local ok, th = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and th then
			thumbnail = th
		end
	end

	return {UserId = userId, Name = name, Thumbnail = thumbnail}, nil
end

--==================================================
-- MORPH / RESET APPLY
--==================================================
local originalDesc = nil
do
	local ok, myDesc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)
	if ok then
		originalDesc = myDesc
	end
end

local function applyDescriptionToHumanoid(humanoid, desc)
	local ok = false
	if humanoid.ApplyDescription then
		ok = pcall(function()
			humanoid:ApplyDescription(desc)
		end)
	end
	if not ok and humanoid.ApplyDescriptionClientServer then
		ok = pcall(function()
			humanoid:ApplyDescriptionClientServer(desc)
		end)
	end
	return ok
end

local function clearOldAppearance(character)
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			obj:Destroy()
		end
	end

	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
			obj:Destroy()
		end
	end

	local bc = character:FindFirstChildOfClass("BodyColors")
	if bc then
		bc:Destroy()
	end
end

local function applyDescriptionPreserveRoot(desc)
	if not desc then
		return false, "No description."
	end

	local character, humanoid = waitForCharacterReady()
	if not humanoid then
		return false, "Failed to find humanoid."
	end

	local rootState = captureRootState(character)

	stopAllTracks(humanoid)
	clearOldAppearance(character)

	task.wait(0.08)

	local okApply = applyDescriptionToHumanoid(humanoid, desc)
	if not okApply then
		return false, "Failed to apply avatar."
	end

	task.wait(0.2)

	forceRootFollowRestore(character, rootState)
	refreshSpatialPresence(character, humanoid, rootState)

	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
	task.wait(0.03)
	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end)

	refreshSpatialPresence(character, humanoid, rootState)

	return true, nil
end

local function morphToUserId(userId, targetName, targetThumb)
	if not userId then return false, "No target." end
	if userId == player.UserId then return false, "Cannot morph to yourself." end

	local okDesc, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(userId)
	end)
	if not okDesc or not desc then
		return false, "Failed to load avatar data."
	end

	local okApply, err = applyDescriptionPreserveRoot(desc)
	if not okApply then
		if originalDesc then
			pcall(function()
				applyDescriptionPreserveRoot(originalDesc)
			end)
		end
		return false, err or "Failed to apply avatar."
	end

	task.wait(0.15)
	reapplySelectedPack()

	local character, humanoid = waitForCharacterReady()
	local rootState = captureRootState(character)
	refreshSpatialPresence(character, humanoid, rootState)

	sendNotif("Avatar Changer", "Successfully copied " .. (targetName or "target") .. "!", targetThumb or "")
	return true, nil
end

local function resetToOriginalAvatar()
	if not originalDesc then
		return false, "Original avatar data not available."
	end

	local okApply, err = applyDescriptionPreserveRoot(originalDesc)
	if not okApply then
		return false, err or "Failed to reset avatar."
	end

	local character, humanoid = waitForCharacterReady()
	local rootState = captureRootState(character)
	refreshSpatialPresence(character, humanoid, rootState)

	sendNotif("Avatar Changer", "Avatar reset to default.", "")
	return true, nil
end

--==================================================
-- CLEANUP OLD GUI
--==================================================
local guiName = "MorphAvatarAnimMerged"
do
	local existing = CoreGui:FindFirstChild(guiName)
	if existing then existing:Destroy() end
	local pg = player:FindFirstChild("PlayerGui")
	if pg then
		local ex2 = pg:FindFirstChild(guiName)
		if ex2 then ex2:Destroy() end
	end
end

--==================================================
-- CREATE GUI
--==================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.IgnoreGuiInset = true
screenGui.Enabled = true

local parentOk = pcall(function()
	screenGui.Parent = CoreGui
end)
if not parentOk then
	local pg = player:WaitForChild("PlayerGui")
	screenGui.Parent = pg
end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 390, 0, 478)
frame.Position = UDim2.new(0.5, -195, 0.5, -209)
frame.BackgroundColor3 = BLACK
frame.BackgroundTransparency = 1 - MENU_ALPHA
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Visible = true
frame.ClipsDescendants = true
frame.Active = true

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = Color3.fromRGB(80, 80, 80)
stroke.Transparency = 0.3
stroke.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundTransparency = 1
titleBar.Parent = frame
titleBar.Active = true

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -170, 0, 32)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "Avatar + Animation Changer"
title.TextColor3 = WHITE
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0, 160, 0, 32)
hint.Position = UDim2.new(1, -225, 0, 0)
hint.Text = "( comma = hide )"
hint.TextColor3 = Color3.fromRGB(170, 170, 170)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Parent = titleBar

local miniBtn = Instance.new("TextButton")
miniBtn.Size = UDim2.new(0, 32, 0, 32)
miniBtn.Position = UDim2.new(1, -70, 0, 0)
miniBtn.Text = "-"
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 16
miniBtn.TextColor3 = WHITE
miniBtn.BackgroundTransparency = 1
miniBtn.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -35, 0, 0)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = RED
closeBtn.BackgroundTransparency = 1
closeBtn.Parent = titleBar

local usernameInput = Instance.new("TextBox")
usernameInput.Size = UDim2.new(1, -130, 0, 30)
usernameInput.Position = UDim2.new(0, 10, 0, 45)
usernameInput.PlaceholderText = "Username or UserId"
usernameInput.Font = Enum.Font.GothamBold
usernameInput.TextSize = 14
usernameInput.Text = ""
usernameInput.TextColor3 = WHITE
usernameInput.BackgroundColor3 = DARK_GRAY
usernameInput.ClearTextOnFocus = false
usernameInput.TextWrapped = false
usernameInput.Parent = frame
Instance.new("UICorner", usernameInput).CornerRadius = UDim.new(0, 6)

local searchBtn = Instance.new("TextButton")
searchBtn.Size = UDim2.new(0, 100, 0, 30)
searchBtn.Position = UDim2.new(1, -110, 0, 45)
searchBtn.Text = "Search"
searchBtn.Font = Enum.Font.GothamBold
searchBtn.TextSize = 14
searchBtn.TextColor3 = WHITE
searchBtn.BackgroundColor3 = MID_GRAY
searchBtn.Parent = frame
searchBtn:SetAttribute("BaseColor", searchBtn.BackgroundColor3)
Instance.new("UICorner", searchBtn).CornerRadius = UDim.new(0, 6)

local previewBox = Instance.new("Frame")
previewBox.Size = UDim2.new(1, -20, 0, 78)
previewBox.Position = UDim2.new(0, 10, 0, 83)
previewBox.BackgroundColor3 = DARK_GRAY
previewBox.BorderSizePixel = 0
previewBox.Parent = frame
Instance.new("UICorner", previewBox).CornerRadius = UDim.new(0, 8)

local avatarImg = Instance.new("ImageLabel")
avatarImg.Size = UDim2.new(0, 64, 0, 64)
avatarImg.Position = UDim2.new(0, 8, 0, 7)
avatarImg.BackgroundTransparency = 1
avatarImg.Image = ""
avatarImg.Parent = previewBox
Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(0, 10)

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -84, 0, 22)
nameLabel.Position = UDim2.new(0, 80, 0, 10)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = WHITE
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 14
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Text = "Name: -"
nameLabel.Parent = previewBox

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(1, -84, 0, 18)
idLabel.Position = UDim2.new(0, 80, 0, 34)
idLabel.BackgroundTransparency = 1
idLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
idLabel.Font = Enum.Font.GothamBold
idLabel.TextSize = 12
idLabel.TextXAlignment = Enum.TextXAlignment.Left
idLabel.Text = "UserId: -"
idLabel.Parent = previewBox

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -84, 0, 18)
statusLabel.Position = UDim2.new(0, 80, 0, 54)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "Status: idle"
statusLabel.Parent = previewBox

local packLabel = Instance.new("TextLabel")
packLabel.Size = UDim2.new(1, -20, 0, 20)
packLabel.Position = UDim2.new(0, 10, 0, 170)
packLabel.BackgroundTransparency = 1
packLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
packLabel.Font = Enum.Font.GothamBold
packLabel.TextSize = 13
packLabel.TextXAlignment = Enum.TextXAlignment.Left
packLabel.Text = "Selected Pack: (none)"
packLabel.Parent = frame

local packSearch = Instance.new("TextBox")
packSearch.Size = UDim2.new(1, -20, 0, 30)
packSearch.Position = UDim2.new(0, 10, 0, 195)
packSearch.PlaceholderText = "Search animation pack..."
packSearch.Font = Enum.Font.Gotham
packSearch.TextSize = 14
packSearch.Text = ""
packSearch.TextColor3 = WHITE
packSearch.BackgroundColor3 = DARK_GRAY
packSearch.ClearTextOnFocus = false
packSearch.Parent = frame
Instance.new("UICorner", packSearch).CornerRadius = UDim.new(0, 6)

local listFrame = Instance.new("Frame")
listFrame.Size = UDim2.new(1, -20, 0, 160)
listFrame.Position = UDim2.new(0, 10, 0, 232)
listFrame.BackgroundColor3 = DARK_GRAY
listFrame.BorderSizePixel = 0
listFrame.Parent = frame
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -10)
scroll.Position = UDim2.new(0, 5, 0, 5)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = listFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local buttonsByPack = {}

local function refreshCanvas()
	task.wait()
	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)

local function updatePackLabel()
	packLabel.Text = "Selected Pack: " .. (selectedPackName or "(none)")
end

local function filterPackButtons(text)
	text = (text or ""):lower()
	for name, btn in pairs(buttonsByPack) do
		btn.Visible = (text == "") or (name:lower():find(text, 1, true) ~= nil)
	end
	refreshCanvas()
end

for i, packName in ipairs(orderedPackNames) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = MID_GRAY
	btn.TextColor3 = WHITE
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = packName
	btn.Parent = scroll
	btn.LayoutOrder = i
	btn:SetAttribute("BaseColor", btn.BackgroundColor3)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseEnter:Connect(function() hoverTween(btn, true) end)
	btn.MouseLeave:Connect(function() hoverTween(btn, false) end)

	btn.MouseButton1Click:Connect(function()
		local ok = applyPack(packName)
		if ok then
			updatePackLabel()
			sendNotif("Animation Pack", "Applied: " .. packName, "")
		else
			sendNotif("Animation Pack", "Failed to apply: " .. packName, "")
		end
	end)

	buttonsByPack[packName] = btn
end

local updateBtn = Instance.new("TextButton")
updateBtn.Size = UDim2.new(1, -20, 0, 30)
updateBtn.Position = UDim2.new(0, 10, 1, -73)
updateBtn.Text = "Copy Avatar"
updateBtn.Font = Enum.Font.GothamBold
updateBtn.TextSize = 14
updateBtn.TextColor3 = WHITE
updateBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
updateBtn.Parent = frame
updateBtn:SetAttribute("BaseColor", updateBtn.BackgroundColor3)
Instance.new("UICorner", updateBtn).CornerRadius = UDim.new(0, 8)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -20, 0, 30)
stopBtn.Position = UDim2.new(0, 10, 1, -37)
stopBtn.Text = "Stop Script"
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 14
stopBtn.TextColor3 = WHITE
stopBtn.BackgroundColor3 = Color3.fromRGB(140, 45, 45)
stopBtn.Parent = frame
stopBtn:SetAttribute("BaseColor", stopBtn.BackgroundColor3)
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

setButtonEnabled(updateBtn, false)
setButtonEnabled(stopBtn, originalDesc ~= nil)
filterPackButtons("")
updatePackLabel()

--==================================================
-- DRAGGING
--==================================================
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingTitleBar = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingTitleBar = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingTitleBar and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

--==================================================
-- MINIMIZE / CLOSE / TOGGLE
--==================================================
miniBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		frame.Size = UDim2.new(0, 390, 0, 32)
		miniBtn.Text = "+"
		usernameInput.Visible = false
		searchBtn.Visible = false
		previewBox.Visible = false
		packLabel.Visible = false
		packSearch.Visible = false
		listFrame.Visible = false
		updateBtn.Visible = false
		stopBtn.Visible = false
	else
		frame.Size = UDim2.new(0, 390, 0, 478)
		miniBtn.Text = "-"
		usernameInput.Visible = true
		searchBtn.Visible = true
		previewBox.Visible = true
		packLabel.Visible = true
		packSearch.Visible = true
		listFrame.Visible = true
		updateBtn.Visible = true
		stopBtn.Visible = true
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Comma then
		screenGui.Enabled = not screenGui.Enabled
	end
end)

for _, b in ipairs({searchBtn, updateBtn, stopBtn}) do
	b.MouseEnter:Connect(function() hoverTween(b, true) end)
	b.MouseLeave:Connect(function() hoverTween(b, false) end)
end

--==================================================
-- UI HELPERS
--==================================================
local function setPreview(target, errMsg)
	if target then
		currentTarget = target
		avatarImg.Image = target.Thumbnail or ""
		nameLabel.Text = "Name: " .. (target.Name or "-")
		idLabel.Text = "UserId: " .. tostring(target.UserId or "-")
		statusLabel.TextColor3 = GREEN
		statusLabel.Text = "Status: ready (press Copy)"
		setButtonEnabled(updateBtn, true)
	else
		currentTarget = nil
		avatarImg.Image = ""
		nameLabel.Text = "Name: -"
		idLabel.Text = "UserId: -"
		statusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
		statusLabel.Text = "Status: " .. (errMsg or "not found")
		setButtonEnabled(updateBtn, false)
	end
end

--==================================================
-- ACTIONS
--==================================================
local function doSearch()
	if searching then return end
	searching = true
	setButtonEnabled(searchBtn, false)
	statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	statusLabel.Text = "Status: searching..."

	local query = usernameInput.Text
	local target, err = resolveTarget(query)

	if target then
		usernameInput.Text = target.Name
		setPreview(target)
	else
		setPreview(nil, err)
		sendNotif("Morph Avatar", err or "Search failed.", "")
	end

	setButtonEnabled(searchBtn, true)
	searching = false
end

local function doUpdate()
	if applying or resetting then return end
	if not currentTarget then
		sendNotif("Morph Avatar", "Search target dulu.", "")
		return
	end

	applying = true
	setButtonEnabled(updateBtn, false)
	setButtonEnabled(stopBtn, false)
	statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	statusLabel.Text = "Status: applying..."

	local ok, err = morphToUserId(currentTarget.UserId, currentTarget.Name, currentTarget.Thumbnail)
	if ok then
		statusLabel.TextColor3 = GREEN
		statusLabel.Text = "Status: applied"
	end
	if not ok then
		statusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
		statusLabel.Text = "Status: " .. (err or "failed")
		sendNotif("Morph Avatar", err or "Failed to apply.", "")
	end

	setButtonEnabled(updateBtn, currentTarget ~= nil)
	setButtonEnabled(stopBtn, originalDesc ~= nil)
	applying = false
end

local function doStopScript()
	if resetting or applying then return end
	if not originalDesc then
		sendNotif("Stop Script", "Original avatar data not available.", "")
		return
	end

	resetting = true
	setButtonEnabled(updateBtn, false)
	setButtonEnabled(stopBtn, false)
	statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	statusLabel.Text = "Status: resetting to default..."

	local ok, err = resetToOriginalAvatar()
	if ok then
		statusLabel.TextColor3 = GREEN
		statusLabel.Text = "Status: default avatar restored"
	else
		statusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
		statusLabel.Text = "Status: " .. (err or "reset failed")
		sendNotif("Stop Script", err or "Failed to reset avatar.", "")
	end

	setButtonEnabled(updateBtn, currentTarget ~= nil)
	setButtonEnabled(stopBtn, originalDesc ~= nil)
	resetting = false
end

searchBtn.MouseButton1Click:Connect(doSearch)
updateBtn.MouseButton1Click:Connect(doUpdate)
stopBtn.MouseButton1Click:Connect(doStopScript)

usernameInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		doSearch()
	end
end)

packSearch:GetPropertyChangedSignal("Text"):Connect(function()
	filterPackButtons(packSearch.Text)
end)

--==================================================
-- RESPAWN REAPPLY
--==================================================
player.CharacterAdded:Connect(function()
	task.wait(0.8)

	local character, humanoid = waitForCharacterReady()
	local rootState = captureRootState(character)

	refreshSpatialPresence(character, humanoid, rootState)

	local saved = player:GetAttribute(ATTR_LAST)
	if type(saved) == "string" and saved ~= "" and PACKS[saved] then
		selectedPackName = saved
		updatePackLabel()
		applyPack(saved)
	end

	local newChar, newHum = waitForCharacterReady()
	local newRootState = captureRootState(newChar)
	refreshSpatialPresence(newChar, newHum, newRootState)
end)

task.defer(function()
	local character, humanoid = waitForCharacterReady()
	local rootState = captureRootState(character)

	refreshSpatialPresence(character, humanoid, rootState)

	local saved = player:GetAttribute(ATTR_LAST)
	if type(saved) == "string" and saved ~= "" and PACKS[saved] then
		selectedPackName = saved
		updatePackLabel()
		task.wait(0.2)
		applyPack(saved)
	end

	local newChar, newHum = waitForCharacterReady()
	local newRootState = captureRootState(newChar)
	refreshSpatialPresence(newChar, newHum, newRootState)
end)
