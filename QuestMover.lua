QuestMover = {}

QuestMover.name = "QuestMover"
QuestMover.VisualName = "Quest Mover"
QuestMover.version = 1
QuestMover.defaultCharacter = 
{	
	["offsetY"] = 325,
	["offsetX"] = 0,
	["scale"] = 1,
	["useCharacterSettings"] = false,
}
QuestMover.default = {
	["accountWideProfile"] = QuestMover.defaultCharacter,
}

local ZoneStoryQuest = false
--local scaleOffset = 0 --scale affects the amount we need to offset Y need to use for golden and story
local QuestTrackerInMenu = false
local GoldenAnchorCorrect = true --is the anchor in the right spot
function QuestMover.GetSettings()
	if QuestMover.charSavedVars or QuestMover.savedvars then
		if QuestMover.charSavedVars.useCharacterSettings then
			return QuestMover.charSavedVars
		else
			return QuestMover.savedvars.accountWideProfile
		end
	else
		return QuestMover.defaultCharacter 
	end
end
local scaleOffset = {
	Quest = { x = 0, y = 0 },
	Zone = { x = 0, y = 0 },
	Gold = { x = 0, y = 0 },
	House = { x = 0, y = 0 },
}
local function getScaleOffset()
	local questH = ZO_FocusedQuestTrackerPanelContainerQuestContainer:GetHeight()
	local questW = ZO_FocusedQuestTrackerPanelContainerQuestContainer:GetWidth()
	local scale = QuestMover.GetSettings().scale
	scaleOffset.Quest.x = (questW * scale) - questW
	scaleOffset.Quest.y = (questH * scale) - questH
	local zoneH = ZO_ZoneStoryTrackerContainer:GetHeight()
	local zoneW = ZO_ZoneStoryTrackerContainer:GetWidth()
	scaleOffset.Zone.x = (zoneW * scale) - zoneW
	scaleOffset.Zone.y = (zoneH * scale) - zoneH
	local gold = ZO_PromotionalEventTracker_TLContainer or ZO_PromotionalEventTracker_TL
	local goldH = gold:GetHeight()
	local goldW = gold:GetWidth()
	scaleOffset.Gold.x = (goldW * scale) - goldW
	scaleOffset.Gold.y = (goldH * scale) - goldH
	local house = ZO_HouseInformationTrackerTopLevelContainer or ZO_HouseInformationTrackerTopLevel
	if house then
		local houseH = house:GetHeight()
		local houseW = house:GetWidth()
		scaleOffset.House.x = (houseW * scale) - houseW
		scaleOffset.House.y = (houseH * scale) - houseH
	end
end

function QuestMover.ApplyAnchor()
	ZO_FocusedQuestTrackerPanel:ClearAnchors()	
	ZO_FocusedQuestTrackerPanel:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, QuestMover.GetSettings().offsetX, QuestMover.GetSettings().offsetY)	
	if GoldenAnchorCorrect then
		GoldenAnchorCorrect = false
		EVENT_MANAGER:RegisterForEvent("QuestMover", EVENT_RETICLE_HIDDEN_UPDATE, function()
			EVENT_MANAGER:UnregisterForEvent("QuestMover", EVENT_RETICLE_HIDDEN_UPDATE)
			PROMOTIONAL_EVENT_TRACKER:RefreshAnchors()
			if HOUSE_INFORMATION_TRACKER then
				HOUSE_INFORMATION_TRACKER:RefreshAnchors()
			end
			GoldenAnchorCorrect = true
		end)
	end
end	
local anchor1 = ZO_Anchor:New(TOPRIGHT, ZO_FocusedQuestTrackerPanelContainerQuestContainer, BOTTOMRIGHT,15 + -ZO_FocusedQuestTrackerPanel:GetWidth(), 0)
local anchor2 = ZO_Anchor:New(TOPRIGHT, ZO_FocusedQuestTrackerPanelContainerQuestContainer, TOPRIGHT, 0,0)
function ZONE_STORY_TRACKER:GetPrimaryAnchor()
    if FOCUSED_QUEST_TRACKER_FRAGMENT:IsShowing() then
		return anchor1		
    else
	anchor2:SetOffsets(58-(58*QuestMover.GetSettings().scale),-60-(-60*QuestMover.GetSettings().scale))
		return anchor2
    end
end
-- Anchor Golden (Promo) to Zone *container* so we use actual content bounds; TL can differ.
local GOLDEN_ZONE_GAP = 4
local GoldenPrimaryAnchor = ZO_Anchor:New(TOPLEFT, ZO_ZoneStoryTrackerContainer, BOTTOMLEFT, 0, 0)
function PROMOTIONAL_EVENT_TRACKER:GetPrimaryAnchor()
	getScaleOffset()
	local offsetY = GOLDEN_ZONE_GAP + scaleOffset.Zone.y
	GoldenPrimaryAnchor:SetOffsets(0, offsetY)
	return GoldenPrimaryAnchor
