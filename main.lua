--==================================================
-- LOCAL OVERLAY AVATAR
-- - Client-only overlay: only YOU can see it
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================== CONFIG ======================
local FONT_UI = Enum.Font.GothamBold
local OVERLAY_FOLDER_NAME = "_LocalAvatarOverlay"
local DEFAULT_OFFSET = CFrame.new(0, 0, 0)

--==================== UI helpers ====================
local function setCorner(inst, px)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = inst
	return c
end

local function applyButtonFX(btn, normalColor, hoverColor, pressColor)
	btn.BackgroundColor3 = normalColor
	btn.AutoButtonColor = false
	local originalSize = btn.Size

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = hoverColor
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = normalColor,
			Size = originalSize
		}):Play()
	end)

	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = pressColor,
			Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset - 4, originalSize.Y.Scale, originalSize.Y.Offset - 4)
		}):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = hoverColor,
			Size = originalSize
		}):Play()
	end)
end

local function makeDraggable(dragHandle, targetFrame)
	local dragging = false
	local dragStart, startPos
	local dragInput

	local function beginDrag(input)
		dragging = true
		dragStart = input.Position
		startPos = targetFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end

	local function updateDrag(input)
		local delta = input.Position - dragStart
		targetFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			updateDrag(input)
		end
	end)
end

local function safeNumber(str, fallback)
	str = tostring(str or ""):gsub(",", ".")
	local n = tonumber(str)
	return n or fallback
end

--==================== Character helpers =============
local function getChar()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP(char)
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(char)
	return char and char:FindFirstChildOfClass("Humanoid")
end

