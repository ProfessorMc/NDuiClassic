local _, ns = ...
local B, C, L, DB = unpack(ns)
local M = B:GetModule("Misc")

local wipe, gmatch, tinsert, ipairs, pairs = wipe, gmatch, tinsert, ipairs, pairs
local tonumber, tostring, max = tonumber, tostring, max
local cr, cg, cb = DB.r, DB.g, DB.b

local hasOtherAddon

local function SetCharacterStats(statsTable, category)
	if category == "PLAYERSTAT_BASE_STATS" then
		PaperDollFrame_SetStat(statsTable[1], 1)
		PaperDollFrame_SetStat(statsTable[2], 2)
		PaperDollFrame_SetStat(statsTable[3], 3)
		PaperDollFrame_SetStat(statsTable[4], 4)
		PaperDollFrame_SetStat(statsTable[5], 5)
		PaperDollFrame_SetArmor(statsTable[6])
	elseif category == "PLAYERSTAT_DEFENSES" then
		PaperDollFrame_SetArmor(statsTable[1])
		PaperDollFrame_SetDefense(statsTable[2])
		PaperDollFrame_SetDodge(statsTable[3])
		PaperDollFrame_SetParry(statsTable[4])
		PaperDollFrame_SetBlock(statsTable[5])
		PaperDollFrame_SetResilience(statsTable[6])
	elseif category == "PLAYERSTAT_MELEE_COMBAT" then
		PaperDollFrame_SetDamage(statsTable[1])
		statsTable[1]:SetScript("OnEnter", CharacterDamageFrame_OnEnter)
		PaperDollFrame_SetAttackSpeed(statsTable[2])
		PaperDollFrame_SetAttackPower(statsTable[3])
		PaperDollFrame_SetRating(statsTable[4], CR_HIT_MELEE)
		PaperDollFrame_SetMeleeCritChance(statsTable[5])
		PaperDollFrame_SetExpertise(statsTable[6])
	elseif category == "PLAYERSTAT_SPELL_COMBAT" then
		PaperDollFrame_SetSpellBonusDamage(statsTable[1])
		statsTable[1]:SetScript("OnEnter", CharacterSpellBonusDamage_OnEnter)
		PaperDollFrame_SetSpellBonusHealing(statsTable[2])
		PaperDollFrame_SetRating(statsTable[3], CR_HIT_SPELL)
		PaperDollFrame_SetSpellCritChance(statsTable[4])
		statsTable[4]:SetScript("OnEnter", CharacterSpellCritChance_OnEnter)
		PaperDollFrame_SetSpellHaste(statsTable[5])
		PaperDollFrame_SetManaRegen(statsTable[6])
	elseif category == "PLAYERSTAT_RANGED_COMBAT" then
		PaperDollFrame_SetRangedDamage(statsTable[1])
		statsTable[1]:SetScript("OnEnter", CharacterRangedDamageFrame_OnEnter)
		PaperDollFrame_SetRangedAttackSpeed(statsTable[2])
		PaperDollFrame_SetRangedAttackPower(statsTable[3])
		PaperDollFrame_SetRating(statsTable[4], CR_HIT_RANGED)
		PaperDollFrame_SetRangedCritChance(statsTable[5])
	end
end

local orderList = {}
local function BuildListFromValue()
	wipe(orderList)

	for number in gmatch(C.db["Misc"]["StatOrder"], "%d") do
		tinsert(orderList, tonumber(number))
	end
end

local categoryFrames = {}
local framesToSort = {}
local function UpdateCategoriesOrder()
	wipe(framesToSort)

	for order, index in ipairs(orderList) do
		tinsert(framesToSort, categoryFrames[index])
	end
end

local function UpdateCategoriesAnchor()
	UpdateCategoriesOrder()

	local prev
	for _, frame in pairs(framesToSort) do
		if not prev then
			frame:SetPoint("TOP", 0, -70)
		else
			frame:SetPoint("TOP", prev, "BOTTOM")
		end
		prev = frame
	end
