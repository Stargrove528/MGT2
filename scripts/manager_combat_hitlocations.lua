--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYHITLOCATIONS = "applyhitlocation";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYHITLOCATIONS, self.handleApplyHitLocation);
	ActionsManager.registerResultHandler("combathitlocation", self.onHitLocation);
end

function handleApplyHitLocation(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);

	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyHitLocation(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sAttackType, msgOOB.sDesc, nTotal, msgOOB.sResults);	
end

function notifyApplyHitLocation(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYHITLOCATIONS;

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

function onHitLocation(rSource, rTarget, rRoll)
    local nTotal = ActionsManager.total(rRoll);

    if nTotal > 6 then
        nTotal = 6;
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
		notifyApplyHitLocation(rSource, rTarget, rRoll.bTower, rRoll.sType, rRoll.sDesc, rAction.nTotal, table.concat(rAction.aMessages, " "));
	end
end

function rollForHitLocation(node)
	local rActor = ActorManager.resolveActor(node);

    local rAction = {};
    rAction.nMod = 0;

	performRoll(nil, rActor, rAction);
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};

	rRoll.sType = "combathitlocation";
	rRoll.aDice = DiceRollManager.getActorDice({ "d6" }, rActor);
	rRoll.nMod = 0;
	rRoll.sDesc = "[HIT LOCATION]";

	return rRoll;
end

function applyHitLocation(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};

	msgShort.text = "Hit Location ->";
	msgLong.text = "Hit Location [" .. nTotal .. "] ->";
	if rTarget then
		msgShort.text = msgShort.text .. DataCommon.aHitLocations[nTotal];
		msgLong.text = msgLong.text .. DataCommon.aHitLocations[nTotal];
	end
	if sResults ~= "" then
		msgLong.text = msgLong.text .. " " .. sResults;
	end

	msgShort.icon = "roll_hitlocation";
	msgLong.icon = "roll_hitlocation";

	ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);

	-- Now we set the 'Hit Location' so we can know if a Damage Roll is applied
	local nodeTargetCT = ActorManager.getCTNode(rTarget);
	DB.setValue(nodeTargetCT, "last_hit_location", "string", DataCommon.aHitLocations[nTotal]);
end

