local PLUGIN = PLUGIN

PLUGIN.name = "Diseases"
PLUGIN.author = "Server"
PLUGIN.description = "Система заболеваний: ОРЗ, пневмония, паразиты и онкологическое заболевание."

-- ===================== НАСТРОЙКИ =====================
-- Радиус заражения при кашле или чихании (в юнитах, ~52 юнита = 1 метр)
PLUGIN.contagionRadius = 150

-- Вероятность самопроизвольно заболеть ОРЗ за один час игры.
-- 0.02 = 2%. Поставьте 0, чтобы болезнь появлялась только по команде администратора
-- или через заражение от другого игрока.
PLUGIN.spontaneousChancePerHour = 0.02

-- Самопроизвольное появление рака. false = только через администратора/сценарий.
PLUGIN.cancerSpontaneousEnabled = false
-- Вероятность за час игры, если переключатель выше включён.
PLUGIN.cancerSpontaneousChancePerHour = 0.001

-- Защищает ли маска от заражения:
PLUGIN.carrierMaskBlocks = true -- маска на больном не даёт ему заражать других
PLUGIN.targetMaskBlocks = true  -- маска на здоровом не даёт ему заразиться

-- Предметы-маски (uniqueID = имя файла без "sh_" и без ".lua").
-- Защищают только когда надеты.
PLUGIN.maskItems = {
	["gasmask"] = true,
	["respirator"] = true,
	["facemask"] = true,
	["metropolice_gasmask"] = true
}

-- Звуки кашля (стандартные звуки HL2)
PLUGIN.coughSounds = {
	"ambient/voices/cough1.wav",
	"ambient/voices/cough2.wav",
	"ambient/voices/cough3.wav",
	"ambient/voices/cough4.wav"
}

-- Звуки чихания. В обычной HL2 их нет, поэтому список пуст.
-- Если добавите свои звуки на сервер, впишите их пути сюда, например:
-- "sneeze/sneeze1.wav",
PLUGIN.sneezeSounds = {
}
-- ======================================================

local TICK = 10 -- как часто (в секундах) обновляются болезни

PLUGIN.diseases = PLUGIN.diseases or {}

function PLUGIN:RegisterDisease(id, data)
	data.id = id
	self.diseases[id] = data
end

-- ---------------------- ОПИСАНИЕ БОЛЕЗНЕЙ ----------------------
PLUGIN:RegisterDisease("cold", {
	name = "ОРЗ",
	duration = 2400,       -- сколько секунд игры длится болезнь, если не лечить
	immunity = 1200,       -- сколько секунд (реального времени) после выздоровления нет повторного заражения
	staminaRegen = 0.6,    -- восстановление стамины умножается на это число
	staminaDrain = 1.25,   -- расход стамины умножается на это число
	healthDrain = 0,       -- потеря здоровья за каждый такт (0 = нет)
	coughChance = 0.3,     -- шанс кашля за такт (10 секунд)
	sneezeChance = 0.2,    -- шанс чихания за такт (работает, только если есть звуки)
	contagious = true,
	contagionChance = 0.25, -- шанс заразить каждого, кто рядом, при кашле или чихании
	complication = {id = "pneumonia", after = 1500, chance = 0.005}, -- после 1500 с без лечения каждый такт есть шанс перейти в пневмонию
	infectMessage = "Вы чувствуете першение в горле и озноб.",
	recoverMessage = "Вы чувствуете, что болезнь отступила."
})

PLUGIN:RegisterDisease("pneumonia", {
	name = "Пневмония",
	duration = 5400,       -- без лечения проходит через 90 минут игры. nil = только лечением
	immunity = 600,
	staminaRegen = 0.35,
	staminaDrain = 1.6,
	healthDrain = 1,       -- потеря здоровья за каждый такт (10 секунд)
	healthFloor = 30,      -- болезнь не опускает здоровье ниже этого значения
	coughChance = 0.6,
	sneezeChance = 0,
	contagious = false,
	infectMessage = "Вам тяжело дышать, в груди колет, поднимается жар.",
	recoverMessage = "Дыхание постепенно становится ровным, жар спадает."
})