end

local function BuildValueFromList()
	local str = ""
	for _, index in ipairs(orderList) do
		str = str..tostring(index)
	end
	C.db["Misc"]["StatOrder"] = str

	UpdateCategoriesAnchor()
end

local function Arrow_GoUp(bu)
	local frameIndex = bu.__owner.index

	BuildListFromValue()

	for order, index in pairs(orderList) do
		if index == frameIndex then
			if order > 1 then
				local oldIndex = orderList[order-1]
				orderList[order-1] = frameIndex
				orderList[order] = oldIndex

				BuildValueFromList()
			end
			break
		end
	end
end

local function Arrow_GoDown(bu)
	local frameIndex = bu.__owner.index

	BuildListFromValue()

	for order, index in pairs(orderList) do
		if index == frameIndex then
			if order < 5 then
				local oldIndex = orderList[order+1]
				orderList[order+1] = frameIndex
				orderList[order] = oldIndex

				BuildValueFromList()
			end
			break
		end
	end
end

local function CreateStatRow(parent, index)
	local frame = CreateFrame("Frame", "$parentRow"..index, parent, "StatFrameTemplate")
	frame:SetWidth(180)
	frame:SetPoint("TOP", parent.header, "BOTTOM", 0, -2 - (index-1)*16)
	local background = frame:CreateTexture(nil, "BACKGROUND")
	background:SetAtlas("UI-Character-Info-Line-Bounce", true)
	background:SetAlpha(.3)
	background:SetPoint("CENTER")
	background:SetShown(index%2 == 0)
	frame.background = background

	return frame
end

local function CreateHeaderArrow(parent, direct, func)
	local onLeft = direct == "LEFT"
	local xOffset = onLeft and 10 or -10
	local arrowDirec = onLeft and "up" or "down"

	local bu = CreateFrame("Button", nil, parent)
	bu:SetPoint(direct, parent.header, xOffset, 0)
	local tex = bu:CreateTexture()
	tex:SetAllPoints()
	B.SetupArrow(tex, arrowDirec)
	bu.__texture = tex
	bu:SetScript("OnEnter", B.Texture_OnEnter)
	bu:SetScript("OnLeave", B.Texture_OnLeave)

	bu:SetSize(18, 18)
	bu.__owner = parent
	bu:SetScript("OnClick", func)
end

local function CreatePlayerILvl(parent, category)
	local frame = CreateFrame("Frame", "NDuiStatCategoryIlvl", parent)
	frame:SetWidth(200)
	frame:SetHeight(42 + 16)
	frame:SetPoint("TOP")

	local header = CreateFrame("Frame", "$parentHeader", frame, "CharacterStatFrameCategoryTemplate")
	header:SetPoint("TOP", 0, 10)
	header.Background:Hide()
	header.Title:SetText(category)
	header.Title:SetTextColor(cr, cg, cb)
	frame.header = header

	local line = frame:CreateTexture(nil, "ARTWORK")
	line:SetSize(180, C.mult)
	line:SetPoint("BOTTOM", header, 0, 5)
	line:SetColorTexture(1, 1, 1, .25)

	local iLvlFrame = CreateStatRow(frame, 1)
	iLvlFrame:SetHeight(30)
	iLvlFrame.background:Show()
	iLvlFrame.background:SetAtlas("UI-Character-Info-ItemLevel-Bounce", true)

	M.PlayerILvl = B.CreateFS(iLvlFrame, 20)
end

local function GetItemSlotLevel(unit, index)
	local level
	local itemLink = GetInventoryItemLink(unit, index)
	if itemLink then
		level = select(4, GetItemInfo(itemLink))
	end
	return tonumber(level) or 0
end

