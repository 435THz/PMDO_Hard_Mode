require 'origin.common'

function SINGLE_CHAR_SCRIPT.HardModeProcessCharacter(owner, ownerChar, context, args)
	if not context.User then return end
	if context.User.MemberTeam.MapFaction == RogueEssence.Dungeon.Faction.Player and context.User.LuaData.HARD_MODE then
        context.User.ProxyAtk = -1;
        context.User.ProxyDef = -1;
        context.User.ProxyMAtk = -1;
        context.User.ProxyMDef = -1;
        context.User.ProxySpeed = -1;
		context.User.LuaData.HARD_MODE = nil
	elseif context.User.MemberTeam.MapFaction == RogueEssence.Dungeon.Faction.Foe and not context.User.LuaData.HARD_MODE then
		HARD_MODE.applySpawnEffects(context.User)
		context.User.LuaData.HARD_MODE = true
	end
end