--==================== Local-only overlay folder =====
local function getOverlayFolder()
	local cam = workspace.CurrentCamera
	if not cam then return nil end

	local folder = cam:FindFirstChild(OVERLAY_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = OVERLAY_FOLDER_NAME
		folder.Parent = cam
	end
	return folder
end

--==================== Overlay state =================
local Overlay = {
	model = nil,
	hrp = nil,
	weld = nil,
	renderConn = nil,
	motorPairs = {},

	hideSelf = true,
	hiddenParts = {},
	hideConn = nil,
	hideEnforceConn = nil,

	lastUserId = nil,
	lastUsername = nil,
	offset = DEFAULT_OFFSET,
}

--==================== Visual Name state =============
local VisualName = {
	enabled = false,
	mode = "OFF", -- "CUSTOM" | "HIDEONLY" | "OFF"
	displayName = "",
	userName = "",

	-- style settings
	yOffset = 2.6,
	fontMode = "BOLD", -- BOLD / BLACK
	outline = 0.35,    -- 0..1 (lebih kecil = outline lebih tebal)

	tagGui = nil,

	-- default overhead suppression (Humanoid)
	orig = {},
	propConns = {},
	overheadEnforceConn = nil,

	-- custom tags suppression
	suppressed = {}, -- [Gui] = prevEnabled
	addConns = {},
	suppressEnforceConn = nil,
}

--====================================================
-- HIDE SELF (anti camera override)
--====================================================
local function stopHideHooks()
	if Overlay.hideConn then Overlay.hideConn:Disconnect() Overlay.hideConn = nil end
	if Overlay.hideEnforceConn then Overlay.hideEnforceConn:Disconnect() Overlay.hideEnforceConn = nil end
end

local function enforceHideOnce()
	if not Overlay.hideSelf then return end
	for inst, _prev in pairs(Overlay.hiddenParts) do
		if inst and inst.Parent then
			if inst:IsA("BasePart") then
				if inst.LocalTransparencyModifier ~= 1 then inst.LocalTransparencyModifier = 1 end
			elseif inst:IsA("Decal") or inst:IsA("Texture") then
				if inst.Transparency ~= 1 then inst.Transparency = 1 end
			end
		end
	end
end

local function setLocalHideSelf(enabled)
	Overlay.hideSelf = enabled
	local char = LocalPlayer.Character
	if not char then return end

	stopHideHooks()

	-- restore
	for inst, prev in pairs(Overlay.hiddenParts) do
		if inst and inst.Parent then
			if inst:IsA("BasePart") then
				inst.LocalTransparencyModifier = prev
			elseif inst:IsA("Decal") or inst:IsA("Texture") then
				inst.Transparency = prev
			end
		end
	end
	table.clear(Overlay.hiddenParts)

	if not enabled then return end

	for _, inst in ipairs(char:GetDescendants()) do
		if inst:IsA("BasePart") then
			Overlay.hiddenParts[inst] = inst.LocalTransparencyModifier
			inst.LocalTransparencyModifier = 1
		elseif inst:IsA("Decal") or inst:IsA("Texture") then
			Overlay.hiddenParts[inst] = inst.Transparency
			inst.Transparency = 1
		end
	end

	local head = char:FindFirstChild("Head")
	if head then
		for _, d in ipairs(head:GetDescendants()) do
			if d:IsA("Decal") or d:IsA("Texture") then
				if Overlay.hiddenParts[d] == nil then
					Overlay.hiddenParts[d] = d.Transparency
				end
				d.Transparency = 1
			end
		end
	end

	Overlay.hideConn = char.DescendantAdded:Connect(function(inst)
		if not Overlay.hideSelf then return end
		if inst:IsA("BasePart") then
			if Overlay.hiddenParts[inst] == nil then
				Overlay.hiddenParts[inst] = inst.LocalTransparencyModifier
			end
			inst.LocalTransparencyModifier = 1
		elseif inst:IsA("Decal") or inst:IsA("Texture") then
			if Overlay.hiddenParts[inst] == nil then
				Overlay.hiddenParts[inst] = inst.Transparency
			end
			inst.Transparency = 1
		end
	end)

	local acc = 0
	Overlay.hideEnforceConn = RunService.RenderStepped:Connect(function(dt)
		if not Overlay.hideSelf then return end
		acc += dt
		if acc < 0.12 then return end
		acc = 0
		enforceHideOnce()
	end)
end

--====================================================
-- NAMETAG: suppress default overhead (Humanoid)
--====================================================
local function stopDefaultOverheadSuppress()
	if VisualName.overheadEnforceConn then
		VisualName.overheadEnforceConn:Disconnect()
		VisualName.overheadEnforceConn = nil
	end
	for _, c in ipairs(VisualName.propConns) do
		if c then c:Disconnect() end
	end
	table.clear(VisualName.propConns)
end

local function startDefaultOverheadSuppress()
	stopDefaultOverheadSuppress()

	local char = LocalPlayer.Character
	local hum = getHumanoid(char)
	if not hum then return end

	if VisualName.orig.hum ~= hum then
		VisualName.orig = {
			hum = hum,
			DisplayDistanceType = hum.DisplayDistanceType,
			NameDisplayDistance = hum.NameDisplayDistance,
			HealthDisplayType = hum.HealthDisplayType,
			HealthDisplayDistance = hum.HealthDisplayDistance,
		}
	end

	local function apply()
		if not VisualName.enabled then return end
		pcall(function()
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.NameDisplayDistance = 0
			hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			hum.HealthDisplayDistance = 0
		end)
	end

	apply()

	table.insert(VisualName.propConns, hum:GetPropertyChangedSignal("DisplayDistanceType"):Connect(apply))
	table.insert(VisualName.propConns, hum:GetPropertyChangedSignal("NameDisplayDistance"):Connect(apply))
	table.insert(VisualName.propConns, hum:GetPropertyChangedSignal("HealthDisplayType"):Connect(apply))
	table.insert(VisualName.propConns, hum:GetPropertyChangedSignal("HealthDisplayDistance"):Connect(apply))

	local acc = 0
	VisualName.overheadEnforceConn = RunService.RenderStepped:Connect(function(dt)
		if not VisualName.enabled then return end
		acc += dt
		if acc < 0.2 then return end
		acc = 0
		apply()
	end)
end

local function restoreDefaultOverhead()
	stopDefaultOverheadSuppress()
	local o = VisualName.orig
	local hum = o and o.hum
	if hum and hum.Parent then
		pcall(function()
			hum.DisplayDistanceType = o.DisplayDistanceType
			hum.NameDisplayDistance = o.NameDisplayDistance
			hum.HealthDisplayType = o.HealthDisplayType
			hum.HealthDisplayDistance = o.HealthDisplayDistance
		end)
	end
end

--====================================================
-- NAMETAG: suppress custom game tags (BillboardGui/SurfaceGui)
--====================================================
local function stopCustomTagSuppress()
	if VisualName.suppressEnforceConn then
		VisualName.suppressEnforceConn:Disconnect()
		VisualName.suppressEnforceConn = nil
	end
	for _, c in ipairs(VisualName.addConns) do
		if c then c:Disconnect() end
	end
	table.clear(VisualName.addConns)
end

local function isOurTag(gui)
	return (gui == VisualName.tagGui) or (gui.Name == "LocalReplacedNameTag")
end

local function isAttachedToLocalCharacter(gui)
	local char = LocalPlayer.Character
	if not char then return false end

	local ad = gui.Adornee
	if ad and ad:IsDescendantOf(char) then
		return true
	end
	if gui.Parent and gui.Parent:IsDescendantOf(char) then
		return true
	end
	return false
end

local function trySuppressGui(gui)
	if not (gui:IsA("BillboardGui") or gui:IsA("SurfaceGui")) then return end
	if isOurTag(gui) then return end
	if not isAttachedToLocalCharacter(gui) then return end

	if VisualName.suppressed[gui] == nil then
		VisualName.suppressed[gui] = gui.Enabled
	end
	gui.Enabled = false
end

local function suppressExistingCharacterTags()
	local char = LocalPlayer.Character
	if not char then return end

	-- scan character descendants (fast)
	for _, inst in ipairs(char:GetDescendants()) do
		if inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
			trySuppressGui(inst)
		end
	end

	-- scan workspace for guis that adore/attach to our character (time-sliced)
	local all = workspace:GetDescendants()
	for i = 1, #all do
		local inst = all[i]
		if inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
			if isAttachedToLocalCharacter(inst) then
				trySuppressGui(inst)
			end
		end
		if (i % 2500) == 0 then task.wait() end
	end
end

local function startCustomTagSuppress()
	stopCustomTagSuppress()
	suppressExistingCharacterTags()

	local char = LocalPlayer.Character
	if char then
		table.insert(VisualName.addConns, char.DescendantAdded:Connect(function(inst)
			if not VisualName.enabled then return end
			if inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
				task.defer(function()
					if VisualName.enabled then
						trySuppressGui(inst)
					end
				end)
			end
		end))
	end

	table.insert(VisualName.addConns, workspace.DescendantAdded:Connect(function(inst)
		if not VisualName.enabled then return end
		if inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
			task.defer(function()
				if VisualName.enabled and isAttachedToLocalCharacter(inst) then
					trySuppressGui(inst)
				end
			end)
		end
	end))

	local acc = 0
	VisualName.suppressEnforceConn = RunService.RenderStepped:Connect(function(dt)
		if not VisualName.enabled then return end
		acc += dt
		if acc < 0.2 then return end
		acc = 0

		for gui, _prev in pairs(VisualName.suppressed) do
			if gui and gui.Parent and gui.Enabled ~= false then
				gui.Enabled = false
			end
		end
	end)
end

local function restoreCustomTags()
	stopCustomTagSuppress()
	for gui, prevEnabled in pairs(VisualName.suppressed) do
		if gui and gui.Parent then
			gui.Enabled = prevEnabled
		end
	end
	table.clear(VisualName.suppressed)
end

--====================================================
-- NAMETAG: build our custom tag (adjustable)
--====================================================
local function removeOurNametag()
	if VisualName.tagGui then
		pcall(function() VisualName.tagGui:Destroy() end)
	end
	VisualName.tagGui = nil
end

local function buildOurNametag(displayName, userName)
	removeOurNametag()

	local char = LocalPlayer.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	local bill = Instance.new("BillboardGui")
	bill.Name = "LocalReplacedNameTag"
	bill.Adornee = head
	bill.Size = UDim2.new(0, 230, 0, 56)
	bill.StudsOffset = Vector3.new(0, VisualName.yOffset, 0)
	bill.AlwaysOnTop = true
	bill.LightInfluence = 0
	bill.Parent = head

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1,0,1,0)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.TextColor3 = Color3.new(1,1,1)
	t.TextStrokeColor3 = Color3.new(0,0,0)
	t.TextStrokeTransparency = math.clamp(VisualName.outline, 0, 1)
	t.Font = (VisualName.fontMode == "BLACK") and Enum.Font.GothamBlack or Enum.Font.GothamBold
	t.Parent = bill

	local lines = {}

	if displayName and displayName ~= "" then
		table.insert(lines, displayName)
	end

	if userName and userName ~= "" then
		table.insert(lines, "@" .. userName)
	end

	-- kalau dua-duanya kosong, biar tidak bikin text aneh
	t.Text = (#lines > 0) and table.concat(lines, "\n") or ""


	VisualName.tagGui = bill
end

-- IMPORTANT: sequence is fixed so custom tag won't get suppressed
local function enableNametagReplace(displayName, userName)
	VisualName.enabled = true
	VisualName.mode = "CUSTOM"
	VisualName.displayName = displayName
	VisualName.userName = userName

	startDefaultOverheadSuppress()

	-- 1) build our tag FIRST
	buildOurNametag(displayName, userName)

	-- 2) then suppress all other tags (won't touch ours)
	startCustomTagSuppress()
end

local function enableHideOnly()
	VisualName.enabled = true
	VisualName.mode = "HIDEONLY"
	VisualName.displayName = ""
	VisualName.userName = ""

	removeOurNametag()
	startDefaultOverheadSuppress()
	startCustomTagSuppress()
end

local function disableNametag()
	VisualName.enabled = false
	VisualName.mode = "OFF"
	VisualName.displayName = ""
	VisualName.userName = ""

	removeOurNametag()
	restoreDefaultOverhead()
	restoreCustomTags()
end

--====================================================
-- OVERLAY CORE (pose mirror)
--====================================================
local function clearMotorPairs()
	table.clear(Overlay.motorPairs)
end

local function stopRender()
	if Overlay.renderConn then
		Overlay.renderConn:Disconnect()
		Overlay.renderConn = nil
	end
end

local function destroyOverlay()
	stopRender()
	clearMotorPairs()
	if Overlay.model then pcall(function() Overlay.model:Destroy() end) end
	Overlay.model, Overlay.hrp, Overlay.weld = nil, nil, nil
end

local function motorKey(m)
	local p0 = (m.Part0 and m.Part0.Name) or "nil"
	local p1 = (m.Part1 and m.Part1.Name) or "nil"
	return m.Name .. "|" .. p0 .. ">" .. p1
end

local function buildMotorPairs(sourceChar, targetModel)
	clearMotorPairs()

	local srcMap = {}
	for _, d in ipairs(sourceChar:GetDescendants()) do
		if d:IsA("Motor6D") then
			srcMap[motorKey(d)] = d
		end
	end

	local tgtMap = {}
	for _, d in ipairs(targetModel:GetDescendants()) do
		if d:IsA("Motor6D") then
			tgtMap[motorKey(d)] = d
		end
	end

	for k, src in pairs(srcMap) do
		local tgt = tgtMap[k]
		if tgt then
			table.insert(Overlay.motorPairs, { src = src, tgt = tgt })
		end
	end
end

local function makeModelNonInteractive(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") then d.Disabled = true end
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		end
	end

	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = true
		hum.AutoRotate = false
	end
end

local function createModelFromUserId(userId)
	local ok, modelOrErr = pcall(function()
		local fn = Players.CreateHumanoidModelFromUserIdAsync
		if typeof(fn) == "function" then
			return Players:CreateHumanoidModelFromUserIdAsync(userId)
		end
		return Players:CreateHumanoidModelFromUserId(userId)
	end)
	return ok, modelOrErr
end

local function resolveTarget(text)
	text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" then return false, "Input empty." end

	local asNumber = tonumber(text)
	if asNumber then
		local uid = math.floor(asNumber)
		if uid <= 0 then return false, "Invalid UserId." end
		local okName, uname = pcall(function()
			return Players:GetNameFromUserIdAsync(uid)
		end)
		if not okName or not uname then return false, "UserId not found." end
		return true, uid, uname
	end

	local okId, uid = pcall(function()
		return Players:GetUserIdFromNameAsync(text)
	end)
	if not okId or not uid or uid == 0 then return false, "Username not found." end

	return true, uid, text
end

local function startPoseMirrorLoop()
	stopRender()
	Overlay.renderConn = RunService.RenderStepped:Connect(function()
		if not Overlay.model or not Overlay.hrp then return end
		local folder = getOverlayFolder()
		if folder and Overlay.model.Parent ~= folder then
			Overlay.model.Parent = folder
		end
		for _, pair in ipairs(Overlay.motorPairs) do
			local src, tgt = pair.src, pair.tgt
			if src and tgt and src.Parent and tgt.Parent then
				tgt.Transform = src.Transform
			end
		end
	end)
end

local function spawnOverlay(userId, username, statusFn)
	statusFn("Spawning overlay...")
	destroyOverlay()

	local okModel, modelOrErr = createModelFromUserId(userId)
	if not okModel or typeof(modelOrErr) ~= "Instance" then
		statusFn("Failed to create avatar model.")
		return false
	end

	local model = modelOrErr
	model.Name = ("Overlay_%d"):format(userId)

	local folder = getOverlayFolder()
	if not folder then
		model:Destroy()
		statusFn("Camera not ready.")
		return false
	end
	model.Parent = folder

	makeModelNonInteractive(model)

	local ohrp = model:FindFirstChild("HumanoidRootPart")
	if not ohrp or not ohrp:IsA("BasePart") then
		model:Destroy()
		statusFn("Overlay HRP missing.")
		return false
	end

	local myChar = getChar()
	local myHRP = getHRP(myChar)
	if not myHRP then
		model:Destroy()
		statusFn("Your HRP not ready.")
		return false
	end

	model:PivotTo(myHRP.CFrame * Overlay.offset)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ohrp
	weld.Part1 = myHRP
	weld.Parent = ohrp

	Overlay.model, Overlay.hrp, Overlay.weld = model, ohrp, weld
	Overlay.lastUserId, Overlay.lastUsername = userId, username

	buildMotorPairs(myChar, model)
	startPoseMirrorLoop()

	statusFn(("Overlay ON: %s (%d)"):format(username, userId))
	return true
end

-- Respawn-safe
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.25)

	if Overlay.hideSelf then
		setLocalHideSelf(true)
	end

	if VisualName.enabled then
		if VisualName.mode == "CUSTOM" then
			enableNametagReplace(
				VisualName.displayName ~= "" and VisualName.displayName or LocalPlayer.DisplayName,
				VisualName.userName ~= "" and VisualName.userName or LocalPlayer.Name
			)
		elseif VisualName.mode == "HIDEONLY" then
			enableHideOnly()
		end
	end

	if Overlay.lastUserId then
		spawnOverlay(Overlay.lastUserId, Overlay.lastUsername or tostring(Overlay.lastUserId), function() end)
	end
end)

