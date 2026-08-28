--- @alias referenceSet table<string,boolean> a generic set whose keys are strings and whose values are always ``true``
--- @alias categoryType "level"|"tm"|"tutor"|"egg" types of move pools
--- @alias slotType "stab"|"coverage"|"damage"|"status" types of slots that a move can be inserted into
--- @alias synergyEntry {ApplySynergy:referenceSet, RequestSynergy:referenceSet, Type:string} a table describing the state of a possible synergy in a moveset
--- @alias moveset_entry {ID:string, Type:string, Category:slotType[], Weight:integer, ApplySynergy: string[], RequestSynergy: string[]} a table describing a move and all the properties that may influence moveset generation choices
--- @alias moveset_supertable {stab:moveset_entry[],coverage:moveset_entry[],damage:moveset_entry[],status:moveset_entry[]} a table containing lists of moveset_entries, divided by slotType
--- @alias moveset_list table<string,{cat:slotType[], tables:categoryType[], value:table}> a backwards reference table that links a move to the supertables and subtables that contain it

HARD_MODE = {}
HARD_MODE.globals = {}
HARD_MODE.globals.ctypes = {}
HARD_MODE.globals.ctypes.Integer = luanet.import_type('System.Int32')
HARD_MODE.globals.ctypes.ScriptGenStep = luanet.import_type('RogueEssence.LevelGen.ScriptGenStep`1')
HARD_MODE.globals.ctypes.MapIDState = luanet.import_type("RogueEssence.Dungeon.MapIDState")
HARD_MODE.globals.ctypes.StatusPowerEvent = luanet.import_type('PMDC.Dungeon.StatusPowerEvent')
HARD_MODE.globals.ctypes.StatusStackDifferentEvent = luanet.import_type('PMDC.Dungeon.StatusStackDifferentEvent')
HARD_MODE.globals.ctypes.MajorStatusPowerEvent = luanet.import_type('PMDC.Dungeon.StatusPowerEvent')
HARD_MODE.globals.ctypes.WeatherNeededEvent = luanet.import_type('PMDC.Dungeon.WeatherNeededEvent')
HARD_MODE.globals.ctypes.ChargeOrReleaseEvent = luanet.import_type('PMDC.Dungeon.ChargeOrReleaseEvent')
HARD_MODE.globals.ctypes.GiveMapStatusEvent = luanet.import_type('PMDC.Dungeon.GiveMapStatusEvent')
HARD_MODE.globals.ctypes.StatusBattleEvent = luanet.import_type('PMDC.Dungeon.StatusBattleEvent')
HARD_MODE.globals.ctypes.AdditionalEvent = luanet.import_type('PMDC.Dungeon.AdditionalEvent')
HARD_MODE.globals.ctypes.AddContextStateEvent = luanet.import_type('PMDC.Dungeon.AddContextStateEvent')
HARD_MODE.globals.ctypes.MajorStatusState = luanet.import_type('PMDC.Dungeon.MajorStatusState')
HARD_MODE.globals.ctypes.SleepAttack = luanet.import_type('PMDC.Dungeon.SleepAttack')
HARD_MODE.globals.dataIndices = {}
HARD_MODE.globals.dataIndices.Elements = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Element]
HARD_MODE.globals.dataIndices.Zones = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Zone]


local pmdo_hard_mode_endDungeonDay = COMMON.EndDungeonDay
function COMMON.EndDungeonDay(result, zoneId, structureId, mapId, entryId)
    SV.hard_mode_processed.Location = {Zone = "", Segment = -1, Floor = -1, DiffValue = -1, LevelCap = false}
    pmdo_hard_mode_endDungeonDay(result, zoneId, structureId, mapId, entryId)
end

HARD_MODE.AIUpgrade = {
    item_finder = "item_finder_smart",        -- smart action pick, keeps distance
    loot_guard = "loot_guard_smart",          -- smart action pick
    patrol = "patrol_smart",                  -- smart action pick, wont disturb
    retreater_itemless = "retreater",         -- vanilla
    retreater = "retreater_smart",            -- smart action pick, keeps distance
    thief = "thief_smart",                    -- smart action pick while keeping distance
    tit_for_that = "tit_for_that_smart",      -- smart action, can grab items after aggro
    turret = "turret_smart",                  -- smart action pick, wont disturb
    wander_dumb_itemless = "wander_dumb",     -- vanilla
    wander_dumb = "wander_normal",            -- vanilla
    wander_normal_itemless = "wander_normal", -- vanilla
    wander_normal = "wander_smart",           -- vanilla
    wander_smart = "wander_boss",             -- wander Smart but it avoids traps and allies and knows matchups
    weird_tree = "weird_tree_smart"           -- smart action pick when approached
}

HARD_MODE.FloorWeathers = {
	-- weather chance: 4*difficulty coefficient
	bug = nil, --TODO
    dark = "dark", --TODO insurgence darkness
    dragon = nil, --TODO
    electric = "electric_terrain",
	fairy = "misty_terrain",
	fire = "sunny",
	flying = "wind",
    fighting = nil, --TODO
	grass = "grassy_terrain",
	ground = "sandstorm",
    ghost = nil, --TODO
	ice = "hail",
	normal = "cloudy",
	psychic = "psychic_terrain",
    poison = nil, --TODO
	rock = "sandstorm",
    steel = nil, --TODO magnetic terrain
	water = "rain",
	typeless = "clouds_overhead"
	-- type weather effect chance: 2/3
}
HARD_MODE.WeatherChances = {
    {weather = "floor", weight = 20},
    {weather = "trick_room", weight = 4},
    {weather = "wonder_room", weight = 3},
    {weather = "magic_room", weight = 2},
    {weather = "inverse", weight = 1}
}

