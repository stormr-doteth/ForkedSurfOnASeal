-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Stickers Configuration (unchanged)
local stickers = {
	{
		name = "Cry",
		id = "rbxassetid://103325743514512",
		frameW = 100,
		frameH = 100,
		rows = 9,
		cols = 10,
		totalFrames = 90,
		fps = 30,
		numberOfLoops = 1,
	},
	{
		name = "Headphones",
		id = "rbxassetid://128076453503381",
		frameW = 100,
		frameH = 100,
		rows = 8,
		cols = 10,
		totalFrames = 71,
		fps = 30,
		numberOfLoops = 1,
	},
	{
		name = "Wow",
		id = "rbxassetid://120121986197103",
		frameW = 100,
		frameH = 100,
		rows = 9,
		cols = 10,
		totalFrames = 89,
		fps = 60,
		numberOfLoops = 1,
	},
	{
		name = "Nod",
		id = "rbxassetid://114127577008358",
		frameW = 100,
		frameH = 100,
		rows = 3,
		cols = 10,
		totalFrames = 30,
		fps = 60,
		numberOfLoops = 3,
	},
	{
		name = "Shocked",
		id = "rbxassetid://138246976882657",
		frameW = 100,
		frameH = 100,
		rows = 6,
		cols = 10,
		totalFrames = 52,
		fps = 30,
		numberOfLoops = 1,
	},
	{
		name = "Hello",
		id = "rbxassetid://91908853294713",
		frameW = 100,
		frameH = 100,
		rows = 6,
		cols = 10,
		totalFrames = 60,
		fps = 30,
		numberOfLoops = 1,
	},
	{
		name = "Airplane",
		id = "rbxassetid://75877361985702",
		frameW = 100,
		frameH = 100,
		rows = 9,
		cols = 10,
		totalFrames = 90,
		fps = 30,
		numberOfLoops = 1,
	},
	{
		name = "Tail",
		id = "rbxassetid://135267146676686",
		frameW = 100,
		frameH = 100,
		rows = 4,
		cols = 10,
		totalFrames = 37,
		fps = 30,
		numberOfLoops = 1,
	},
}

-- Configuration
local TWEEN_TIME = 0.5 -- Duration for tween in/out (seconds)
local BACKGROUND_IMAGE_ID = "rbxassetid://139491745816890" -- Background image ID

-- Create RemoteEvents if they don't exist
local remoteEvent = ReplicatedStorage:FindFirstChild("StickerAnimationEvent")
if not remoteEvent then
	remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = "StickerAnimationEvent"
	remoteEvent.Parent = ReplicatedStorage
end

local completionEvent = ReplicatedStorage:FindFirstChild("StickerAnimationCompleted")
if not completionEvent then
	completionEvent = Instance.new("RemoteEvent")
	completionEvent.Name = "StickerAnimationCompleted"
	completionEvent.Parent = ReplicatedStorage
end

-- Tweening functions (updated to use requested scale sizes)
local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local function tweenIn(imageLabel, config)
	imageLabel.ImageTransparency = 1
	imageLabel.Size = UDim2.fromScale(0, 0)
	local tween = TweenService:Create(imageLabel, tweenInfo, {
		ImageTransparency = 0,
		Size = UDim2.fromScale(.8,.8) -- Sticker label size {1, 0}, {1, 0}
	})
	tween:Play()
	return tween
end

local function tweenInBackground(backgroundLabel)
	backgroundLabel.ImageTransparency = 1
	backgroundLabel.Size = UDim2.fromScale(0, 0)
	local tween = TweenService:Create(backgroundLabel, tweenInfo, {
		ImageTransparency = 0,
		Size = UDim2.fromScale(1.4,.9) -- Background size {1.5, 0}, {1, 0}
	})
	tween:Play()
	return tween
end

local function tweenOut(imageLabel)
	local tween = TweenService:Create(imageLabel, tweenInfo, {
		ImageTransparency = 1,
		Size = UDim2.fromScale(0, 0)
	})
	tween:Play()
	return tween
end

local function tweenOutBackground(backgroundLabel)
	local tween = TweenService:Create(backgroundLabel, tweenInfo, {
		ImageTransparency = 1,
		Size = UDim2.fromScale(0, 0)
	})
	tween:Play()
	return tween
end

-- Animation (unchanged)
local function setFrame(imageLabel, frameIndex, config)
	local row = math.floor(frameIndex / config.cols)
	local col = frameIndex % config.cols
	imageLabel.ImageRectOffset = Vector2.new(col * config.frameW, row * config.frameH)
