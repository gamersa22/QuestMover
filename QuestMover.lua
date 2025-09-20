QuestMover = {}

QuestMover.name = "QuestMover"
QuestMover.version = 1
QuestMover.defaultCharacter = 
{	
	["offsetY"] = 325,
	["offsetX"] = 0,
	["useCharacterSettings"] = false,
}
QuestMover.default = {
	["accountWideProfile"] = QuestMover.defaultCharacter,
}

function QuestMover.GetSettings()--
	if QuestMover.charSavedVars.useCharacterSettings then
		return QuestMover.charSavedVars
	else
		return QuestMover.savedvars.accountWideProfile
	end
end
--local offsetX
function QuestMover.ApplyAnchor()
	ZO_FocusedQuestTrackerPanel:ClearAnchors()	
	ZO_FocusedQuestTrackerPanel:SetAnchor(9, GuiRoot, 0, QuestMover.GetSettings().offsetX, QuestMover.GetSettings().offsetY)	
end	
local ZoneStoryQuest =false
function QuestMover.ApplyGoldenAnchor()
	--normally has a Anchor with ANCHOR_CONSTRAINS_X on it so we remove it
	ZO_PromotionalEventTracker_TL:ClearAnchors()
	ZO_PromotionalEventTracker_TL:SetAnchor(BOTTOMRIGHT, ZO_ZoneStoryTracker, BOTTOMRIGHT,0,151)
end

local QuestTrackerInMenu = false
function QuestMover.Initialize()
	--Load up, those Saved Vars
	local serverName = GetWorldName()
	QuestMover.savedvars = ZO_SavedVars:NewAccountWide("QuestMoverSavedVariables", QuestMover.version, serverName, QuestMover.default)
	QuestMover.charSavedVars = ZO_SavedVars:NewCharacterIdSettings("QuestMoverSavedVariables",QuestMover.version, serverName, QuestMover.savedvars.accountWideProfile) 	
	QuestMover.ApplyAnchor() --move to saved position
	--The position of Golden Pursuit Resets when we come out of a menu this should fix it
	ZO_FocusedQuestTrackerPanelContainer:SetHandler("OnShow",function() ZoneStoryQuest=false QuestMover.ApplyGoldenAnchor() end)
	ZO_ZoneStoryTrackerContainer:SetHandler("OnShow",function()ZoneStoryQuest=true QuestMover.ApplyGoldenAnchor() end)
	QuestMover.ApplyGoldenAnchor()
	
    local LHAS = LibHarvensAddonSettings
    
    local options = {
        allowDefaults = true,
		allowRefresh = false,
		defaultsFunction = function()      
		d("QuestMover Reset")
        end,
    }
    
    local settings = LHAS:AddAddon("Quest Mover", options)
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
	
	local function addQT()
		if QuestTrackerInMenu then
			return
		end
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
		QuestMover.ApplyGoldenAnchor()
	end
	
	local function addonSelected(_, addonSettings)
		local addQT = addonSettings == settings
		if not addQT and QuestTrackerInMenu then	
			scene:RemoveFragment(ZONE_STORY_TRACKER_FRAGMENT)
			ZONE_STORY_TRACKER_FRAGMENT:Refresh()
			scene:RemoveFragment(FOCUSED_QUEST_TRACKER_FRAGMENT)
			FOCUSED_QUEST_TRACKER_FRAGMENT:Refresh()
			QuestTrackerInMenu = false
		end
	end
		
	CALLBACK_MANAGER:RegisterCallback("LibHarvensAddonSettings_AddonSelected", addonSelected)

	local button = {
        type = LHAS.ST_BUTTON,
        label = "Show Quest Tracker NOW",		
        buttonText = "Show",
        clickHandler = function(control, button)
			if not QuestTrackerInMenu then
				addQT()
			else
				addonSelected()
			end
        end,
    }
	settings:AddSetting(button)
	
	--Slider to Adjust Quest Traker's Y Position
    local slider = {
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
        --default = 100,
        min = 0,
        max = 900,
        step = 5
    }
    settings:AddSetting(slider)
	--X value
	 local slider = {
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
        --default = 100,
        min = -1650,
        max = 0,
        step = 5
    }
    settings:AddSetting(slider)
	local checkbox = {
		type = LHAS.ST_BUTTON,
        label = "Report a Bug",
        tooltip = "Open a thread to report bugs specifically with the console version of Quest Mover. Please check to make sure the issue hasn't been reported yet.",
        buttonText = "Open URL",
        clickHandler = function(control, button)
			RequestOpenUnsafeURL("https://www.esoui.com/forums/showthread.php?t=11316")
		end,
    }
    settings:AddSetting(checkbox)
end
function QuestMover.OnAddOnLoaded(event, addonName)
	if addonName == QuestMover.name then
		QuestMover.Initialize()		
		EVENT_MANAGER:UnregisterForEvent(QuestMover.name, EVENT_ADD_ON_LOADED)
	end
end
 
EVENT_MANAGER:RegisterForEvent(QuestMover.name, EVENT_ADD_ON_LOADED, QuestMover.OnAddOnLoaded)

--HUGE thanks to Dolgubon for helping me working out on how to do this