local settingsList = {
    UpgradeMovesets = 1,             -- if true, roll random powerful movesets for spawned pokémon
    MovesetLevelShift = 0,           -- let the moveset generator access moves that are this number of levels away from the pokémon's current level.
    AllowEggMovesAtLowLevel = 0,     -- if true, all pokémon have access to egg moves. If false, only mons above lv30 will.
    ChangeMovesEveryFloor = 0,       -- if true, movesets are rerolled at every floor. If false, they are rerolled only after beginning a new adventure
    AllMovesEnabled = 1,             -- if true, pokémon that are spawned with a limited number of enabled slots will instead have all move slots enabled
    IncreaseAISmartness = 0,         -- if true, enemy ai will be upgraded to a higher smartness one at spawn
    IncreaseStats = 0,               -- if true, all spawned pokémon will receive a temporary stat increase of some kind
    DungeonEffects = 0,              -- if true, dungeon floors will have a chance to have modifiers applied to them
    PermanentLevelCap = 0            -- if true, all dungeons will restrict the user's level
}

HARD_MODE.loadDefaultSettings = function()
    SV.Hard_Mode_Settings = SV.Hard_Mode_Settings or {}
    for setting, default in pairs(settingsList) do
        SV.Hard_Mode_Settings[setting] = default
    end
end

HARD_MODE.loadSettings = function()
    HARD_MODE.Settings = HARD_MODE.Settings or {}
    SV.Hard_Mode_Settings = SV.Hard_Mode_Settings or {}
    for setting, default in pairs(settingsList) do
        HARD_MODE.loadSetting(setting, default)
    end
end

HARD_MODE.loadSetting = function(setting, default)
    if SV.Hard_Mode_Settings[setting] == nil then
        HARD_MODE.Settings[setting] = default
    else
        HARD_MODE.Settings[setting] = SV.Hard_Mode_Settings[setting]
    end
end

---@param chara any the Character to build.
HARD_MODE.applySpawnEffects = function(chara)
    HARD_MODE.loadLocation()
    HARD_MODE.upgradeAI(chara)
    HARD_MODE.boostStats(chara)
    HARD_MODE.assignStrongerMoves(chara)
end

HARD_MODE.loadLocation = function(map)
    map = map or _ZONE.CurrentMap
    SV.hard_mode_processed = SV.hard_mode_processed or {}
    SV.hard_mode_processed.Location = SV.hard_mode_processed.Location or {Zone = "", Segment = -1, Floor = -1, DiffValue = -1, LevelCap = false}
    SV.hard_mode_processed.Moves = SV.hard_mode_processed.Moves or {}

    local curr_floor = map.ID
    local curr_zone = _ZONE.CurrentZoneID
    local curr_segment = map.Segment
    local zoneSummary = nil

    if SV.hard_mode_processed.Location.Floor ~= curr_floor then
        if SV.Hard_Mode_Settings.ChangeMovesEveryFloor ~= 0 then
            SV.hard_mode_processed.Moves = {}
        end
        if SV.hard_mode_processed.Location.LevelCap and SV.hard_mode_processed.Location.Floor ~= curr_floor then
            zoneSummary = HARD_MODE.globals.dataIndices.Zones:Get(curr_zone)
        end
    end
    if SV.hard_mode_processed.Location.Zone ~= curr_zone or SV.hard_mode_processed.Location.Segment ~= curr_segment then
        SV.hard_mode_processed.Moves = {}
        zoneSummary = zoneSummary or HARD_MODE.globals.dataIndices.Zones:Get(curr_zone)
        SV.hard_mode_processed.Location.LevelCap = zoneSummary.LevelCap
    end

    if zoneSummary ~= nil then
        local diff_k = math.floor(zoneSummary.Level/5)
        local diff_mult = 1

        if zoneSummary.TeamRestrict then
            diff_k = diff_k + 3
        elseif zoneSummary.TeamSize > -1 then
            diff_k = diff_k + math.max(0, 4-zoneSummary.TeamSize)
        end
        if zoneSummary.BagRestrict>-1 then
            if zoneSummary.BagRestrict==0 then
                diff_k = diff_k + 2
            elseif zoneSummary.BagRestrict<8 then
                diff_k = diff_k + 1
            end
        end
        if not zoneSummary.KeepSkills then
            diff_mult=diff_mult+0.5
        end

        if SV.hard_mode_processed.Location.LevelCap then
            local total = 0
            local amount = 0
            for char in luanet.each(LUA_ENGINE:MakeList(map:IterateCharacters(false, true))) do
                if char.MemberTeam.MapFaction ~= RogueEssence.Dungeon.Faction.Player then
                    total = total + char.Level
                    amount = amount + 1
                end
            end
            local average = total/amount
            diff_k = diff_k + math.floor(math.max(0, (average-zoneSummary.Level))/5)
            SV.hard_mode_processed.Location.DiffValue = math.floor(diff_k*diff_mult)
            print("Dungeon difficulty coefficient: "..SV.hard_mode_processed.Location.DiffValue)
        end
    end

    SV.hard_mode_processed.Location.Zone = curr_zone
    SV.hard_mode_processed.Location.Segment = curr_segment
    SV.hard_mode_processed.Location.Floor = curr_floor
end

