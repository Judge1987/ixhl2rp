local PLUGIN = PLUGIN

local PANEL = {}

-- соотношение сторон листа A4 (210 x 297 мм)
local A4_RATIO = 210 / 297

AccessorFunc(PANEL, "bEditable", "Editable", FORCE_BOOL)
AccessorFunc(PANEL, "itemID", "ItemID", FORCE_NUMBER)

-- переводит сырой пользовательский текст в HTML-разметку страниц
local function textToHTML(raw)
	raw = tostring(raw or "")

	if (raw == "") then
		return ""
	end

	local out = {}

	for line in (raw .. "\n"):gmatch("([^\r\n]*)\r?\n") do
		if (line ~= "") then
			out[#out + 1] = "<p>" .. line:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;") .. "</p>"
		else
			out[#out + 1] = "<p>&nbsp;</p>"
		end
	end

	return table.concat(out, "\n")
end

-- извлекает "тело" страницы из собранного HTML (обёртку добавляет сервер).
-- заголовок при этом вырезается — иначе он бы удваивался при повторной сборке
local function extractBody(html)
	html = tostring(html or "")

	local start = html:find('<div class="a4">', 1, true)

	if (!start) then
		return html
	end

	start = start + #'<div class="a4">'

	local finish = html:find("</div></body>", start, true)
	local body = finish and html:sub(start, finish - 1) or html:sub(start)

	body = body:gsub('<h1 class="note-title">.-</h1>', "", 1)

	return body
end

function PANEL:Init()
	if (IsValid(PLUGIN.panel)) then
		PLUGIN.panel:Remove()
	end

	PLUGIN.panel = self

	self.pages = {}
	self.currentPage = 1
	self.bEditable = false
	self.htmlMode = "text"

	self:SetTitle(L("notepaperUntitled"))
	self:SetBackgroundBlur(true)
	self:SetDeleteOnClose(true)
	self:SetSizable(true)

	-- широкий лист: примерно 3/5 экрана в ширину, высота — по формату A4
	local width = ScrW() * 0.6
	self:SetSize(math.Clamp(width, 640, ScrW() - 100), math.Clamp(width / A4_RATIO, 480, ScrH() - 120))
	self:Center()

	-- верхняя панель: навигация по страницам
	local top = self:Add("DPanel")
	top:Dock(TOP)
	top:DockMargin(0, 4, 0, 4)
	top.Paint = function(_, w, h) end
	top:SetTall(26)

	self.pageLabel = top:Add("DLabel")
	self.pageLabel:Dock(LEFT)
	self.pageLabel:DockMargin(4, 0, 8, 0)
	self.pageLabel:SetText("")

	self.prevButton = top:Add("DButton")
	self.prevButton:Dock(LEFT)
	self.prevButton:SetWidth(28)
	self.prevButton:SetText("<")
	self.prevButton.DoClick = function()
		self:ShowPage(self.currentPage - 1)
	end

	self.nextButton = top:Add("DButton")
	self.nextButton:Dock(LEFT)
	self.nextButton:SetWidth(28)
	self.nextButton:SetText(">")
	self.nextButton.DoClick = function()
		self:ShowPage(self.currentPage + 1)
	end

	local addPageButton = top:Add("DButton")
	addPageButton:Dock(RIGHT)
	addPageButton:DockMargin(0, 0, 4, 0)
	addPageButton:SetWidth(90)
	addPageButton:SetText("+ " .. L("notepaperNewPage"))
	addPageButton.DoClick = function()
		self:addPage()
	end

	self.addPageButton = addPageButton

	local btnRich = top:Add("DButton")
	btnRich:Dock(RIGHT)
	btnRich:DockMargin(0, 0, 4, 0)
	btnRich:SetWidth(120)
	btnRich:SetText(L("notepaperModeRich"))
	btnRich.DoClick = function()
		self:setHtmlMode("rich")
	end

	self.btnRich = btnRich

	local btnText = top:Add("DButton")
	btnText:Dock(RIGHT)
	btnText:DockMargin(0, 0, 4, 0)
	btnText:SetWidth(120)
	btnText:SetText(L("notepaperModeText"))
	btnText.DoClick = function()
		self:setHtmlMode("text")
	end

	self.btnText = btnText

	-- панель инструментов форматирования (видна только в режиме разметки)
	local bar = self:Add("DPanel")
	bar:Dock(TOP)
	bar:DockMargin(0, 0, 0, 4)
	bar:SetTall(26)
	bar.Paint = function(_, w, h) end

	local tools = {
		{"notepaperBold", "document.execCommand('bold', false, null);"},
		{"notepaperItalic", "document.execCommand('italic', false, null);"},
		{"notepaperUnderline", "document.execCommand('underline', false, null);"},
		{"notepaperHeading", "document.execCommand('formatBlock', false, 'h2');"},
		{"notepaperParagraph", "document.execCommand('formatBlock', false, 'p');"},
		{"notepaperList", "document.execCommand('insertUnorderedList', false, null);"},
		{"notepaperQuote", "document.execCommand('formatBlock', false, 'blockquote');"}
	}

	for index, tool in ipairs(tools) do
		local button = bar:Add("DButton")
		button:Dock(LEFT)
		button:DockMargin(0, 0, 4, 0)
		button:SetWidth(70)
		button:SetText(L(tool[1]))
		button.DoClick = function()
			if (IsValid(self.html) and self.bEditable and self.htmlMode == "rich") then
				self.html:AllowScriptAccess(true)
				self.html:ExecuteJavaScript(tools[index][2])
			end
		end
	end

	self.formatBar = bar
	bar:SetVisible(false)

	-- нижняя панель: название и кнопка сохранения/закрытия
	local bottom = self:Add("DPanel")
	bottom:Dock(BOTTOM)
	bottom:DockMargin(0, 4, 0, 0)
	bottom.Paint = function(_, w, h) end
	bottom:SetTall(28)

	self.copy = bottom:Add("DButton")
	self.copy:Dock(LEFT)
	self.copy:DockMargin(4, 0, 0, 0)
	self.copy:SetWidth(110)
	self.copy:SetText(L("notepaperCopy"))
	self.copy.DoClick = function()
		-- копируем содержимое текущей страницы как обычный текст
		local page = tostring(self.pages[self.currentPage] or "")

		if (page == "") then
			return
		end

		SetClipboardText(page
			:gsub("<br%s*/?>", "\n")
			:gsub("</p>", "\n")
			:gsub("<[^>]->", "")
			:gsub("&nbsp;", " ")
			:gsub("&lt;", "<")
			:gsub("&gt;", ">")
			:gsub("&amp;", "&"))

		notification.Add(L("notepaperCopied"), NOT_GENERIC, ScrH() * 0.15)
	end

	self.close = bottom:Add("DButton")
	self.close:Dock(RIGHT)
	self.close:DockMargin(0, 0, 4, 0)
	self.close:SetText(L("notepaperClose"))
	self.close.DoClick = function()
		if (self.bEditable) then
			self.saveRequested = true

			if (self.htmlMode == "rich" and IsValid(self.html)) then
				-- контент страницы забирается из DHTML асинхронно —
				-- сохранение продолжится в CanExecuteJavascript
				self.html:AllowScriptAccess(true)
				self.html:QueueJavascript([[ixGetBody();]])
			else
				self:commitCurrentPage()
				self:finishSave()
			end

			return
		end

		self:Close()
	end

	self.title = bottom:Add("DTextEntry")
	self.title:Dock(FILL)
	self.title:DockMargin(4, 0, 4, 0)
	self.title:SetText("")
	self.title:SetPlaceholderText(L("notepaperUntitled"))
	self.title:SetVisible(false)

	-- сам лист
	self.html = self:Add("DHTML")
	self.html:Dock(FILL)
	self.html:DockMargin(4, 0, 4, 0)
	self.html:SetAllowedScripts({"lua"})

	-- приём изменённого HTML из страницы (режим WYSIWYG-разметки)
	self.html.CanExecuteJavascript = function(_, json)
		if (IsValid(self) and self.saveRequested and self.htmlMode == "rich") then
			-- ixGetBody() возвращает JSON.stringify(html) — снимаем обе уровня кодирования
			local value = util.JSONToTable(util.JSONToTable(json))

			if (isstring(value)) then
				self.pages[self.currentPage] = value
			end

			self:finishSave()
		end

		return true
	end

	-- после загрузки страницы включаем редактирование; если сохранение уже
	-- запрошено — сразу забираем изменённый HTML обратно
	self.html.OnHtmlFinished = function()
		if (!IsValid(self) or !self.bEditable or self.htmlMode != "rich") then
			return
		end

		self.html:AllowScriptAccess(true)
		self.html:QueueJavascript(PLUGIN.editorJS .. (self.saveRequested and "ixGetBody();" or ""))
	end

	self.textEditor = self:Add("DTextEntry")
	self.textEditor:Dock(FILL)
	self.textEditor:DockMargin(4, 0, 4, 0)
	self.textEditor:SetMultiline(true)
	self.textEditor:SetVerticalScrollbarEnabled(true)
	self.textEditor:SetVisible(false)

	self:MakePopup()
end

-- сохраняет текущий ввод редактора в массив страниц (только для HTML-режима)
function PANEL:commitCurrentPage()
	if (self.bEditable and IsValid(self.textEditor) and self.htmlMode ~= "rich") then
		self.pages[self.currentPage] = self.textEditor:GetValue()
	end
end

-- переключение режима редактирования: простой текст / HTML-разметка
function PANEL:setHtmlMode(mode)
	if (mode ~= "text" and mode ~= "rich") then
		return
	end

	if (self.htmlMode == mode) then
		return
	end

	if (self.htmlMode == "text") then
		self:commitCurrentPage()
	end

	self.htmlMode = mode

	if (IsValid(self.btnText)) then
		self.btnText:SetActive(mode == "text")
	end

	if (IsValid(self.btnRich)) then
		self.btnRich:SetActive(mode == "rich")
	end

	if (IsValid(self.formatBar)) then
		self.formatBar:SetVisible(self.bEditable and mode == "rich")
	end

	self:ShowPage(self.currentPage)
end

-- максимум страниц для текущего предмета
function PANEL:getMaxPages()
	return math.min(self.itemMaxPages or PLUGIN.maxPages, PLUGIN.maxPages)
end

-- добавляет новую пустую страницу (если позволяет лимит предмета)
function PANEL:addPage()
	if (#self.pages >= self:getMaxPages()) then
		return
	end

	self:commitCurrentPage()
	self.pages[#self.pages + 1] = ""
	self:ShowPage(#self.pages)
end

-- учитываем, что отправка идёт через netstream — один пакет не должен
-- превышать размер буфера потока (32 КБ), поэтому ограничиваем общий объём
function PANEL:canSendToServer()
	local total = #tostring(self.title:GetValue())

	for i = 1, #self.pages do
		total = total + tostring(self.pages[i]):len() + 8
	end

	-- весь пакет уходит одним сообщением netstream (буфер ~32 КБ)
	if (total > PLUGIN.maxPageLength * 2) then
		return false
	end

	return true
end

function PANEL:ShowPage(index)
	index = math.Clamp(index, 1, #self.pages)

	self:commitCurrentPage()

	self.currentPage = index

	local page = tostring(self.pages[index] or "")

	if (self.htmlMode == "rich" and !page:find("<")) then
		-- страница пока хранится как сырой текст — превращаем её в разметку
		page = textToHTML(page)
		self.pages[index] = page
	end

	if (self.bEditable and self.htmlMode == "text") then
		self.textEditor:SetValue(page)
		self.html:SetVisible(false)
		self.textEditor:SetVisible(true)
	else
		self.html:SetHTML(PLUGIN.BuildPage(self.strTitle or "", page))
		self.html:SetVisible(true)
		self.textEditor:SetVisible(false)
	end

	self:updateControls()
end

function PANEL:updateControls()
	local count = #self.pages

	self.pageLabel:SetText(string.format("%s %d %s %d", L("notepaperPage"), self.currentPage, L("notepaperOf"), count))
	self.prevButton:SetEnabled(self.currentPage > 1)
	self.nextButton:SetEnabled(self.currentPage < count)

	if (IsValid(self.addPageButton)) then
		self.addPageButton:SetVisible(self.bEditable)
		self.addPageButton:SetEnabled(count < self:getMaxPages())
	end

	if (IsValid(self.btnText)) then
		self.btnText:SetVisible(self.bEditable)
		self.btnText:SetActive(self.htmlMode == "text")
	end

	if (IsValid(self.btnRich)) then
		self.btnRich:SetVisible(self.bEditable)
		self.btnRich:SetActive(self.htmlMode == "rich")
	end

	if (IsValid(self.formatBar)) then
		self.formatBar:SetVisible(self.bEditable and self.htmlMode == "rich")
	end
end

function PANEL:SetEditable(bValue)
	bValue = tobool(bValue)

	if (bValue == self.bEditable) then
		return
	end

	self.bEditable = bValue

	if (!bValue) then
		self.htmlMode = "text"
	end

	if (IsValid(self.title)) then
		self.title:SetVisible(bValue)
	end

	if (bValue) then
		self.close:SetText(L("notepaperSave"))
	else
		self.close:SetText(L("notepaperClose"))
	end

	self:ShowPage(self.currentPage)
end

function PANEL:SetNoteData(data)
	self.strTitle = tostring(data.title or "")
	self.itemMaxPages = tonumber(data.maxPages) or self.itemMaxPages
	self.pages = {}

	for i = 1, math.max(#data.pages or {}, 1) do
		-- если страница уже собрана сервером в полный HTML — вытаскиваем тело,
		-- иначе считаем её сырым содержимым
		self.pages[i] = extractBody(data.pages[i])
	end

	self.title:SetText(self.strTitle)
	self:SetTitle(self.strTitle ~= "" and self.strTitle or L("notepaperUntitled"))

	self:ShowPage(1)
end

function PANEL:Think()
	if (self.bEditable and self.htmlMode == "text" and IsValid(self.textEditor)) then
		local text = self.textEditor:GetValue()

		if (text:len() > PLUGIN.maxPageLength) then
			self.textEditor:SetText(text:sub(1, PLUGIN.maxPageLength))
			self.textEditor:SetCaretPos(PLUGIN.maxPageLength)
		end
	end
end

-- завершает сохранение: проверяет размер и отправляет данные на сервер
function PANEL:finishSave()
	if (!self.bEditable) then
		return
	end

	if (!self:canSendToServer()) then
		self.saveRequested = false
		notification.Add(L("notepaperTooLong"), NOT_GENERIC, ScrH() * 0.25)

		return
	end

	self.saveRequested = false

	netstream.Start("ixNoteEdit", self.itemID, {
		title = self.title:GetValue(),
		pages = self.pages
	})

	self:Close()
end

function PANEL:OnMouseReleased(mouseCode)
	if (mouseCode == MOUSE_RIGHT and self.bEditable) then
		local menu = DermaMenu()

		menu:AddOption(L("notepaperAddPage"), function()
			self:addPage()
		end):SetIcon("page_white_add")

		menu:AddOption(L("notepaperRemovePage"), function()
			if (#self.pages <= 1) then
				return
			end

			table.remove(self.pages, self.currentPage)
			self:ShowPage(math.min(self.currentPage, #self.pages))
		end):SetIcon("page_white_delete")

		menu:Open()
	end
end

function PANEL:OnRemove()
	if (PLUGIN.panel == self) then
		PLUGIN.panel = nil
	end
end

vgui.Register("ixNotePaper", PANEL, "DFrame")
