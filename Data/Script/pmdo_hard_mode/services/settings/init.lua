require 'origin.services.baseservice'

local HardModeSettings = Class('HardModeSettings', BaseService)

function HardModeSettings:initialize()
        self.settingsList = {
            "UpgradeMovesets",
            "MovesetLevelShift",
            "AllowEggMovesAtLowLevel",
            "ChangeMovesEveryFloor",
            "IncreaseAISmartness",
            "AllMovesEnabled",
            "IncreaseStats",
            "DungeonEffects",
            --"PermanentLevelCap"
        }
        self.settingsData = {
            UpgradeMovesets = "Upgrade Movesets",
            MovesetLevelShift = "Moveset Level Bonus",
            AllowEggMovesAtLowLevel = "Low Level Egg Moves",
            ChangeMovesEveryFloor = "Floor Only Movesets",
            IncreaseAISmartness = "Smarter Enemies",
            AllMovesEnabled = "All Moves Enabled",
            IncreaseStats = "Stat Increases",
            DungeonEffects = "Floor Weathers",
            --PermanentLevelCap = "Permanent Level Cap"
        }

end

function HardModeSettings:OnAddMenu(menu)
    if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then return end
    if menu:HasLabel() and menu.Label == RogueEssence.Menu.MenuLabel.SETTINGS_MENU then
        local page = menu:AddPage("hard_mode", "Hard Mode")
        if not HARD_MODE.Settings then HARD_MODE.loadSettings() end
        local options_boolean = {"Off", "On"}
        local options_level = {"Off", "+5", "+10", "+15", "+20", "+25", "+30", "+35", "+40", "+45", "+50", "+55", "+60", "+65", "+70", "+75", "+80", "+85", "+90", "+95", "+100"}
        local saveFunction = function(setting_obj, setting_name)
            if menu.InGame then
                SV.Hard_Mode_Settings[setting_name] = setting_obj.CurrentChoice
            else
                HARD_MODE.Settings[setting_name] = setting_obj.CurrentChoice
            end
        end

        for _, setting_key in ipairs(self.settingsList) do
            local options = options_boolean
            if(setting_key == "MovesetLevelShift") then
                options = options_level
            end
            page:AddSetting(self.settingsData[setting_key], options, HARD_MODE.Settings[setting_key], function(s) saveFunction(s, setting_key) end)
        end
    end
end

function HardModeSettings:OnSaveLoad()
    if not SV.Hard_Mode_Settings then
        HARD_MODE.loadDefaultSettings()
    end
    if HARD_MODE.Settings then
        for _, val in ipairs(self.settingsList) do
            SV.Hard_Mode_Settings[val] = HARD_MODE.Settings[val]
        end
    end
    HARD_MODE.Settings = nil
end

function HardModeSettings:Subscribe(med)
    med:Subscribe("HardModeSettings", EngineServiceEvents.AddMenu,       function(_, args) self:OnAddMenu(args[0]) end )
    med:Subscribe("HardModeSettings", EngineServiceEvents.LoadSavedData, function(_)       self:OnSaveLoad() end )
end

SCRIPT:AddService("HardModeSettings", HardModeSettings:new())
return HardModeSettings