-- Паразиты не передаются между игроками. Заражение только через предметы:
-- в коде предмета нужна строка client:RiskDisease("parasites", 0.3)
-- Само не проходит, лечится только противопаразитарным препаратом.
PLUGIN:RegisterDisease("parasites", {
	name = "Паразитарное заражение",
	incubation = 900,         -- первые 15 минут игры никаких симптомов и эффектов нет
	staminaRegen = 0.8,
	staminaDrain = 1.15,
	healthDrain = 1,          -- потеря здоровья за каждый такт (10 секунд)
	healthFloor = 60,         -- ниже этого значения болезнь здоровье не опускает
	hungerDrainChance = 0.2,  -- шанс за такт потерять лишний пункт сытости
	thirstDrainChance = 0.1,  -- шанс за такт потерять лишний пункт воды
	contagious = false,
	messageChance = 0.08,     -- шанс сообщения о самочувствии за такт
	symptomMessages = {
		"Живот скручивает спазм.",
		"Вас мутит, во рту неприятный привкус.",
		"Вы чувствуете слабость и тянущую боль в животе."
	},
	recoverMessage = "Желудок наконец успокаивается."
})
PLUGIN:RegisterDisease("cancer", {
	name = "Онкологическое заболевание",
	-- duration не задан: само по себе заболевание не проходит.
	immunity = 0,
	staminaRegen = 0.65,
	staminaDrain = 1.35,
	healthDrain = 1,
	healthFloor = 25,
	hungerDrain = 2,       -- дополнительная потеря сытости за такт
	thirstDrain = 2,       -- дополнительная потеря жажды за такт
	messageChance = 0.12,
	symptomMessages = {
		"Вы чувствуете себя истощённым.",
		"Слабость нарастает, даже простые движения требуют усилий.",
		"Вас знобит, а во рту пересохло.",
		"Вы чувствуете тяжёлую усталость и нехватку сил."
	},
	infectMessage = "Вы чувствуете необъяснимую слабость и постоянное истощение.",
	recoverMessage = "Ваше состояние заметно улучшилось."
})
-- ---------------------------------------------------------------

-- Команды для администраторов
ix.command.Add("CharGiveDisease", {
	description = "Заразить персонажа болезнью (например, cold).",
	adminOnly = true,
	arguments = {ix.type.character, ix.type.string},
	OnRun = function(self, client, target, id)
		id = string.lower(id)

		if (!PLUGIN.diseases[id]) then
			return "Неизвестная болезнь: " .. id
		end

		local targetPlayer = target:GetPlayer()

		if (!IsValid(targetPlayer)) then
			return "Игрок не найден."
		end

		if (PLUGIN:Infect(targetPlayer, id, true)) then
			return "Персонаж " .. target:GetName() .. " заражён: " .. PLUGIN.diseases[id].name .. "."
		end

		return "Персонаж уже болен этой болезнью."
	end
})

ix.command.Add("CharCureDisease", {
	description = "Вылечить персонажа от болезни (id или all).",
	adminOnly = true,
	arguments = {ix.type.character, ix.type.string},
	OnRun = function(self, client, target, id)
		id = string.lower(id)

		local targetPlayer = target:GetPlayer()

		if (!IsValid(targetPlayer)) then
			return "Игрок не найден."
		end

		if (id == "all") then
			for diseaseID in pairs(target:GetData("diseases", {})) do
				PLUGIN:Cure(targetPlayer, diseaseID, true)
			end

			return "Персонаж " .. target:GetName() .. " вылечен от всех болезней."
		end

		if (PLUGIN:Cure(targetPlayer, id, true)) then
			return "Персонаж " .. target:GetName() .. " вылечен."
		end

		return "Персонаж не болен этой болезнью."
	end
})

