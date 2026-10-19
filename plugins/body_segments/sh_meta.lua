local PLUGIN = PLUGIN

-- Возвращает таблицу всех сегментов персонажа (или создаёт пустую, если её нет).
local function GetSegmentsTable(character)
	local data = character:GetData(PLUGIN.dataKey, nil)
	if (!istable(data)) then
		data = {}
		for id, def in pairs(PLUGIN.segments) do
			data[id] = { hp = def.maxHP, status = "healthy" }
		end
		character:SetData(PLUGIN.dataKey, data)
	end
	return data
end

-- Определяет статус сегмента по текущему HP
local function ComputeStatus(id, hp)
	local def = PLUGIN.segments[id]
	if (!def) then return "healthy" end
	local ratio = hp / def.maxHP
	if (ratio <= def.thresholds.broken) then return "broken" end
	if (ratio <= def.thresholds.wounded) then return "wounded" end
	return "healthy"
end

-- ===================== ПУБЛИЧНЫЕ ФУНКЦИИ =====================
-- Получить HP сегмента
function PLUGIN:GetSegmentHP(character, id)
	local segs = GetSegmentsTable(character)
	return (segs[id] and segs[id].hp) or PLUGIN.segments[id].maxHP
end

-- Получить статус сегмента ("healthy" / "wounded" / "broken")
function PLUGIN:GetSegmentStatus(character, id)
	local segs = GetSegmentsTable(character)
	return (segs[id] and segs[id].status) or "healthy"
end

-- Задать HP сегмента (с пересчётом статуса)
function PLUGIN:SetSegmentHP(character, id, hp)
	local def = self.segments[id]
	if (!def) then return false end

	local segs = table.Copy(GetSegmentsTable(character))
	hp = math.Clamp(hp, 0, def.maxHP)
	segs[id] = { hp = hp, status = ComputeStatus(id, hp) }
	character:SetData(self.dataKey, segs)
	return true
end

-- Нанести урон сегменту. Возвращает новый статус (удобно для уведомлений).
function PLUGIN:DamageSegment(character, id, amount)
	local currentHP = self:GetSegmentHP(character, id)
	local newHP = math.max(currentHP - amount, 0)
	self:SetSegmentHP(character, id, newHP)
	return self:GetSegmentStatus(character, id)
end

-- Полностью восстановить сегмент
function PLUGIN:HealSegment(character, id)
	local def = self.segments[id]
	if (!def) then return false end
	return self:SetSegmentHP(character, id, def.maxHP)
end

-- Восстановить ВСЕ сегменты (например, при полном лечении)
function PLUGIN:HealAllSegments(character)
	for id in pairs(self.segments) do
		self:HealSegment(character, id)
	end
	return true
end

-- Инициализация сегментов при создании/загрузке персонажа
function PLUGIN:PlayerLoadedCharacter(client, character)
	GetSegmentsTable(character) -- просто создаёт таблицу, если её нет
end