--====================================================
-- UI BUILD
--====================================================
local pg = LocalPlayer:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("LocalOverlayAvatarGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "LocalOverlayAvatarGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 999999
gui.Parent = pg

local uiHidden = false
local minimized = false
local normalSize

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 420, 0, 430)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(25,25,30)
frame.BorderSizePixel = 0
frame.Active = true
setCorner(frame, 14)
normalSize = frame.Size

local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1,0,0,44)
header.BackgroundColor3 = Color3.fromRGB(40,40,55)
header.BorderSizePixel = 0
header.Active = true

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-170,1,0)
title.Position = UDim2.new(0,12,0,0)
title.BackgroundTransparency = 1
title.Text = "AVATAR CREATOR COPIER by KIXDEV"
title.Font = FONT_UI
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left

local idBtn = Instance.new("TextButton", header)
idBtn.Size = UDim2.new(0,36,0,36)
idBtn.Position = UDim2.new(1,-124,0,4)
idBtn.Text = "ID"
idBtn.Font = FONT_UI
idBtn.TextSize = 14
idBtn.TextColor3 = Color3.new(1,1,1)
idBtn.BackgroundColor3 = Color3.fromRGB(70,70,90)
setCorner(idBtn, 10)
applyButtonFX(idBtn, Color3.fromRGB(70,70,90), Color3.fromRGB(90,90,115), Color3.fromRGB(55,55,70))

