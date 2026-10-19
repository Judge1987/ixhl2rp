local PLUGIN = PLUGIN

ITEM.name = "Notepad"
ITEM.description = "A pocket notepad with %d pages, %s."
ITEM.model = Model("models/props_office/notepad_office.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.price = 10
ITEM.maxPages = 8

function ITEM:GetDescription()
	local pages = self:GetData("pages", {})

	return string.format(self.description, math.max(#pages, 1),
		self:GetData("owner", 0) == 0 and "all of them still blank" or "filled with someone's handwriting")
end

-- страницы оборачиваются в A4-шаблон из sh_paper.lua (PLUGIN.BuildPage)
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
