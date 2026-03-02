
-- TimeTrialUI: Client-side UI for the Time Trials experience
-- Handles track selection, live timer, and results display

-- Services --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Networking --

local Networking = ReplicatedStorage:WaitForChild("Networking")
local SelectTrackRemote = Networking.Server.RemoteEvents.SelectTrack
local ReturnToLobbyRemote = Networking.Server.RemoteEvents.ReturnToLobby
local CancelRunRemote = Networking.Server.RemoteEvents.CancelRun
local ReadyForCountdownRemote = Networking.Server.RemoteEvents.ReadyForCountdown

local TrackListRemote = Networking.Client.RemoteEvents.TrackList
local StartTimerRemote = Networking.Client.RemoteEvents.StartTimer
local StopTimerRemote = Networking.Client.RemoteEvents.StopTimer
local ShowTimeTrialResultsRemote = Networking.Client.RemoteEvents.ShowTimeTrialResults
local UpdateProgessBarRemote = Networking.Client.RemoteEvents.UpdateProgessBar
local SendBestSplitsRemote = Networking.Client.RemoteEvents.SendBestSplits
local ReportSplitsRemote = Networking.Server.RemoteEvents.ReportSplits
local SoundManager = Networking.Client.BindableEvents.SoundManager

local TrackPreviews = ReplicatedStorage:WaitForChild("TrackPreviews", 10)


-- State --

local currentScreen = "waiting" -- "waiting", "picker", "detail", "racing", "results"
local timerRunning = false
local timerStartTime = 0
local timerConnection = nil
local trackNames = {}
local lastSelectedTrack = nil
local loadingStartTime = 0
local trackStartZ = nil
local trackEndZ = nil
local playerPin = nil
local checkpointZPositions = {}
local nextCheckpointIndex = 1
local currentSplits = {}
local bestSplits = {}
local segmentCount = 0
local splitsPanel = nil
local splitRows = {}


-- UI Creation --

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TimeTrialUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Clone TitleLabel from main game's loading screen as a style template --
local LoadingScreenFrameRef = PlayerGui:WaitForChild("ScreenGui"):FindFirstChild("LoadingScreenFrame")
local TitleLabelTemplate = LoadingScreenFrameRef and LoadingScreenFrameRef:FindFirstChild("TitleLabel")

local function CreateStyledLabel(name, size, position, textColor)
	local label
	if TitleLabelTemplate then
		label = TitleLabelTemplate:Clone()
	else
		-- Fallback: create manually matching the style
		label = Instance.new("TextLabel")
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.TextXAlignment = Enum.TextXAlignment.Center
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Thickness = 3
		stroke.Transparency = 0
		stroke.Parent = label
	end
	label.Name = name
	label.Size = size
	label.Position = position
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.Text = ""
	label.ZIndex = 11
	return label
end

-- Built-in UI references (from ScreenGui.Gameplay.ProgressBar) --
local GameplayFrame = PlayerGui:WaitForChild("ScreenGui"):WaitForChild("Gameplay")
local ProgressBar = GameplayFrame:WaitForChild("ProgressBar")
local BuiltInTimerLabel = ProgressBar:WaitForChild("TimerLabel")
local MarkerFrame = ProgressBar:WaitForChild("MarkerFrame")
local SplitFrame = ProgressBar:WaitForChild("SplitFrame")
local SegmentsFrame = SplitFrame:WaitForChild("Segments")
local ProgressBarBackground = ProgressBar:WaitForChild("Background")
local RaceStartFrame = GameplayFrame:WaitForChild("RaceStart")
GameplayFrame.Visible = false

-- Hide TeleportButton — not needed in time trials (RaceStartScript sets it visible)
local teleportButton = RaceStartFrame:FindFirstChild("TeleportButton")
if teleportButton then
	teleportButton.Visible = false
	teleportButton:GetPropertyChangedSignal("Visible"):Connect(function()
		if teleportButton.Visible then
			teleportButton.Visible = false
		end
	end)
end

-- RaceEndMenu references (use the main game's PersonalResultsFrame for results display)
local MainScreenGui = PlayerGui:WaitForChild("ScreenGui")
local RaceEndMenu = MainScreenGui:WaitForChild("RaceEndMenu")
local RaceEndMenuScript = RaceEndMenu:FindFirstChild("RaceEndMenuScript")
if RaceEndMenuScript then RaceEndMenuScript.Disabled = true end

local PersonalResultsFrame = RaceEndMenu:WaitForChild("PersonalResultsFrame")
local StatsFrame = PersonalResultsFrame:WaitForChild("StatsFrame")
local StatLabelThing = StatsFrame:WaitForChild("StatLabelThing")
local RaceEndExitButton = PersonalResultsFrame:WaitForChild("ExitButton")
local RaceEndShopButton = PersonalResultsFrame:WaitForChild("ShopButton")
local RaceEndMySealButton = PersonalResultsFrame:WaitForChild("MySealButton")

-- Make StatsFrame taller to fit splits breakdown
StatsFrame.Size = UDim2.new(0.46, 0, 0.55, 0)

-- Hide elements not needed for time trials
RaceEndMenu.Visible = false
PersonalResultsFrame.Visible = false
local battlePassFrame = PersonalResultsFrame:FindFirstChild("BattlePassFrame")
if battlePassFrame then battlePassFrame.Visible = false end

-- RaceFinish overlay references (FINISH! splash screen)
local RaceFinishFrame = GameplayFrame:WaitForChild("RaceFinish")
local FinishFrame = RaceFinishFrame:WaitForChild("FinishFrame")
local FinishTimeLabel = FinishFrame:FindFirstChild("TimeLabel")
if not FinishTimeLabel then
	FinishTimeLabel = Instance.new("TextLabel")
	FinishTimeLabel.Name = "TimeLabel"
	FinishTimeLabel.Size = UDim2.new(0.8, 0, 0.25, 0)
	FinishTimeLabel.Position = UDim2.new(0.5, 0, 0.7, 0)
	FinishTimeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	FinishTimeLabel.BackgroundTransparency = 1
	FinishTimeLabel.Font = Enum.Font.FredokaOne
	FinishTimeLabel.TextScaled = true
	FinishTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	FinishTimeLabel.Text = ""
	local finishStroke = Instance.new("UIStroke")
	finishStroke.Color = Color3.new(0, 0, 0)
	finishStroke.Thickness = 3
	finishStroke.Transparency = 0
	finishStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	finishStroke.Parent = FinishTimeLabel
	FinishTimeLabel.Parent = FinishFrame
end
local FinishImage = FinishFrame:FindFirstChild("FinishImage")
local RaceFinishScript = RaceFinishFrame:FindFirstChild("RaceFinishScript")
if RaceFinishScript then RaceFinishScript.Disabled = true end

-- Undo RaceFinishScript's ResetUI() which set FinishImage.ImageTransparency = 1
if FinishImage then
	FinishImage.ImageTransparency = 0
	FinishImage.Size = UDim2.new(1.2, 0, 1.2, 0)
	FinishImage.Position = UDim2.new(0.5, 0, 0.35, 0)
end

-- Hide RaceFinishFrame entirely until we need it (prevents blocking input)
RaceFinishFrame.Visible = false

-- Hide placement UI elements not needed in time trials
for _, name in ipairs({"PlacementDestination", "PlacementSpawn", "PlacementImageFrame"}) do
	local el = RaceFinishFrame:FindFirstChild(name)
	if el then el.Visible = false end
end

-- Disable the built-in countdown timer script so we can drive it with count-up
local timerLabelScript = BuiltInTimerLabel:FindFirstChild("TimerLabelScript")
if timerLabelScript then
	timerLabelScript.Disabled = true
end
BuiltInTimerLabel.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular)
BuiltInTimerLabel.TextScaled = true

-- Disable the built-in progress bar script so we can drive pin position ourselves
local progressBarScript = ProgressBar:FindFirstChild("ProgressBarScript")
if progressBarScript then
	progressBarScript.Disabled = true
end


-- Helper: add UITextSizeConstraint to a TextScaled label
local function addTextSizeConstraint(textObj, maxSize, minSize)
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = maxSize
	constraint.MinTextSize = minSize or 8
	constraint.Parent = textObj
end

-- ============================================================
-- TRACK PICKER SCREEN
-- ============================================================

local PickerFrame = Instance.new("Frame")
PickerFrame.Name = "PickerFrame"
PickerFrame.Size = UDim2.new(0.88, 0, 0.88, 0)
PickerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
PickerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
PickerFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 35)
PickerFrame.BackgroundTransparency = 0
PickerFrame.BorderSizePixel = 0
PickerFrame.Visible = false
PickerFrame.Parent = ScreenGui

local PickerCorner = Instance.new("UICorner")
PickerCorner.CornerRadius = UDim.new(0, 16)
PickerCorner.Parent = PickerFrame

local PickerStroke = Instance.new("UIStroke")
PickerStroke.Color = Color3.fromRGB(255, 230, 44)
PickerStroke.Thickness = 2
PickerStroke.Transparency = 0.7
PickerStroke.Parent = PickerFrame

-- Header area (~120px)
local HeaderFrame = Instance.new("Frame")
HeaderFrame.Name = "HeaderFrame"
HeaderFrame.Size = UDim2.new(1, 0, 0.15, 0)
HeaderFrame.BackgroundTransparency = 1
HeaderFrame.Parent = PickerFrame

-- Title: "TIME TRIALS"
local PickerTitle = Instance.new("TextLabel")
PickerTitle.Name = "Title"
PickerTitle.Size = UDim2.new(1, 0, 0.45, 0)
PickerTitle.Position = UDim2.new(0, 0, 0.05, 0)
PickerTitle.BackgroundTransparency = 1
PickerTitle.Text = "TIME TRIALS"
PickerTitle.TextColor3 = Color3.fromRGB(255, 230, 44)
PickerTitle.TextScaled = true
PickerTitle.Font = Enum.Font.FredokaOne
PickerTitle.Parent = HeaderFrame
addTextSizeConstraint(PickerTitle, 38, 16)

local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color = Color3.new(0, 0, 0)
TitleStroke.Thickness = 3
TitleStroke.Transparency = 0
TitleStroke.Parent = PickerTitle

-- Subtitle row frame
local SubtitleRow = Instance.new("Frame")
SubtitleRow.Name = "SubtitleRow"
SubtitleRow.Size = UDim2.new(0.9, 0, 0.28, 0)
SubtitleRow.Position = UDim2.new(0.05, 0, 0.6, 0)
SubtitleRow.BackgroundTransparency = 1
SubtitleRow.Parent = HeaderFrame