---@param chara any the Character to build.
HARD_MODE.boostStats = function(chara)
    if SV.Hard_Mode_Settings.IncreaseStats == 0 then return end
    local boostn = chara.Level/10
    local boostchance = boostn%1
    if boostchance*10 > (_DATA.Save.Rand:Next(10)+1) then
        boostn = math.ceil(boostn)
    end
    local stats = {
        {stat = "atk", weight = chara.Atk},
        {stat = "def", weight = chara.Def},
        {stat = "mat", weight = chara.MAtk},
        {stat = "mdf", weight = chara.MDef},
        {stat = "spd", weight = chara.Speed}
    }
    local boosts = {}
    while boostn>=1 do
        local boost, i = HARD_MODE.weightedRandom(stats, true)
        ---@cast boost -?
        boosts[boost.stat] = boosts[boost.stat] or 0
        boosts[boost.stat] = boosts[boost.stat] + 1
        stats[i].weight = math.floor(stats[i].weight*0.9)
        boostn=boostn-1
    end
    for stat, num in pairs(boosts) do
        if stat=="atk" then
            chara.ProxyAtk = chara.Atk + math.max(1, math.floor(chara.Atk*num/10))
        elseif stat=="def" then
            chara.ProxyDef = chara.Def + math.max(1, math.floor(chara.Def*num/10))
        elseif stat=="mat" then
            chara.ProxyMAtk = chara.MAtk + math.max(1, math.floor(chara.MAtk*num/10))
        elseif stat=="mdf" then
            chara.ProxyMDef = chara.MDef + math.max(1, math.floor(chara.MDef*num/10))
        elseif stat=="spd" then
            chara.ProxySpeed = chara.Speed + math.max(1, math.floor(chara.Speed*num/10))
        end
    end
end

---@param chara any the Character to build.
HARD_MODE.upgradeAI = function(chara)
    if SV.Hard_Mode_Settings.IncreaseAISmartness ~= 0 and HARD_MODE.AIUpgrade[chara.Tactic.ID] ~= nil then
        local tactic = _DATA:GetAITactic(HARD_MODE.AIUpgrade[chara.Tactic.ID])
        chara.Tactic = RogueEssence.Data.AITactic(tactic)
    end
end

---@param chara any the Character to build.
HARD_MODE.assignStrongerMoves = function(chara)
    local print_generated = "Generated"

    local prevSet = {set = {}, enabled = 0}
    for i=0, 3, 1 do
        local slot = chara.Skills[i]
        if slot.Element.Enabled then
            prevSet.enabled = prevSet.enabled+1
        end
        prevSet.set[i+1] = slot.Element.SkillNum
    end
    local prevSetString = prevSet.set[1]..prevSet.set[2]..prevSet.set[3]..prevSet.set[4]..prevSet.enabled

    if SV.Hard_Mode_Settings.AllMovesEnabled ~= 0 then prevSet.enabled = 4 end

    if SV.hard_mode_processed.Moves[chara.BaseForm.Species] and SV.hard_mode_processed.Moves[chara.BaseForm.Species][chara.BaseForm.Form] and SV.hard_mode_processed.Moves[chara.BaseForm.Species][chara.BaseForm.Form][prevSetString] then
        -- Assign moves that were previously rolled
        print_generated = "Assigned"
        local enabledNum = 0
        for _ = 1, 4, 1 do
            chara:DeleteSkill(0)
        end
        local halfPP = false
        for i, move in pairs(SV.hard_mode_processed.Moves[chara.BaseForm.Species][chara.BaseForm.Form][prevSetString]) do
            if move ~= "" then
                local enabled = true
                if enabledNum < prevSet.enabled then
                    enabledNum = enabledNum +1
                else
                    enabled = false
                end
                chara:ReplaceSkill(move, i - 1, enabled)
                if halfPP then chara.Skills[i-1].Element.Charges = math.floor(chara.Skills[i-1].Element.Charges/2) end
            end
        end
    else
        local prevLevel = chara.Level
        chara.Level = math.max(1, math.min(chara.Level + SV.Hard_Mode_Settings.MovesetLevelShift, _DATA.Start.MaxLevel))
        -- Roll a new moveset and save it
        SV.hard_mode_processed.Moves[chara.BaseForm.Species] = SV.hard_mode_processed.Moves[chara.BaseForm.Species] or {}
        SV.hard_mode_processed.Moves[chara.BaseForm.Species][chara.BaseForm.Form] = SV.hard_mode_processed.Moves[chara.BaseForm.Species][chara.BaseForm.Form] or {}
        local k = chara.Level
        local tmnum  = math.max(0, math.floor((k-10)/10))
        local tutnum = math.max(0, math.floor((k-5)/20))
        local egnum  = math.max(0, math.min(k-30, 1))
        if SV.Hard_Mode_Settings.AllowEggMovesAtLowLevel ~= 0 then egnum = 1 end
        local _, moves = HARD_MODE.assignBossMoves(chara, tmnum, tutnum, egnum, {})
        SV.hard_mode_processed.Moves[chara.BaseForm.Species][chara.BaseForm.Form][prevSetString] = moves

        local numEnabled = 0
        for slot in luanet.each(chara.Skills) do
            if slot.Element.SkillNum ~= "" then
                if numEnabled <= prevSet.enabled then
                    numEnabled = numEnabled+1
                else
                    slot.Element.Enabled = false
                end
            end
        end
        chara.Level = prevLevel
    end

    local moveset = SV.hard_mode_processed.Moves[chara.BaseForm.Species][chara.BaseForm.Form][prevSetString]
	PrintInfo("Moveset assigned to: "..chara.Name.." - Lv"..chara.Level.."\n"..
        print_generated..": "..moveset[1].." - "..moveset[2].." - "..moveset[3].." - "..moveset[4])
