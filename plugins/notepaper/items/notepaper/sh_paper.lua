local PLUGIN = PLUGIN

ITEM.name = "Sheet of Paper"
ITEM.description = "A clean A4 sheet of paper, %s."
ITEM.model = Model("models/props_c17/paper01.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.price = 2
ITEM.maxPages = 1

function ITEM:GetDescription()
	return self:GetData("owner", 0) == 0
		and string.format(self.description, "it is blank")
		or string.format(self.description, "someone has written on it")
end

-- при сохранении сервер оборачивает каждую страницу в A4-шаблон
-- (PLUGIN.BuildPage определена в sh_plugin.lua)
function ITEM:SetNote(note, character)
	note = note or {}

	local pages = {}
	for i = 1, math.min(#note.pages or {}, self.maxPages or PLUGIN.maxPages) do
		pages[i] = PLUGIN.BuildPage(note.title, note.pages[i])
	end

	self:SetData("title", tostring(note.title or ""), false, false, true)
	self:SetData("pages", pages, false, false, true)
	self:SetData("owner", character and character:GetID() or self:GetData("owner", 0), false, false, true)
end

ITEM.functions.Read = {
	name = "@notepaperRead",
	OnRun = function(item)
		netstream.Start(item.player, "ixNoteView", item:GetID(), item:GetNote(), false)

		return false
	end
}

ITEM.functions.Edit = {
	name = "@notepaperEdit",
	OnRun = function(item)
		if (!item:CanEdit(item.player)) then
			item.player:Notify(L("notepaperNotOwner"))

			return false
		end

		netstream.Start(item.player, "ixNoteView", item:GetID(), item:GetNote(), true)

		return false
	end,
	OnCanRun = function(item)
		return item:CanEdit(item.player)
	end
}
