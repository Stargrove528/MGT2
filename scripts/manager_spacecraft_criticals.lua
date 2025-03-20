--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYCRITICAL = "applycriticalupdate";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYCRITICAL, handleApplyCritical);

	ActionsManager.registerResultHandler("shipcritical", onCritical);
end

function onCritical(rSource, rTarget, rRoll)
    local nodeSourceCT = ActorManager.getCTNode(rSource);
    local nTotal = ActionsManager.total(rRoll);

    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

    rMessage.text = rMessage.text .. " " .. DataCommon.aSpacecraftCriticals[nTotal];

	local nCurrentSeverity = getCurrentSeverity(nodeSourceCT, DataCommon.aSpacecraftCriticals[nTotal]);
    local nNewSeverity = nCurrentSeverity +1;

    if nNewSeverity < 7 then
        rMessage.text = rMessage.text .. "\nSeverity " .. nNewSeverity .. ": " .. DataCommon.aSpacecraftCriticalHitEffects[DataCommon.aSpacecraftCriticals[nTotal]][nNewSeverity];
    else
        rMessage.text = rMessage.text .. "\nShip suffers extra 6D damage";
    end

    putNewSeverity(nodeSourceCT, DataCommon.aSpacecraftCriticals[nTotal], nNewSeverity, DataCommon.aSpacecraftCriticalHitEffects[DataCommon.aSpacecraftCriticals[nTotal]][nNewSeverity]);

    Comm.deliverChatMessage(rMessage);
end

function rollForCritcal(node, bAutomaticCritical)
	local rActor = ActorManager.resolveActor(node);

    local rAction = {};
    rAction.modifier = 0;
    rAction.nMod = 0;
    rAction.bAutomaticCritical = bAutomaticCritical;

	performRoll(nil, rActor, rAction);
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};

	rRoll.sType = "shipcritical";
	rRoll.aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor);
	rRoll.nMod = 0;
	rRoll.sDesc = "[CRITICAL HIT]";

    ActionsManager2.encodeDesktopMods(rRoll);

	return rRoll;
end

function getCurrentSeverity(node, sCriticalSystem)
    local nCurrentSeverity = 0;
    local vCriticalsNode = node;

    if vCriticalsNode then
        for _,v in ipairs(DB.getChildList(vCriticalsNode, "criticals")) do
            local sSystem = DB.getValue(v, "system", "");
            if sSystem:lower() == sCriticalSystem:lower() then
                nCurrentSeverity = DB.getValue(v, "severity", "");
                break;
            end
        end
    end

    return nCurrentSeverity;
end

function putNewSeverity(node, sCriticalSystem, nNewSeverity, sCriticalText)
    local vCriticalsNode = DB.createChild(node, 'criticals');
    local vCriticalNode;

    for _,v in ipairs(DB.getChildList(node, "criticals")) do
        local sSystem = DB.getValue(v, "system", "");
        if sSystem == sCriticalSystem then
            vCriticalNode = v;
            break;
        end
    end

    if not vCriticalNode then
        vNewNode = DB.createChild(vCriticalsNode);
        DB.setValue(vNewNode,"system","string",sCriticalSystem);
        DB.setValue(vNewNode,"text","string",sCriticalText);
        DB.setValue(vNewNode,"severity","number",nNewSeverity);
    else
        DB.setValue(vCriticalNode,"severity","number",nNewSeverity);
        DB.setValue(vCriticalNode,"text","string",sCriticalText);
    end
end

function reduceCriticalSeverity(node, sCriticalSystem)
    local nCurrentSeverity = getCurrentSeverity(node, sCriticalSystem);
    if nCurrentSeverity > 1 then
        local nNewSeverity = nCurrentSeverity -1;
        local sNewCriticalEffect = DataCommon.aSpacecraftCriticalHitEffects[sCriticalSystem][nNewSeverity];
        putNewSeverity(node, sCriticalSystem, nNewSeverity, sNewCriticalEffect);
    end
end