end

--- Dynamically builds a boss moveset and assigns it to a character.
--- The character's level should be assigned before running this script. Reduce the level afterwards if you want to be illegal about it.
--- The character is always allowed to have as many level-up moves as it can learn at its level. The number of other move types is arbitrary.
---@param chara any the Character to build.
---@param tm_allowed integer the maximum number of tm moves that the character is allowed to have. Defaults to 0
---@param tutor_allowed integer the maximum number of tutor moves that the character is allowed to have. Defaults to 0
---@param egg_allowed integer the maximum number of egg moves that the character is allowed to have. Defaults to 0
---@param blacklist referenceSet list of move ids that must never be included in a moveset generated by this function
---@return slotType[], string[] #the list of slot types chosen, in the order they were applied, and the moves that have been rolled
HARD_MODE.assignBossMoves = function(chara, tm_allowed, tutor_allowed, egg_allowed, blacklist)
    if RogueEssence.GameManager.Instance.CurrentScene ~= RogueEssence.Dungeon.DungeonScene.Instance then
        print("This function can only be called inside dungeons.")
        return {}, {}
    end
    -- prepare lists
    ---@type table<categoryType, integer>
    local allowed = { level = 4 }
    allowed.tm, allowed.tutor, allowed.egg = tm_allowed or 0, tutor_allowed or 0, egg_allowed or 0
    local moveset_table = HARD_MODE.filterMoveset(chara, allowed.tm > 0, allowed.tutor > 0, allowed.egg > 0, blacklist)
    ---@type table<"_Completed"|integer,synergyEntry|referenceSet>
    local synergies = { _Completed = {} }
    ---@type slotType[][]
    local move_slot_options = {
        { "stab", "coverage", "damage", "status" },
        { "stab", "coverage", "status", "status" }
    }
    local move_slots = HARD_MODE.weightlessRandom(move_slot_options, true) --[[ @as slotType[] ]]
    local shuffled_slots = HARD_MODE.shuffleTable(move_slots, true) --[[ @as slotType[] ]]
    ---@type table<slotType,string[]> keeps track of what moves are assigned to what slot type
    local slot_to_moves = {}
    ---@type string[]
    local move_list = {}

    -- select the moves
    for _, slot_type in pairs(shuffled_slots) do
        slot_to_moves[slot_type] = slot_to_moves[slot_type] or {}
        table.insert(slot_to_moves[slot_type], HARD_MODE.moveSelection[slot_type](moveset_table, synergies, allowed))
    end
    for _ = 1, 4, 1 do
        chara:DeleteSkill(0)
    end
    local halfPP = false
    if chara.Fullness < 50 then halfPP = true end
    -- apply the moves to the character in move_slot order
    for i, slot_type in pairs(move_slots) do
        local move = slot_to_moves[slot_type][1] --FIFO
        if move == "" then
            move_list[i] = ""
        else
            chara:ReplaceSkill(move, i - 1, true)
            if halfPP then chara.Skills[i-1].Element.Charges = math.floor(chara.Skills[i-1].Element.Charges/2) end
            move_list[i] = move
        end
        table.remove(slot_to_moves[slot_type], 1) --the slot to moves list gets progressively emptied out
    end
    return shuffled_slots, move_list
end

