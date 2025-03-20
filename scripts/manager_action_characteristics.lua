--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("ability", modRoll);
	ActionsManager.registerResultHandler("ability", onRoll);
end

function performPartySheetRoll(draginfo, rActor, sCheck)
	local sNodeToQuery = 'woundtrack.' .. sCheck:sub(1,3):lower() .. '_mod';
	local nMod = DB.getValue(ActorManager.getCreatureNode(rActor), sNodeToQuery, -3);
	local rRoll = getRoll(rActor, 2, sCheck, nMod, 0);

	-- getRoll(rActor, nAttributeDice, sAttributeName, nMod, nEncMod, bSecretRoll, sExtra);

	local nTargetDC = DB.getValue("partysheet.checkdc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end

function modRoll(rSource, rTarget, rRoll)
	local nEffectsMod = 0;
	local aAddDesc = {};

	if EffectManagerTraveller.hasEffectCondition(rSource, "Head severe wound") then
		table.insert(aAddDesc,"[Head Severe Wound, -2 DM]");
		nEffectsMod = nEffectsMod -2;
	elseif EffectManagerTraveller.hasEffectCondition(rSource, "Head major wound") then
		table.insert(aAddDesc,"[Head Major Wound, -1 DM]");
		nEffectsMod = nEffectsMod -1;
	end

	if EffectManagerTraveller.hasEffectCondition(rSource, "Arms severe wound") then
		table.insert(aAddDesc,"[Arms Severe Wound, -1 DM]");
		nEffectsMod = nEffectsMod -2;
	elseif EffectManagerTraveller.hasEffectCondition(rSource, "Arms major wound") then
		table.insert(aAddDesc,"[Arms Major Wound, -1 DM]");
		nEffectsMod = nEffectsMod -1;
	end

	-- Arms and Torso would only really be physical activities
	if StringManager.contains(DataCommon.physicalcharacteristics, rRoll.sAttributeName) then
		if EffectManagerTraveller.hasEffectCondition(rSource, "Arms severe wound") then
			table.insert(aAddDesc,"[Arms Severe Wound, -1 DM]");
			nEffectsMod = nEffectsMod -1;
		elseif EffectManagerTraveller.hasEffectCondition(rSource, "Arms major wound") then
			table.insert(aAddDesc,"[Arms Major Wound, -1 DM]");
			nEffectsMod = nEffectsMod -1;
		end

		if EffectManagerTraveller.hasEffectCondition(rSource, "Torso severe wound") then
			table.insert(aAddDesc,"[Torso Severe Wound, -2 DM]");
			nEffectsMod = nEffectsMod -2;
		elseif EffectManagerTraveller.hasEffectCondition(rSource, "Torso major wound") then
			table.insert(aAddDesc,"[Torso Major Wound, -2 DM]");
			nEffectsMod = nEffectsMod -1;
		end
	end
	
	rRoll.nMod = rRoll.nMod + nEffectsMod;

	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end

	ActionsManager2.encodeDesktopMods(rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local nTarget;
	if rRoll.nTarget then
		nTarget = tonumber(rRoll.nTarget) or 0;
	else
		nTarget = DB.getValue("desktoppanel.difficultynumber", 8);
	end

	-- we finally have all the dice, let's report our success
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	rMessage.text = rMessage.text .. " (vs Diff. " .. nTarget .. ")";

	local nTotal = ActionsManager.total(rRoll);
	local n6srolled = 0;
	local nEffect = nTotal - nTarget

	CharManager.showEffect(nEffect, nTotal, nTarget, rMessage)

	Comm.deliverChatMessage(rMessage);

	local msg = {font = "narratorfont"};
	msg.text = rMessage.effectresulttext;
	msg.secret = rMessage.secret;

	Comm.deliverChatMessage(msg);

end

function getRoll(rActor, nAttributeDice, sAttributeName, nMod, nEncMod, bSecretRoll, sExtra)

	local nTotal = nAttributeDice;

	local modifierDice = 0;
	local bDescNotEmpty = true;
	local sStackDesc, nStackMod = ModifierStack.getStack(bDescNotEmpty);

    modifierDice = nStackMod;

	nTotal = nTotal + modifierDice + nEncMod;

	local rRoll = {};
    rRoll.sType = "ability";
    if nStackMod ~= 0 then
        rRoll.nMod = nMod + nStackMod;
    else
        rRoll.nMod = nMod
	end
	rRoll.aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor);
	rRoll.sDesc = "[CHARACTERISTIC] " .. StringManager.capitalizeAll(sAttributeName);

    if rRoll.nMod ~= 0 then
        if rRoll.nMod > 0 then
            rRoll.sDesc = rRoll.sDesc .. " (" .. "2D+".. rRoll.nMod .. ")";
        else
            rRoll.sDesc = rRoll.sDesc .. " (" .. "2D".. rRoll.nMod .. ")";
        end
    else
        rRoll.sDesc = rRoll.sDesc .. " (" .. "2D)";
    end

	rRoll.nMod = rRoll.nMod + nEncMod;

	if (modifierDice ~= 0) then
		rRoll.sDesc = rRoll.sDesc .. "\n + [MOD (" .. modifierDice ..")]"
	end

	if (nEncMod ~= 0) then
		rRoll.sDesc = rRoll.sDesc .. "\n + [ENCUMBERED (" .. nEncMod ..")]"
	end

	if sExtra then
		rRoll.sDesc = rRoll.sDesc .. " " .. sExtra;
	end

	ActionsManager2.encodeAdvantage(rRoll);

	rRoll.bSecret = bSecretRoll;
	rRoll.nTarget = nTargetDC;
	rRoll.sAttributeName = sAttributeName;

	return rRoll;
end

function performRoll(draginfo, rActor, nAttributeDice, sAttributeName, nMod, nEncMod, bSecretRoll, sExtra)

	local rRoll = getRoll(rActor, nAttributeDice, sAttributeName, nMod, nEncMod, bSecretRoll, sExtra);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getFullAttribute(sCurrentAttribute)
	local sFullAttribute = '';

	if sCurrentAttribute == 'str' then
		sFullAttribute = 'strength';
	elseif sCurrentAttribute == 'dex' then
		sFullAttribute = 'dexterity';
	elseif sCurrentAttribute == 'end' then
		sFullAttribute = 'endurance';
	elseif sCurrentAttribute == 'int' then
		sFullAttribute = 'intelligence';
	elseif sCurrentAttribute == 'edu' then
		sFullAttribute = 'education';
	elseif sCurrentAttribute == 'soc' then
		sFullAttribute = 'social';
	elseif sCurrentAttribute == 'psi' then
		sFullAttribute = 'psi';
	end

	return sFullAttribute;
end