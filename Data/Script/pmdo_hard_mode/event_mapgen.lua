
ZONE_GEN_SCRIPT.ApplyHardMode = function(zoneContext, context, queue, seed, args)
    local activeEffect = RogueEssence.Data.ActiveEffect()
    local priority_gen  = RogueElements.Priority(LUA_ENGINE:MakeLuaArray(HARD_MODE.globals.ctypes.Integer, {6, 5}))

    activeEffect.OnMapStarts:Add(priority_gen, RogueEssence.Dungeon.SingleCharScriptEvent("HardModeProcessCharacter", '{}'))

    if LUA_ENGINE:TypeOf(context) ~= luanet.ctype(HARD_MODE.globals.ctypes.MapGenContext) and 
            LUA_ENGINE:TypeOf(context) ~= luanet.ctype(HARD_MODE.globals.ctypes.StairsMapGenContext) and
            LUA_ENGINE:TypeOf(context) ~= luanet.ctype(HARD_MODE.globals.ctypes.ListMapGenContext) then
        return
    end

    local hardmode_floor_step = LUA_ENGINE:MakeGenericType(HARD_MODE.globals.ctypes.ScriptGenStep, { HARD_MODE.globals.ctypes.ListMapGenContext }, {"HardModeProcessFloor"})
    hardmode_floor_step.Script = "HardModeProcessFloor"
    queue:Enqueue(priority_gen, hardmode_floor_step)

    local destNote = LUA_ENGINE:MakeGenericType(MapEffectStepType, { HARD_MODE.globals.ctypes.ListMapGenContext }, { activeEffect })
    queue:Enqueue(priority_gen, destNote)
end

FLOOR_GEN_SCRIPT.HardModeProcessFloor = function(map, args)
    map.Map.Status:Remove("default_weather")
    HARD_MODE.loadLocation(map.Map)

    local rand = _DATA.Save.Rand:Next(100)+1
    if (SV.Hard_Mode_Settings.DungeonEffects == 0) or (SV.hard_mode_processed.Location.DiffValue*4 <= rand) then return end
    local chosen = HARD_MODE.weightedRandom(HARD_MODE.WeatherChances, true)
    local chosenStatus = {status = "clear", weather = true}

    if chosen then
        if chosen.weather == "floor" then
            if HARD_MODE.FloorWeathers[map.Map.Element] then
                chosenStatus = HARD_MODE.FloorWeathers[map.Map.Element]
            else
                chosenStatus = HARD_MODE.FloorWeathers["typeless"]
            end
        else
            chosenStatus = {status = chosen.weather, weather = false}
        end
    end
    ---@cast chosenStatus -?
    --print(chosenStatus)
    local SetterID = "default_mapstatus"
    if chosenStatus.weather then SetterID = "default_weather" end
    local statusSetter = RogueEssence.Dungeon.MapStatus(SetterID)
    statusSetter:LoadFromData()
    local indexState = statusSetter.StatusStates:GetWithDefault(luanet.ctype(HARD_MODE.globals.ctypes.MapIDState))
    indexState.ID = chosenStatus.status
    map.Map.Status:Add(SetterID, statusSetter)
end