-- Subtitle text (left)
local PickerSubtitle = Instance.new("TextLabel")
PickerSubtitle.Name = "Subtitle"
PickerSubtitle.Size = UDim2.new(0.5, 0, 1, 0)
PickerSubtitle.Position = UDim2.new(0, 0, 0, 0)
PickerSubtitle.BackgroundTransparency = 1
PickerSubtitle.Text = "Select a track to practice"
PickerSubtitle.TextColor3 = Color3.fromRGB(160, 160, 175)
PickerSubtitle.TextScaled = true
PickerSubtitle.Font = Enum.Font.Gotham
PickerSubtitle.TextXAlignment = Enum.TextXAlignment.Left
PickerSubtitle.Parent = SubtitleRow
addTextSizeConstraint(PickerSubtitle, 28, 10)

-- Stats pill (right)
local StatsPill = Instance.new("Frame")
StatsPill.Name = "StatsPill"
StatsPill.Size = UDim2.new(0.4, 0, 0.85, 0)
StatsPill.Position = UDim2.new(1, 0, 0.5, 0)
StatsPill.AnchorPoint = Vector2.new(1, 0.5)
StatsPill.BackgroundColor3 = Color3.fromRGB(22, 32, 58)
StatsPill.BorderSizePixel = 0
StatsPill.Parent = SubtitleRow

local StatsPillCorner = Instance.new("UICorner")
StatsPillCorner.CornerRadius = UDim.new(0.5, 0)
StatsPillCorner.Parent = StatsPill

local StatsPillLabel = Instance.new("TextLabel")
StatsPillLabel.Name = "Label"
StatsPillLabel.Size = UDim2.new(1, 0, 1, 0)
StatsPillLabel.BackgroundTransparency = 1
StatsPillLabel.Text = "0 / 0 Completed"
StatsPillLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatsPillLabel.TextScaled = true
StatsPillLabel.Font = Enum.Font.GothamBold
StatsPillLabel.Parent = StatsPill
addTextSizeConstraint(StatsPillLabel, 24, 8)

-- Scrolling frame for track cards
local TrackScroller = Instance.new("ScrollingFrame")
TrackScroller.Name = "TrackScroller"
TrackScroller.Size = UDim2.new(0.92, 0, 0.73, 0)
TrackScroller.Position = UDim2.new(0.04, 0, 0.15, 0)
TrackScroller.BackgroundTransparency = 1
TrackScroller.ScrollBarThickness = 6
TrackScroller.ScrollBarImageColor3 = Color3.fromRGB(255, 230, 44)
TrackScroller.BorderSizePixel = 0
TrackScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
TrackScroller.Parent = PickerFrame

local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize = UDim2.new(0.48, 0, 0, 120)
GridLayout.CellPadding = UDim2.new(0.02, 0, 0, 8)
GridLayout.SortOrder = Enum.SortOrder.Name
GridLayout.FillDirectionMaxCells = 2
GridLayout.Parent = TrackScroller

-- Return to lobby button
local ReturnButton = Instance.new("TextButton")
ReturnButton.Name = "ReturnButton"
ReturnButton.Size = UDim2.new(0.3, 0, 0.065, 0)
ReturnButton.Position = UDim2.new(0.5, 0, 0.92, 0)
ReturnButton.AnchorPoint = Vector2.new(0.5, 0)
ReturnButton.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
ReturnButton.BorderSizePixel = 0
ReturnButton.Text = "RETURN TO LOBBY"
ReturnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ReturnButton.TextScaled = true
ReturnButton.Font = Enum.Font.FredokaOne
ReturnButton.AutoButtonColor = true
ReturnButton.Parent = PickerFrame

local ReturnCorner = Instance.new("UICorner")
ReturnCorner.CornerRadius = UDim.new(0.3, 0)
ReturnCorner.Parent = ReturnButton

local ReturnStroke = Instance.new("UIStroke")
ReturnStroke.Color = Color3.fromRGB(0, 0, 0)
ReturnStroke.Thickness = 3
ReturnStroke.Parent = ReturnButton

local ReturnPadding = Instance.new("UIPadding")
ReturnPadding.PaddingTop = UDim.new(0.1, 0)
ReturnPadding.PaddingBottom = UDim.new(0.1, 0)
ReturnPadding.PaddingLeft = UDim.new(0.05, 0)
ReturnPadding.PaddingRight = UDim.new(0.05, 0)
ReturnPadding.Parent = ReturnButton


-- ============================================================
-- TRACK DETAIL MODAL
-- ============================================================

local DetailModal = Instance.new("Frame")
DetailModal.Name = "DetailModal"
DetailModal.Size = UDim2.new(0.5, 0, 0.7, 0)
DetailModal.Position = UDim2.new(0.5, 0, 0.5, 0)
DetailModal.AnchorPoint = Vector2.new(0.5, 0.5)
DetailModal.BackgroundColor3 = Color3.fromRGB(10, 15, 35)
DetailModal.BackgroundTransparency = 0
DetailModal.BorderSizePixel = 0
DetailModal.Visible = false
DetailModal.Parent = ScreenGui

local DetailModalCorner = Instance.new("UICorner")
DetailModalCorner.CornerRadius = UDim.new(0, 16)
DetailModalCorner.Parent = DetailModal

local DetailModalStroke = Instance.new("UIStroke")
DetailModalStroke.Color = Color3.fromRGB(255, 230, 44)
DetailModalStroke.Thickness = 2
DetailModalStroke.Transparency = 0.5
DetailModalStroke.Parent = DetailModal

local DetailModalScale = Instance.new("UIScale")
DetailModalScale.Scale = 1
DetailModalScale.Parent = DetailModal

-- Large viewport for track preview (~top 60%)
local DetailViewport = Instance.new("ViewportFrame")
DetailViewport.Name = "DetailViewport"
DetailViewport.Size = UDim2.new(0.9, 0, 0.55, 0)
DetailViewport.Position = UDim2.new(0.5, 0, 0.03, 0)
DetailViewport.AnchorPoint = Vector2.new(0.5, 0)
DetailViewport.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
DetailViewport.BorderSizePixel = 0
DetailViewport.Ambient = Color3.fromRGB(180, 180, 180)
DetailViewport.LightColor = Color3.fromRGB(255, 255, 255)
DetailViewport.LightDirection = Vector3.new(-1, -1, -1)
DetailViewport.Parent = DetailModal

local DetailViewportCorner = Instance.new("UICorner")
DetailViewportCorner.CornerRadius = UDim.new(0.03, 0)
DetailViewportCorner.Parent = DetailViewport

-- Orbit camera state for detail viewport
local detailCameraYaw = 0
local detailCameraPitch = 0.3
local detailCameraDistance = 100
local detailCameraCenter = Vector3.new(0, 0, 0)
local detailCameraMinDist = 20
local detailCameraMaxDist = 500
local detailDragging = false
local detailDragStartYaw = 0
local detailDragStartPitch = 0
local detailDragStartPos = Vector2.new(0, 0)

local function UpdateDetailCamera()
	local cam = DetailViewport.CurrentCamera
	if not cam then return end

	local cosP = math.cos(detailCameraPitch)
	local sinP = math.sin(detailCameraPitch)
	local cosY = math.cos(detailCameraYaw)
	local sinY = math.sin(detailCameraYaw)

	local offset = Vector3.new(
		detailCameraDistance * cosP * sinY,
		detailCameraDistance * sinP,
		detailCameraDistance * cosP * cosY
	)
	cam.CFrame = CFrame.lookAt(detailCameraCenter + offset, detailCameraCenter)
end

DetailViewport.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		detailDragging = true
		detailDragStartYaw = detailCameraYaw
		detailDragStartPitch = detailCameraPitch
		detailDragStartPos = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

DetailViewport.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		if detailDragging then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - detailDragStartPos
			detailCameraYaw = detailDragStartYaw - delta.X * 0.005
			detailCameraPitch = math.clamp(detailDragStartPitch + delta.Y * 0.005, -1.2, 1.2)
			UpdateDetailCamera()
		end
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		detailCameraDistance = math.clamp(
			detailCameraDistance - input.Position.Z * detailCameraDistance * 0.1,
			detailCameraMinDist,
			detailCameraMaxDist
		)
		UpdateDetailCamera()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		detailDragging = false
	end
end)

local SCROLL_SINK_ACTION = "TimeTrialScrollSink"

local function SinkScroll()
	ContextActionService:BindAction(SCROLL_SINK_ACTION, function()
		return Enum.ContextActionResult.Sink
	end, false, Enum.UserInputType.MouseWheel)
end

local function UnsinkScroll()
	ContextActionService:UnbindAction(SCROLL_SINK_ACTION)
end

-- Track name label
local DetailTrackName = Instance.new("TextLabel")
DetailTrackName.Name = "DetailTrackName"
DetailTrackName.Size = UDim2.new(0.9, 0, 0.1, 0)
DetailTrackName.Position = UDim2.new(0.5, 0, 0.60, 0)
DetailTrackName.AnchorPoint = Vector2.new(0.5, 0)
DetailTrackName.BackgroundTransparency = 1
DetailTrackName.Text = ""
DetailTrackName.TextColor3 = Color3.fromRGB(255, 230, 44)
DetailTrackName.TextScaled = true
DetailTrackName.Font = Enum.Font.FredokaOne
DetailTrackName.Parent = DetailModal
addTextSizeConstraint(DetailTrackName, 36, 14)

local DetailTrackNameStroke = Instance.new("UIStroke")
DetailTrackNameStroke.Color = Color3.new(0, 0, 0)
DetailTrackNameStroke.Thickness = 3
DetailTrackNameStroke.Parent = DetailTrackName

-- Personal best label
local DetailPBLabel = Instance.new("TextLabel")
DetailPBLabel.Name = "DetailPBLabel"
DetailPBLabel.Size = UDim2.new(0.9, 0, 0.06, 0)
DetailPBLabel.Position = UDim2.new(0.5, 0, 0.71, 0)
DetailPBLabel.AnchorPoint = Vector2.new(0.5, 0)
DetailPBLabel.BackgroundTransparency = 1
DetailPBLabel.Text = "No time set"
DetailPBLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
DetailPBLabel.TextScaled = true
DetailPBLabel.Font = Enum.Font.GothamBold
DetailPBLabel.Parent = DetailModal
addTextSizeConstraint(DetailPBLabel, 28, 10)