end
local GoldenSecondAnchor = ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X)
function PROMOTIONAL_EVENT_TRACKER:GetSecondaryAnchor()
	GoldenSecondAnchor:SetOffsets(-15 + QuestMover.GetSettings().offsetX, 0)
	return GoldenSecondAnchor
end

-- House Info anchors below Golden (Promo); use Gold container for layout.
local HOUSE_GOLDEN_GAP = 4
local HousePrimaryAnchor = ZO_Anchor:New(TOPLEFT, ZO_PromotionalEventTracker_TLContainer or ZO_PromotionalEventTracker_TL, BOTTOMLEFT, 0, 0)
local HouseSecondaryAnchor = ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X)
if HOUSE_INFORMATION_TRACKER then
	function HOUSE_INFORMATION_TRACKER:GetPrimaryAnchor()
		getScaleOffset()
		local offsetY = HOUSE_GOLDEN_GAP + scaleOffset.Gold.y
		HousePrimaryAnchor:SetOffsets(0, offsetY)
		return HousePrimaryAnchor
	end
	function HOUSE_INFORMATION_TRACKER:GetSecondaryAnchor()
		HouseSecondaryAnchor:SetOffsets(-15 + QuestMover.GetSettings().offsetX, 0)
		return HouseSecondaryAnchor
	end
end

function QuestMover.enableInheritScaleRecursive(control)
    if not control then return end
    if not control:GetInheritsScale() then control:SetInheritScale(true) end
    local numChildren = control:GetNumChildren()
    for i = 1, numChildren do
        local child = control:GetChild(i)
        if child then
            QuestMover.enableInheritScaleRecursive(child)
        end
    end
end

---Applies scale transform to Quest Tracker (ty DakJaniels)
function QuestMover.applyScale(controlToScale, scale)
    if not controlToScale then return end
    local appliedScale = scale or 1
    QuestMover.enableInheritScaleRecursive(controlToScale);
    controlToScale:SetTransformScale(appliedScale);
end
function QuestMover.applyScales()
	QuestMover.applyScale(ZO_FocusedQuestTrackerPanel, QuestMover.GetSettings().scale)
	QuestMover.applyScale(ZO_ZoneStoryTracker, QuestMover.GetSettings().scale)
	QuestMover.applyScale(ZO_PromotionalEventTracker_TL, QuestMover.GetSettings().scale)
	if ZO_HouseInformationTrackerTopLevel then
		QuestMover.applyScale(ZO_HouseInformationTrackerTopLevel, QuestMover.GetSettings().scale)
	end
end