local minimizeBtn = Instance.new("TextButton", header)
minimizeBtn.Size = UDim2.new(0,36,0,36)
minimizeBtn.Position = UDim2.new(1,-84,0,4)
minimizeBtn.Text = "−"
minimizeBtn.Font = FONT_UI
minimizeBtn.TextSize = 22
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(70,70,90)
setCorner(minimizeBtn, 10)
applyButtonFX(minimizeBtn, Color3.fromRGB(70,70,90), Color3.fromRGB(90,90,115), Color3.fromRGB(55,55,70))

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0,36,0,36)
closeBtn.Position = UDim2.new(1,-44,0,4)
closeBtn.Text = "×"
closeBtn.Font = FONT_UI
closeBtn.TextSize = 22
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
setCorner(closeBtn, 10)
applyButtonFX(closeBtn, Color3.fromRGB(180,60,60), Color3.fromRGB(200,80,80), Color3.fromRGB(150,40,40))

makeDraggable(header, frame)

-- content scroll
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Position = UDim2.new(0,0,0,44)
scroll.Size = UDim2.new(1,0,1,-44)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ClipsDescendants = true

local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0,10)

local pad = Instance.new("UIPadding", scroll)
pad.PaddingLeft = UDim.new(0,18)
pad.PaddingRight = UDim.new(0,18)
pad.PaddingTop = UDim.new(0,14)
pad.PaddingBottom = UDim.new(0,16)

