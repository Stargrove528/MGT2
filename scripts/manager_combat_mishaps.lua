--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYMISHAPS = "applymishap";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYMISHAPS, handleApplyMishaps);

	ActionsManager.registerResultHandler("combatmishap", onMishap);
end

function handleApplyMishaps(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyMishap(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sAttackType, msgOOB.sDesc, nTotal, msgOOB.sResults);	
end

function notifyApplyMishap(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYMISHAPS;
	
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

function onMishap(rSource, rTarget, rRoll)
    local nTotal = ActionsManager.total(rRoll);

    if nTotal > 12 then
        nTotal = 12;
    elseif nTotal < 2 then
        nTotal = 2;
    end

    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
    
    Comm.deliverChatMessage(rMessage);

    rTarget = rSource;

    local rAction = {};
    rAction.nTotal = nTotal;
    rAction.aMessages = {};

	if rTarget then
		notifyApplyMishap(rSource, rTarget, rRoll.bTower, rRoll.sType, rRoll.sDesc, rAction.nTotal, table.concat(rAction.aMessages, " "));
	end    
end

function rollForMishap(node, nAttackSkill)
	local rActor = ActorManager.resolveActor(node);

    local rAction = {};
    rAction.nMod = nAttackSkill;
    
	performRoll(nil, rActor, rAction);

end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};

	rRoll.sType = "combatmishap";
	rRoll.aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor);
	rRoll.nMod = rAction.nMod;
	rRoll.sDesc = "[COMBAT MISHAP]";

    ActionsManager2.encodeDesktopMods(rRoll);

	return rRoll;
end

function applyMishap(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = "Combat Mishap ->";
	msgLong.text = "Combat Mishap [" .. nTotal .. "] ->";
	if rTarget then
		msgShort.text = msgShort.text .. DataCommon.aCombatMishaps[nTotal];
		msgLong.text = msgLong.text .. DataCommon.aCombatMishaps[nTotal];
	end
	if sResults ~= "" then
		msgLong.text = msgLong.text .. " " .. sResults;
	end
	
	msgShort.icon = "roll_Mishap";
	msgLong.icon = "roll_Mishap";
		
	ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end