local function GetILvlTextColor(level)
	if level >= 150 then
		return 1, .5, 0
	elseif level >= 115 then
		return .63, .2, .93
	elseif level >= 80 then
		return 0, .43, .87
	elseif level >= 45 then
		return .12, 1, 0
	else
		return 1, 1, 1
	end
end

function M:UpdateUnitILvl(unit, text)
	if not text then return end

	local total, level = 0
	for index = 1, 15 do
		if index ~= 4 then
			level = GetItemSlotLevel(unit, index)
			if level > 0 then
				total = total + level
			end
		end
	end

	local mainhand = GetItemSlotLevel(unit, 16)
	local offhand = GetItemSlotLevel(unit, 17)
	local ranged = GetItemSlotLevel(unit, 18)

	--[[
 		Note: We have to unify iLvl with others who use MerInspect,
		 although it seems incorrect for Hunter with two melee weapons.
	]]
	if mainhand > 0 and offhand > 0 then
		total = total + mainhand + offhand
	elseif offhand > 0 and ranged > 0 then
		total = total + offhand + ranged
	else
		total = total + max(mainhand, offhand, ranged) * 2
	end

	local average = B:Round(total/16, 1)
	text:SetText(average)
	text:SetTextColor(GetILvlTextColor(average))
end

function M:UpdatePlayerILvl()
	M:UpdateUnitILvl("player", M.PlayerILvl)
end

local function CreateStatHeader(parent, index, category)
	local maxLines = index == 5 and 5 or 6
	local frame = CreateFrame("Frame", "NDuiStatCategory"..index, parent)
	frame:SetWidth(200)
	frame:SetHeight(42 + maxLines*16)
	frame.index = index
	tinsert(categoryFrames, frame)

	local header = CreateFrame("Frame", "$parentHeader", frame, "CharacterStatFrameCategoryTemplate")
	header:SetPoint("TOP")
	header.Background:Hide()
	header.Title:SetText(_G[category])
	header.Title:SetTextColor(cr, cg, cb)
	frame.header = header

	CreateHeaderArrow(frame, "LEFT", Arrow_GoUp)
	CreateHeaderArrow(frame, "RIGHT", Arrow_GoDown)

	local line = frame:CreateTexture(nil, "ARTWORK")
	line:SetSize(180, C.mult)
	line:SetPoint("BOTTOM", header, 0, 5)
	line:SetColorTexture(1, 1, 1, .25)

	local statsTable = {}
	for i = 1, maxLines do
		statsTable[i] = CreateStatRow(frame, i)
	end
	SetCharacterStats(statsTable, category)
	frame.category = category
	frame.statsTable = statsTable

	return frame
end

local function ToggleMagicRes()
	if C.db["Misc"]["StatExpand"] then
		CharacterResistanceFrame:ClearAllPoints()
		CharacterResistanceFrame:SetPoint("TOPLEFT", M.StatPanel2, 28, -25)
		CharacterResistanceFrame:SetParent(M.StatPanel2)
		if not hasOtherAddon then CharacterModelFrame:SetSize(231, 320) end -- size in retail

		for i = 1, 5 do
			local bu = _G["MagicResFrame"..i]
			if i > 1 then
				bu:ClearAllPoints()
				bu:SetPoint("LEFT", _G["MagicResFrame"..(i-1)], "RIGHT", 3, 0)
			end
		end
	else
		CharacterResistanceFrame:ClearAllPoints()
		CharacterResistanceFrame:SetPoint("TOPRIGHT", PaperDollFrame, "TOPLEFT", 297, -77)
		CharacterResistanceFrame:SetParent(PaperDollFrame)
		CharacterModelFrame:SetSize(233, 224)

		for i = 1, 5 do
			local bu = _G["MagicResFrame"..i]
			if i > 1 then
				bu:ClearAllPoints()
				bu:SetPoint("TOP", _G["MagicResFrame"..(i-1)], "BOTTOM", 0, -3)
			end
		end
	end
end