--- Generates a list of allowed moves for a specific character, taking into account how that move can be obtained.
--- @param chara any The character to check
--- @param tm_allowed boolean If true, the tm list will be populated
--- @param tutor_allowed boolean If true, the tutor list will be populated
--- @param egg_allowed boolean If true, the egg list will be populated
--- @param blacklist referenceSet a reference set of moves that must never be picked no matter what
--- @return {all:moveset_list, level:moveset_supertable,tm:moveset_supertable,tutor:moveset_supertable,egg:moveset_supertable}
HARD_MODE.filterMoveset = function(chara, tm_allowed, tutor_allowed, egg_allowed, blacklist)
    ---@type {all:moveset_list, level:moveset_supertable,tm:moveset_supertable,tutor:moveset_supertable,egg:moveset_supertable}
    local moveset_table = {
        all = {
        },
        level = {
            stab = {},
            coverage = {},
            damage = {},
            status = {}
        },
        tm = {
            stab = {},
            coverage = {},
            damage = {},
            status = {}
        },
        tutor = {
            stab = {},
            coverage = {},
            damage = {},
            status = {}
        },
        egg = {
            stab = {},
            coverage = {},
            damage = {},
            status = {}
        }
    }
    ---@type {id: string, enabled: boolean, getList: fun(integer):{[integer]: {Skill:string, Level:integer?}, Count: integer}}[]
    local workPhases = {
        {id = "level", enabled = true,          getList = function(form) return form.LevelSkills end},
        {id = "tm",    enabled = tm_allowed,    getList = function(form) return form.TeachSkills end},
        {id = "tutor", enabled = tutor_allowed, getList = function(form) return form.SecretSkills end},
        {id = "egg",   enabled = egg_allowed,   getList = function(form) return form.SharedSkills end}
    }
    local stages = {}
    local evolutionStage = chara.BaseForm
    local stageData = _DATA:GetMonster(evolutionStage.Species)
    local stageForm = stageData.Forms[evolutionStage.Form]

    local types = {stageForm.Element1, stageForm.Element1}
    if stageForm.Element2 ~= "" then types[2] = stageForm.Element2 end
    local coverage = HARD_MODE.getCoverageTypes(types)
    local attackStats = {stageForm.BaseAtk, stageForm.BaseMAtk}
    while (evolutionStage:IsValid()) do
        stageData = _DATA:GetMonster(evolutionStage.Species)
        stageForm = stageData.Forms[evolutionStage.Form]
        table.insert(stages, stageForm)
        evolutionStage = RogueEssence.Dungeon.MonsterID(stageData.PromoteFrom, stageForm.PromoteForm, evolutionStage.Skin, evolutionStage.Gender);
    end

    for _, form in ipairs(stages) do
        for _, phase in ipairs(workPhases) do
            if phase.enabled then
                local supertable = phase.id
                local skillList = phase.getList(form)
                for i=0, skillList.Count-1, 1 do
                    if not skillList[i].Level or skillList[i].Level<=chara.Level then
                        local skill = skillList[i].Skill
                        local value = {ID = skill, Type = "", Category = "status", Weight = 1000, ApplySynergy = {}, RequestSynergy = {}}
                        if not moveset_table.all[skill] and not blacklist[skill] then
                            local skillData = _DATA:GetSkill(skill)
                            value.Type = skillData.Element
                            local category, subtables = -1, {}
                            if skillData.Data.Category == RogueEssence.Data.BattleData.SkillCategory.Status then
                                category, subtables = 0, {"status"}
                                HARD_MODE.synergyLookup(skillData, value)
                                table.insert(moveset_table[supertable].status, value) --we save now because the other categories are damage only anyway
                            elseif skillData.Data.Category == RogueEssence.Data.BattleData.SkillCategory.Physical then
                                category, subtables = 1, {"damage"}
                            elseif skillData.Data.Category == RogueEssence.Data.BattleData.SkillCategory.Magical then
                                category, subtables = 2, {"damage"}
                            end
                            if category > 0 then
                                value.Category = "damage"
                                HARD_MODE.synergyLookup(skillData, value)
                                local PowerStateType = luanet.import_type('RogueEssence.Dungeon.BasePowerState')
                                local power = skillData.Data.SkillStates:GetWithDefault(luanet.ctype(PowerStateType))
                                if power and power.Power>0 then power = power.Power else power = 40 end
                                local weight = power * skillData.Strikes * attackStats[category]
                                if types[1] == skillData.Data.Element or types[2] == skillData.Data.Element then
                                    weight = math.floor(weight*1.5)
                                    table.insert(subtables, "stab")
                                end
                                if coverage[skillData.Data.Element] then
                                    table.insert(subtables, "coverage")
                                end
                                for _, subtable in ipairs(subtables) do
                                    value.Weight = weight
                                    table.insert(moveset_table[supertable][subtable], value)
                                end
                            end
                            if #subtables>0 then
                                moveset_table.all[skill] = {cat = subtables, tables = {supertable}, value = value}
                            end
                        elseif moveset_table.all[skill] then
                            for _, subtable in ipairs(moveset_table.all[skill].cat) do
                                table.insert(moveset_table[supertable][subtable], moveset_table.all[skill].value)
                            end
                            table.insert(moveset_table.all[skill].tables, supertable)
                        end
                    end
                end
            end
        end
    end

    return moveset_table
end

--- Returns a set of all types that cover the weaknesses of a type combination.
--- @return referenceSet #a table whose keys are element ids and whose values are ``true``
HARD_MODE.getCoverageTypes = function(types)
    local all_types = HARD_MODE.globals.dataIndices.Elements:GetOrderedKeys(true)
    local weaknesses = {}
    local coverage = {}
    for id in luanet.each(all_types) do
        local matchup = 0
        for _, id2 in ipairs(types) do
            matchup = matchup + PMDC.Dungeon.PreTypeEvent.CalculateTypeMatchup(id, id2)
        end
        if matchup >= PMDC.Dungeon.PreTypeEvent.S_E_2 then
            table.insert(weaknesses, id)
        end
    end
    for id in luanet.each(all_types) do
        for _, id2 in ipairs(weaknesses) do
            local matchup = PMDC.Dungeon.PreTypeEvent.CalculateTypeMatchup(id, id2)
            if matchup >= PMDC.Dungeon.PreTypeEvent.S_E then
                coverage[id] = true
                break
            end
        end
    end
    return coverage
end


