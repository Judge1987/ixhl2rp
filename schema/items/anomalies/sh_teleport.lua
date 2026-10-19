ITEM.name = "Странная фигурка"
ITEM.description = "Предмет, от которого неприятно покалывает пальцы. Лучше не держать его слишком долго."
ITEM.model = "models/props_lab/huladoll.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Аномалии"

-- ===================== НАСТРОЙКИ =====================
-- Список мест, куда может телепортировать предмет. Формат: Vector(x, y, z)
-- Если список пустой, места выбираются автоматически (узлы навигации карты
-- и точки появления игроков).
-- Свои координаты можно узнать, встав на нужное место и введя в консоль: getpos
ITEM.positions = {
	-- Vector(0, 0, 0),
}

-- Максимальное число попыток найти свободное место
ITEM.maxAttempts = 40
-- ======================================================

-- Собирает список возможных мест
local function GetCandidates(positions)
	if (#positions > 0) then
		return positions
	end

	local list = {}

	for _, class in ipairs({"info_node", "info_player_start", "info_player_rebel", "info_player_combine"}) do
		for _, entity in ipairs(ents.FindByClass(class)) do
			list[#list + 1] = entity:GetPos() + Vector(0, 0, 8)
		end
	end

	return list
end

-- Проверяет, что в этой точке поместится игрок
local function IsSpotFree(position)
	local trace = util.TraceHull({
		start = position,
		endpos = position,
		mins = Vector(-16, -16, 0),
		maxs = Vector(16, 16, 72),
		mask = MASK_PLAYERSOLID
	})

	return !trace.StartSolid and !trace.AllSolid
end

ITEM.functions.Use = {
	name = "Использовать",
	icon = "icon16/arrow_switch.png",
	OnRun = function(itemTable)
		local client = itemTable.player

		if (client:InVehicle()) then
			client:Notify("Здесь ничего не произойдёт.")
			return false -- предмет не расходуется
		end

		local candidates = GetCandidates(itemTable.positions)

		if (#candidates == 0) then
			client:Notify("Предмет остаётся безжизненным.")
			return false
		end

		local destination

		for _ = 1, itemTable.maxAttempts do
			local position = table.Random(candidates)

			if (IsSpotFree(position)) then
				destination = position
				break
			end
		end

		if (!destination) then
			client:Notify("Предмет дрожит, но ничего не происходит.")
			return false
		end

		client:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 75, 100, 0.6)
		client:SetVelocity(-client:GetVelocity())
		client:SetPos(destination)
		client:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 255), 1, 0.2)
		client:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 75, 100, 0.6)

		-- Предмет исчезает после использования.
		-- Чтобы он был многоразовым, замените следующую строку на: return false
		return false
	end
}