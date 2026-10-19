-- клиентская часть netstream-обработчика. регистрируется самой первой, чтобы
-- серверная отправка "ixNoteView" не падала с "Undefined hook", даже если файл
-- derma/cl_notepaper.lua по какой-то причине не загрузится
local PLUGIN = PLUGIN

netstream.Hook("ixNoteView", function(itemID, data, bEditable)
	if (!vgui.Get("ixNotePaper")) then
		ErrorNoHalt("[notepaper] панель ixNotePaper не зарегистрирована — проверьте derma/cl_notepaper.lua\n")

		return
	end

	local panel = vgui.Create("ixNotePaper")

	panel:SetItemID(tonumber(itemID) or 0)
	panel:SetEditable(tobool(bEditable))
	panel:SetNoteData(istable(data) and data or {})
end)
