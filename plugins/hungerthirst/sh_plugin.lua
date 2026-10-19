local PLUGIN = PLUGIN

PLUGIN.name = "Hunger and Thirst"
PLUGIN.author = "Server"
PLUGIN.description = "Добавляет персонажам сытость и насыщение (голод и жажда) с полосками на HUD."

-- ===================== НАСТРОЙКИ =====================
-- Максимальное значение показателей (100 = полностью сыт / напился)
PLUGIN.maxValue = 100

-- Сколько секунд проходит до потери 1 пункта
PLUGIN.hungerInterval = 90 -- сытость: 100 пунктов уходят примерно за 2.5 часа
PLUGIN.thirstInterval = 60 -- насыщение (вода): примерно за 1.7 часа

-- Сколько здоровья отнимается каждые 10 секунд, если сытость или насыщение
-- равны нулю. Здоровье не опускается ниже 1 (игрок не умирает от голода).
-- Поставьте 0, чтобы отключить урон полностью.
PLUGIN.damageWhenEmpty = 1

-- true  = Альянс (Combine) не испытывает голод и жажду и не видит полоски
--         (в вашей схеме они не могут пить воду из предметов).
-- false = голод и жажда действуют на всех.
PLUGIN.ignoreCombine = true

-- Цвета полосок
PLUGIN.hungerColor = Color(215, 130, 40)
PLUGIN.thirstColor = Color(50, 150, 220)
-- ======================================================

function PLUGIN:IsExempt(client)
	return self.ignoreCombine and client.IsCombine and client:IsCombine()
end

-- Показатели хранятся в персонаже и сохраняются в базе данных
ix.char.RegisterVar("hunger", {
	field = "hunger",
	fieldType = ix.type.number,
	default = PLUGIN.maxValue,
	isLocal = true,
	bNoDisplay = true
})

ix.char.RegisterVar("thirst", {
	field = "thirst",
	fieldType = ix.type.number,
	default = PLUGIN.maxValue,
	isLocal = true,
	bNoDisplay = true
})

-- Команды для администраторов (удобно для проверки)
ix.command.Add("CharSetHunger", {
	description = "Установить сытость персонажа (0-100).",
	adminOnly = true,
	arguments = {ix.type.character, ix.type.number},
	OnRun = function(self, client, target, amount)
		amount = math.Clamp(math.floor(amount), 0, PLUGIN.maxValue)
		target:SetHunger(amount)

		return "Сытость персонажа " .. target:GetName() .. " установлена на " .. amount .. "."
	end
})

ix.command.Add("CharSetThirst", {
	description = "Установить насыщение (воду) персонажа (0-100).",
	adminOnly = true,
	arguments = {ix.type.character, ix.type.number},
	OnRun = function(self, client, target, amount)
		amount = math.Clamp(math.floor(amount), 0, PLUGIN.maxValue)
		target:SetThirst(amount)

		return "Насыщение персонажа " .. target:GetName() .. " установлено на " .. amount .. "."
	end
})

if (SERVER) then
	local TICK = 10 -- как часто (в секундах) плагин проверяет игроков

	local playerMeta = FindMetaTable("Player")

	-- Использование в предметах: client:RestoreHunger(30) и client:RestoreThirst(40)
	function playerMeta:RestoreHunger(amount)
		local character = self:GetCharacter()

		if (character) then
			local value = character:GetHunger() or PLUGIN.maxValue
			character:SetHunger(math.Clamp(math.floor(value + amount), 0, PLUGIN.maxValue))
		end
	end

	function playerMeta:RestoreThirst(amount)
		local character = self:GetCharacter()

		if (character) then
			local value = character:GetThirst() or PLUGIN.maxValue
			character:SetThirst(math.Clamp(math.floor(value + amount), 0, PLUGIN.maxValue))
		end
	end

	timer.Create("ixHungerThirstTick", TICK, 0, function()
		for _, client in ipairs(player.GetAll()) do
			local character = client:GetCharacter()

			-- пропускаем игроков без персонажа, мёртвых, в ноклипе и исключённых
			if (!character or !client:Alive()) then continue end
			if (client:GetMoveType() == MOVETYPE_NOCLIP) then continue end
			if (PLUGIN:IsExempt(client)) then continue end

			local hunger = character:GetHunger() or PLUGIN.maxValue
			local thirst = character:GetThirst() or PLUGIN.maxValue

			client.ixHungerTimer = (client.ixHungerTimer or 0) + TICK
			client.ixThirstTimer = (client.ixThirstTimer or 0) + TICK

			if (client.ixHungerTimer >= PLUGIN.hungerInterval) then
				client.ixHungerTimer = 0
				hunger = math.max(hunger - 1, 0)
				character:SetHunger(hunger)
			end

			if (client.ixThirstTimer >= PLUGIN.thirstInterval) then
				client.ixThirstTimer = 0
				thirst = math.max(thirst - 1, 0)
				character:SetThirst(thirst)
			end

			-- урон при полном истощении
			if (PLUGIN.damageWhenEmpty > 0 and (hunger <= 0 or thirst <= 0)) then
				local health = client:Health()

				if (health > 1) then
					client:SetHealth(math.max(health - PLUGIN.damageWhenEmpty, 1))
				end
			end
		end
	end)

	-- после смерти показатели восстанавливаются
	function PLUGIN:PlayerDeath(client)
		local character = client:GetCharacter()

		if (character) then
			character:SetHunger(PLUGIN.maxValue)
			character:SetThirst(PLUGIN.maxValue)
		end
	end
end

if (CLIENT) then
	-- Полоски рядом со здоровьем и стаминой
	ix.bar.Add(function()
		local client = LocalPlayer()

		if (!IsValid(client) or PLUGIN:IsExempt(client)) then return false end

		local character = client:GetCharacter()

		if (!character) then return false end

		return (character:GetHunger() or PLUGIN.maxValue) / PLUGIN.maxValue
	end, PLUGIN.hungerColor, nil, "hunger")

	ix.bar.Add(function()
		local client = LocalPlayer()

		if (!IsValid(client) or PLUGIN:IsExempt(client)) then return false end

		local character = client:GetCharacter()

		if (!character) then return false end

		return (character:GetThirst() or PLUGIN.maxValue) / PLUGIN.maxValue
	end, PLUGIN.thirstColor, nil, "thirst")
end
