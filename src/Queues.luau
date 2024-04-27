if game:GetService("RunService"):IsServer() then
	return require(script.Server)
end

script.Server:Destroy()
return require(script.Client)