--- Checks for synergies a move can make and stores them in its moveset entry
--- @param skill any a RogueEssence.Data.SkillData object
--- @param entry moveset_entry the moveset entry to store data in
HARD_MODE.synergyLookup = function(skill, entry)
    local data = skill.Data

    local memory = {}
    for pair in luanet.each(LUA_ENGINE:MakeList(data.BeforeTryActions)) do
        if LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(HARD_MODE.globals.ctypes.WeatherNeededEvent) then
            --before try actions, WeatherNeededEvent and ChargeOrReleaseEvent, request "weather <WeatherID>"
            if memory.weather and memory.weather.chargerelease and not memory.weather.request then
                table.insert(entry.RequestSynergy, "weather "..pair.Value.WeatherID)
            end
            memory.weather = memory.weather or {}
            memory.weather.request = "weather "..pair.Value.WeatherID
        elseif LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(HARD_MODE.globals.ctypes.ChargeOrReleaseEvent) then
            --before try actions, WeatherNeededEvent and ChargeOrReleaseEvent, request "weather <WeatherID>"
            if memory.weather and memory.weather.request and not memory.weather.chargerelease then
                table.insert(entry.RequestSynergy, memory.weather.request)
            end
            memory.weather = memory.weather or {}
            memory.weather.chargerelease = true
        end
    end
    for pair in luanet.each(LUA_ENGINE:MakeList(data.BeforeActions)) do
        if LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(HARD_MODE.globals.ctypes.AddContextStateEvent) then
            --before actions, AddContextStateEvent.SleepAttack, request "user sleep"
            if not pair.Value.Global and LUA_ENGINE:TypeOf(pair.Value.AddedState) == luanet.ctype(HARD_MODE.globals.ctypes.SleepAttack) then
                table.insert(entry.RequestSynergy, "user sleep")
            end
        end
    end
    for pair in luanet.each(LUA_ENGINE:MakeList(data.OnActions)) do
        if LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(HARD_MODE.globals.ctypes.StatusStackDifferentEvent) then
            --on actions, StatusStackDifferentEvent, request "user <StatusID>"
            table.insert(entry.RequestSynergy, "user "..pair.Value.StatusID)
        elseif LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(HARD_MODE.globals.ctypes.MajorStatusPowerEvent) then
            --on actions, MajorStatusPowerEvent(num>den), request "<AffectedTarget> MajorStatus"
            if pair.Value.Numerator and pair.Value.Denominator and pair.Value.Numerator > pair.Value.Denominator then
                local target = "user"
                if pair.Value.AffectTarget == true then target = "target" end
                table.insert(entry.RequestSynergy, target.." major status")
            end
        end
    end
    for pair in luanet.each(LUA_ENGINE:MakeList(data.BeforeHits)) do
        if LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(HARD_MODE.globals.ctypes.StatusPowerEvent) then
            --before hits, StatusPowerEvent, request "<AffectTarget> <StatusID>"
            local target = "user"
            if pair.Value.AffectTarget == true then target = "target" end
            table.insert(entry.RequestSynergy, target.." "..pair.Value.StatusID)
        end
    end
    for pair in luanet.each(LUA_ENGINE:MakeList(data.OnHits)) do
        if LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(HARD_MODE.globals.ctypes.GiveMapStatusEvent) then
            --on hits, GiveMapStatusEvent, apply "weather <WeatherID>"
            table.insert(entry.ApplySynergy, "weather "..pair.Value.StatusID)
        elseif LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(HARD_MODE.globals.ctypes.StatusBattleEvent) then
            --on hits, StatusBattleEvent, apply "<AffectTarget> <StatusID>"
            local target = "user"
            if pair.Value.AffectTarget == true then target = "target" end
            local status = _DATA:GetStatus(pair.Value.StatusID)
            for state in luanet.each(status.StatusStates) do
                if LUA_ENGINE:TypeOf(state) == luanet.ctype(HARD_MODE.globals.ctypes.MajorStatusState) then
                    table.insert(entry.ApplySynergy, target.." major status")
                end
            end
            table.insert(entry.ApplySynergy, target.." "..pair.Value.StatusID)
        elseif LUA_ENGINE:TypeOf(pair.Value) == luanet.ctype(HARD_MODE.globals.ctypes.AdditionalEvent) then
            --on hits, AdditionalEvent.StatusBattleEvent, apply "<AffectTarget> <StatusID>"
            for event in luanet.each(pair.Value.BaseEvents) do
                if LUA_ENGINE:TypeOf(event) == luanet.ctype(HARD_MODE.globals.ctypes.StatusBattleEvent) then
                    local target = "user"
                    if pair.Value.AffectTarget == true then target = "target" end
                    local status = _DATA:GetStatus(event.StatusID)
                    for state in luanet.each(status.StatusStates) do
                        if LUA_ENGINE:TypeOf(state) == luanet.ctype(HARD_MODE.globals.ctypes.MajorStatusState) then
                            table.insert(entry.ApplySynergy, target.." major status")
                        end
                    end
                    table.insert(entry.ApplySynergy, target.." "..event.StatusID)
                end
            end
        end
    end
end

HARD_MODE.moveSelection = {}
--- Picks one stab move if the list is not empty. Otherwise, coverage gets called.
--- @param moveset_table {all:moveset_list, level:moveset_supertable,tm:moveset_supertable,tutor:moveset_supertable,egg:moveset_supertable} the moveset table
--- @param synergies table<"_Completed"|integer,synergyEntry|referenceSet> the synergy table
--- @param allowed table<categoryType, integer> number of allowed moves per category
function HARD_MODE.moveSelection.stab(moveset_table, synergies, allowed)
    local fallback = function() return HARD_MODE.moveSelection.coverage(moveset_table, synergies, allowed) end
    return HARD_MODE.moveSelection.selectMove(moveset_table, synergies, allowed, "stab", fallback)
end

--- Picks one coverage move if the list is not empty. Otherwise, damage gets called.
--- @param moveset_table {all:moveset_list, level:moveset_supertable,tm:moveset_supertable,tutor:moveset_supertable,egg:moveset_supertable} the moveset table
--- @param synergies table<"_Completed"|integer,synergyEntry|referenceSet> the synergy table
--- @param allowed table<categoryType, integer> number of allowed moves per category
function HARD_MODE.moveSelection.coverage(moveset_table, synergies, allowed)
    local fallback = function() return HARD_MODE.moveSelection.damage(moveset_table, synergies, allowed) end
    return HARD_MODE.moveSelection.selectMove(moveset_table, synergies, allowed, "coverage", fallback)
end

--- Picks one damaging move if the list is not empty. Otherwise, it picks one status move. If that list is also empty, it selects nothing.
--- @param moveset_table {all:moveset_list, level:moveset_supertable,tm:moveset_supertable,tutor:moveset_supertable,egg:moveset_supertable} the moveset table
--- @param synergies table<"_Completed"|integer,synergyEntry|referenceSet> the synergy table
--- @param allowed table<categoryType, integer> number of allowed moves per category
function HARD_MODE.moveSelection.damage(moveset_table, synergies, allowed)
    local pick_none = function() return "" end
    local fallback = function() return HARD_MODE.moveSelection.selectMove(moveset_table, synergies, allowed, "status", pick_none) end
    return HARD_MODE.moveSelection.selectMove(moveset_table, synergies, allowed, "damage", fallback)
