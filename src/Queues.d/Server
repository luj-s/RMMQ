--!strict

local Server = {}

local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local RemoteEvent = script.Parent.RemoteEvent

local PlaceId: number = 0000000000
local MinimumQueuePlayers = 2
local MaximumQueuePlayers = 2
local QueueWaitTime = 60

local Queues: {[string]: {number}} = {}
local WaitingQueueThreads: {[string]: thread} = {}

Players.PlayerAdded:Connect(function(Player)
	Player:GetAttributeChangedSignal("QueueAccessCode"):Connect(function()
		local QueueAccessCode: string? = Player:GetAttribute("QueueAccessCode")
		MessagingService:PublishAsync("P", {if type(QueueAccessCode) == "string" then 1 else 2, Player.UserId, QueueAccessCode})
	end)
end)

local Callbacks = {
	function(Player: Player)
		local QueuesAccessCodes: {string} = {}
		for QueueAccessCode, _ in Queues do
			table.insert(QueuesAccessCodes, QueueAccessCode)
		end

		local QueuesAccessCodesN = #QueuesAccessCodes
		if QueuesAccessCodesN == 0 then
			local QueueAccessCode = TeleportService:ReserveServer(PlaceId)
			MessagingService:PublishAsync("Q", QueueAccessCode)
			Player:SetAttribute("QueueAccessCode", QueueAccessCode)
			return
		end
		
		Player:SetAttribute("QueueAccessCode", QueuesAccessCodes[math.random(1, QueuesAccessCodesN)])
	end,
	function(Player: Player)
		Player:SetAttribute("QueueAccessCode", nil)
	end
}

RemoteEvent.OnServerEvent:Connect(function(Player, Callback: number)
	Callbacks[Callback](Player)
end)

MessagingService:SubscribeAsync("Q", function(Message: {Data: string, Sent: number})
	local QueueAccessCode = Message.Data
	Queues[QueueAccessCode] = if Queues[QueueAccessCode] then nil else {}
end)

local function GetQueuePlayers(QueueAccessCode: string): {Player}
	local QueuePlayers = {}

	local Queue = Queues[QueueAccessCode]
	for _, Player in Players:GetPlayers() do
		if not table.find(Queue, Player.UserId) then continue end

		table.insert(QueuePlayers, Player)
	end
	
	return QueuePlayers
end

local function Start(QueueAccessCode: string)
	local PlayersToBeTeleported = GetQueuePlayers(QueueAccessCode)
	if #PlayersToBeTeleported == 0 then return end
	
	for _, Player in PlayersToBeTeleported do
		RemoteEvent:FireClient(Player, 3)
	end
	
	TeleportService:TeleportToPrivateServer(PlaceId, QueueAccessCode, PlayersToBeTeleported)
end

local PlayerActions = {
	function(UserId: number, QueueAccessCode: string)
		local Queue = Queues[QueueAccessCode]
		table.insert(Queue, UserId)
		
		local Quantity	= 0
		for _, Player in Players:GetPlayers() do
			if not table.find(Queue, Player.UserId) then continue end
			Quantity += 1
			RemoteEvent:FireClient(Player, 1, UserId)
		end
		
		if Quantity == 0 then return end
		
		local QueueN = #Queue
		if QueueN >= MinimumQueuePlayers and QueueN < MaximumQueuePlayers and not WaitingQueueThreads[QueueAccessCode] then
			WaitingQueueThreads[QueueAccessCode] = task.spawn(function()
				task.wait(QueueWaitTime)

				if not Queues[QueueAccessCode] then return end
				Start(QueueAccessCode)
			end)
		elseif QueueN == MaximumQueuePlayers then
			Start(QueueAccessCode)
		end
	end,
	function(UserId: number, QueueAccessCode: string)
		local Queue = Queues[QueueAccessCode]
		table.remove(Queue, table.find(Queue, UserId))
		
		for _, Player in GetQueuePlayers(QueueAccessCode) do
			RemoteEvent:FireClient(Player, 2, UserId)
		end
		
		if #Queue ~= 0 then return end
		Queues[QueueAccessCode] = nil
		
		if not WaitingQueueThreads[QueueAccessCode] then return end
		WaitingQueueThreads[QueueAccessCode] = nil
	end
}

MessagingService:SubscribeAsync("P", function(Message: {Data: {any},  Sent: number})
	local Data = Message.Data
	PlayerActions[Data[1]](Data[2], Data[3])
end)

Players.PlayerRemoving:Connect(Callbacks[2])

game:BindToClose(function()
	for _, Player in Players:GetPlayers() do
		Callbacks[2](Player)
	end
end)

return Server
