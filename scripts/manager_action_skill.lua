--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("skill", modSkill);
	ActionsManager.registerResultHandler("skill", onRoll);
	ActionsManager.registerModHandler("psiability", modSkill);
	ActionsManager.registerResultHandler("psiability", onRollPSIAbility);
end

function performPartySheetRoll(draginfo, rActor, sSkill, sSkillCharacteristic)
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if sNodeType ~= "pc" then
		return;
	end

	local sNodeToQuery = 'woundtrack.' .. sSkillCharacteristic:sub(1,3):lower() .. '_mod';
	local nMod = DB.getValue(ActorManager.getCreatureNode(rActor), sNodeToQuery, -3);

	local rRoll = nil;
	for _,v in ipairs(DB.getChildList(nodeActor, "skilllist")) do
		if DB.getValue(v, "name", "") == sSkill then
			nLevel = DB.getValue(v, "level", 0);
			nSkillMod = DB.getValue(v, "mod", 0);
			rRoll = getRoll(rActor, sSkill, nMod + nLevel + nSkillMod, sSkillCharacteristic:sub(1,3), 0);
			break;
		end
		rRoll = getRoll(rActor, "Unskilled Skill", nMod-3, sSkillCharacteristic:sub(1,3), 0);
	end

	-- getRoll(rActor, sSkillName, nSkillMod, sSkillStat, nStatMod, bPSIRoll)
	local nTargetDC = DB.getValue("partysheet.skilldc", 0);
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

function performPCRoll(draginfo, rActor, nodeSkill)
	local sSkillName = DB.getValue(nodeSkill, "label", "");
	local sSubskillName = DB.getValue(nodeSkill, "sublabel", "");
	if sSubskillName ~= "" then
		sSkillName = sSkillName .. " (" .. sSubskillName .. ")";
	end

	local nSkillMod = DB.getValue(nodeSkill, "total", 0);
	if (nSkillMod > 0) then
		nSkillMod = 0
	end
	local sSkillStat = DB.getValue(nodeSkill, "statname", "");

	performRoll(draginfo, rActor, sSkillName, nSkillMod, sSkillStat);
end

function getRoll(rActor, sSkillName, nSkillMod, sSkillStat, nStatMod, bPSIRoll)
	local rRoll = {};
	rRoll.sType = "skill";
	rRoll.aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor);
	rRoll.nMod = nSkillMod or 0;
	rRoll.sSkillStat = sSkillStat
	rRoll.nSkillMod = nSkillMod
	rRoll.nStatMod = nStatMod

	if not bPSIRoll then
		rRoll.sDesc = "[SKILL] " .. StringManager.capitalizeAll(sSkillName);
	else
		rRoll.sDesc = "[PSI ABILITY] " .. StringManager.capitalizeAll(sSkillName);
		rRoll.nPSICost = nStatMod
		rRoll.sType = "psiability";
	end

	local nJoaT = CharManager.getJackOfAllTradesSkillLevel(ActorManager.getCreatureNode(rActor));

	if nJoaT ~= nil and nJoaT > 0 and sSkillName:lower() == "unskilled skill" then
		rRoll.nMod = rRoll.nMod + nJoaT;
	end

	if rRoll.nMod ~= 0 then
        if rRoll.nMod > 0 then
            rRoll.sDesc = rRoll.sDesc .. " (" .. "2D+".. rRoll.nMod .. ")";
        else
            rRoll.sDesc = rRoll.sDesc .. " (" .. "2D".. rRoll.nMod .. ")";
        end
    else
        rRoll.sDesc = rRoll.sDesc .. " (" .. "2D)";
	end

	if sExtra then
		rRoll.sDesc = rRoll.sDesc .. " " .. sExtra;
	end
	if nJoaT ~= nil and nJoaT > 0 and sSkillName:lower() == "unskilled skill" then
		rRoll.sDesc = rRoll.sDesc .. " [JoaT " .. tostring(nJoaT) .. " applied]";
	end

	ActionsManager2.encodeAdvantage(rRoll);

	return rRoll;
end

