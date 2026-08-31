function BATTLE_SCRIPT.MultiplyHitChance(owner, ownerChar, context, args)
    if not context.Data.SkillStates:Contains(luanet.ctype(HARD_MODE.globals.ctypes.ContactState))
        and context.Data.Category ~= RogueEssence.Data.BattleData.SkillCategory.Status then
        context.Data.HitRate = context.Data.HitRate*args.rate/100
    end
end