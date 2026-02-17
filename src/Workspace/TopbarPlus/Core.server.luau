-- Place this in a LocalScript inside StarterPlayerScripts
local Icon = require(script.Parent.Icon) -- Assuming Icon module is in ReplicatedStorage
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 60)
local screenGui = playerGui:WaitForChild("ScreenGui", 60)
local ToggleMenuFrameEvent = game.ReplicatedStorage.Networking.Client.BindableEvents.ToggleMenuFrame
local SoundManager = game.ReplicatedStorage.Networking.Client.BindableEvents.SoundManager

-- Image IDs for enabled and disabled states
local enabledImageId = "rbxassetid://13847974326"
local disabledImageId = "rbxassetid://13847978382"
local settingsImageId = "rbxassetid://13850086817" -- Default settings icon, replace with your asset ID

-- Track if UI is currently visible
local uiEnabled = true
local isSettingsOpen = false

-- Table to store the original visibility state of each UI element
local originalVisibility = {}

-- Function to save the current visibility states
local function saveVisibilityStates(parent)
	for _, element in pairs(parent:GetChildren()) do
		-- Skip the SelfieMode, ScreenshotMode, and DisableUi frames
		if element.Name ~= "SelfieMode" and 
			element.Name ~= "ScreenshotMode" and 
			element.Name ~= "DisableUi" and 
			element.ClassName ~= "Script" and 
			element.ClassName ~= "LocalScript" then
			if element:IsA("Frame") or 
				element:IsA("ViewportFrame") or 
				element:IsA("ImageLabel") or 
				element:IsA("TextLabel") or 
				element:IsA("TextButton") or 
				element:IsA("ImageButton") then
				-- Store the current visibility state using the element's path as a key
				local path = element:GetFullName()
				originalVisibility[path] = element.Visible
			end
			-- Recursive call to handle children
			saveVisibilityStates(element)
		end
	end
end

-- Function to toggle UI visibility
local function toggleUI()
	-- Toggle the state
	uiEnabled = not uiEnabled

	-- If disabling UI, save current states
	if not uiEnabled then
		saveVisibilityStates(screenGui)
	end

	-- Function to set visibility based on the toggle state
	local function setVisibility(parent)
		for _, element in pairs(parent:GetChildren()) do
			-- Skip the SelfieMode, ScreenshotMode, and DisableUi frames
			if element.Name ~= "SelfieMode" and 
				element.Name ~= "ScreenshotMode" and 
				element.Name ~= "DisableUi" and 
				element.ClassName ~= "Script" and 
				element.ClassName ~= "LocalScript" then
				if element:IsA("Frame") or 
					element:IsA("ViewportFrame") or 
					element:IsA("ImageLabel") or 
					element:IsA("TextLabel") or 
					element:IsA("TextButton") or 
					element:IsA("ImageButton") then
					local path = element:GetFullName()
					-- If UI is being enabled, restore original visibility
					if uiEnabled then
						if originalVisibility[path] ~= nil then
							element.Visible = originalVisibility[path]
						else
							element.Visible = true -- Default to visible if no saved state
						end
					else
						-- If UI is being disabled, hide everything
						element.Visible = false
						game.Lighting.UI_Blur.Size = 0
					end
				end
				-- Recursive call to handle children
				setVisibility(element)
			end
		end
	end

	-- Start the recursive function from ScreenGui
	setVisibility(screenGui)

	return uiEnabled -- Return current state for TopbarPlus to use
end

-- Function to update icon appearance based on state
local function updateIconAppearance(iconObj)
	if uiEnabled then
		iconObj:setImage(enabledImageId)
	else
		iconObj:setImage(disabledImageId)
	end
end

-- Create the UI Toggle TopbarPlus icon
local uiToggleIcon = Icon.new()
	:setName("UiToggleButton")
	:setImage(enabledImageId)
	:setLabel("UI") -- Initial state label
	:setOrder(1) -- Set order so UI toggle comes first
	:setAlignment("right")

-- Set up the icon to toggle using our custom function
uiToggleIcon:call(function(iconObj)
	-- Option 2: One-click behavior (uncomment to use)
    
    iconObj:oneClick()
    iconObj.selected:Connect(function()
        toggleUI()
        updateIconAppearance(iconObj)
    end)
    
end)

-- Optional: Bind a keyboard shortcut
uiToggleIcon:bindToggleKey(Enum.KeyCode.U) -- User can press 'U' to toggle UI visibility

-- Create the Settings TopbarPlus icon
local settingsIcon = Icon.new()
	:setName("SettingsButton")
	:setImage(settingsImageId)
	:setOrder(2) -- Set order so settings comes second
	:setAlignment("left")

-- Set up the settings icon
settingsIcon:call(function(iconObj)
	-- Use oneClick for better UX with your menu system
	iconObj:oneClick()

	-- Connect to selected event (when clicked)
	iconObj.selected:Connect(function()
		-- Toggle the state
		isSettingsOpen = not isSettingsOpen

		-- Play the appropriate sound effect based on your existing system
		if isSettingsOpen then
			SoundManager:Fire("Player", "UI_Click")
		else
			SoundManager:Fire("Player", "UI_Close")
		end

		-- Use your existing ToggleMenuFrameEvent to open/close the menu
		ToggleMenuFrameEvent:Fire("Settings", isSettingsOpen)

		-- No label change - it stays as "Settings"
	end)

	-- Add keyboard shortcut (S key)
	iconObj:bindToggleKey(Enum.KeyCode.S)
end)

-- Listen for when the menu is closed through other means (like exit buttons)
-- Only tracking state without updating the label
ToggleMenuFrameEvent.Event:Connect(function(menuName, shouldOpen)
	if menuName == "Settings" then
		isSettingsOpen = shouldOpen
		-- No label change happens here
	end
end)