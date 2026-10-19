local PLUGIN = PLUGIN

local PANEL = {}

-- соотношение сторон листа A4 (210 x 297 мм)
local A4_RATIO = 210 / 297

AccessorFunc(PANEL, "bEditable", "Editable", FORCE_BOOL)
AccessorFunc(PANEL, "itemID", "ItemID", FORCE_NUMBER)

-- извлекает "тело" страницы из собранного HTML (обёртку добавляет сервер)
local function extractBody(html)
	html = tostring(html or "")

	local start = html:find("<div class=\"a4\">", 1, true)

	if (!start) then
		return html
	end

	start = start + #"<div class=\"a4\">"

	local finish = html:find("</div></body>", start, true)

	if (!finish) then
		return html:sub(start)
	end

	return html:sub(start, finish - 1)
end

function PANEL:Init()
	if (IsValid(PLUGIN.panel)) then
		PLUGIN.panel:Remove()
	end

	PLUGIN.panel = self

	self.pages = {}
	self.currentPage = 1
	self.bEditable = false

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

	self:addPageButton = top:Add("DButton")
	self:addPageButton:Dock(RIGHT)
	self:addPageButton:DockMargin(0, 0, 4, 0)
	self:addPageButton:SetWidth(90)
	self:addPageButton:SetText("+ " .. L("notepaperNewPage"))
	self:addPageButton.DoClick = function()
		self:addPage()
	end

	-- нижняя панель: название и кнопка сохранения/закрытия
	local bottom = self:Add("DPanel")
	bottom:Dock(BOTTOM)
	bottom:DockMargin(0, 4, 0, 0)
	bottom.Paint = function(_, w, h) end
	bottom:SetTall(28)

	self.close = bottom:Add("DButton")
	self.close:Dock(RIGHT)
	self.close:DockMargin(0, 0, 4, 0)
	self.close:SetText(L("notepaperClose"))
	self.close.DoClick = function()
		if (self.bEditable) then
			self:commitCurrentPage()

			if (!self:canSendToServer()) then
				notification.Add(L("notepaperTooLong"), NOT_GENERIC, ScrH() * 0.25)

				return
			end

			netstream.Start("ixNoteEdit", self.itemID, {
				title = self.title:GetValue(),
				pages = self.pages
			})
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

	self.textEditor = self:Add("DTextEntry")
	self.textEditor:Dock(FILL)
	self.textEditor:DockMargin(4, 0, 4, 0)
	self.textEditor:SetMultiline(true)
	self.textEditor:SetVerticalScrollbarEnabled(true)
	self.textEditor:SetVisible(false)

	self:MakePopup()
end

-- сохраняет текущий ввод редактора в массив страниц
function PANEL:commitCurrentPage()
	if (self.bEditable and IsValid(self.textEditor)) then
		self.pages[self.currentPage] = self.textEditor:GetValue()
	end
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
		total = total + self.pages[i]:len() + 8

		if (total > PLUGIN.maxPageLength) then
			return false
		end
	end

	return true
end

function PANEL:ShowPage(index)
	index = math.Clamp(index, 1, #self.pages)

	self:commitCurrentPage()

	self.currentPage = index

	local page = self.pages[index] or ""

	if (self.bEditable) then
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
end

function PANEL:SetEditable(bValue)
	bValue = tobool(bValue)

	if (bValue == self.bEditable) then
		return
	end

	self.bEditable = bValue

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
	if (self.bEditable and IsValid(self.textEditor)) then
		local text = self.textEditor:GetValue()

		if (text:len() > PLUGIN.maxPageLength) then
			self.textEditor:SetText(text:sub(1, PLUGIN.maxPageLength))
			self.textEditor:SetCaretPos(PLUGIN.maxPageLength)
		end
	end
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
