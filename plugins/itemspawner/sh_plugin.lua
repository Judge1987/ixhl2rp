local PLUGIN = PLUGIN

PLUGIN.name = "Item Spawner"
PLUGIN.author = "Server"
PLUGIN.description = "Добавляет в Q-меню вкладку со всеми предметами Helix и позволяет их спавнить."

-- ===================== НАСТРОЙКИ =====================
-- Максимальное количество предметов, которое можно создать за один раз
PLUGIN.maxAmount = 20

-- Кто может спавнить предметы. Можно изменить условие под себя
-- (например, client:IsSuperAdmin() только для суперадминов).
function PLUGIN:CanUseItemSpawner(client)
    return client:IsAdmin()
end
-- ======================================================

if (SERVER) then
    util.AddNetworkString("ixItemSpawnerSpawn")

    net.Receive("ixItemSpawnerSpawn", function(_, client)
        if (!IsValid(client)) then return end

        -- защита от спама
        if ((client.ixItemSpawnerNext or 0) > CurTime()) then return end
        client.ixItemSpawnerNext = CurTime() + 0.2

        -- проверка прав на сервере
        if (!PLUGIN:CanUseItemSpawner(client)) then
            client:Notify("У вас нет прав на спавн предметов.")
            return
        end

        local uniqueID = net.ReadString()
        local amount = math.Clamp(net.ReadUInt(7), 1, PLUGIN.maxAmount)

        if (!ix.item.list[uniqueID]) then return end

        local trace = client:GetEyeTrace()
        local position = trace.HitPos + trace.HitNormal * 8

        for i = 1, amount do
            ix.item.Spawn(uniqueID, position + Vector(0, 0, (i - 1) * 6))
        end
    end)
end

if (CLIENT) then
    local DEFAULT_MODEL = "models/props_junk/cardboard_box004a.mdl"

    local function SafeLocalize(text)
        local ok, result = pcall(L, text)

        if (ok and isstring(result)) then
            return result
        end

        return tostring(text)
    end

    local function RequestSpawn(uniqueID, amount)
        net.Start("ixItemSpawnerSpawn")
            net.WriteString(uniqueID)
            net.WriteUInt(amount, 7)
        net.SendToServer()
    end

    local function BuildPanel()
        local root = vgui.Create("DPanel")
        root:SetPaintBackground(false)

        local search = vgui.Create("DTextEntry", root)
        search:Dock(TOP)
        search:DockMargin(0, 0, 0, 4)
        search:SetPlaceholderText("Поиск предмета (название или ID)...")

        local hint = vgui.Create("DLabel", root)
        hint:Dock(TOP)
        hint:DockMargin(2, 0, 0, 4)
        hint:SetText("ЛКМ — создать 1 шт. ПКМ — выбрать количество.")
        hint:SetTextColor(Color(200, 200, 200))
        hint:SizeToContents()

        local scroll = vgui.Create("DScrollPanel", root)
        scroll:Dock(FILL)

        local function Populate(filter)
            scroll:Clear()
            filter = string.lower(filter or "")

            -- группировка предметов по категориям
            local groups = {}

            for uniqueID, item in pairs(ix.item.list) do
                local name = SafeLocalize(item.name or uniqueID)
                local category = SafeLocalize(item.category or "misc")

                if (filter == "" or string.find(string.lower(name), filter, 1, true)
                or string.find(string.lower(uniqueID), filter, 1, true)) then
                    groups[category] = groups[category] or {}
                    groups[category][#groups[category] + 1] = {
                        id = uniqueID,
                        name = name,
                        item = item
                    }
                end
            end

            local categories = table.GetKeys(groups)
            table.sort(categories)

            for _, category in ipairs(categories) do
                local entries = groups[category]

                table.sort(entries, function(a, b)
                    return a.name < b.name
                end)

                local panel = vgui.Create("DCollapsibleCategory", scroll)
                panel:Dock(TOP)
                panel:DockMargin(0, 0, 0, 4)
                panel:SetLabel(category .. " (" .. #entries .. ")")
                panel:SetExpanded(true)

                local layout = vgui.Create("DIconLayout")
                layout:SetSpaceX(4)
                layout:SetSpaceY(4)
                panel:SetContents(layout)

                for _, entry in ipairs(entries) do
                    local model = isstring(entry.item.model) and entry.item.model or DEFAULT_MODEL
                    local description = SafeLocalize(entry.item.description or "")

                    local icon = layout:Add("SpawnIcon")
                    icon:SetSize(64, 64)
                    icon:SetModel(model)
                    icon:SetTooltip(entry.name .. "\n" .. description .. "\n[" .. entry.id .. "]")

                    icon.DoClick = function()
                        RequestSpawn(entry.id, 1)
                    end

                    icon.DoRightClick = function()
                        local menu = DermaMenu()

                        for _, count in ipairs({1, 5, 10, 20}) do
                            menu:AddOption("Создать x" .. count, function()
                                RequestSpawn(entry.id, count)
                            end)
                        end

                        menu:AddSpacer()
                        menu:AddOption("Копировать ID", function()
                            SetClipboardText(entry.id)
                        end)

                        menu:Open()
                    end
                end
            end
        end

        search.OnChange = function(self)
            Populate(self:GetValue())
        end

        Populate("")

        return root
    end

    spawnmenu.AddCreationTab("Предметы Helix", BuildPanel, "icon16/box.png", 200, "Спавн предметов Helix")
end