local function UpdateStats()
	if not (M.StatPanel2 and M.StatPanel2:IsShown()) then return end

	for _, frame in pairs(categoryFrames) do
		SetCharacterStats(frame.statsTable, frame.category)
	end
end

local function ToggleStatPanel(texture)
	if C.db["Misc"]["StatExpand"] then
		B.SetupArrow(texture, "left")
		CharacterAttributesFrame:Hide()
		M.StatPanel2:Show()
	else
		B.SetupArrow(texture, "right")
		CharacterAttributesFrame:SetShown(not hasOtherAddon)
		M.StatPanel2:Hide()
	end
	ToggleMagicRes()
end

local function ExpandCharacterFrame(expand)
	CharacterFrame:SetWidth(expand and 584 or 384)
end

function M:CharacterStatePanel()
	if not C.db["Skins"]["BlizzardSkins"] then return end   -- disable if skins off, needs review

	hasOtherAddon = IsAddOnLoaded("CharacterStatsTBC")

	local statPanel = CreateFrame("Frame", "NDuiStatPanel", PaperDollFrame)
	statPanel:SetSize(200, 422)
	statPanel:SetPoint("TOPRIGHT", PaperDollFrame, "TOPRIGHT", -35, -16)
	M.StatPanel2 = statPanel

	local scrollFrame = CreateFrame("ScrollFrame", nil, statPanel, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 0, -60)
	scrollFrame:SetPoint("BOTTOMRIGHT", 0, 2)
	scrollFrame.ScrollBar:Hide()
	scrollFrame.ScrollBar.Show = B.Dummy
	local stat = CreateFrame("Frame", nil, scrollFrame)
	stat:SetSize(200, 1)
	statPanel.child = stat
	scrollFrame:SetScrollChild(stat)
	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local scrollBar = self.ScrollBar
		local step = delta*25
		if IsShiftKeyDown() then
			step = step*6
		end
		scrollBar:SetValue(scrollBar:GetValue() - step)
	end)

	-- Player iLvl
	CreatePlayerILvl(stat, STAT_AVERAGE_ITEM_LEVEL)
	hooksecurefunc("PaperDollFrame_UpdateStats", M.UpdatePlayerILvl)

	-- Player stats
	local categories = {
		"PLAYERSTAT_BASE_STATS",
		"PLAYERSTAT_DEFENSES",
		"PLAYERSTAT_MELEE_COMBAT",
		"PLAYERSTAT_SPELL_COMBAT",
		"PLAYERSTAT_RANGED_COMBAT",
	}
	for index, category in pairs(categories) do
		CreateStatHeader(stat, index, category)
	end

	-- Init
	BuildListFromValue()
	BuildValueFromList()
	CharacterNameFrame:ClearAllPoints()
	CharacterNameFrame:SetPoint("TOPLEFT", CharacterFrame, 130, -20)

	-- Update data
	hooksecurefunc("ToggleCharacter", UpdateStats)
	PaperDollFrame:HookScript("OnEvent", UpdateStats)

	-- Expand button
	local bu = CreateFrame("Button", nil, PaperDollFrame)
	bu:SetPoint("RIGHT", CharacterFrameCloseButton, "LEFT", -3, 0)
	B.ReskinArrow(bu, "right")

	bu:SetScript("OnClick", function(self)
		C.db["Misc"]["StatExpand"] = not C.db["Misc"]["StatExpand"]
		ExpandCharacterFrame(C.db["Misc"]["StatExpand"])
		ToggleStatPanel(self.__texture)
	end)

	ToggleStatPanel(bu.__texture)

	PaperDollFrame:HookScript("OnHide", function()
		ExpandCharacterFrame()
	end)

	PaperDollFrame:HookScript("OnShow", function()
		ExpandCharacterFrame(C.db["Misc"]["StatExpand"])
	end)
end

M:RegisterMisc("StatPanel", M.CharacterStatePanel)