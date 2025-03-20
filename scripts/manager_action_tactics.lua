--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--
OOB_MSGTYPE_APPLYINITMOD = "applyinitmod";

function onInit()
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYINITMOD, handleApplyInitMod);
	ActionsManager.registerModHandler("tactics", modTactics);
	ActionsManager.registerResultHandler("tactics", onTactics);
end

function handleApplyInitMod(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local nTotal = tonumber(msgOOB.nTotal) or 0;

	for _,v in pairs(CombatManager.getCombatantNodes()) do
        if DB.getValue(v, "friendfoe", "") == "friend" then
            DB.setValue(v, "init_mod", "number", nTotal);
        end
	end
end

function notifyApplyInitMod(rSource, nTotal)
	if not rSource then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYINITMOD;

	msgOOB.nTotal = nTotal;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
end

function getRoll(rActor, sSkillName, nSkillMod, sSkillStat, nStatMod)
	local rRoll = {};
	rRoll.sType = "tactics";
	rRoll.aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor);
	rRoll.nMod = nSkillMod or 0;
	rRoll.sSkillStat = sSkillStat
	rRoll.nSkillMod = nSkillMod
	rRoll.nStatMod = nStatMod
	rRoll.sDesc = "[TACTICS] " .. StringManager.capitalizeAll(sSkillName);

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

	ActionsManager2.encodeAdvantage(rRoll);

	return rRoll;
end

function performRoll(draginfo, rActor, sSkillName, nSkillMod, sSkillStat, nStatMod)
	local rRoll = getRoll(rActor, sSkillName, nSkillMod, sSkillStat, nStatMod);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modTactics(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

	-- Track how many tactics clauses before effects applied
	local nPreEffectClauses = 0 -- #(rRoll.clauses);

	if rSource then
		local bEffects = false;
	end

	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	ActionsManager2.encodeDesktopMods(rRoll);
	for _,vDie in ipairs(aAddDice) do
		if vDie:sub(1,1) == "-" then
			table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
		else
			table.insert(rRoll.aDice, "p" .. vDie:sub(2));
		end
	end
	rRoll.nMod = rRoll.nMod + nAddMod;

	-- Handle fixed damage option
	if not ActorManager.isPC(rSource) and OptionsManager.isOption("NPCD", "fixed") then
		local aFixedClauses = {};
		local aFixedDice = {};
		local nFixedPositiveCount = 0;
		local nFixedNegativeCount = 0;
		local nFixedMod = 0;

		for kClause,vClause in ipairs(rRoll.clauses) do
			if kClause <= nPreEffectClauses then
				local nClauseFixedMod = 0;
				for kDie,vDie in ipairs(vClause.dice) do
					if vDie:sub(1,1) == "-" then
						nFixedNegativeCount = nFixedNegativeCount + 1;
						nClauseFixedMod = nClauseFixedMod - math.floor(math.ceil(tonumber(vDie:sub(3)) or 0) / 2);
						if nFixedNegativeCount % 2 == 0 then
							nClauseFixedMod = nClauseFixedMod - 1;
						end
					else
						nFixedPositiveCount = nFixedPositiveCount + 1;
						nClauseFixedMod = nClauseFixedMod + math.floor(math.ceil(tonumber(vDie:sub(2)) or 0) / 2);
						if nFixedPositiveCount % 2 == 0 then
							nClauseFixedMod = nClauseFixedMod + 1;
						end
					end
					vClause.dice = {};
					vClause.modifier = vClause.modifier + nClauseFixedMod;
				end
				nFixedMod = nFixedMod + nClauseFixedMod;
			else
				for kDie,vDie in ipairs(vClause.dice) do
					table.insert(aFixedDice, vDie);
				end
			end

			table.insert(aFixedClauses, vClause);
		end

		rRoll.clauses = aFixedClauses;
		rRoll.aDice = aFixedDice;
		rRoll.nMod = rRoll.nMod + nFixedMod;
	end
end

function onTactics(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");

	local nTotal = ActionsManager.total(rRoll);
	-- we can work out the tactics efft here
	local nInitModEffect, sEffectMessage = calculateTacticsEffect(rRoll, nTotal, rMessage)

	Comm.deliverChatMessage(rMessage);
    -- Get effect

    notifyApplyInitMod(rSource, nInitModEffect);

    ChatManager.SystemMessage(sEffectMessage);
end

--
-- UTILITY FUNCTIONS
--

function calculateTacticsEffect(rRoll, nTotal, rMessage)
	local nTotal = ActionsManager.total(rRoll);

    local nEffect = nTotal - 8

    local sFormat = Interface.getString("char_tactics_modifier");
    local sMsg = string.format(sFormat, nEffect);

    return nEffect, sMsg;
end
