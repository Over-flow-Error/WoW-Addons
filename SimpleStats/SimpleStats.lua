local _, addon = ...

function addon.Init()
    -- Создаем основной фрейм с золотой рамкой
    addon.frame = CreateFrame("Frame", "SimpleStatsFrame", UIParent, "BackdropTemplate")
    addon.frame:SetSize(320, 150)
    addon.frame:SetFrameStrata("MEDIUM")
    addon.frame:SetClampedToScreen(true)
    
    -- Загрузка сохраненной позиции
    SimpleStatsDB = SimpleStatsDB or {}
    addon.frame:SetPoint(SimpleStatsDB.point or "CENTER", SimpleStatsDB.x or 0, SimpleStatsDB.y or 0)

    -- Стиль окна (золотая рамка Blizzard)
    addon.frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    addon.frame:SetBackdropColor(0.1, 0.1, 0.1, 0.85)  -- Темный полупрозрачный фон
    addon.frame:SetBackdropBorderColor(0.9, 0.8, 0.1)  -- Золотая рамка

    -- Заголовок с золотым текстом
    addon.title = addon.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    addon.title:SetPoint("TOP", 0, -15)
    addon.title:SetText("|cffffcc00Статистика персонажа|r")
    addon.title:SetShadowColor(0, 0, 0, 1)
    addon.title:SetShadowOffset(1, -1)

    -- Текстовые поля с улучшенным оформлением
    local CreateStatText = function(parent, anchor, yOffset)
        local text = parent:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med1")
        text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset or -10)
        text:SetJustifyH("LEFT")
        text:SetShadowColor(0, 0, 0, 0.8)
        text:SetShadowOffset(1, -1)
        return text
    end

    addon.healthText = CreateStatText(addon.frame, addon.title, -15)
    addon.powerText = CreateStatText(addon.frame, addon.healthText)
    addon.moneyText = CreateStatText(addon.frame, addon.powerText)

    -- Перемещение окна
    addon.frame:SetMovable(true)
    addon.frame:EnableMouse(true)
    addon.frame:RegisterForDrag("LeftButton")
    addon.frame:SetScript("OnDragStart", addon.frame.StartMoving)
    addon.frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SimpleStatsDB.point, _, _, SimpleStatsDB.x, SimpleStatsDB.y = self:GetPoint()
    end)

    -- Кнопка закрытия (стилизованная)
    addon.closeBtn = CreateFrame("Button", nil, addon.frame, "UIPanelCloseButton")
    addon.closeBtn:SetSize(28, 28)
    addon.closeBtn:SetPoint("TOPRIGHT", -5, -5)
    addon.closeBtn:SetScript("OnClick", function() addon.frame:Hide() end)

    -- Обновление статистики
    addon.UpdateStats = function()
        -- Здоровье (красный)
        local health, maxHealth = UnitHealth("player"), UnitHealthMax("player")
        addon.healthText:SetFormattedText("|cffff2020Здоровье:|r %d / %d (%.0f%%)", 
            health, maxHealth, health > 0 and (health/maxHealth)*100 or 0)

        -- Ресурс (синий/зеленый в зависимости от класса)
        local powerType = UnitPowerType("player")
        local powerColor = powerType == 0 and "|cff00a0ff" or "|cff20ff20"
        local powerNames = {"Мана", "Ярость", "Энергия", "Сила рун"}
        local power, maxPower = UnitPower("player"), UnitPowerMax("player")
        addon.powerText:SetFormattedText("%s%s:|r %d / %d", 
            powerColor, powerNames[powerType+1] or "Ресурс", power, maxPower)

        -- Деньги (золотой)
        local gold = floor(GetMoney() / 10000)
        local silver = floor((GetMoney() % 10000) / 100)
        local copper = GetMoney() % 100
          addon.moneyText:SetFormattedText("Деньги: %d|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t %d|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t %d|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t", 
        gold, silver, copper)
    end

    -- Регистрация событий
    local events = {
        "PLAYER_ENTERING_WORLD",
        "UNIT_HEALTH",
        "UNIT_POWER_UPDATE",
        "PLAYER_MONEY"
    }
    for _, event in ipairs(events) do
        addon.frame:RegisterEvent(event)
    end
    addon.frame:SetScript("OnEvent", addon.UpdateStats)
    
    -- Плавное обновление (0.5 сек)
    addon.frame:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer > 0.5 then
            addon.UpdateStats()
            self.timer = 0
        end
    end)

    -- Показать и обновить при загрузке
    addon.frame:Show()
    addon.UpdateStats()
end




-- Инициализация при загрузке аддона
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, name)
    if name == "SimpleStats" then
        addon.Init()
    end
end)




SLASH_SIMPLESTATS1 = "/ss"
SlashCmdList["SIMPLESTATS"] = function()
    if not addon.frame then
        addon.Init() -- Создаём фрейм, если его нет
    end
    
    if addon.frame:IsShown() then
        addon.frame:Hide()
    else
        addon.frame:Show()
        addon.UpdateStats()
    end
end