function performRoll(draginfo, rActor, sSkillName, nSkillMod, sSkillStat, nStatMod, bPSIRoll, bSecretRoll)
	local rRoll = getRoll(rActor, sSkillName, nSkillMod, sSkillStat, nStatMod, bPSIRoll, bSecretRoll);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modSkill(rSource, rTarget, rRoll)
	local bAssist = Input.isShiftPressed();
	if bAssist then
		rRoll.sDesc = rRoll.sDesc .. " [ASSIST]";
	end

	if rSource then
		local bEffects = false;

		-- Determine skill used
		local sSkillLower = "";
		local sSkill = string.match(rRoll.sDesc, "%[SKILL%] ([^[]+)");
		if sSkill then
			sSkillLower = string.lower(StringManager.trim(sSkill));
		end

		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = SkillsManager.ability_stol[sModStat];
		else
			for k, v in pairs(SkillsManager.getSkills()) do
				if string.lower(k) == sSkillLower then
					sActionStat = v.stat;
				end
			end
		end

		local sSourceNode = ActorManager.getCreatureNodeName(rSource);
		local nOverrideValue, sOverrideStat = ActionsManager2.endcodeDesktopAttributes(rRoll, sSourceNode)

		-- Determine ability used with this skill
		if sOverrideStat ~= "" then
			if not rRoll.bNoStatSelected then
				rRoll.sDesc = rRoll.sDesc .. " [OVERRIDE - " .. sOverrideStat;
			else
				rRoll.sDesc = rRoll.sDesc .. " [Using " .. sOverrideStat;
			end
			if nOverrideValue < 0 then
				rRoll.sDesc = rRoll.sDesc .. " = 2D" .. nOverrideValue .. "]";
			else
				rRoll.sDesc = rRoll.sDesc .. " = 2D+" .. nOverrideValue .. "]";
			end

			-- Seems like a hack but it'll do for now
			if string.find(rRoll.sDesc, "Unskilled Skill") then
				rRoll.nMod = -3 + (rRoll.nMod +3) + nOverrideValue;
			else
				rRoll.nMod = rRoll.nMod - (rRoll.nStatMod or 0) + nOverrideValue;
			end
		end

		-- Effects here.
		local bEffects = false;
		local nEffectsMod = 0;

		if EffectManagerTraveller.hasEffectCondition(rSource, "Fatigued") then
			bEffects = true;
			rRoll.sDesc = rRoll.sDesc .. "[Fatigue-BANE]";
			table.insert(rRoll.aDice, "d6");
		end

		if bEffects then
			rRoll.nMod = rRoll.nMod + nEffectsMod
			rRoll.sDesc = string.format("%s %s", rRoll.sDesc, EffectManager.buildEffectOutput(nEffectsMod));
		end

		local nSkillDifferenceDM = CharManager.getArmourWornModifier(sSourceNode)

		if nSkillDifferenceDM < 0 then
			rRoll.sDesc = rRoll.sDesc .. "[Armour " .. nSkillDifferenceDM .. "]";
			rRoll.nMod = rRoll.nMod + nSkillDifferenceDM;
		end

		CharManager.checkTraits(sSourceNode, rRoll);

	end

	ActionsManager2.encodeDesktopMods(rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	local nTotal = ActionsManager.total(rRoll);

	local nTarget;
	if rRoll.nTarget then
		nTarget = tonumber(rRoll.nTarget) or 0;
	else
		nTarget = DB.getValue("desktoppanel.difficultynumber", 8);
	end

	rMessage.text = rMessage.text .. "\n(vs Difficulty " .. nTarget .. ")";

	local nEffect = nTotal - nTarget;

	CharManager.showEffect(nEffect, nTotal, nTarget, rMessage);

	local nTotal = ActionsManager.total(rRoll);
	Comm.deliverChatMessage(rMessage);

	local msg = {font = "narratorfont"};
	msg.text = rMessage.effectresulttext;
	msg.secret = rMessage.secret;

	Comm.deliverChatMessage(msg);
end

function onRollPSIAbility(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	local nTotal = ActionsManager.total(rRoll);

	local nTarget;
	if rRoll.nTarget then
		nTarget = tonumber(rRoll.nTarget) or 0;
	else
		nTarget = DB.getValue("desktoppanel.difficultynumber", 8);
	end

	rMessage.text = rMessage.text .. "\n(vs Difficulty " .. nTarget .. ")";

	local nEffect = nTotal - nTarget
	local nPSICost = 0

	if nTotal >= nTarget then
		nPSICost = tonumber(rRoll.nPSICost)
	else
		nPSICost = 1
	end

	CharManager.showEffect(nEffect, nTotal, nTarget, rMessage)

	local nTotal = ActionsManager.total(rRoll);
	Comm.deliverChatMessage(rMessage);

	local msg = {font = "narratorfont"};
	msg.text = rMessage.effectresulttext;
	msg.secret = rMessage.secret;

	Comm.deliverChatMessage(msg);

	reducePSIStrength(rSource, nPSICost);
end

function reducePSIStrength(rActor, nCost)
	if (nCost or 0) == 0 then
		ChatManager.SystemMessage('No PSI Cost set');
		return;
	end

	if nCost > 0 then
		nodeActor = ActorManager.getCreatureNode(rActor);

		local nPSIStrength = DB.getValue(nodeActor, "woundtrack.psi", 0);
		local sFormat = Interface.getString("char_psitalent_psistrength")

		if nPSIStrength >= nCost then
			DB.setValue(nodeActor, "woundtrack.psi", "number", nPSIStrength - nCost)
			ChatManager.SystemMessage(string.format(sFormat, nCost, nPSIStrength - nCost));
		else
			DB.setValue(nodeActor, "woundtrack.psi", "number", 0)
			ChatManager.SystemMessage(string.format(sFormat, nCost, 0));

			local nEndLoss = nCost - nPSIStrength
			local nEnduranceTotal = DB.getValue(nodeActor, "woundtrack.end", 0);
			if nEnduranceTotal >= nEndLoss then
				DB.setValue(nodeActor, "woundtrack.end", "number", nEnduranceTotal - nEndLoss)
			else
				DB.setValue(nodeActor, "woundtrack.end", "number", 0)
			end
			ChatManager.SystemMessage(string.format("Excess PSI cost of '%s' taken as Damage to Endurance", nEndLoss));
		end

		-- re-calc the PSI Strength DM
		local nValue = DB.getValue(nodeActor, "woundtrack.psi", 0);
		local nPSIStrengthDM = GameSystem.calculateCharacteristicDM(nValue)
		DB.setValue(nodeActor, "woundtrack.psi_dm", "number", nPSIStrengthDM)
	end
end