end

-- Create or get BillboardGui for a player (updated size)
local function getBillboardGui(player)
	local character = player.Character
	if not character then return nil end
	local head = character:FindFirstChild("Head")
	if not head then return nil end
	local billboardGui = head:FindFirstChild("StickerBillboard")
	if not billboardGui then
		billboardGui = Instance.new("BillboardGui")
		billboardGui.Name = "StickerBillboard"
		billboardGui.AlwaysOnTop = true
		billboardGui.MaxDistance = 100
		billboardGui.ExtentsOffset = Vector3.new(0, 3, 0)
		billboardGui.Size = UDim2.fromScale(2.5, 2.5) -- BillboardGui size {2.5, 0}, {2.5, 0}
		billboardGui.Parent = head
		-- Create background ImageLabel
		local backgroundLabel = Instance.new("ImageLabel")
		backgroundLabel.Name = "BackgroundImageLabel"
		backgroundLabel.BackgroundTransparency = 1
		backgroundLabel.Image = BACKGROUND_IMAGE_ID
		backgroundLabel.Size = UDim2.fromScale(0, 0) -- Start scaled down
		backgroundLabel.ImageTransparency = 1 -- Start hidden
		backgroundLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		backgroundLabel.Position = UDim2.fromScale(0.5, 0.5) -- Position {0.5, 0}, {0.5, 0}
		backgroundLabel.ZIndex = 0 -- Behind the main ImageLabel
		backgroundLabel.Parent = billboardGui
		-- Create main ImageLabel
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Name = "ImageLabel"
		imageLabel.BackgroundTransparency = 1
		imageLabel.Size = UDim2.fromScale(0, 0) -- Start scaled down
		imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		imageLabel.Position = UDim2.fromScale(0.5, 0.5) -- Position {0.5, 0}, {0.5, 0}
		imageLabel.ImageTransparency = 1 -- Start hidden
		imageLabel.ZIndex = 1 -- In front of BackgroundImageLabel
		imageLabel.Parent = billboardGui
	end
	return billboardGui
end

-- Animation logic (updated to set scale-based size)
local function playAnimation(player, stickerIndex)
	local config = stickers[stickerIndex]
	if not config then return end
	local billboardGui = getBillboardGui(player)
	if not billboardGui then return end
	local imageLabel = billboardGui.ImageLabel
	local backgroundLabel = billboardGui.BackgroundImageLabel
	if not imageLabel or not backgroundLabel then return end
	imageLabel.Image = config.id
	imageLabel.ImageRectSize = Vector2.new(config.frameW, config.frameH)
	billboardGui.Size = UDim2.fromScale(2.5, 2.5) -- BillboardGui size {2.5, 0}, {2.5, 0}
	local currentFrame = 0
	local acc = 0
	local totalFrames = config.totalFrames
	local frameTime = 1 / config.fps
	local loopsCompleted = 0
	local numberOfLoops = config.numberOfLoops or 1
	setFrame(imageLabel, 0, config)
	-- Tween in both main and background labels
	local tweenInInstance = tweenIn(imageLabel, config)
	local tweenInBackgroundInstance = tweenInBackground(backgroundLabel)
	tweenInInstance.Completed:Wait()
	-- Start animation
	local renderConnection
	renderConnection = RunService.Heartbeat:Connect(function(deltaTime)
		acc = acc + deltaTime
		if acc >= frameTime then
			currentFrame = currentFrame + 1
			if currentFrame >= totalFrames then
				loopsCompleted = loopsCompleted + 1
				if loopsCompleted >= numberOfLoops then
					renderConnection:Disconnect()
					local tweenOutInstance = tweenOut(imageLabel)
					local tweenOutBackgroundInstance = tweenOutBackground(backgroundLabel)
					tweenOutInstance.Completed:Connect(function()
						completionEvent:FireClient(player) -- Notify client when animation completes
					end)
				else
					currentFrame = 0
					setFrame(imageLabel, currentFrame, config)
				end
				acc = acc - frameTime
			else
				setFrame(imageLabel, currentFrame, config)
				acc = acc - frameTime
			end
		end
	end)
end

-- Handle RemoteEvent
remoteEvent.OnServerEvent:Connect(function(player, stickerIndex)
	playAnimation(player, stickerIndex)
end)

-- Handle player character respawn
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Ensure BillboardGui is recreated if needed
		local billboardGui = getBillboardGui(player)
	end)
end)