end

--- Picks one status move if the list is not empty. Otherwise, it picks one damaging move. If that list is also empty, it selects nothing.
--- @param moveset_table {all:moveset_list, level:moveset_supertable,tm:moveset_supertable,tutor:moveset_supertable,egg:moveset_supertable} the moveset table
--- @param synergies table<"_Completed"|integer,synergyEntry|referenceSet> the synergy table
--- @param allowed table<categoryType, integer> number of allowed moves per category
function HARD_MODE.moveSelection.status(moveset_table, synergies, allowed)
    local pick_none = function() return "" end
    local fallback = function() return HARD_MODE.moveSelection.selectMove(moveset_table, synergies, allowed, "damage", pick_none) end
    return HARD_MODE.moveSelection.selectMove(moveset_table, synergies, allowed, "status", fallback)
end

--- Scans for possible synergies and returns a weight multiplier based on them.
--- @param data moveset_entry the data associated to a specific move
--- @param synergies table<"_Completed"|integer,synergyEntry|referenceSet> the synergy table
--- @return number #the final weight multiplier for the move
HARD_MODE.getSynergyMultiplier = function(data, synergies)
    local mult = 1
    local fulfilled = false
    for _, syn_data in ipairs(synergies) do
        ---@cast syn_data synergyEntry
        --move allows a synergy another move requests
        for _, syn in ipairs(data.ApplySynergy) do
            if syn_data.RequestSynergy[syn] then
                mult = mult*1.75
                break
            end
        end
        --move requests a synergy another move allows
        for _, syn in ipairs(data.RequestSynergy) do
            if syn_data.ApplySynergy[syn] then
                mult = mult * 1.25
                break
            end
        end
        --discourage repeated types
        if data.Category ~= "status" and syn_data.Type == data.Type then
            mult = mult * 0.85
        end
    end
    --no move allows this synergy and this is the last move
    if #synergies == 3 and #data.RequestSynergy>0 and not fulfilled then
        return 0
    end
    return mult
end

--- Updates the synergy table by adding the synergies of the newly selected move.
--- @param data moveset_entry the synergy data for a move
--- @param synergies table<"_Completed"|integer,synergyEntry|referenceSet> the synergy table
HARD_MODE.updateSynergies = function(data, synergies)
    ---@type synergyEntry
    local newdata = { RequestSynergy = {}, ApplySynergy = {}, Type = data.Type }
    for _, syn in ipairs(data.ApplySynergy) do
        -- don't do anything if the synergy was already completed
        if not synergies._Completed[syn] then
            for _, syn_data in ipairs(synergies) do
                ---@cast syn_data synergyEntry
                if syn_data.RequestSynergy[syn] then
                    synergies._Completed[syn] = true -- Complete the synergy if it is in requested list
                end
                if synergies._Completed[syn] then
                    syn_data.RequestSynergy = {} -- Clear synergy list. Completing one requested synergy is enough 99% of the times
                end
            end
            if not synergies._Completed[syn] then
                newdata.ApplySynergy[syn] = true -- Add to applied synergies if no picked move completed it
            end
        end
    end
    for _, syn in ipairs(data.RequestSynergy) do
        -- don't do anything if the synergy was already completed
        if not synergies._Completed[syn] then
            for _, syn_data in ipairs(synergies) do
                if syn_data.ApplySynergy[syn] then
                    synergies._Completed[syn] = true -- Complete the synergy if it is in applied list
                end
                if synergies._Completed[syn] then
                    syn_data.ApplySynergy[syn] = nil -- Remove from apply list of all moves
                end
            end
        end
        if synergies._Completed[syn] then -- not an else case because it might change status during the above loop
            newdata.RequestSynergy = {} -- Clean requested synergy list. Completing one requested synergy is enough 99% of the times
            break --RequestedSynergy is empty and it should stay that way. end the loop
        end
        newdata.RequestSynergy[syn] = true -- Add to requested synergies if no picked move completed it
    end
    table.insert(synergies, newdata)
end

---Picks one move from the subtable if the list is not empty. Otherwise, fallback gets called
---@param moveset_table {all:moveset_list, level:moveset_supertable,tm:moveset_supertable,tutor:moveset_supertable,egg:moveset_supertable} the moveset table
---@param synergies table<"_Completed"|integer,synergyEntry|referenceSet> the synergy table
---@param allowed table<categoryType, integer> number of allowed moves per category
---@param subtable slotType the slot to pick a move for
---@param fallback function function to call if the current settings would return nothing
HARD_MODE.moveSelection.selectMove = function(moveset_table, synergies, allowed, subtable, fallback)
    ---@type moveset_entry[]
    local data_list = {}
    local id_list = {}
    local optional = {"tm", "tutor", "egg"}
    local phases = {"level"}
    for i, phase in ipairs(optional) do
        if allowed[phase]>0 then table.insert(phases, optional[i]) end
    end
    local maxweight = 0
    for _, tbl in ipairs(phases) do
        ---@type moveset_entry[]
        local list = HARD_MODE.deepCopy(moveset_table[tbl][subtable])
        for _, data in ipairs(list) do
            if not id_list[data.ID] then
                id_list[data.ID] = true
                if moveset_table.all[data.ID] then
                    table.insert(data_list, data)
                    --boost moves that would complete a synergy
                    data.Weight = data.Weight * HARD_MODE.getSynergyMultiplier(data, synergies)
                    maxweight = math.max(maxweight, data.Weight or 0)
                end
            end
        end
    end
    --heavily penalize lower weights, potentially removing them completely
    if #data_list>0 then
        local len = #data_list
        for i=1, len, 1 do
            local j = len -i + 1
            local data = data_list[j]
            local new_wt = data.Weight - (maxweight-data.Weight)
            if new_wt<=0 then table.remove(data_list, j)
            else
                data.Weight = math.floor(new_wt)
            end
        end
    end
    local result
    if #data_list > 0 then
        result = HARD_MODE.weightedRandom(data_list, true) --[[@as moveset_entry]]
        HARD_MODE.updateSynergies(result, synergies)
        result = result.ID
        local supertables = moveset_table.all[result].tables
        allowed[supertables[1]] = allowed[supertables[1]]-1
        moveset_table.all[result] = nil
    else
        result = fallback()
    end
    return result
