--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYINIT = "applyinit";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYINIT, handleApplyInit);

	ActionsManager.registerModHandler("init", modRoll);
	ActionsManager.registerResultHandler("init", onResolve);
end

function handleApplyInit(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local nTotal = tonumber(msgOOB.nTotal) or 0;

	DB.setValue(ActorManager.getCTNode(rSource), "initresult", "number", nTotal);
end

function notifyApplyInit(rSource, nTotal)
	if not rSource then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYINIT;

	msgOOB.nTotal = nTotal;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
end

function getRoll(rActor, bSecretRoll)
	local rRoll = {};
	rRoll.sType = "init";
	rRoll.aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor);
	rRoll.nMod = 0;

	rRoll.sDesc = "[INIT]";

	rRoll.bSecret = bSecretRoll;

	return rRoll;
end

function performRoll(draginfo, rActor, bSecretRoll)
	local rRoll = getRoll(rActor, bSecretRoll);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, rTarget, rRoll)
	if rSource then
		nodeActor = ActorManager.getCreatureNode(rSource);

		local nDexDM = DB.getValue(nodeActor, "attributes.dex_mod", 0);
		local nIntDM = DB.getValue(nodeActor, "attributes.int_mod", 0);
		local initiativeBonus = DB.getValue(nodeActor, "initiative", 0);

		local nInitMod = nDexDM;
		if nIntDM > nInitMod then
			nInitMod = nIntDM;
		end
		initiativeBonus = initiativeBonus + nInitMod;

		if initiativeBonus ~= 0 then
			if initiativeBonus > 0 then
				rRoll.sDesc = rRoll.sDesc .. '[MOD +'..initiativeBonus .."]"
			else
				rRoll.sDesc = rRoll.sDesc .. '[MOD '..initiativeBonus .."]"
			end
		end
		rRoll.nMod = rRoll.nMod + initiativeBonus;

		ActionsManager2.encodeDesktopMods(rRoll);
	end
end

function onResolve(rSource, rTarget, rRoll)
	local nTotal = ActionsManager.total(rRoll);

	--NOTE: Why are we subtracting 8? What is the "effect Level"?
	-- Now we get the effect level
	nTotal = nTotal - 8;

	if nTotal >= 0 then
		rRoll.sDesc = rRoll.sDesc .. '\nInitiative Effect Score: [+'..nTotal..']';
	else
		rRoll.sDesc = rRoll.sDesc .. '\nInitiative Effect Score: [-'..nTotal..']';
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	notifyApplyInit(rSource, nTotal);
end
