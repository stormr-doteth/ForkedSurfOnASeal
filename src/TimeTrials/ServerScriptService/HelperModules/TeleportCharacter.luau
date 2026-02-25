
-- Constants --

local TeleportResetEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.TeleportReset


-- Functions --

local function TeleportCharacter(TargetPlayer, TargetPart, LocalCharacterTeleport)

	local TargetCharacter = TargetPlayer.Character
	if not TargetCharacter then
		return
	end

	local Target_HRP = TargetCharacter:FindFirstChild("HumanoidRootPart")
	local TargetSealRoot = TargetCharacter.Parent:FindFirstChild("SealRoot")

	if not Target_HRP or not TargetSealRoot then
		return
	end

	-- If TargetPart is a Model, use its PrimaryPart
	local actualPart = TargetPart
	if TargetPart:IsA("Model") then
		actualPart = TargetPart.PrimaryPart or TargetPart:FindFirstChildWhichIsA("BasePart")
		if not actualPart then return end
	end

	local NewOrientation = CFrame.Angles(0, math.rad(actualPart.Orientation.Y + 180), 0)
	local NewDestination = actualPart.CFrame * NewOrientation

	if not LocalCharacterTeleport then
		Target_HRP.CFrame = NewDestination
		TargetSealRoot.CFrame = NewDestination
	end

	TeleportResetEvent:FireClient(TargetPlayer, NewDestination, NewOrientation, LocalCharacterTeleport)

end


-- Setup --

return TeleportCharacter