-- "PLAY NOW" button
local DetailPlayButton = Instance.new("TextButton")
DetailPlayButton.Name = "DetailPlayButton"
DetailPlayButton.Size = UDim2.new(0.5, 0, 0.09, 0)
DetailPlayButton.Position = UDim2.new(0.5, 0, 0.80, 0)
DetailPlayButton.AnchorPoint = Vector2.new(0.5, 0)
DetailPlayButton.BackgroundColor3 = Color3.fromRGB(40, 170, 80)
DetailPlayButton.BorderSizePixel = 0
DetailPlayButton.Text = "PLAY NOW"
DetailPlayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DetailPlayButton.TextScaled = true
DetailPlayButton.Font = Enum.Font.FredokaOne
DetailPlayButton.AutoButtonColor = true
DetailPlayButton.Parent = DetailModal

local DetailPlayCorner = Instance.new("UICorner")
DetailPlayCorner.CornerRadius = UDim.new(0.3, 0)
DetailPlayCorner.Parent = DetailPlayButton

local DetailPlayStroke = Instance.new("UIStroke")
DetailPlayStroke.Color = Color3.new(0, 0, 0)
DetailPlayStroke.Thickness = 3
DetailPlayStroke.Parent = DetailPlayButton

local DetailPlayPadding = Instance.new("UIPadding")
DetailPlayPadding.PaddingTop = UDim.new(0.1, 0)
DetailPlayPadding.PaddingBottom = UDim.new(0.1, 0)
DetailPlayPadding.PaddingLeft = UDim.new(0.05, 0)
DetailPlayPadding.PaddingRight = UDim.new(0.05, 0)
DetailPlayPadding.Parent = DetailPlayButton

-- "BACK TO ALL TRACKS" button
local DetailBackButton = Instance.new("TextButton")
DetailBackButton.Name = "DetailBackButton"
DetailBackButton.Size = UDim2.new(0.4, 0, 0.06, 0)
DetailBackButton.Position = UDim2.new(0.5, 0, 0.92, 0)
DetailBackButton.AnchorPoint = Vector2.new(0.5, 0)
DetailBackButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
DetailBackButton.BorderSizePixel = 0
DetailBackButton.Text = "BACK TO ALL TRACKS"
DetailBackButton.TextColor3 = Color3.fromRGB(200, 200, 200)
DetailBackButton.TextScaled = true
DetailBackButton.Font = Enum.Font.FredokaOne
DetailBackButton.AutoButtonColor = true
DetailBackButton.Parent = DetailModal

local DetailBackCorner = Instance.new("UICorner")
DetailBackCorner.CornerRadius = UDim.new(0.3, 0)
DetailBackCorner.Parent = DetailBackButton

local DetailBackStroke = Instance.new("UIStroke")
DetailBackStroke.Color = Color3.fromRGB(0, 0, 0)
DetailBackStroke.Thickness = 2
DetailBackStroke.Parent = DetailBackButton

local DetailBackPadding = Instance.new("UIPadding")
DetailBackPadding.PaddingTop = UDim.new(0.1, 0)
DetailBackPadding.PaddingBottom = UDim.new(0.1, 0)
DetailBackPadding.PaddingLeft = UDim.new(0.05, 0)
DetailBackPadding.PaddingRight = UDim.new(0.05, 0)
DetailBackPadding.Parent = DetailBackButton


-- Cancel Run button (visible during racing, beside progress bar)
local CancelButton = Instance.new("TextButton")
CancelButton.Name = "CancelButton"
CancelButton.Size = UDim2.new(0.12, 0, 0.035, 0)
CancelButton.Position = UDim2.new(0.9, 0, 0.02, 0)
CancelButton.AnchorPoint = Vector2.new(0.5, 0)
CancelButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CancelButton.BackgroundTransparency = 0
CancelButton.BorderSizePixel = 0
CancelButton.Text = "Cancel Run"
CancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CancelButton.TextScaled = true
CancelButton.Font = Enum.Font.FredokaOne
CancelButton.Visible = false
CancelButton.Parent = ScreenGui
addTextSizeConstraint(CancelButton, 16, 8)

local CancelCorner = Instance.new("UICorner")
CancelCorner.CornerRadius = UDim.new(0.3, 0)
CancelCorner.Parent = CancelButton

local CancelStroke = Instance.new("UIStroke")
CancelStroke.Color = Color3.new(0, 0, 0)
CancelStroke.Thickness = 2
CancelStroke.Parent = CancelButton

local CancelPadding = Instance.new("UIPadding")
CancelPadding.PaddingTop = UDim.new(0.1, 0)
CancelPadding.PaddingBottom = UDim.new(0.1, 0)
CancelPadding.PaddingLeft = UDim.new(0.05, 0)
CancelPadding.PaddingRight = UDim.new(0.05, 0)
CancelPadding.Parent = CancelButton


-- ============================================================
-- LOADING OVERLAY
-- ============================================================

local LoadingOverlay = Instance.new("ImageLabel")
LoadingOverlay.Name = "LoadingOverlay"
LoadingOverlay.Size = UDim2.new(2, 0, 2, 0)
LoadingOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
LoadingOverlay.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadingOverlay.BackgroundTransparency = 1
LoadingOverlay.Image = "rbxassetid://106586504083934"
LoadingOverlay.ScaleType = Enum.ScaleType.Stretch
LoadingOverlay.ImageTransparency = 0
LoadingOverlay.BorderSizePixel = 0
LoadingOverlay.ZIndex = 10
LoadingOverlay.Visible = false
LoadingOverlay.Parent = ScreenGui

-- Track name — large, centered, yellow
local LoadingTrackName = CreateStyledLabel(
	"TrackName",
	UDim2.new(0.8, 0, 0.1, 0),
	UDim2.new(0.5, 0, 0.4, 0),
	Color3.fromRGB(255, 230, 44)
)
LoadingTrackName.Parent = LoadingOverlay

-- Subtitle — "Loading Track..."
local LoadingSubtitle = CreateStyledLabel(
	"Subtitle",
	UDim2.new(0.6, 0, 0.06, 0),
	UDim2.new(0.5, 0, 0.5, 0),
	Color3.fromRGB(200, 200, 200)
)
LoadingSubtitle.Text = "Loading Track..."
LoadingSubtitle.Parent = LoadingOverlay

-- Personal best text
local LoadingPBText = CreateStyledLabel(
	"PBText",
	UDim2.new(0.6, 0, 0.05, 0),
	UDim2.new(0.5, 0, 0.57, 0),
	Color3.fromRGB(180, 180, 180)
)
LoadingPBText.Parent = LoadingOverlay


-- ============================================================
-- RESULTS SCREEN (uses main game's PersonalResultsFrame)
-- ============================================================

-- Hide all main-game buttons (we create our own)
RaceEndExitButton.Visible = false
RaceEndShopButton.Visible = false
RaceEndMySealButton.Visible = false

-- Create custom centered buttons for time trials
local function CreateResultsButton(name, text, layoutOrder)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.38, 0, 0, 44)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.FredokaOne
	btn.TextScaled = true
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextStrokeColor3 = Color3.new(0, 0, 0)
	btn.TextStrokeTransparency = 0
	btn.LayoutOrder = layoutOrder
	btn.AutoButtonColor = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = btn

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = btn

	return btn
end

-- Button container — centered at the bottom of PersonalResultsFrame
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Name = "TTButtonContainer"
ButtonContainer.Size = UDim2.new(0.8, 0, 0, 50)
ButtonContainer.Position = UDim2.new(0.5, 0, 1, -20)
ButtonContainer.AnchorPoint = Vector2.new(0.5, 1)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = PersonalResultsFrame

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Padding = UDim.new(0, 16)
btnLayout.Parent = ButtonContainer

local RetryButton = CreateResultsButton("RetryButton", "RETRY", 1)
RetryButton.Parent = ButtonContainer

local NewTrackButton = CreateResultsButton("NewTrackButton", "SELECT NEW TRACK", 2)
NewTrackButton.Parent = ButtonContainer

-- Track dynamically-created split row instances for cleanup
local endScreenRows = {}


-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

local function FormatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%06.3f", mins, secs)
end

local function FormatTrackDisplayName(raw)
	-- Strip numeric prefixes like "06_20_"
	local name = raw:gsub("^%d+_%d+_", "")
	-- Replace underscores with spaces
	name = name:gsub("_", " ")
	-- Split camelCase: insert space before each uppercase letter that follows a lowercase letter
	name = name:gsub("(%l)(%u)", "%1 %2")
	-- Also split when a sequence of uppercase is followed by uppercase+lowercase (e.g. "PBTime" -> "PB Time")
	name = name:gsub("(%u+)(%u%l)", "%1 %2")
	-- Clean up any double spaces
	name = name:gsub("  +", " ")
	-- Trim
	name = name:match("^%s*(.-)%s*$")
	return name
end