local status = Instance.new("TextLabel", scroll)
status.LayoutOrder = 1
status.Size = UDim2.new(1,0,0,20)
status.BackgroundTransparency = 1
status.Text = "Status: Ready"
status.Font = FONT_UI
status.TextSize = 12
status.TextColor3 = Color3.fromRGB(170,170,170)
status.TextXAlignment = Enum.TextXAlignment.Left

local function setStatus(t)
	status.Text = "Status: " .. tostring(t)
end

local function makeClippedBox(parent, order, placeholder, defaultText)
	local holder = Instance.new("Frame", parent)
	holder.LayoutOrder = order
	holder.Size = UDim2.new(1,0,0,40)
	holder.BackgroundColor3 = Color3.fromRGB(45,45,55)
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = true
	setCorner(holder, 10)

	local box = Instance.new("TextBox", holder)
	box.Size = UDim2.new(1,-20,1,0)
	box.Position = UDim2.new(0,10,0,0)
	box.BackgroundTransparency = 1
	box.PlaceholderText = placeholder
	box.Text = defaultText or ""
	box.ClearTextOnFocus = false
	box.Font = FONT_UI
	box.TextSize = 15
	box.TextColor3 = Color3.new(1,1,1)
	box.TextXAlignment = Enum.TextXAlignment.Left
	return box
end

local inputBox = makeClippedBox(scroll, 2, "Username / UserId...", "")

local searchBtn = Instance.new("TextButton", scroll)
searchBtn.LayoutOrder = 3
searchBtn.Size = UDim2.new(1,0,0,36)
searchBtn.Text = "Search Target"
searchBtn.Font = FONT_UI
searchBtn.TextSize = 14
searchBtn.TextColor3 = Color3.new(1,1,1)
searchBtn.BackgroundColor3 = Color3.fromRGB(60,120,180)
setCorner(searchBtn, 10)
applyButtonFX(searchBtn, Color3.fromRGB(60,120,180), Color3.fromRGB(80,140,200), Color3.fromRGB(40,90,140))

local preview = Instance.new("Frame", scroll)
preview.LayoutOrder = 4
preview.Size = UDim2.new(1,0,0,140)
preview.BackgroundColor3 = Color3.fromRGB(35,35,45)
preview.BorderSizePixel = 0
setCorner(preview, 12)

local thumb = Instance.new("ImageLabel", preview)
thumb.Size = UDim2.new(0,96,0,96)
thumb.Position = UDim2.new(0,14,0,22)
thumb.BackgroundTransparency = 1
thumb.Image = ""

local nameLbl = Instance.new("TextLabel", preview)
nameLbl.Size = UDim2.new(1,-130,0,26)
nameLbl.Position = UDim2.new(0,120,0,28)
nameLbl.BackgroundTransparency = 1
nameLbl.Text = "No target selected"
nameLbl.Font = FONT_UI
nameLbl.TextSize = 16
nameLbl.TextColor3 = Color3.new(1,1,1)
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

local idLbl = Instance.new("TextLabel", preview)
idLbl.Size = UDim2.new(1,-130,0,20)
idLbl.Position = UDim2.new(0,120,0,58)
idLbl.BackgroundTransparency = 1
idLbl.Text = "UserId: -"
idLbl.Font = FONT_UI
idLbl.TextSize = 12
idLbl.TextColor3 = Color3.fromRGB(180,180,180)
idLbl.TextXAlignment = Enum.TextXAlignment.Left

local hintLbl = Instance.new("TextLabel", preview)
hintLbl.Size = UDim2.new(1,-130,0,20)
hintLbl.Position = UDim2.new(0,120,0,80)
hintLbl.BackgroundTransparency = 1
hintLbl.Text = "Spawn overlay to preview"
hintLbl.Font = FONT_UI
hintLbl.TextSize = 12
hintLbl.TextColor3 = Color3.fromRGB(150,150,150)
hintLbl.TextXAlignment = Enum.TextXAlignment.Left

