
-- Constants --

local TeleportCharacter = require(game.ServerScriptService.HelperModules.TeleportCharacter)


-- Event Functions --

game.Players.PlayerAdded:Connect(function(NewPlayer)
	
	local PlayerData = game.ReplicatedStorage.PlayerData:WaitForChild(NewPlayer.Name, 60)
	
	if not PlayerData.DataFlags.TutorialCompleted.Value then
		wait(3)
		TeleportCharacter(NewPlayer, workspace.TutorialStuff.TutorialTeleporter, true)
	end
	
end)