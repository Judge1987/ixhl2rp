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

ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")

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