ix.command.Add("CharDiseases", {
	description = "Показать болезни персонажа.",
	adminOnly = true,
	arguments = ix.type.character,
	OnRun = function(self, client, target)
		local list = {}

		for id, state in pairs(target:GetData("diseases", {})) do
			list[#list + 1] = id .. " (" .. math.floor(state.elapsed or 0) .. " с)"
		end

		if (#list == 0) then
			return "У персонажа " .. target:GetName() .. " нет болезней."
		end

		return target:GetName() .. ": " .. table.concat(list, ", ")
	end
})

if (SERVER) then
	local playerMeta = FindMetaTable("Player")

	-- Функции для использования в предметах
	function playerMeta:HasDisease(id)
		local character = self:GetCharacter()

		return character != nil and character:GetData("diseases", {})[id] != nil
	end

	function playerMeta:GiveDisease(id)
		return PLUGIN:Infect(self, id)
	end

	function playerMeta:CureDisease(id)
		return PLUGIN:Cure(self, id)
	end

	-- Проверяет, надета ли на игроке маска
	function PLUGIN:HasMask(client)
		local character = client:GetCharacter()
		local inventory = character and character:GetInventory()

		if (!inventory) then return false end

		for _, item in pairs(inventory:GetItems()) do
			if (self.maskItems[item.uniqueID] and item:GetData("equip")) then
				return true
			end
		end

		return false
	end

	function PLUGIN:IsImmune(character, id)
		local immunity = character:GetData("diseaseImmunity", {})

		return (immunity[id] or 0) > os.time()
	end

	function PLUGIN:SetImmunity(character, id, seconds)
		if (!seconds or seconds <= 0) then return end

		local immunity = table.Copy(character:GetData("diseaseImmunity", {}))
		immunity[id] = os.time() + seconds
		character:SetData("diseaseImmunity", immunity)
	end

	-- Пересчитывает влияние болезней на стамину
	function PLUGIN:RefreshEffects(client, diseases)
		local regen, drain = 1, 1

		for id in pairs(diseases) do
			local def = self.diseases[id]

			if (def) then
				regen = regen * (def.staminaRegen or 1)
				drain = drain * (def.staminaDrain or 1)
			end
		end

		client.ixDiseaseRegen = regen
		client.ixDiseaseDrain = drain
	end

	-- Заражение. bForce = true игнорирует иммунитет (для команд администратора)
	function PLUGIN:Infect(client, id, bForce)
		local def = self.diseases[id]
		local character = client:GetCharacter()

		if (!def or !character) then return false end

		local diseases = table.Copy(character:GetData("diseases", {}))

		if (diseases[id]) then return false end
		if (!bForce and self:IsImmune(character, id)) then return false end

		diseases[id] = {elapsed = 0}
		character:SetData("diseases", diseases)
		self:RefreshEffects(client, diseases)

		if (def.infectMessage) then
			client:Notify(def.infectMessage)
		end

		return true
	end

	-- Лечение. bNoImmunity = true не даёт иммунитет (для команд администратора)
	function PLUGIN:Cure(client, id, bNoImmunity)
		local def = self.diseases[id]
		local character = client:GetCharacter()

		if (!def or !character) then return false end

		local diseases = table.Copy(character:GetData("diseases", {}))

		if (!diseases[id]) then return false end

		diseases[id] = nil
		character:SetData("diseases", diseases)
		self:RefreshEffects(client, diseases)

		if (!bNoImmunity) then
			self:SetImmunity(character, id, def.immunity)
		end

		return true
	end

	-- Заражение окружающих
	function PLUGIN:Spread(source, def)
		if (!def.contagious) then return end
		if (self.carrierMaskBlocks and self:HasMask(source)) then return end

		local origin = source:GetPos()
		local radiusSqr = self.contagionRadius * self.contagionRadius

		for _, other in ipairs(player.GetAll()) do
			if (other == source or !other:Alive() or !other:GetCharacter()) then continue end
			if (other:GetPos():DistToSqr(origin) > radiusSqr) then continue end
			if (self.targetMaskBlocks and self:HasMask(other)) then continue end

			if (math.random() < (def.contagionChance or 0)) then
				self:Infect(other, def.id)
			end
		end
	end

	-- Симптомы: кашель и чихание
	function PLUGIN:Symptoms(client, def)
		if (#self.coughSounds > 0 and math.random() < (def.coughChance or 0)) then
			client:EmitSound(table.Random(self.coughSounds), 70, math.random(95, 105))
			self:Spread(client, def)
		elseif (#self.sneezeSounds > 0 and math.random() < (def.sneezeChance or 0)) then
			client:EmitSound(table.Random(self.sneezeSounds), 70, math.random(95, 105))
			self:Spread(client, def)
		end
	end

	function PLUGIN:ProcessPlayer(client, character)
		-- самопроизвольное заболевание
		if (self.spontaneousChancePerHour > 0
		and math.random() < self.spontaneousChancePerHour * TICK / 3600) then
			self:Infect(client, "cold")
		end

		if (self.cancerSpontaneousEnabled
		and self.cancerSpontaneousChancePerHour > 0
		and math.random() < self.cancerSpontaneousChancePerHour * TICK / 3600) then
			self:Infect(client, "cancer")
		end

		local diseases = table.Copy(character:GetData("diseases", {}))
		local changed = false
		local complications = {}

		for id, state in pairs(diseases) do
			local def = self.diseases[id]
			changed = true

			if (!def) then
				diseases[id] = nil
			else
				state.elapsed = (state.elapsed or 0) + TICK
				if (def.incubation and state.elapsed < def.incubation) then continue end
				local comp = def.complication

				if (comp and state.elapsed >= comp.after and math.random() < comp.chance) then
					-- осложнение: болезнь переходит в другую
					diseases[id] = nil
					complications[#complications + 1] = comp.id
				elseif (def.duration and state.elapsed >= def.duration) then
					-- самостоятельное выздоровление
					diseases[id] = nil
					self:SetImmunity(character, id, def.immunity)

					if (def.recoverMessage) then
						client:Notify(def.recoverMessage)
					end
				else
					-- потеря здоровья (не ниже 1)
					local floor = def.healthFloor or 1

					if (def.healthDrain and def.healthDrain > 0 and client:Health() > floor) then
						client:SetHealth(math.max(client:Health() - def.healthDrain, floor))
					end

					-- Дополнительное снижение сытости/жажды. Используем методы Helix,
					-- если они есть в установленной схеме; иначе пробуем стандартные данные.
					if (def.hungerDrain and def.hungerDrain > 0) then
						if (character.GetHunger and character.SetHunger) then
							character:SetHunger(math.max(character:GetHunger() - def.hungerDrain, 0))
						elseif (character.GetData and character.SetData) then
							local hunger = character:GetData("hunger", nil)
							if (isnumber(hunger)) then character:SetData("hunger", math.max(hunger - def.hungerDrain, 0)) end
						end
					end

					if (def.thirstDrain and def.thirstDrain > 0) then
						if (character.GetThirst and character.SetThirst) then
							character:SetThirst(math.max(character:GetThirst() - def.thirstDrain, 0))
						elseif (character.GetData and character.SetData) then
							local thirst = character:GetData("thirst", nil)
							if (isnumber(thirst)) then character:SetData("thirst", math.max(thirst - def.thirstDrain, 0)) end
						end
					end

					if (def.messageChance and math.random() < def.messageChance
					and istable(def.symptomMessages) and #def.symptomMessages > 0) then
						if (id == "cancer") then
							client:ChatPrint(table.Random(def.symptomMessages))
						else
							client:Notify(table.Random(def.symptomMessages))
						end
					end

					self:Symptoms(client, def)
				end
			end
		end

		for _, newID in ipairs(complications) do
			local newDef = self.diseases[newID]

			if (newDef and !diseases[newID]) then
				diseases[newID] = {elapsed = 0}

				if (newDef.infectMessage) then
					client:Notify(newDef.infectMessage)
				end
			end
		end

		if (changed) then
			character:SetData("diseases", diseases)
		end

		self:RefreshEffects(client, diseases)
	end

	timer.Create("ixDiseaseTick", TICK, 0, function()
		for _, client in ipairs(player.GetAll()) do
			local character = client:GetCharacter()

			if (!character or !client:Alive()) then continue end
			if (client:GetMoveType() == MOVETYPE_NOCLIP) then continue end

			PLUGIN:ProcessPlayer(client, character)
		end
	end)

	-- при загрузке персонажа пересчитываем эффекты
	function PLUGIN:PlayerLoadedCharacter(client, character)
		self:RefreshEffects(client, character:GetData("diseases", {}))
	end

	-- влияние на стамину (хук стамины Helix)
	function PLUGIN:AdjustStaminaOffset(client, offset)
		if (offset > 0) then
			return offset * (client.ixDiseaseRegen or 1)
		end

		return offset * (client.ixDiseaseDrain or 1)
	end
end

-- Клиентские эффекты для рака: мягкое размытие и пульсация изображения.
if (CLIENT) then
	hook.Add("RenderScreenspaceEffects", "ixDiseaseCancerScreenEffects", function()
		local client = LocalPlayer()
		if (!IsValid(client) or !client:Alive()) then return end

		local character = client:GetCharacter()
		if (!character) then return end

		local diseases = character:GetData("diseases", {})
		if (!diseases.cancer) then return end

		local pulse = (math.sin(CurTime() * 2.2) + 1) * 0.5

		DrawMotionBlur(0.08, 0.35 + pulse * 0.12, 0.01)
		DrawSharpen(0.3, 0.5)
		DrawColorModify({
			["$pp_colour_addr"] = 0.015 + pulse * 0.012,
			["$pp_colour_addg"] = 0,
			["$pp_colour_addb"] = 0,
			["$pp_colour_brightness"] = -0.015 - pulse * 0.015,
			["$pp_colour_contrast"] = 1.0 - pulse * 0.08,
			["$pp_colour_colour"] = 0.85 - pulse * 0.15,
			["$pp_colour_mulr"] = 0,
			["$pp_colour_mulg"] = 0,
			["$pp_colour_mulb"] = 0
		})
	end)
end