local function CreateSettingMenu()
  local LHAS = LibHarvensAddonSettings
	--/script function ttt() local iii = 0 EVENT_MANAGER:RegisterForEvent("Tesstinggtestttt", EVENT_RETICLE_HIDDEN_UPDATE , function() iii=iii+1 d("EVENT_RETICLE_HIDDEN_UPDATE "..iii) end ) end ttt()
    local options = {
        allowDefaults = true,
		allowRefresh = false,
		defaultsFunction = function()      
		d("QuestMover Reset")
        end,
    }
    
    local settings = LHAS:AddAddon(QuestMover.VisualName, options)
    if not settings then
        return
    end
	--On/Off for Character Settings
    local checkbox = {
        type = LHAS.ST_CHECKBOX,
        label = "Use character settings", 
		--default = false, 
        setFunction = function(value)
           QuestMover.charSavedVars.useCharacterSettings = value
        end,
        getFunction = function()
            return QuestMover.charSavedVars.useCharacterSettings
        end,
    }
    settings:AddSetting(checkbox)
	local scene
	local function addQT()
		if QuestTrackerInMenu then return end
		scene = SCENE_MANAGER:GetCurrentScene()					
		if ZoneStoryQuest then
			scene:AddFragment(ZONE_STORY_TRACKER_FRAGMENT)
			ZONE_STORY_TRACKER_FRAGMENT:Refresh()
			ZO_ZoneStoryTrackerContainer:SetHidden(false)
		else
			scene:AddFragment(FOCUSED_QUEST_TRACKER_FRAGMENT)
			FOCUSED_QUEST_TRACKER_FRAGMENT:Refresh()
			ZO_FocusedQuestTrackerPanelContainer:SetHidden(false)
		end
		QuestTrackerInMenu = true	
		--QuestMover.ApplyGoldenAnchor()
	end
	
	local function addonSelected(_, addonSettings)
		if QuestTrackerInMenu then	
			scene:RemoveFragment(ZONE_STORY_TRACKER_FRAGMENT)
			ZONE_STORY_TRACKER_FRAGMENT:Refresh()
			scene:RemoveFragment(FOCUSED_QUEST_TRACKER_FRAGMENT)
			FOCUSED_QUEST_TRACKER_FRAGMENT:Refresh()
			QuestTrackerInMenu = false
		end
	end	
	CALLBACK_MANAGER:RegisterCallback("LibHarvensAddonSettings_AddonSelected", addonSelected)

	settings:AddSetting({
        type = LHAS.ST_BUTTON,
        label = "Show Quest Tracker",		
        buttonText = "Show",
        clickHandler = function(control, button)
			if not QuestTrackerInMenu then
				addQT()
			else
				addonSelected()
			end
        end,
    })	
	local maxX, maxY = GuiRoot:GetDimensions()
	maxX = math.floor(maxX)
	maxY = math.floor(maxY)
	--Slider to Adjust Quest Traker's X Position
	 settings:AddSetting({
        type = LHAS.ST_SLIDER,
        label = "Left <- -> Right",
		tooltip = "Default is 0",
        setFunction = function(value)
            QuestMover.GetSettings().offsetX = value
			QuestMover.ApplyAnchor()
        end,
        getFunction = function()
            return QuestMover.GetSettings().offsetX
        end,
        default = QuestMover.defaultCharacter.offsetX,
        min = -maxX,
        max = 100,
        step = 5
    })
	--Slider to Adjust Quest Traker's Y Position
    settings:AddSetting({
        type = LHAS.ST_SLIDER,
        label = "Up <- -> Down",
		tooltip = "Default: 325 \nBase Game: 100",
        setFunction = function(value)
            QuestMover.GetSettings().offsetY = value
			QuestMover.ApplyAnchor()
        end,
        getFunction = function()
            return QuestMover.GetSettings().offsetY
        end,
        default = QuestMover.defaultCharacter.offsetY,
        min = -50,
        max = maxY,
        step = 5
    })
	--Slider to Adjust Quest Traker's Scale
    settings:AddSetting({
        type = LHAS.ST_SLIDER,
        label = "Small <- -> Large",
		tooltip = "Default: 1",
        setFunction = function(value)
            QuestMover.GetSettings().scale = value
			QuestMover.applyScales()
			PROMOTIONAL_EVENT_TRACKER:RefreshAnchors()
			if HOUSE_INFORMATION_TRACKER then
				HOUSE_INFORMATION_TRACKER:RefreshAnchors()
			end
        end,
        getFunction = function()
            return QuestMover.GetSettings().scale
        end,
        default = QuestMover.defaultCharacter.scale,
        min = 0.5,
        max = 1.5,
        step = 0.05
    })
	settings:AddSetting({
        type = LHAS.ST_BUTTON,
        label = "Submit Feedback / Request",
		tooltip = "link to a form where you can leave feedback or even leave a request",
		buttonText = "Open URL",
		clickHandler = function(control, button)
			RequestOpenUnsafeURL("https://docs.google.com/forms/d/e/1FAIpQLScYWtcIJmjn0ZUrjsvpB5rwA5AlsLvasHUIcKqzIYcogo9vjQ/viewform?usp=pp_url&entry.550722213="..QuestMover.VisualName)
		end,
	})
end

local function RegisterEvents()
	CALLBACK_MANAGER:RegisterCallback("QuestTrackerUpdatedOnScreen", function()
		zo_callLater(function()
			PROMOTIONAL_EVENT_TRACKER:RefreshAnchors()
			if HOUSE_INFORMATION_TRACKER then
				HOUSE_INFORMATION_TRACKER:RefreshAnchors()
			end
		end, 10)
	end)
end


function QuestMover.Initialize()
	--Load up, those Saved Vars
	local serverName = GetWorldName()
	QuestMover.savedvars = ZO_SavedVars:NewAccountWide("QuestMoverSavedVariables", QuestMover.version, serverName, QuestMover.default)
	QuestMover.charSavedVars = ZO_SavedVars:NewCharacterIdSettings("QuestMoverSavedVariables",QuestMover.version, serverName, QuestMover.savedvars.accountWideProfile) 	
	
	QuestMover.applyScales()
	--move to saved position
	QuestMover.ApplyAnchor() 	

	RegisterEvents()
	
	CreateSettingMenu()
	
end
function QuestMover.OnAddOnLoaded(event, addonName)
	if addonName == QuestMover.name then
		QuestMover.Initialize()		
		EVENT_MANAGER:UnregisterForEvent(QuestMover.name, EVENT_ADD_ON_LOADED)
	end
end
 
EVENT_MANAGER:RegisterForEvent(QuestMover.name, EVENT_ADD_ON_LOADED, QuestMover.OnAddOnLoaded)

--HUGE thanks to Dolgubon for helping me working out on how to do this
