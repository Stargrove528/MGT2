--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYDWE = "applydisablingwoundeffect";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDWE, handleApplyDisablingWoundEffect);

	ActionsManager.registerResultHandler("combatdisablingwoundeffect", onDisablingWoundEffect);
end

function handleApplyDisablingWoundEffect(msgOOB)
    local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyDisablingWoundEffect(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sAttackType, msgOOB.sDesc, nTotal, msgOOB.sResults);
end

function notifyApplyDisablingWoundEffect(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDWE;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.nTotal = nTotal;
	msgOOB.sDesc = sDesc;
	msgOOB.sResults = sResults;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	Comm.deliverOOBMessage(msgOOB, "");
end

function onDisablingWoundEffect(rSource, rTarget, rRoll)

    local nTotal = ActionsManager.total(rRoll);

    if nTotal > 12 then
        nTotal = 12;
    elseif nTotal < 1 then
        nTotal = 1;
    end

    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
    
    Comm.deliverChatMessage(rMessage);

    rTarget = rSource;

    local rAction = {};
    rAction.nTotal = nTotal;
    rAction.aMessages = {};

	if rTarget then
		notifyApplyDisablingWoundEffect(rSource, rTarget, rRoll.bTower, rRoll.sType, rRoll.sDesc, rAction.nTotal, table.concat(rAction.aMessages, " "));
	end    

end

function rollForDisablingWoundEffect(node, nModifier)
	local rActor = ActorManager.resolveActor(node);

    local rAction = {};
    rAction.nMod = nModifier;
    
	performRoll(nil, rActor, rAction);
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};

	rRoll.sType = "combatdisablingwoundeffect";
	rRoll.aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor);
	rRoll.nMod = rAction.nMod;
	rRoll.sDesc = "[DISABLING WOUND EFFECT]";

    ActionsManager2.encodeDesktopMods(rRoll);

	return rRoll;
end

function applyDisablingWoundEffect(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = "Disabling Wound ->";
	msgLong.text = "Disabling Wound [" .. nTotal .. "] ->";
	if rTarget then
		msgShort.text = msgShort.text .. DataCommon.aDisablingWoundEffects[nTotal];
		msgLong.text = msgLong.text .. DataCommon.aDisablingWoundEffects[nTotal];
	end
	if sResults ~= "" then
		msgLong.text = msgLong.text .. " " .. sResults;
	end
	
	msgShort.icon = "roll_disablingwound";
	msgLong.icon = "roll_disablingwound";
		
	ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end