local function GetModelBoundingBox(model)
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

	for _, desc in pairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			local cf = desc.CFrame
			local size = desc.Size
			-- Approximate AABB from part corners
			for _, dx in ipairs({-0.5, 0.5}) do
				for _, dy in ipairs({-0.5, 0.5}) do
					for _, dz in ipairs({-0.5, 0.5}) do
						local corner = cf:PointToWorldSpace(Vector3.new(size.X * dx, size.Y * dy, size.Z * dz))
						minX = math.min(minX, corner.X)
						minY = math.min(minY, corner.Y)
						minZ = math.min(minZ, corner.Z)
						maxX = math.max(maxX, corner.X)
						maxY = math.max(maxY, corner.Y)
						maxZ = math.max(maxZ, corner.Z)
					end
				end
			end
		end
	end

	local center = Vector3.new((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
	local extents = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
	return center, extents
end

local function CreatePreviewCamera(model)
	local cam = Instance.new("Camera")
	cam.FieldOfView = 50

	-- Bounding-box overview: frame the entire track from an elevated isometric angle
	local center, extents = GetModelBoundingBox(model)
	local maxHorizontal = math.max(extents.X, extents.Z)
	local verticalExtent = extents.Y
	local halfFOV = math.rad(50 / 2)
	local distance = ((maxHorizontal / 2) / math.tan(halfFOV) + verticalExtent) * 0.5

	-- Elevated isometric view with slight yaw for visual interest
	local pitch = math.rad(50) -- ~50 degrees above horizontal
	local yaw = math.rad(25)   -- slight angle offset
	local offset = Vector3.new(
		distance * math.cos(pitch) * math.sin(yaw),
		distance * math.sin(pitch),
		distance * math.cos(pitch) * math.cos(yaw)
	)
	cam.CFrame = CFrame.lookAt(center + offset, center)

	return cam
end

local function ShowScreen(screen)
	currentScreen = screen

	-- Sink scroll wheel input so it doesn't affect the game camera
	if screen == "picker" or screen == "detail" then
		SinkScroll()
	else
		UnsinkScroll()
	end

	CancelButton.Visible = (screen == "racing")
	GameplayFrame.Visible = (screen == "racing" or screen == "finish")

	-- Picker entrance animation
	if screen == "picker" then
		PickerFrame.Visible = true
		-- Reset picker internals to visible/centered positions
		TrackScroller.Position = UDim2.new(0.04, 0, 0.15, 0)
		HeaderFrame.Position = UDim2.new(0, 0, 0, 0)
		ReturnButton.Visible = true
		ReturnButton.TextTransparency = 0
		ReturnButton.BackgroundTransparency = 0

		PickerFrame.Position = UDim2.new(0.5, 0, 1.5, 0) -- start below screen
		TweenService:Create(PickerFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
	elseif screen == "detail" then
		-- Keep PickerFrame visible for animation but don't re-animate entrance
		PickerFrame.Visible = true
	else
		PickerFrame.Visible = false
	end

	-- Detail modal visibility (managed by transition animations)
	if screen ~= "detail" then
		DetailModal.Visible = false
	end

	-- RaceEndMenu / PersonalResultsFrame for results
	if screen ~= "results" then
		RaceEndMenu.Visible = false
		PersonalResultsFrame.Visible = false
	end
	-- (results visibility is handled by TransitionToResults)

	-- Show splits panel only during racing; tween away on finish/results
	if screen == "racing" then
		if splitsPanel then
			splitsPanel.Position = UDim2.new(0.99, 0, 0.06, 0)
			splitsPanel.Visible = true
		end
	elseif screen == "finish" or screen == "results" then
		if splitsPanel and splitsPanel.Visible then
			local tween = TweenService:Create(splitsPanel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1.3, 0, 0.06, 0)
			})
			tween:Play()
			tween.Completed:Connect(function()
				if splitsPanel then
					splitsPanel.Visible = false
				end
			end)
		end
	end
end

local function GetPlayerPB(trkName)
	local playerData = ReplicatedStorage:WaitForChild("PlayerData"):FindFirstChild(Player.Name)
	if not playerData then return nil end
	local careerStats = playerData:FindFirstChild("CareerStats")
	if not careerStats then return nil end
	local pbFolder = careerStats:FindFirstChild("TimeTrialBests")
	if not pbFolder then return nil end
	local pbValue = pbFolder:FindFirstChild(trkName)
	if not pbValue then return nil end
	return pbValue.Value
end

local function ShowLoadingScreen(trkName)
	-- Set track name (formatted for display)
	LoadingTrackName.Text = FormatTrackDisplayName(trkName)

	-- Set PB text
	local pb = GetPlayerPB(trkName)
	if pb then
		LoadingPBText.Text = "Personal Best: " .. FormatTime(pb)
		LoadingPBText.TextColor3 = Color3.fromRGB(255, 230, 44)
	else
		LoadingPBText.Text = "No time set"
		LoadingPBText.TextColor3 = Color3.fromRGB(180, 180, 180)
	end

	-- Reset transparencies
	LoadingOverlay.ImageTransparency = 0
	LoadingTrackName.TextTransparency = 0
	LoadingSubtitle.TextTransparency = 0
	LoadingPBText.TextTransparency = 0
	for _, lbl in ipairs({LoadingTrackName, LoadingSubtitle, LoadingPBText}) do
		local stroke = lbl:FindFirstChildWhichIsA("UIStroke")
		if stroke then stroke.Transparency = 0 end
	end

	LoadingOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
	LoadingOverlay.Position = UDim2.new(0.5, 0, 0.5, 0)
	LoadingOverlay.Visible = true
	loadingStartTime = tick()
end

local function HideLoadingScreen()
	-- Slide the loading overlay off-screen to the left like a curtain
	LoadingOverlay.AnchorPoint = Vector2.new(0, 0)
	LoadingOverlay.Position = UDim2.new(-0.5, 0, -0.5, 0)

	local slideInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local slideTween = TweenService:Create(LoadingOverlay, slideInfo, {
		Position = UDim2.new(-2, 0, -0.5, 0)
	})
	slideTween:Play()
	slideTween.Completed:Wait()

	-- Reset and hide
	LoadingOverlay.Visible = false
	LoadingOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
	LoadingOverlay.Position = UDim2.new(0.5, 0, 0.5, 0)
	LoadingOverlay.ImageTransparency = 0
end

local function UpdateStatsPill(tracks)
	local completed = 0
	local total = #tracks
	for _, trkName in ipairs(tracks) do
		if GetPlayerPB(trkName) then
			completed = completed + 1
		end
	end
	local pillLabel = StatsPill:FindFirstChild("Label")
	if pillLabel then
		-- Use RichText to color the completed count green
		pillLabel.RichText = true
		pillLabel.Text = string.format(
			'<font color="#50C864">%d</font> / %d Completed',
			completed, total
		)
	end
end

-- ============================================================
-- DETAIL MODAL TRANSITIONS
-- ============================================================

local function PopulateDetailModal(trkName)
	-- Set track name
	DetailTrackName.Text = FormatTrackDisplayName(trkName)

	-- Set PB
	local pb = GetPlayerPB(trkName)
	if pb then
		DetailPBLabel.Text = "Personal Best: " .. FormatTime(pb)
		DetailPBLabel.TextColor3 = Color3.fromRGB(255, 230, 44)
	else
		DetailPBLabel.Text = "No time set"
		DetailPBLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	end

	-- Clear old viewport contents
	for _, child in pairs(DetailViewport:GetChildren()) do
		if child:IsA("Model") or child:IsA("Camera") then
			child:Destroy()
		end
	end

	-- Clone track preview model + camera into the large viewport
	if TrackPreviews then
		local previewModel = TrackPreviews:FindFirstChild(trkName)
		if previewModel then
			local clone = previewModel:Clone()
			clone.Parent = DetailViewport

			local cam = CreatePreviewCamera(clone)
			cam.Parent = DetailViewport
			DetailViewport.CurrentCamera = cam

			-- Initialize orbit camera from bounding box
			local center, extents = GetModelBoundingBox(clone)
			detailCameraCenter = center
			local maxExtent = math.max(extents.X, extents.Y, extents.Z)
			detailCameraMinDist = maxExtent * 0.3
			detailCameraMaxDist = maxExtent * 4

			-- Derive initial yaw/pitch/distance from the camera CFrame
			local camOffset = cam.CFrame.Position - center
			detailCameraDistance = camOffset.Magnitude
			detailCameraPitch = math.asin(math.clamp(camOffset.Y / detailCameraDistance, -1, 1))
			detailCameraYaw = math.atan2(camOffset.X, camOffset.Z)
		end
	end
end

local function AnimateGridToDetail(trkName)
	-- Store the track name for the detail modal
	lastSelectedTrack = trkName

	-- Populate modal content
	PopulateDetailModal(trkName)

	-- Animate grid elements out to the left
	local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	local scrollerTween = TweenService:Create(TrackScroller, tweenInfo, {
		Position = UDim2.new(-1, 0, 0.15, 0)
	})
	local headerTween = TweenService:Create(HeaderFrame, tweenInfo, {
		Position = UDim2.new(-1, 0, 0, 0)
	})

	-- Use BackgroundTransparency for ReturnButton fade since TextButton doesn't have GroupTransparency
	local returnFadeInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local returnBgTween = TweenService:Create(ReturnButton, returnFadeInfo, {
		TextTransparency = 1,
		BackgroundTransparency = 1
	})

	scrollerTween:Play()
	headerTween:Play()
	returnBgTween:Play()

	scrollerTween.Completed:Wait()

	-- Hide picker internals, show detail modal
	ReturnButton.Visible = false

	-- Show detail modal with scale-up animation
	currentScreen = "detail"
	DetailModal.Visible = true
	DetailModalScale.Scale = 0.8
	DetailModal.BackgroundTransparency = 1
	DetailTrackName.TextTransparency = 1
	DetailPBLabel.TextTransparency = 1
	DetailPlayButton.TextTransparency = 1
	DetailPlayButton.BackgroundTransparency = 1
	DetailBackButton.TextTransparency = 1
	DetailBackButton.BackgroundTransparency = 1
	DetailViewport.ImageTransparency = 1

	local modalTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(DetailModalScale, modalTweenInfo, {Scale = 1}):Play()
	TweenService:Create(DetailModal, modalTweenInfo, {BackgroundTransparency = 0}):Play()
	TweenService:Create(DetailTrackName, modalTweenInfo, {TextTransparency = 0}):Play()
	TweenService:Create(DetailPBLabel, modalTweenInfo, {TextTransparency = 0}):Play()
	TweenService:Create(DetailPlayButton, modalTweenInfo, {TextTransparency = 0, BackgroundTransparency = 0}):Play()
	TweenService:Create(DetailBackButton, modalTweenInfo, {TextTransparency = 0, BackgroundTransparency = 0}):Play()
	TweenService:Create(DetailViewport, modalTweenInfo, {ImageTransparency = 0}):Play()

	-- Fade in strokes
	DetailModalStroke.Transparency = 1
	DetailPlayStroke.Transparency = 1
	DetailBackStroke.Transparency = 1
	DetailTrackNameStroke.Transparency = 1
	TweenService:Create(DetailModalStroke, modalTweenInfo, {Transparency = 0.5}):Play()
	TweenService:Create(DetailPlayStroke, modalTweenInfo, {Transparency = 0}):Play()
	TweenService:Create(DetailBackStroke, modalTweenInfo, {Transparency = 0}):Play()
	TweenService:Create(DetailTrackNameStroke, modalTweenInfo, {Transparency = 0}):Play()
end

local function AnimateDetailToGrid()
	-- Animate modal out (scale down + fade)
	local modalOutInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(DetailModalScale, modalOutInfo, {Scale = 0.8}):Play()
	TweenService:Create(DetailModal, modalOutInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(DetailTrackName, modalOutInfo, {TextTransparency = 1}):Play()
	TweenService:Create(DetailPBLabel, modalOutInfo, {TextTransparency = 1}):Play()
	TweenService:Create(DetailPlayButton, modalOutInfo, {TextTransparency = 1, BackgroundTransparency = 1}):Play()
	TweenService:Create(DetailBackButton, modalOutInfo, {TextTransparency = 1, BackgroundTransparency = 1}):Play()
	local viewportTween = TweenService:Create(DetailViewport, modalOutInfo, {ImageTransparency = 1})
	viewportTween:Play()
	viewportTween.Completed:Wait()

	DetailModal.Visible = false
	DetailModalScale.Scale = 1

	-- Animate grid back in from left
	ReturnButton.Visible = true
	ReturnButton.TextTransparency = 1
	ReturnButton.BackgroundTransparency = 1

	local gridInInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(TrackScroller, gridInInfo, {
		Position = UDim2.new(0.04, 0, 0.15, 0)
	}):Play()
	TweenService:Create(HeaderFrame, gridInInfo, {
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()
	TweenService:Create(ReturnButton, gridInInfo, {
		TextTransparency = 0,
		BackgroundTransparency = 0
	}):Play()

	currentScreen = "picker"
end

local DEFAULT_CARD_COLOR = Color3.fromRGB(20, 30, 55)
local HOVER_CARD_COLOR = Color3.fromRGB(30, 42, 75)

local function PopulateTrackList(tracks)
	-- Clear existing entries
	for _, child in pairs(TrackScroller:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for i, trkName in ipairs(tracks) do
		local pb = GetPlayerPB(trkName)
		local hasPB = pb ~= nil

		local entry = Instance.new("TextButton")
		entry.Name = string.format("%03d_%s", i, trkName)
		entry.BackgroundColor3 = DEFAULT_CARD_COLOR
		entry.BorderSizePixel = 0
		entry.Text = ""
		entry.AutoButtonColor = false
		entry.ClipsDescendants = true
		entry.Parent = TrackScroller

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 10)
		entryCorner.Parent = entry

		-- UIScale for hover animation
		local entryScale = Instance.new("UIScale")
		entryScale.Scale = 1
		entryScale.Parent = entry

		-- Left accent bar
		local accentBar = Instance.new("Frame")
		accentBar.Name = "AccentBar"
		accentBar.Size = UDim2.new(0.015, 0, 1, 0)
		accentBar.Position = UDim2.new(0, 0, 0, 0)
		accentBar.BackgroundColor3 = hasPB and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(45, 55, 80)
		accentBar.BorderSizePixel = 0
		accentBar.Parent = entry

		-- Track 3D preview viewport
		local viewport = Instance.new("ViewportFrame")
		viewport.Name = "Thumbnail"
		viewport.Size = UDim2.new(0.5, -6, 1, -8)
		viewport.Position = UDim2.new(0.015, 0, 0, 4)
		viewport.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
		viewport.BorderSizePixel = 0
		viewport.Ambient = Color3.fromRGB(180, 180, 180)
		viewport.LightColor = Color3.fromRGB(255, 255, 255)
		viewport.LightDirection = Vector3.new(-1, -1, -1)
		viewport.Parent = entry
		viewport:SetAttribute("TrackName", trkName)

		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = UDim.new(0.06, 0)
		thumbCorner.Parent = viewport

		-- Fallback number label (visible while 3D preview loads)
		local thumbFallback = Instance.new("TextLabel")
		thumbFallback.Name = "FallbackLabel"
		thumbFallback.Size = UDim2.new(1, 0, 1, 0)
		thumbFallback.BackgroundTransparency = 1
		thumbFallback.Text = tostring(i)
		thumbFallback.TextColor3 = Color3.fromRGB(60, 70, 100)
		thumbFallback.TextScaled = true
		thumbFallback.Font = Enum.Font.FredokaOne
		thumbFallback.Parent = viewport

		-- Completion circle
		local circle = Instance.new("Frame")
		circle.Name = "CompletionCircle"
		circle.Size = UDim2.new(0.08, 0, 0.38, 0)
		circle.SizeConstraint = Enum.SizeConstraint.RelativeYY
		circle.Position = UDim2.new(0.52, 4, 0.5, 0)
		circle.AnchorPoint = Vector2.new(0, 0.5)
		circle.BackgroundColor3 = hasPB and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(35, 45, 70)
		circle.BorderSizePixel = 0
		circle.Parent = entry

		local circleCorner = Instance.new("UICorner")
		circleCorner.CornerRadius = UDim.new(1, 0)
		circleCorner.Parent = circle

		local circleLabel = Instance.new("TextLabel")
		circleLabel.Name = "CircleLabel"
		circleLabel.Size = UDim2.new(1, 0, 1, 0)
		circleLabel.BackgroundTransparency = 1
		circleLabel.Text = hasPB and "\226\156\147" or tostring(i)
		circleLabel.TextColor3 = hasPB and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 140)
		circleLabel.TextScaled = true
		circleLabel.Font = Enum.Font.GothamBold
		circleLabel.Parent = circle

		-- Track name (stores raw name for lookup, displays formatted)
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "TrackName"
		nameLabel.Size = UDim2.new(0.36, 0, 0.3, 0)
		nameLabel.Position = UDim2.new(0.62, 0, 0.06, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = FormatTrackDisplayName(trkName)
		nameLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = entry
		addTextSizeConstraint(nameLabel, 36, 10)

		-- Hidden label storing raw track name for lookup
		local rawNameLabel = Instance.new("StringValue")
		rawNameLabel.Name = "RawTrackName"
		rawNameLabel.Value = trkName
		rawNameLabel.Parent = entry

		-- Status subtitle
		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "StatusLabel"
		statusLabel.Size = UDim2.new(0.36, 0, 0.22, 0)
		statusLabel.Position = UDim2.new(0.62, 0, 0.42, 0)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Text = hasPB and "Personal Best" or "Not attempted"
		statusLabel.TextColor3 = hasPB and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(100, 100, 120)
		statusLabel.TextScaled = true
		statusLabel.Font = Enum.Font.Gotham
		statusLabel.TextXAlignment = Enum.TextXAlignment.Left
		statusLabel.Parent = entry
		addTextSizeConstraint(statusLabel, 28, 8)

		-- PB time (below status label, left-aligned)
		local pbText = Instance.new("TextLabel")
		pbText.Name = "PBText"
		pbText.Size = UDim2.new(0.36, 0, 0.22, 0)
		pbText.Position = UDim2.new(0.62, 0, 0.66, 0)
		pbText.BackgroundTransparency = 1
		pbText.Text = hasPB and FormatTime(pb) or "--:--.---"
		pbText.TextColor3 = hasPB and Color3.fromRGB(255, 230, 44) or Color3.fromRGB(45, 55, 80)
		pbText.TextScaled = true
		pbText.Font = Enum.Font.Code
		pbText.TextXAlignment = Enum.TextXAlignment.Left
		pbText.Parent = entry
		addTextSizeConstraint(pbText, 28, 8)

		-- Hover animations
		local hoverTweenIn = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local hoverTweenOut = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		entry.MouseEnter:Connect(function()
			TweenService:Create(entry, hoverTweenIn, {BackgroundColor3 = HOVER_CARD_COLOR}):Play()
			TweenService:Create(entryScale, hoverTweenIn, {Scale = 1.02}):Play()
		end)

		entry.MouseLeave:Connect(function()
			TweenService:Create(entry, hoverTweenOut, {BackgroundColor3 = DEFAULT_CARD_COLOR}):Play()
			TweenService:Create(entryScale, hoverTweenOut, {Scale = 1}):Play()
		end)

		entry.MouseButton1Click:Connect(function()
			SoundManager:Fire("Player", "UI_Click")
			-- Brief press-in animation
			local pressIn = TweenService:Create(entryScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.97})
			pressIn:Play()
			pressIn.Completed:Wait()
			TweenService:Create(entryScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()

			-- Open detail modal instead of immediately starting
			AnimateGridToDetail(trkName)
		end)
	end

	-- Update canvas size for two-column grid
	local rows = math.ceil(#tracks / 2)
	TrackScroller.CanvasSize = UDim2.new(0, 0, 0, rows * (140 + 8) + 8)

	-- Update stats pill
	UpdateStatsPill(tracks)
end

local function PopulateViewports()
	if not TrackPreviews then return end

	for _, child in pairs(TrackScroller:GetChildren()) do
		if not child:IsA("TextButton") then continue end

		local viewport = child:FindFirstChild("Thumbnail")
		if not viewport or not viewport:IsA("ViewportFrame") then continue end

		local trkName = viewport:GetAttribute("TrackName")
		if not trkName then continue end

		local previewModel = TrackPreviews:FindFirstChild(trkName)
		if not previewModel then continue end

		local clone = previewModel:Clone()
		clone.Parent = viewport

		local cam = CreatePreviewCamera(clone)
		cam.Parent = viewport
		viewport.CurrentCamera = cam

		-- Hide fallback label now that 3D preview is loaded
		local fallback = viewport:FindFirstChild("FallbackLabel")
		if fallback then
			fallback.Visible = false
		end

		-- Stagger GPU load across frames
		task.wait()
	end
end

local function CreateSplitsPanel(numSegments)
	-- Destroy old panel if it exists
	if splitsPanel then
		splitsPanel:Destroy()
		splitsPanel = nil
	end
	splitRows = {}

	-- Scale-based layout: panel is a fraction of screen, rows divide evenly
	local headerFraction = 0.12
	local rowFraction = (1 - headerFraction - 0.02) / numSegments

	local panel = Instance.new("Frame")
	panel.Name = "SplitsPanel"
	panel.Size = UDim2.new(0.22, 0, 0.06 + numSegments * 0.05, 0)
	panel.Position = UDim2.new(0.99, 0, 0.06, 0)
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	panel.BackgroundTransparency = 0.3
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = ScreenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = panel

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, headerFraction, 0)
	header.BackgroundTransparency = 1
	header.Text = "SPLITS"
	header.TextColor3 = Color3.fromRGB(255, 230, 44)
	header.TextScaled = true
	header.Font = Enum.Font.FredokaOne
	header.Parent = panel
	addTextSizeConstraint(header, 24, 10)

	for i = 1, numSegments do
		local rowY = headerFraction + (i - 1) * rowFraction

		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.Size = UDim2.new(0.9, 0, rowFraction, 0)
		row.Position = UDim2.new(0.05, 0, rowY, 0)
		row.BackgroundTransparency = 1
		row.Parent = panel

		-- Column 1: Segment label (left, ~20% of row)
		local segLabel = Instance.new("TextLabel")
		segLabel.Name = "SegLabel"
		segLabel.Size = UDim2.new(0.2, 0, 1, 0)
		segLabel.Position = UDim2.new(0, 0, 0, 0)
		segLabel.BackgroundTransparency = 1
		segLabel.Text = "Seg " .. i
		segLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		segLabel.TextScaled = true
		segLabel.Font = Enum.Font.FredokaOne
		segLabel.TextXAlignment = Enum.TextXAlignment.Left
		segLabel.Parent = row
		addTextSizeConstraint(segLabel, 20, 8)

		-- Column 2: Best split time (center, ~38% of row)
		local bestLabel = Instance.new("TextLabel")
		bestLabel.Name = "BestLabel"
		bestLabel.Size = UDim2.new(0.38, 0, 1, 0)
		bestLabel.Position = UDim2.new(0.22, 0, 0, 0)
		bestLabel.BackgroundTransparency = 1
		bestLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		bestLabel.TextScaled = true
		bestLabel.Font = Enum.Font.Code
		bestLabel.TextXAlignment = Enum.TextXAlignment.Right
		bestLabel.Parent = row
		addTextSizeConstraint(bestLabel, 20, 8)

		-- Populate best label from bestSplits (already loaded via SendBestSplitsRemote)
		if bestSplits[i] then
			bestLabel.Text = FormatTime(bestSplits[i])
		else
			bestLabel.Text = "\226\128\148"
		end

		-- Column 3: Current split time (right, ~38% of row)
		local currentLabel = Instance.new("TextLabel")
		currentLabel.Name = "CurrentLabel"
		currentLabel.Size = UDim2.new(0.38, 0, 1, 0)
		currentLabel.Position = UDim2.new(0.62, 0, 0, 0)
		currentLabel.BackgroundTransparency = 1
		currentLabel.Text = "\226\128\148"
		currentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		currentLabel.TextScaled = true
		currentLabel.Font = Enum.Font.Code
		currentLabel.TextXAlignment = Enum.TextXAlignment.Right
		currentLabel.Parent = row
		addTextSizeConstraint(currentLabel, 20, 8)

		splitRows[i] = {
			bestLabel = bestLabel,
			currentLabel = currentLabel,
		}
	end

	splitsPanel = panel
	return panel
end

local function UpdateSplitRow(segIndex, splitTime)
	local row = splitRows[segIndex]
	if not row then return end

	row.currentLabel.Text = FormatTime(splitTime)

	-- Color based on comparison to best
	if bestSplits[segIndex] then
		if splitTime <= bestSplits[segIndex] then
			row.currentLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
		else
			row.currentLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		end
	else
		row.currentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function ShowSplitsPanel()
	if splitsPanel then
		splitsPanel.Position = UDim2.new(0.99, 0, 0.06, 0)
		splitsPanel.Visible = true
	end
end

local function HideSplitsPanel()
	if splitsPanel then
		splitsPanel.Visible = false
	end
end

local function TweenSplitsPanelAway()
	if splitsPanel and splitsPanel.Visible then
		local tween = TweenService:Create(splitsPanel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1.3, 0, 0.06, 0)
		})
		tween:Play()
		tween.Completed:Connect(function()
			if splitsPanel then
				splitsPanel.Visible = false
			end
		end)
	end
end

local function ResetSplitsState()
	currentSplits = {}
	-- Reset row text
	for i, row in pairs(splitRows) do
		if bestSplits[i] then
			row.bestLabel.Text = FormatTime(bestSplits[i])
		else
			row.bestLabel.Text = "\226\128\148"
		end
		row.currentLabel.Text = "\226\128\148"
		row.currentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function PopulateEndScreen(elapsed, previousPB, isNewPB, trkName)
	-- Clear previous rows
	for _, row in ipairs(endScreenRows) do
		row:Destroy()
	end
	endScreenRows = {}

	-- Set header to track name (formatted for display)
	StatLabelThing.Text = FormatTrackDisplayName(trkName)

	local ROW_HEIGHT = 28
	local layoutOrder = 0

	-- Ensure StatList exists (create if needed)
	local statList = StatsFrame:FindFirstChild("StatList")
	if not statList then
		statList = Instance.new("Frame")
		statList.Name = "StatList"
		statList.Size = UDim2.new(1, -16, 1, -40)
		statList.Position = UDim2.new(0, 8, 0, 36)
		statList.BackgroundTransparency = 1
		statList.Parent = StatsFrame
	end

	-- Clear any existing children in StatList (except UIListLayout)
	for _, child in pairs(statList:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Ensure UIListLayout
	local listLayout = statList:FindFirstChild("UIListLayout")
	if not listLayout then
		listLayout = Instance.new("UIListLayout")
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 2)
		listLayout.Parent = statList
	end

	-- === Final Time Row (prominent — same scale as track name header) ===
	local finalRow = Instance.new("Frame")
	finalRow.Name = "FinalTimeRow"
	finalRow.Size = UDim2.new(1, 0, 0, 80)
	finalRow.BackgroundTransparency = 1
	finalRow.LayoutOrder = layoutOrder
	finalRow.Parent = statList
	table.insert(endScreenRows, finalRow)
	layoutOrder = layoutOrder + 1

	local finalTimeLabel = CreateStyledLabel(
		"FinalTime",
		UDim2.new(0.7, 0, 1, 0),
		UDim2.new(0.35, 0, 0.5, 0),
		Color3.fromRGB(255, 230, 44)
	)
	finalTimeLabel.Text = FormatTime(elapsed)
	finalTimeLabel.TextXAlignment = Enum.TextXAlignment.Center
	finalTimeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	finalTimeLabel.ZIndex = 1
	finalTimeLabel.Parent = finalRow

	if isNewPB then
		local pbBadge = CreateStyledLabel(
			"PBBadge",
			UDim2.new(0.35, 0, 0.45, 0),
			UDim2.new(0.88, 0, 0.5, 0),
			Color3.fromRGB(255, 230, 44)
		)
		pbBadge.Text = "NEW PB!"
		pbBadge.AnchorPoint = Vector2.new(0.5, 0.5)
		pbBadge.ZIndex = 1
		pbBadge.Parent = finalRow
	end

	-- === PB Delta Row ===
	if previousPB then
		local deltaRow = Instance.new("Frame")
		deltaRow.Name = "DeltaRow"
		deltaRow.Size = UDim2.new(1, 0, 0, 22)
		deltaRow.BackgroundTransparency = 1
		deltaRow.LayoutOrder = layoutOrder
		deltaRow.Parent = statList
		table.insert(endScreenRows, deltaRow)
		layoutOrder = layoutOrder + 1

		local delta = elapsed - previousPB
		local deltaText, deltaColor
		if delta < 0 then
			deltaText = string.format("-%05.3f vs PB", math.abs(delta))
			deltaColor = Color3.fromRGB(80, 255, 80)
		elseif delta > 0 then
			deltaText = string.format("+%05.3f vs PB", delta)
			deltaColor = Color3.fromRGB(255, 80, 80)
		else
			deltaText = "+0.000 vs PB"
			deltaColor = Color3.fromRGB(255, 255, 255)
		end

		local deltaLabel = CreateStyledLabel(
			"DeltaLabel",
			UDim2.new(0.8, 0, 1, 0),
			UDim2.new(0.5, 0, 0.5, 0),
			deltaColor
		)
		deltaLabel.Text = deltaText
		deltaLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		deltaLabel.ZIndex = 1
		deltaLabel.Parent = deltaRow
	end

	-- === Separator ===
	local sep = Instance.new("Frame")
	sep.Name = "Separator"
	sep.Size = UDim2.new(0.9, 0, 0, 2)
	sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sep.BackgroundTransparency = 0.7
	sep.BorderSizePixel = 0
	sep.LayoutOrder = layoutOrder
	sep.Parent = statList
	table.insert(endScreenRows, sep)
	layoutOrder = layoutOrder + 1

	-- === Header Row (Seg / Time / Delta) ===
	local headerRow = Instance.new("Frame")
	headerRow.Name = "HeaderRow"
	headerRow.Size = UDim2.new(1, 0, 0, 22)
	headerRow.BackgroundTransparency = 1
	headerRow.LayoutOrder = layoutOrder
	headerRow.Parent = statList
	table.insert(endScreenRows, headerRow)
	layoutOrder = layoutOrder + 1

	for colIdx, colInfo in ipairs({
		{text = "LAP", pos = UDim2.new(0, 0, 0, 0), size = UDim2.new(0.12, 0, 1, 0), align = Enum.TextXAlignment.Center},
		{text = "TIME", pos = UDim2.new(0.12, 0, 0, 0), size = UDim2.new(0.30, 0, 1, 0), align = Enum.TextXAlignment.Center},
		{text = "BEST", pos = UDim2.new(0.42, 0, 0, 0), size = UDim2.new(0.30, 0, 1, 0), align = Enum.TextXAlignment.Center},
		{text = "+/-", pos = UDim2.new(0.72, 0, 0, 0), size = UDim2.new(0.28, 0, 1, 0), align = Enum.TextXAlignment.Center},
	}) do
		local colLabel = Instance.new("TextLabel")
		colLabel.Name = "Col" .. colIdx
		colLabel.Size = colInfo.size
		colLabel.Position = colInfo.pos
		colLabel.BackgroundTransparency = 1
		colLabel.Text = colInfo.text
		colLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		colLabel.Font = Enum.Font.FredokaOne
		colLabel.TextScaled = true
		colLabel.TextXAlignment = colInfo.align
		colLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		colLabel.TextStrokeTransparency = 0
		colLabel.Parent = headerRow
	end

	-- === Segment Split Rows ===
	for i = 1, segmentCount do
		local row = Instance.new("Frame")
		row.Name = "SplitRow" .. i
		row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
		row.BackgroundTransparency = (i % 2 == 0) and 0.85 or 1
		row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		row.BorderSizePixel = 0
		row.LayoutOrder = layoutOrder
		row.Parent = statList
		table.insert(endScreenRows, row)
		layoutOrder = layoutOrder + 1

		-- LAP number
		local segNum = Instance.new("TextLabel")
		segNum.Name = "SegNum"
		segNum.Size = UDim2.new(0.12, 0, 1, 0)
		segNum.Position = UDim2.new(0, 0, 0, 0)
		segNum.BackgroundTransparency = 1
		segNum.Text = tostring(i)
		segNum.TextColor3 = Color3.fromRGB(200, 200, 200)
		segNum.Font = Enum.Font.FredokaOne
		segNum.TextScaled = true
		segNum.TextXAlignment = Enum.TextXAlignment.Center
		segNum.TextStrokeColor3 = Color3.new(0, 0, 0)
		segNum.TextStrokeTransparency = 0
		segNum.Parent = row

		-- Per-segment time
		local segTime = 0
		if currentSplits[i] then
			if i == 1 then
				segTime = currentSplits[1]
			else
				segTime = currentSplits[i] - (currentSplits[i - 1] or 0)
			end
		end

		-- TIME column
		local timeLabel = Instance.new("TextLabel")
		timeLabel.Name = "TimeLabel"
		timeLabel.Size = UDim2.new(0.30, 0, 1, 0)
		timeLabel.Position = UDim2.new(0.12, 0, 0, 0)
		timeLabel.BackgroundTransparency = 1
		timeLabel.Text = currentSplits[i] and FormatTime(segTime) or "-"
		timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		timeLabel.Font = Enum.Font.FredokaOne
		timeLabel.TextScaled = true
		timeLabel.TextXAlignment = Enum.TextXAlignment.Center
		timeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		timeLabel.TextStrokeTransparency = 0
		timeLabel.Parent = row

		-- Compute best segment time
		local bestSegTime = nil
		if bestSplits[i] then
			if i == 1 then
				bestSegTime = bestSplits[1]
			else
				bestSegTime = bestSplits[i] - (bestSplits[i - 1] or 0)
			end
		end

		-- BEST column
		local bestLabel = Instance.new("TextLabel")
		bestLabel.Name = "BestLabel"
		bestLabel.Size = UDim2.new(0.30, 0, 1, 0)
		bestLabel.Position = UDim2.new(0.42, 0, 0, 0)
		bestLabel.BackgroundTransparency = 1
		bestLabel.Text = bestSegTime and FormatTime(bestSegTime) or "-"
		bestLabel.TextColor3 = bestSegTime and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(150, 150, 150)
		bestLabel.Font = Enum.Font.FredokaOne
		bestLabel.TextScaled = true
		bestLabel.TextXAlignment = Enum.TextXAlignment.Center
		bestLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		bestLabel.TextStrokeTransparency = 0
		bestLabel.Parent = row

		-- +/- column (delta vs best)
		local deltaLabel = Instance.new("TextLabel")
		deltaLabel.Name = "DeltaLabel"
		deltaLabel.Size = UDim2.new(0.28, 0, 1, 0)
		deltaLabel.Position = UDim2.new(0.72, 0, 0, 0)
		deltaLabel.BackgroundTransparency = 1
		deltaLabel.Font = Enum.Font.FredokaOne
		deltaLabel.TextScaled = true
		deltaLabel.TextXAlignment = Enum.TextXAlignment.Center
		deltaLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		deltaLabel.TextStrokeTransparency = 0
		deltaLabel.Parent = row

		if currentSplits[i] and bestSegTime then
			local delta = segTime - bestSegTime
			if delta < 0 then
				deltaLabel.Text = string.format("-%05.3f", math.abs(delta))
				deltaLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
			elseif delta > 0 then
				deltaLabel.Text = string.format("+%05.3f", delta)
				deltaLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			else
				deltaLabel.Text = "+0.000"
				deltaLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		else
			deltaLabel.Text = "-"
			deltaLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end
end

local function SetupProgressBar(trackData, totalDistance, startZ, endZ, checkpoints)
	checkpointZPositions = checkpoints or {}
	nextCheckpointIndex = 1
	trackStartZ = startZ
	trackEndZ = endZ

	-- Setup splits panel for this track
	segmentCount = #trackData
	CreateSplitsPanel(segmentCount)
	ResetSplitsState()

	-- Clear existing segment frames
	for _, child in pairs(SegmentsFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create alternating-transparency segment frames
	for i, dist in ipairs(trackData) do
		local segFrame = Instance.new("Frame")
		segFrame.Name = "Segment" .. i
		segFrame.Size = UDim2.new(dist / totalDistance, 0, 1, 0)
		segFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		segFrame.BackgroundTransparency = (i % 2 == 0) and 0.85 or 0.7
		segFrame.BorderSizePixel = 0
		segFrame.Parent = SegmentsFrame
	end

	-- Create or update the local player pin
	if not playerPin or not playerPin.Parent then
		-- Try to clone from the template in ProgressBarScript
		local template = progressBarScript and progressBarScript:FindFirstChild("LocalPlayerPinTemplate")
		if template then
			playerPin = template:Clone()
		else
			-- Create manually
			playerPin = Instance.new("Frame")
			playerPin.Size = UDim2.new(0, 4, 1, 0)
			playerPin.AnchorPoint = Vector2.new(0.5, 0)
			playerPin.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			playerPin.BorderSizePixel = 0

			local icon = Instance.new("ImageLabel")
			icon.Name = "CharacterIcon"
			icon.Size = UDim2.new(0, 32, 0, 32)
			icon.Position = UDim2.new(0.5, 0, 0, -36)
			icon.AnchorPoint = Vector2.new(0.5, 0)
			icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			icon.BackgroundTransparency = 0
			icon.Parent = playerPin

			local iconCorner = Instance.new("UICorner")
			iconCorner.CornerRadius = UDim.new(1, 0)
			iconCorner.Parent = icon
		end
		playerPin.Name = "LocalPlayerPin"
		playerPin.Parent = MarkerFrame
	end

	-- Set avatar headshot
	local charIcon = playerPin:FindFirstChild("CharacterIcon")
	if charIcon then
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size48x48
		local content, isReady = Players:GetUserThumbnailAsync(Player.UserId, thumbType, thumbSize)
		charIcon.Image = content
	end

	playerPin.Position = UDim2.new(0, 0, 0, 0)
	playerPin.Visible = true

	-- Make progress bar sub-elements visible
	MarkerFrame.Visible = true
	ProgressBarBackground.Visible = true
	SplitFrame.Visible = true
end

local function HideProgressBarPin()
	if playerPin then
		playerPin.Visible = false
	end
	RaceStartFrame.Visible = false
	trackStartZ = nil
	trackEndZ = nil
	checkpointZPositions = {}
	nextCheckpointIndex = 1
end

local function StartTimer()
	timerRunning = true
	timerStartTime = tick()
	BuiltInTimerLabel.Text = "00:00.000"

	if timerConnection then
		timerConnection:Disconnect()
	end

	timerConnection = RunService.Heartbeat:Connect(function()
		if not timerRunning then return end
		local elapsed = tick() - timerStartTime
		BuiltInTimerLabel.Text = FormatTime(elapsed)

		-- Update progress bar pin position
		if trackStartZ and trackEndZ and playerPin then
			local character = Player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local z = hrp.Position.Z
					local progress = (z - trackStartZ) / (trackEndZ - trackStartZ)
					progress = math.clamp(progress, 0, 1)
					playerPin.Position = UDim2.new(progress, 0, 0, 0)

					-- Live-tick the current segment's split time
					local currentSegIndex = nextCheckpointIndex
					if currentSegIndex <= segmentCount and splitRows[currentSegIndex] then
						local liveTime = elapsed
						splitRows[currentSegIndex].currentLabel.Text = FormatTime(liveTime)
						if bestSplits[currentSegIndex] then
							if liveTime <= bestSplits[currentSegIndex] then
								splitRows[currentSegIndex].currentLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
							else
								splitRows[currentSegIndex].currentLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
							end
						else
							splitRows[currentSegIndex].currentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
						end
					end

					-- Check for checkpoint crossings
					if nextCheckpointIndex <= #checkpointZPositions then
						local nextZ = checkpointZPositions[nextCheckpointIndex]
						if z <= nextZ then
							-- Record split time for completed segment
							local splitTime = elapsed
							local segIndex = nextCheckpointIndex
							currentSplits[segIndex] = splitTime
							UpdateSplitRow(segIndex, splitTime)

							-- Build notification with delta
							local notifText = "CHECKPOINT REACHED!"
							local notifColor = Color3.fromRGB(85, 170, 255)
							if bestSplits[segIndex] then
								local delta = splitTime - bestSplits[segIndex]
								if delta < 0 then
									local absDelta = math.abs(delta)
									notifText = string.format("-%05.3f", absDelta)
									notifColor = Color3.fromRGB(80, 255, 80)
								elseif delta > 0 then
									notifText = string.format("+%05.3f", delta)
									notifColor = Color3.fromRGB(255, 80, 80)
								else
									notifText = "+0.000"
									notifColor = Color3.fromRGB(255, 255, 255)
								end
							end

							nextCheckpointIndex = nextCheckpointIndex + 1
							local bindables = ReplicatedStorage.Networking.Client.BindableEvents
							bindables.SoundManager:Fire("Player", "Checkpoint")
							bindables.Play_VFX:Fire("Player", "Checkpoint")
							bindables.SendNotification:Fire(notifText, notifColor)
						end
					end
				end
			end
		end
	end)
end

local function StopTimer()
	timerRunning = false
	if timerConnection then
		timerConnection:Disconnect()
		timerConnection = nil
	end
	HideProgressBarPin()
end

local function RefreshPickerPBs()
	for _, child in pairs(TrackScroller:GetChildren()) do
		if child:IsA("TextButton") then
			local rawNameVal = child:FindFirstChild("RawTrackName")
			if not rawNameVal then continue end
			local trkName = rawNameVal.Value

			local pb = GetPlayerPB(trkName)
			local hasPB = pb ~= nil

			-- Update PB text
			local pbText = child:FindFirstChild("PBText")
			if pbText then
				pbText.Text = hasPB and FormatTime(pb) or "--:--.---"
				pbText.TextColor3 = hasPB and Color3.fromRGB(255, 230, 44) or Color3.fromRGB(45, 55, 80)
			end

			-- Update accent bar
			local accentBar = child:FindFirstChild("AccentBar")
			if accentBar then
				accentBar.BackgroundColor3 = hasPB and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(45, 55, 80)
			end

			-- Update completion circle
			local circle = child:FindFirstChild("CompletionCircle")
			if circle then
				circle.BackgroundColor3 = hasPB and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(35, 45, 70)
				local circleLabel = circle:FindFirstChild("CircleLabel")
				if circleLabel then
					circleLabel.Text = hasPB and "\226\156\147" or circleLabel.Text
					circleLabel.TextColor3 = hasPB and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 140)
				end
			end

			-- Update status subtitle
			local statusLabel = child:FindFirstChild("StatusLabel")
			if statusLabel then
				statusLabel.Text = hasPB and "Personal Best" or "Not attempted"
				statusLabel.TextColor3 = hasPB and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(100, 100, 120)
			end
		end
	end

	-- Update stats pill
	UpdateStatsPill(trackNames)
end


-- ============================================================
-- FINISH SPLASH & RESULTS TRANSITION
-- ============================================================

local function ShowFinishSplash(elapsed)
	-- Set the finish time
	FinishTimeLabel.Text = FormatTime(elapsed)

	-- Ensure FinishImage is visible (safety net)
	if FinishImage then
		FinishImage.ImageTransparency = 0
	end

	-- Reset FinishFrame to off-screen right
	FinishFrame.Position = UDim2.new(1, 0, 0.5, 0)
	RaceFinishFrame.Visible = true
	FinishFrame.Visible = true

	-- Tween FinishFrame in from right → centered (X=0.5)
	local slideIn = TweenService:Create(FinishFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	slideIn:Play()
	slideIn.Completed:Wait()

	-- Hold for ~1.5 seconds so player can see "FINISH!" + time
	task.wait(1.5)
end

local function TransitionToResults()
	-- Make RaceEndMenu visible but prepare for animation
	RaceEndMenu.Visible = true
	PersonalResultsFrame.Visible = true

	-- Fade out FinishFrame by sliding it to the left
	local fadeOutFinish = TweenService:Create(FinishFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(-1, 0, 0.5, 0)
	})

	-- Animate StatsFrame sliding in from the right
	local originalStatsPos = StatsFrame.Position
	StatsFrame.Position = UDim2.new(1, 0, originalStatsPos.Y.Scale, originalStatsPos.Y.Offset)
	local slideInStats = TweenService:Create(StatsFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = originalStatsPos
	})

	-- Collect elements to fade in
	local fadeElements = {}
	for _, name in ipairs({"SceneImage", "ViewportFrame", "RaceCompleteLabel", "MySealLabel", "HintText"}) do
		local el = PersonalResultsFrame:FindFirstChild(name)
		if el then
			if el:IsA("ImageLabel") or el:IsA("ImageButton") then
				el.ImageTransparency = 1
				table.insert(fadeElements, {obj = el, prop = "ImageTransparency", target = 0})
			end
			if el:IsA("TextLabel") then
				el.TextTransparency = 1
				table.insert(fadeElements, {obj = el, prop = "TextTransparency", target = 0})
			end
		end
	end

	-- Fade in custom buttons
	ButtonContainer.Visible = true
	for _, btn in ipairs(ButtonContainer:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.TextTransparency = 1
			btn.BackgroundTransparency = 1
			table.insert(fadeElements, {obj = btn, prop = "TextTransparency", target = 0})
			table.insert(fadeElements, {obj = btn, prop = "BackgroundTransparency", target = 0})
			local stroke = btn:FindFirstChildWhichIsA("UIStroke")
			if stroke then
				stroke.Transparency = 1
				table.insert(fadeElements, {obj = stroke, prop = "Transparency", target = 0})
			end
		end
	end

	-- Play slide-out finish + slide-in results
	fadeOutFinish:Play()
	slideInStats:Play()

	-- Stagger the fade-ins slightly
	task.delay(0.15, function()
		for _, info in ipairs(fadeElements) do
			local tween = TweenService:Create(info.obj, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				[info.prop] = info.target
			})
			tween:Play()
		end
	end)

	-- Wait for animations to complete
	slideInStats.Completed:Wait()

	-- Clean up finish frame
	RaceFinishFrame.Visible = false
	FinishFrame.Position = UDim2.new(1, 0, 0.5, 0) -- reset for next time
end


-- ============================================================
-- EVENT HANDLERS
-- ============================================================

UpdateProgessBarRemote.OnClientEvent:Connect(function(trackData, totalDistance, startZ, endZ, checkpoints)
	SetupProgressBar(trackData, totalDistance, startZ, endZ, checkpoints)
	-- Show gameplay UI behind loading overlay
	ShowScreen("racing")
	CancelButton.Visible = true
	BuiltInTimerLabel.Text = ""
	RaceStartFrame.Visible = true

	-- Ensure minimum 3s loading screen display, then fade out and signal server
	task.spawn(function()
		local elapsed = tick() - loadingStartTime
		if elapsed < 3 then
			task.wait(3 - elapsed)
		end

		HideLoadingScreen()
		ReadyForCountdownRemote:FireServer()
	end)
end)

TrackListRemote.OnClientEvent:Connect(function(tracks)
	trackNames = tracks
	PopulateTrackList(tracks)
	ShowScreen("picker")
	task.spawn(PopulateViewports)
end)

SendBestSplitsRemote.OnClientEvent:Connect(function(splits)
	bestSplits = splits or {}
end)

StartTimerRemote.OnClientEvent:Connect(function()
	-- Reset splits for new run
	ResetSplitsState()

	-- Let the GO image linger briefly before hiding the frame
	task.delay(1.5, function()
		RaceStartFrame.Visible = false
		local countdownFrame = RaceStartFrame:FindFirstChild("CountdownFrame")
		if countdownFrame then
			for _, child in pairs(countdownFrame:GetChildren()) do
				if child:IsA("ImageLabel") then
					child:Destroy()
				end
			end
		end
	end)
	StartTimer()
end)

StopTimerRemote.OnClientEvent:Connect(function()
	StopTimer()
end)

ShowTimeTrialResultsRemote.OnClientEvent:Connect(function(elapsed, previousPB, isNewPB, trkName)
	StopTimer()

	-- Trigger SappyControls speed reduction (same as main game's RaceFinishScript)
	local bindables = ReplicatedStorage.Networking.Client.BindableEvents
	bindables.SpeedReduce:Fire()

	-- Brake the seal: immediately cut most speed, then ease the rest to a smooth stop
	local character = Player.Character
	if character and character.Parent then
		local sealRoot = character.Parent:FindFirstChild("SealRoot")
		if sealRoot then
			-- Hard initial cut — kill 85% of velocity on the first frame to prevent phasing
			sealRoot.AssemblyLinearVelocity = sealRoot.AssemblyLinearVelocity * 0.15
			sealRoot.AssemblyAngularVelocity = sealRoot.AssemblyAngularVelocity * 0.15

			-- Ease the remaining 15% to zero over 0.3s
			local brakeSteps = 6
			local dt = 0.3 / brakeSteps
			for i = 1, brakeSteps do
				if not sealRoot or not sealRoot.Parent then break end
				sealRoot.AssemblyLinearVelocity = sealRoot.AssemblyLinearVelocity * 0.5
				sealRoot.AssemblyAngularVelocity = sealRoot.AssemblyAngularVelocity * 0.5
				task.wait(dt)
			end
			if sealRoot and sealRoot.Parent then
				sealRoot.AssemblyLinearVelocity = Vector3.zero
				sealRoot.AssemblyAngularVelocity = Vector3.zero
				sealRoot.Anchored = true
			end
		end
	end

	-- Record final segment split (finish line = last segment)
	local finalSegIndex = segmentCount
	if finalSegIndex > 0 and not currentSplits[finalSegIndex] then
		currentSplits[finalSegIndex] = elapsed
		UpdateSplitRow(finalSegIndex, elapsed)
	end

	-- Report splits to server for potential PB saving
	ReportSplitsRemote:FireServer(currentSplits)

	-- Populate the results screen data (before showing it)
	PopulateEndScreen(elapsed, previousPB, isNewPB, trkName)

	-- Step 1: Show "FINISH!" splash with time
	ShowScreen("finish")
	ShowFinishSplash(elapsed)

	-- Step 2: Animate in the full results screen
	ShowScreen("results")
	TransitionToResults()
end)

local function UnanchorSeal()
	local character = Player.Character
	if character and character.Parent then
		local sealRoot = character.Parent:FindFirstChild("SealRoot")
		if sealRoot then
			sealRoot.Anchored = false
		end
	end
end

-- Button handlers
ReturnButton.MouseButton1Click:Connect(function()
	SoundManager:Fire("Player", "UI_Click")
	ReturnToLobbyRemote:FireServer()
end)

-- Detail modal button handlers
DetailPlayButton.MouseButton1Click:Connect(function()
	SoundManager:Fire("Player", "UI_Click")
	if not lastSelectedTrack then return end
	DetailModal.Visible = false
	ShowScreen("waiting")
	ShowLoadingScreen(lastSelectedTrack)
	SelectTrackRemote:FireServer(lastSelectedTrack)
end)

DetailBackButton.MouseButton1Click:Connect(function()
	SoundManager:Fire("Player", "UI_Click")
	RefreshPickerPBs()
	AnimateDetailToGrid()
end)

-- RaceEndMenu button handlers (custom buttons)
RetryButton.MouseButton1Click:Connect(function()
	SoundManager:Fire("Player", "UI_Click")
	-- RETRY → replay same track
	UnanchorSeal()
	RaceFinishFrame.Visible = false
	if lastSelectedTrack then
		ShowScreen("waiting")
		ShowLoadingScreen(lastSelectedTrack)
		SelectTrackRemote:FireServer(lastSelectedTrack)
	end
end)

NewTrackButton.MouseButton1Click:Connect(function()
	SoundManager:Fire("Player", "UI_Click")
	-- SELECT NEW TRACK → return to track picker
	UnanchorSeal()
	RaceFinishFrame.Visible = false
	RefreshPickerPBs()
	ShowScreen("picker")
end)

CancelButton.MouseButton1Click:Connect(function()
	SoundManager:Fire("Player", "UI_Click")
	UnanchorSeal()
	CancelRunRemote:FireServer()
	StopTimer()
	HideProgressBarPin()
	HideSplitsPanel()
	RaceFinishFrame.Visible = false
	currentSplits = {}
	bestSplits = {}
	LoadingOverlay.Visible = false
	RefreshPickerPBs()
	ShowScreen("picker")
end)
