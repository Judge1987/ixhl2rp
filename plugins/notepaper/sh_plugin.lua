local PLUGIN = PLUGIN

PLUGIN.name = "Note Paper"
PLUGIN.author = ""
PLUGIN.description = "Adds A4-sized, HTML-like notes and notebooks that players can write, edit (owner only) and read. Content is saved with the item and persists between restarts."

-- максимальная длина содержимого одной страницы в байтах (UTF-8).
-- учтите ограничение netstream на один пакет (~64 КБ): больше 32768 байт
-- на страницу ставить не стоит.
PLUGIN.maxPageLength = 16384
-- сколько максимум страниц можно добавить в блокнот
PLUGIN.maxPages = 16

-- сборка страницы: пользовательская HTML-разметка встраивается внутрь
-- готовой A4-страницы. Функция доступна и на сервере (перед сохранением),
-- и на клиенте (для предпросмотра).
function PLUGIN.BuildPage(title, bodyHTML)
	title = tostring(title or "")

	local style = [[
		@page { size: A4; margin: 0; }
		html, body { margin: 0; padding: 0; }
		body { background: #d9d4c5; font-family: 'Times New Roman', Georgia, serif; }
		.a4 {
			box-sizing: border-box;
			width: 210mm; min-height: 297mm;
			margin: 8px auto; padding: 20mm;
			background: #fffdf5; color: #2b2b2b;
			box-shadow: 0 2px 10px rgba(0,0,0,.35);
		}
		h1.note-title { font-size: 20pt; margin: 0 0 6mm 0; border-bottom: 1px solid #b7b0a0; padding-bottom: 2mm; }
		p { font-size: 12pt; line-height: 1.5; margin: 0 0 3mm 0; white-space: pre-wrap; }
	]]

	return [[<!DOCTYPE html>
<html><head><meta charset="utf-8"><style>]] .. style .. [[</style></head>
<body><div class="a4">]] ..
		(title ~= "" and ('<h1 class="note-title">' .. title .. '</h1>') or "") ..
		tostring(bodyHTML or "") ..
	[[</div></body></html>]]
end

if (SERVER) then
	ix.util.Include("sv_hooks.lua")
else
	ix.util.Include("cl_hooks.lua")
end

ix.lang.AddTable("english", {
	notepaperNotepad = "Notepad",
	notepaperPaper = "Sheet of Paper",
	notepaperRead = "Reads the note.",
	notepaperEdit = "Opens the note for editing.",
	notepaperAddPage = "Adds a new page to the notepad.",
	notepaperRemovePage = "Removes the selected page.",
	notepaperSave = "Save",
	notepaperClose = "Close",
	notepaperPage = "Page",
	notepaperOf = "of",
	notepaperNewPage = "New page",
	notepaperUntitled = "Untitled",
	notepaperEmpty = "(empty)",
	notepaperTooLong = "Your note is too long and was truncated.",
	notepaperNoCharacter = "You need an active character to do that.",
	notepaperNotOwner = "Only the author can edit this note.",
	notepaperMaxPages = "This notepad is full."
})

ix.lang.AddTable("russian", {
		notepaperNotepad = "Блокнот",
		notepaperPaper = "Лист бумаги",
		notepaperRead = "Читать запись.",
		notepaperEdit = "Редактировать запись.",
		notepaperAddPage = "Добавить новую страницу в блокнот.",
		notepaperRemovePage = "Удалить выбранную страницу.",
		notepaperSave = "Сохранить",
		notepaperClose = "Закрыть",
		notepaperPage = "Страница",
		notepaperOf = "из",
		notepaperNewPage = "Новая страница",
		notepaperUntitled = "Без названия",
		notepaperEmpty = "(пусто)",
		notepaperTooLong = "Ваша запись слишком длинная и была обрезана.",
		notepaperNoCharacter = "Для этого нужен активный персонаж.",
		notepaperNotOwner = "Только автор может редактировать эту запись.",
		notepaperMaxPages = "Этот блокнот заполнен."
})