end


-- --------------------------------------------------------------------
--                           HELPER FUNCTIONS                          
-- --------------------------------------------------------------------

--- Returns a randomly chosen element of the given list.
--- All elements have the same chance of being returned.
--- @generic T:any
--- @param list T[] the list of elements to roll.
--- @param replay_sensitive? boolean if true, this function will use a replay-safe rng function. Defaults to false.
--- @return T|nil, number|nil #the element extracted and its index in the list, or nil, nil if the list was empty
HARD_MODE.weightlessRandom = function(list, replay_sensitive)
    if #list == 0 then return end
    local roll = -1
    if replay_sensitive
    then roll = _DATA.Save.Rand:Next(#list)+1 --this one includes 0 but doesn't include the max value so +1 it is
    else roll = math.random(1, #list)
    end
    return list[roll], roll
end

--- Returns a randomly chosen element of the given list.
--- Elements must have a "weight" property, otherwise their weight will default to 1.
--- @generic T:table
--- @param list T[] the list of elements to roll.
--- @param replay_sensitive? boolean if true, this function will use a replay-safe rng function. Defaults to false.
--- @return T|nil, number|nil #the element extracted and its index in the list, or nil, nil if the list was empty
HARD_MODE.weightedRandom = function(list, replay_sensitive)
    local entry, index = HARD_MODE.weightedRandomExclude(list, {}, replay_sensitive)
    return entry, index
end

--- Returns a randomly chosen element of the given list, excluding any key in the exclude table.
--- Elements must have a "weight" property, otherwise their weight will default to 1.
--- @generic T:table
--- @param list T[] the list of elements to roll.
--- @param exclude any[] a table whose keys are the ids of the elements to exclude from the roll, and the value can be anything except "nil" and "false"
--- @param replay_sensitive? boolean if true, this function will use a replay-safe rng function. Defaults to false.
--- @param alt_id? string name of the id property, in case "id" isn't good enough. Use an empty string to require the object itself to be equal instead.
--- @return T|nil, number|nil #the element extracted and its index in the list, or nil, nil if the final list was empty
HARD_MODE.weightedRandomExclude = function(list, exclude, replay_sensitive, alt_id)
    local id = alt_id or "id"
    local weight = 0
    for _, element in ipairs(list) do
        local match = element
        if id ~= "" then match = element[id] end
        if not exclude[match] then
            local elem_weight = element.weight or element.Weight
            if elem_weight
            then weight = weight + elem_weight
            else weight = weight + 1
            end
        end
    end
    if weight <= 0 then return end
    local roll = -1
    if replay_sensitive
    then roll = _DATA.Save.Rand:Next(weight)+1 --this rng getter includes 0 but doesn't include the max value so +1 it is
    else roll = math.random(1, weight)
    end

    weight = 0
    for i, element in ipairs(list) do
        local match = element
        if id ~= "" then match = element[id] end
        if not exclude[match] then
            local elem_weight = element.weight or element.Weight
            if elem_weight
            then weight = weight + elem_weight
            else weight = weight + 1
            end
            if weight >= roll then return element, i end
        end
    end
    return list[#list], #list -- should never hit, but just in case, return last
end

---Takes a list and returns a new, shuffled version of the integer pairs in the list.
---The returned list is new, meaning that tbl is left unmodified, but the items inside are not copies.
---Use deepCopy afterwards if you need to edit them.
---@param tbl any[] a table to shuffle
---@return any[] a shuffled version of the table
HARD_MODE.shuffleTable = function(tbl, replay_sensitive)
    local indices = COMMON.GetSortedKeys(tbl, true)
    local shuffled = {}
    for _=1, #tbl, 1 do
        local index, pos = HARD_MODE.weightlessRandom(indices, replay_sensitive)
        table.remove(indices, pos)
        table.insert(shuffled, tbl[index])
    end
    return shuffled
end

--- Creates a deep copy of a table and returns it.
--- This function checks for redundant paths to avoid infinite recursion.
--- @generic T:table
--- @param tbl T the table to deep copy
--- @return T #the copy
HARD_MODE.deepCopy = function(tbl)
    local deepcopy
    deepcopy = function(orig, copies)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            if copies[orig] then
                copy = copies[orig]
            else
                copy = {}
                copies[orig] = copy
                for orig_key, orig_value in next, orig, nil do
                    copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
                end
                setmetatable(copy, deepcopy(getmetatable(orig), copies))
            end
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end
    return deepcopy(tbl, {})
end