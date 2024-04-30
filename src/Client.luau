--!strict

local Client = game:GetService("Players").LocalPlayer

local GoodSignal = require(game:GetService("ReplicatedStorage").Packages.goodsignal)
local Module = {
	ClientJoinedQueue = GoodSignal.new(),
	PlayerJoinedQueue = GoodSignal.new(),
	PlayerLeftQueue = GoodSignal.new(),
	GameStarting = GoodSignal.new(),
}

local ClientJoinedQueue = Module.ClientJoinedQueue
local PlayerJoinedQueue = Module.PlayerJoinedQueue
local PlayerLeftQueue = Module.PlayerLeftQueue
local GameStarting = Module.GameStarting

local Callbacks = {
	function(PlayerUserId: number)
		PlayerJoinedQueue:Fire(PlayerUserId)
	end,
	function(PlayerUserId: number)
		PlayerLeftQueue:Fire(PlayerUserId)
	end,
	function()
		GameStarting:Fire()
	end,
}

Client:GetAttributeChangedSignal("QueueAccessCode"):Connect(function()
	local QueueAccessCode = Client:GetAttribute("QueueAccessCode")
	if not QueueAccessCode then
		return
	end
	ClientJoinedQueue:Fire(QueueAccessCode)
end)

local RemoteEvent = script.Parent.RemoteEvent

RemoteEvent.OnClientEvent:Connect(function(Callback: number, Argument: number)
	Callbacks[Callback](Argument)
end)

function Module.Ready()
	assert(not Client:GetAttribute("QueueAccessCode"), "Cannot Ready when Client is already ready.")
	RemoteEvent:FireServer(1)
end

function Module.Unready()
	assert(Client:GetAttribute("QueueAccessCode"), "Cannot Unready when Client is already unready.")
	RemoteEvent:FireServer(2)
end

return Module