local hideBtn = Instance.new("TextButton", scroll)
hideBtn.LayoutOrder = 5
hideBtn.Size = UDim2.new(1,0,0,36)
hideBtn.Text = "Hide My Character: ON"
hideBtn.Font = FONT_UI
hideBtn.TextSize = 13
hideBtn.TextColor3 = Color3.new(1,1,1)
hideBtn.BackgroundColor3 = Color3.fromRGB(70,70,90)
setCorner(hideBtn, 12)
applyButtonFX(hideBtn, Color3.fromRGB(70,70,90), Color3.fromRGB(90,90,115), Color3.fromRGB(55,55,70))

local spawnBtn = Instance.new("TextButton", scroll)
spawnBtn.LayoutOrder = 6
spawnBtn.Size = UDim2.new(1,0,0,40)
spawnBtn.Text = "Spawn / Update Overlay"
spawnBtn.Font = FONT_UI
spawnBtn.TextSize = 14
spawnBtn.TextColor3 = Color3.new(1,1,1)
spawnBtn.BackgroundColor3 = Color3.fromRGB(70,140,90)
setCorner(spawnBtn, 12)
applyButtonFX(spawnBtn, Color3.fromRGB(70,140,90), Color3.fromRGB(90,160,110), Color3.fromRGB(55,110,75))

local removeBtn = Instance.new("TextButton", scroll)
removeBtn.LayoutOrder = 7
removeBtn.Size = UDim2.new(1,0,0,40)
removeBtn.Text = "Remove Overlay"
removeBtn.Font = FONT_UI
removeBtn.TextSize = 14
removeBtn.TextColor3 = Color3.new(1,1,1)
removeBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
setCorner(removeBtn, 12)
applyButtonFX(removeBtn, Color3.fromRGB(180,60,60), Color3.fromRGB(200,80,80), Color3.fromRGB(150,40,40))

--==================== NAME PANEL =====
local namePanel = Instance.new("Frame", frame)
namePanel.Visible = false
namePanel.Size = UDim2.new(0, 360, 0, 320)
namePanel.Position = UDim2.new(0.5, -180, 0.5, -160)
namePanel.BackgroundColor3 = Color3.fromRGB(20,20,24)
namePanel.BorderSizePixel = 0
namePanel.ZIndex = 200
namePanel.Active = true
namePanel.ClipsDescendants = true -- FIX: no overflow
setCorner(namePanel, 14)

local nameHeader = Instance.new("Frame", namePanel)
nameHeader.Size = UDim2.new(1,0,0,44)
nameHeader.BackgroundColor3 = Color3.fromRGB(40,40,55)
nameHeader.BorderSizePixel = 0
nameHeader.ZIndex = 201
nameHeader.Active = true

local nameTitle = Instance.new("TextLabel", nameHeader)
nameTitle.Size = UDim2.new(1,-60,1,0)
nameTitle.Position = UDim2.new(0,12,0,0)
nameTitle.BackgroundTransparency = 1
nameTitle.Text = "Nametag Control (Local)"
nameTitle.Font = FONT_UI
nameTitle.TextSize = 16
nameTitle.TextColor3 = Color3.new(1,1,1)
nameTitle.TextXAlignment = Enum.TextXAlignment.Left
nameTitle.ZIndex = 202

local nameClose = Instance.new("TextButton", nameHeader)
nameClose.Size = UDim2.new(0,36,0,36)
nameClose.Position = UDim2.new(1,-44,0,4)
nameClose.Text = "×"
nameClose.Font = FONT_UI
nameClose.TextSize = 22
nameClose.TextColor3 = Color3.new(1,1,1)
nameClose.BackgroundColor3 = Color3.fromRGB(180,60,60)
nameClose.ZIndex = 202
setCorner(nameClose, 10)
applyButtonFX(nameClose, Color3.fromRGB(180,60,60), Color3.fromRGB(200,80,80), Color3.fromRGB(150,40,40))

makeDraggable(nameHeader, namePanel)

-- Body as ScrollingFrame (FIX: always inside panel)
local nameBody = Instance.new("ScrollingFrame", namePanel)
nameBody.Position = UDim2.new(0,0,0,44)
nameBody.Size = UDim2.new(1,0,1,-44)
nameBody.BackgroundTransparency = 1
nameBody.BorderSizePixel = 0
nameBody.ScrollBarThickness = 6
nameBody.AutomaticCanvasSize = Enum.AutomaticSize.Y
nameBody.CanvasSize = UDim2.new(0,0,0,0)
nameBody.ZIndex = 201

local nameLayout = Instance.new("UIListLayout", nameBody)
nameLayout.Padding = UDim.new(0,10)
nameLayout.SortOrder = Enum.SortOrder.LayoutOrder

local namePad = Instance.new("UIPadding", nameBody)
namePad.PaddingLeft = UDim.new(0,16)
namePad.PaddingRight = UDim.new(0,16)
namePad.PaddingTop = UDim.new(0,14)
namePad.PaddingBottom = UDim.new(0,14)

