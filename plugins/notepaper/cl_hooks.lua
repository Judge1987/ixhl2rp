local PLUGIN = PLUGIN

netstream.Hook("ixNoteView", function(itemID, data, bEditable)
	local panel = vgui.Create("ixNotePaper")

	panel:SetItemID(tonumber(itemID) or 0)
	panel:SetEditable(tobool(bEditable))
	panel:SetNoteData(istable(data) and data or {})
end)
