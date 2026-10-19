local PLUGIN = PLUGIN

-- валидация и очистка присланного клиентом содержимого страниц.
-- возвращает таблицу {title = "...", pages = {"...", ...}} или nil
local function sanitizeNote(data)
	if (!istable(data)) then
		return
	end

	local title = string.gsub(tostring(data.title or ""):sub(1, 64), "[\r\n\t]", " ")

	local pages = {}
	for i = 1, math.min(#data.pages or {}, PLUGIN.maxPages) do
		local page = tostring(data.pages[i])

		-- обрезаем по границам многобайтовых символов UTF-8, чтобы не ломать строку
		if (page:len() > PLUGIN.maxPageLength) then
			page = page:sub(1, PLUGIN.maxPageLength)

			local cut = 0
			for j = 1, 3 do
				local byte = page:sub(-j, -j):byte()
				if (!byte or byte < 128 or byte >= 192) then
					cut = j - 1
					break
				end
			end

			if (cut > 0) then
				page = page:sub(1, -cut - 1)
			end
		end

		pages[#pages + 1] = page
	end

	if (#pages == 0) then
		pages[1] = ""
	end

	return {title = title, pages = pages}
end

netstream.Hook("ixNoteEdit", function(client, itemID, data)
	local character = client:GetCharacter()

	if (!character) then
		return
	end

	local item = ix.item.instances[itemID]

	if (!item or item.base != "base_notepaper") then
		return
	end

	-- редактировать может только автор (или предмет ещё не подписан)
	local owner = item:GetData("owner", 0)

	if (owner != 0 and owner != character:GetID()) then
		return
	end

	local note = sanitizeNote(data)

	if (!note) then
		return
	end

	item:SetNote(note, character)
end)