local nameHint = Instance.new("TextLabel", nameBody)
nameHint.LayoutOrder = 1
nameHint.Size = UDim2.new(1,0,0,60)
nameHint.BackgroundTransparency = 1
nameHint.TextWrapped = true
nameHint.TextXAlignment = Enum.TextXAlignment.Left
nameHint.TextYAlignment = Enum.TextYAlignment.Top
nameHint.Font = FONT_UI
nameHint.TextSize = 12
nameHint.TextColor3 = Color3.fromRGB(170,170,170)
nameHint.Text = "APPLY: hide all in-game tags (local) + show custom tag.\nHIDE ONLY: hide all tags (no custom).\nRESET: restore original."
nameHint.ZIndex = 202

local dnBox = makeClippedBox(nameBody, 2, "Custom Display Name", "")
local unBox = makeClippedBox(nameBody, 3, "Custom Username", "")

local row1 = Instance.new("Frame", nameBody)
row1.LayoutOrder = 4
row1.Size = UDim2.new(1,0,0,40)
row1.BackgroundTransparency = 1

local function makeHalfBox(parent, left, placeholder, defaultText)
	local holder = Instance.new("Frame", parent)
	holder.Size = UDim2.new(0.5, -6, 1, 0)
	holder.Position = UDim2.new(left and 0 or 0.5, left and 0 or 6, 0, 0)
	holder.BackgroundColor3 = Color3.fromRGB(45,45,55)
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = true
	holder.ZIndex = 202
	setCorner(holder, 10)

	local box = Instance.new("TextBox", holder)
	box.Size = UDim2.new(1,-20,1,0)
	box.Position = UDim2.new(0,10,0,0)
	box.BackgroundTransparency = 1
	box.PlaceholderText = placeholder
	box.Text = defaultText or ""
	box.ClearTextOnFocus = false
	box.Font = FONT_UI
	box.TextSize = 14
	box.TextColor3 = Color3.new(1,1,1)
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ZIndex = 203
	return box
end

local offsetBox = makeHalfBox(row1, true,  "Height Y (studs)", tostring(VisualName.yOffset))
local outlineBox= makeHalfBox(row1, false, "Outline 0-1", tostring(VisualName.outline))

local fontBtn = Instance.new("TextButton", nameBody)
fontBtn.LayoutOrder = 5
fontBtn.Size = UDim2.new(1,0,0,40)
fontBtn.Text = "Font: BOLD"
fontBtn.Font = FONT_UI
fontBtn.TextSize = 14
fontBtn.TextColor3 = Color3.new(1,1,1)
fontBtn.BackgroundColor3 = Color3.fromRGB(70,70,90)
setCorner(fontBtn, 12)
applyButtonFX(fontBtn, Color3.fromRGB(70,70,90), Color3.fromRGB(90,90,115), Color3.fromRGB(55,55,70))

local row2 = Instance.new("Frame", nameBody)
row2.LayoutOrder = 6
row2.Size = UDim2.new(1,0,0,40)
row2.BackgroundTransparency = 1

local applyBtn = Instance.new("TextButton", row2)
applyBtn.Size = UDim2.new(0.5, -6, 1, 0)
applyBtn.Position = UDim2.new(0,0,0,0)
applyBtn.Text = "APPLY"
applyBtn.Font = FONT_UI
applyBtn.TextSize = 14
applyBtn.TextColor3 = Color3.new(1,1,1)
applyBtn.BackgroundColor3 = Color3.fromRGB(70,140,90)
setCorner(applyBtn, 12)
applyButtonFX(applyBtn, Color3.fromRGB(70,140,90), Color3.fromRGB(90,160,110), Color3.fromRGB(55,110,75))

local hideOnlyBtn = Instance.new("TextButton", row2)
hideOnlyBtn.Size = UDim2.new(0.5, -6, 1, 0)
hideOnlyBtn.Position = UDim2.new(0.5, 6, 0, 0)
hideOnlyBtn.Text = "HIDE ONLY"
hideOnlyBtn.Font = FONT_UI
hideOnlyBtn.TextSize = 14
hideOnlyBtn.TextColor3 = Color3.new(1,1,1)
hideOnlyBtn.BackgroundColor3 = Color3.fromRGB(90,90,115)
setCorner(hideOnlyBtn, 12)
applyButtonFX(hideOnlyBtn, Color3.fromRGB(90,90,115), Color3.fromRGB(110,110,135), Color3.fromRGB(70,70,90))

local resetBtn = Instance.new("TextButton", nameBody)
resetBtn.LayoutOrder = 7
resetBtn.Size = UDim2.new(1,0,0,40)
resetBtn.Text = "RESET"
resetBtn.Font = FONT_UI
resetBtn.TextSize = 14
resetBtn.TextColor3 = Color3.new(1,1,1)
resetBtn.BackgroundColor3 = Color3.fromRGB(180,120,60)
setCorner(resetBtn, 12)
applyButtonFX(resetBtn, Color3.fromRGB(180,120,60), Color3.fromRGB(200,140,80), Color3.fromRGB(150,90,40))

--==================== Minimize / Hide UI ============
local function toggleMinimize()
	if minimized then
		frame.Size = normalSize
		scroll.Visible = true
		minimizeBtn.Text = "−"
	else
		normalSize = frame.Size
		frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, 44)
		scroll.Visible = false
		namePanel.Visible = false
		minimizeBtn.Text = "+"
	end
	minimized = not minimized
