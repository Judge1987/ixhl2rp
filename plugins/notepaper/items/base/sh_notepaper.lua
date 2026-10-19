ITEM.name = "Note Paper Base"
ITEM.description = "Something you can write notes on."
ITEM.model = Model("models/props_c17/paper01.mdl")

-- формат заметки: {title = string, pages = {string, string, ...}}
-- страницы хранятся как HTML-разметка (см. sh_paper.lua / sh_notepad.lua)

function ITEM:GetNote()
	local data = self.data or {}

	if (!istable(data.pages)) then
		return {title = "", pages = {data.text or ""}, maxPages = self.maxPages or 1}
	end

	return {title = data.title or "", pages = data.pages, maxPages = self.maxPages or 1}
end

function ITEM:SetNote(note, character)
	note = note or {}

	self:SetData("title", tostring(note.title or ""), false, false, true)
	self:SetData("pages", note.pages or {""}, false, false, true)
	self:SetData("owner", character and character:GetID() or self:GetData("owner", 0), false, false, true)
end

-- базовая проверка права на редактирование: только автор, либо предмет ещё не подписан
function ITEM:CanEdit(player)
	local character = player:GetCharacter()

	if (!character) then
		return false
	end

	local owner = tonumber(self:GetData("owner", 0))

	return owner == 0 or owner == character:GetID()
end
