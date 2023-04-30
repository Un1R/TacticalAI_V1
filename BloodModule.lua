local module = {}

module.MakePuddle = function(HRP)
	local Pos = Vector3.new(HRP.Position.X ,HRP.Position.Y - 2.8770, HRP.Position.Z)
	local Template = game:GetService("ReplicatedStorage"):WaitForChild("BloodTemplate"):Clone()
	Template.Position = Pos
	Template.Parent = workspace
	Template.Anchored = true
	Template.CanCollide = false
end

return module