end

local function toggleUIHidden()
	uiHidden = not uiHidden
	gui.Enabled = not uiHidden
end

--==================== Main UI logic =================
local selectedUserId, selectedUsername

local function setPreview(userId, username)
	selectedUserId = userId
	selectedUsername = username

	nameLbl.Text = username
	idLbl.Text = "UserId: " .. tostring(userId)

	local okThumb, img = pcall(function()
		local url, _ready = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
		return url
	end)
	if okThumb and img then
		thumb.Image = img
	end
end

local function clearPreview()
	selectedUserId = nil
	selectedUsername = nil
	nameLbl.Text = "No target selected"
	idLbl.Text = "UserId: -"
	thumb.Image = ""
end

local function doSearch()
	setStatus("Searching...")
	local ok, a, b = resolveTarget(inputBox.Text)
	if not ok then
		clearPreview()
		setStatus(a)
		return
	end
	setPreview(a, b)
	setStatus("Target loaded.")
end

searchBtn.MouseButton1Click:Connect(doSearch)
inputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then doSearch() end
end)

hideBtn.MouseButton1Click:Connect(function()
	Overlay.hideSelf = not Overlay.hideSelf
	setLocalHideSelf(Overlay.hideSelf)
	hideBtn.Text = "Hide My Character: " .. (Overlay.hideSelf and "ON" or "OFF")
end)

spawnBtn.MouseButton1Click:Connect(function()
	if not selectedUserId then
		setStatus("Pick a target first.")
		return
	end
	setLocalHideSelf(Overlay.hideSelf)

	local ok = spawnOverlay(selectedUserId, selectedUsername or tostring(selectedUserId), setStatus)
	if ok then hintLbl.Text = "Overlay running (pose mirrored)" end
end)

removeBtn.MouseButton1Click:Connect(function()
	destroyOverlay()
	setStatus("Overlay removed.")
	hintLbl.Text = "Spawn overlay to preview"
end)

minimizeBtn.MouseButton1Click:Connect(toggleMinimize)

idBtn.MouseButton1Click:Connect(function()
	namePanel.Visible = not namePanel.Visible
	if namePanel.Visible then
		dnBox.Text = VisualName.displayName or ""
		unBox.Text = VisualName.userName or ""
		offsetBox.Text = tostring(VisualName.yOffset)
		outlineBox.Text = tostring(VisualName.outline)
		fontBtn.Text = "Font: " .. (VisualName.fontMode == "BLACK" and "BLACK" or "BOLD")
	end
end)

nameClose.MouseButton1Click:Connect(function()
	namePanel.Visible = false
end)

fontBtn.MouseButton1Click:Connect(function()
    VisualName.fontMode = (VisualName.fontMode == "BLACK") and "BOLD" or "BLACK"
    fontBtn.Text = "Font: " .. VisualName.fontMode

    if VisualName.enabled and VisualName.mode == "CUSTOM" then
        enableNametagReplace(VisualName.displayName or "", VisualName.userName or "")
    end
end)

applyBtn.MouseButton1Click:Connect(function()
	local dn = tostring(dnBox.Text or ""):gsub("^%s+",""):gsub("%s+$","")
	local un = tostring(unBox.Text or ""):gsub("^%s+",""):gsub("%s+$","")

	-- IMPORTANT: no auto-fill
	-- empty means "do not show that line"

	VisualName.yOffset = math.clamp(safeNumber(offsetBox.Text, VisualName.yOffset), -10, 50)
	VisualName.outline = math.clamp(safeNumber(outlineBox.Text, VisualName.outline), 0, 1)

	enableNametagReplace(dn, un)
	setStatus(("Nametag replaced (local): %s (@%s)"):format(dn, un))
	namePanel.Visible = false
end)

hideOnlyBtn.MouseButton1Click:Connect(function()
	VisualName.yOffset = math.clamp(safeNumber(offsetBox.Text, VisualName.yOffset), -10, 50)
	VisualName.outline = math.clamp(safeNumber(outlineBox.Text, VisualName.outline), 0, 1)

	enableHideOnly()
	setStatus("In-game nametag hidden (local).")
	namePanel.Visible = false
end)

resetBtn.MouseButton1Click:Connect(function()
	disableNametag()
	setStatus("Nametag restored.")
	namePanel.Visible = false
end)

--==================== FIX: NAME PANEL CONTENT ZINDEX ====================
local function forcePanelZ(root: Instance, baseZ: number)
	-- root harus lebih rendah dari anak-anaknya
	if root:IsA("GuiObject") then
		root.ZIndex = baseZ
	end

	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("GuiObject") then
			-- semua isi panel di atas background panel
			obj.ZIndex = baseZ + 1
		end
	end
end

-- Pastikan namePanel benar-benar berada di atas main UI
forcePanelZ(namePanel, 240)


closeBtn.MouseButton1Click:Connect(function()
	destroyOverlay()
	stopHideHooks()
	disableNametag()
	gui:Destroy()
end)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.Comma then
		toggleUIHidden()
	end
end)

-- default setup
task.spawn(function()
	task.wait(0.1)
	setLocalHideSelf(true)
	setStatus("Ready. Search Username/UserId, then Spawn Overlay.")
end)
