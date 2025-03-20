--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSHIPINIT = "applyshipinit";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSHIPINIT, handleApplyShipInit);

	ActionsManager.registerModHandler("shipinit", modRoll);
	ActionsManager.registerResultHandler("shipinit", onResolve);
end

function notifyApplyShipInit(rSource, nTotal)
	if not rSource then
		return;
	end

	local msgOOB = {};

	msgOOB.type = OOB_MSGTYPE_APPLYSHIPINIT;
	msgOOB.nTotal = nTotal;
	msgOOB.sSourceNode = ActorManager.getCTNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
end
function handleApplyShipInit(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local nodeSource = ActorManager.getCTNode(rSource);
	local nTotal = tonumber(msgOOB.nTotal) or 0;

	DB.setValue(nodeSource, "initresult", "number", nTotal);
end

function getRoll(rActor, nPiloting, bSecretRoll)
	local rRoll = {};
	rRoll.sType = "shipinit";
	rRoll.aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor);
	rRoll.nMod = nPiloting;

	if nPiloting == nil then
		rRoll.sDesc = "[INIT]";
	else
		rRoll.sDesc = "[INIT] (Piloting +" .. nPiloting .. ")";
	end

	rRoll.bSecret = bSecretRoll;

	return rRoll;
end

function performRoll(draginfo, rActor, nPiloting, bSecretRoll)
	local rRoll = getRoll(rActor, nPiloting, bSecretRoll);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

	rRoll.nMod = rRoll.nMod + nAddMod;
end

function onResolve(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	local nTotal = ActionsManager.total(rRoll);
	notifyApplyShipInit(rSource, nTotal);
end
