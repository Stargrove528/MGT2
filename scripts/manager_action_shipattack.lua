--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATK = "applyshipatk";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATK, handleApplyAttack);

	ActionsManager.registerTargetingHandler("shipattack", onTargeting);
	ActionsManager.registerModHandler("shipattack", modAttack);
	ActionsManager.registerResultHandler("shipattack", onAttack);
end

function handleApplyAttack(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);

	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyAttack(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sAttackType, msgOOB.sDesc, nTotal, msgOOB.sResults);
end

function notifyApplyAttack(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYATK;

	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sAttackType = sAttackType;
	msgOOB.nTotal = nTotal;
	msgOOB.sDesc = sDesc;
	msgOOB.sResults = sResults;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	Comm.deliverOOBMessage(msgOOB, "");
end

function onTargeting(rSource, aTargeting, rRolls)
	if #aTargeting == 0 or (#aTargeting == 1 and #aTargeting[1] == 0) then
		return TargetingManager.getFullTargets(rSource);
	end
	return aTargeting;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "shipattack";
	rRoll.aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor);
	rRoll.nMod = rAction.modifier or 0;
	rRoll.sArc = rAction.arc;
	rRoll.sTraits = rAction.weaponTraits;

	rRoll.sDesc = "[SHIP ATTACK] " .. StringManager.capitalizeAll(rAction.label);
	if rRoll.nMod > 0 then
		rRoll.sDesc = rRoll.sDesc .. "(2D +" .. rRoll.nMod .. ")";
	elseif rRoll.nMod < 0 then
		rRoll.sDesc = rRoll.sDesc .. "(2D " .. rRoll.nMod .. ")";
	else
		rRoll.sDesc = rRoll.sDesc .. "(2D)";
	end

	-- Check for Traits
	local tTraitAddDesc = {};
	local sTraitsLower = (rAction.weaponTraits or ""):lower();
	if sTraitsLower:find("pulse laser") then
		table.insert(tTraitAddDesc, "[PULSE LASER +2]");
		rRoll.nMod = rRoll.nMod + 2;
	end
	if sTraitsLower:find("beam laser") then
		table.insert(tTraitAddDesc, "[BEAM LASER +4]");
		rRoll.nMod = rRoll.nMod + 4;
	end
	if sTraitsLower:find("laser drill") then
		table.insert(tTraitAddDesc, "[LASER DRILL -3]");
		rRoll.nMod = rRoll.nMod - 3;
	end
	if sTraitsLower:find("inaccurate") then
		table.insert(tTraitAddDesc, "[INACCURATE -1]");
		rRoll.nMod = rRoll.nMod - 1;
	elseif sTraitsLower:find("accurate") then
		table.insert(tTraitAddDesc, "[ACCURATE +1]");
		rRoll.nMod = rRoll.nMod + 1;
	end
	if #tTraitAddDesc > 0 then
		rRoll.sDesc = string.format("%s %s", rRoll.sDesc, table.concat(tTraitAddDesc, " "));
	end

    -- Add any desktop modifiers (the +1, +2 etc)
    ActionsManager2.encodeDesktopMods(rRoll);

	-- Boon/Bane
	ActionsManager2.encodeAdvantage(rRoll);

	return rRoll;
end

function modAttack(rSource, rTarget, rRoll)
	clearCritState(rSource);

	ActionsManager2.encodeDesktopMods(rRoll);
end

function onAttack(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	local nodeTarget = "";

	local rAction = {};
	rAction.nTotal = ActionsManager.total(rRoll);
	rAction.aMessages = {};

	-- depending if we are attacking a ship or a person this could be a destruction attack
	rMessage.effectresulttext = '';

	if rAction.nTotal >= 8 then
		rAction.sResult = "hit";
		rMessage.effectresulttext = "[HIT]";
	else
		rAction.sResult = "miss";
		rMessage.effectresulttext = "[MISS]";
	end

	local nEffect = rAction.nTotal - 8;
	if rAction.nTotal >= 14 then
		 table.insert(rAction.aMessages, " [CRITICAL] ");
	end

	Comm.deliverChatMessage(rMessage);

	if nEffect >= 0 then
		if nEffect == 0 then
			rMessage.effectresulttext = rMessage.effectresulttext .. " [Marginal Success]";
		elseif (nEffect >= 1) and (nEffect <= 5) then
			rMessage.effectresulttext = rMessage.effectresulttext .. " [Average Success +" .. nEffect .. " DMG]";
		elseif nEffect >= 6 then
			rMessage.effectresulttext = rMessage.effectresulttext .. " [Exceptional Success +" .. nEffect .. " DMG]";
		end
		setCritState(rSource, nEffect);
	end

	local msg = { font = "narratorfont" };
	msg.text = rMessage.effectresulttext;

	Comm.deliverChatMessage(msg);

	if rTarget then
		notifyApplyAttack(rSource, rTarget, rRoll.bTower, rRoll.sType, rRoll.sDesc, rAction.nTotal, table.concat(rAction.aMessages, " "));

		-- REMOVE TARGET ON MISS OPTION
		if (rAction.sResult == "miss") and not string.match(rRoll.sDesc, "%[FULL%]") then
			local bRemoveTarget = false;
			if OptionsManager.isOption("RMMT", "on") then
				bRemoveTarget = true;
			elseif rRoll.bRemoveOnMiss then
				bRemoveTarget = true;
			end

			if bRemoveTarget then
				TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
			end
		end
	end
end

function applyAttack(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	local msgShort = { font = "msgfont" };
	local msgLong = { font = "msgfont" };

	msgShort.text = "Attack ->";
	msgLong.text = "Attack [" .. nTotal .. "] ->";

	if rTarget then
		msgShort.text = msgShort.text .. " [at " .. rTarget.sName .. "]";
		msgLong.text = msgLong.text .. " [at " .. rTarget.sName .. "]";
	end
	if sResults ~= "" then
		msgLong.text = msgLong.text .. " " .. sResults;
	end

	msgShort.icon = "roll_attack";
	if string.match(sResults, "HIT%]") then
		msgLong.icon = "roll_attack_hit";
	elseif string.match(sResults, "MISS%]") then
		msgLong.icon = "roll_attack_miss";
	else
		msgLong.icon = "roll_attack";
	end

	ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end

local aCritState = {};

function attackResult(rAttack)
	local rAttackResult = {}

	-- Miss
	if rAttack.nAttackScore < rAttack.nDefenseScore then
		rAttackResult.bMiss = true

	-- Hit
	elseif rAttack.nAttackScore <= rAttack.nDefenseScore then
		rAttackResult.bHit = true
	end

	return rAttackResult
end

function attackResultFromPendingResult(nodePendingResult)
	if nodePendingResult then
		return attackResult({
			nAttackScore = DB.getValue(nodePendingResult, "attackscore", 0),
			nDefenseScore = DB.getValue(nodePendingResult, "defensescore", 0)
		})
	end
end

aCritState = {};
aEffectMod = {};

function setCritState(rSource, nEffectModifier)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	if nEffectModifier >= 0 then
		aCritState[sSourceCT] = true;
	end
	aEffectMod[sSourceCT] = nEffectModifier;
end

function clearCritState(rSource)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT ~= "" then
		aCritState[sSourceCT] = nil;
		aEffectMod[sSourceCT] = 0;
	end
end

function isCrit(rSource, bClearState)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return false;
	end
	local bState = aCritState[sSourceCT];
	local nEffectModifier = aEffectMod[sSourceCT];
	if bState and bClearState then
		aCritState[sSourceCT] = nil;
		aEffectMod[sSourceCT] = 0;
	end
	return bState, nEffectModifier;
end
