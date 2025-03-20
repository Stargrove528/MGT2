--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

TASK = "";

OOB_MSGTYPE_APPLYTASK = "applytask";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYTASK, handleApplyTask);

	ActionsManager.registerModHandler("task", modTask);
	ActionsManager.registerResultHandler("task", onTaskRoll);
end

function handleApplyTask(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);

	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyTask(rSource, msgOOB.rTarget, msgOOB.sTaskType, msgOOB.sDesc, msgOOB.nTotal, msgOOB.nEffect, msgOOB.sResults);
end

function notifyApplyTask(rSource, rTarget, sTaskType, sDesc, nTotal, nEffect, sResults)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYTASK;

	msgOOB.sTaskType = sTaskType;
	msgOOB.nTotal = nTotal;
	msgOOB.sDesc = sDesc;
	msgOOB.sResults = sResults;
	msgOOB.nEffect = nEffect;
	msgOOB.rTarget = rTarget;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
end

--
-- DROP HANDLING
--

function onDrop(nodetype, nodename, draginfo)
	local rSource = ActionsManager.decodeActors(draginfo);
    local rTarget = nodename;

    TASK = nodename;

	-- Swap Skill for Task
	local sDragType = draginfo.getType();
    local sDragDesc = draginfo.getDescription();
    local sDragString = draginfo.getStringData();
    if sDragType == "skill" then
        sDragDesc = sDragDesc:gsub('SKILL','TASK');
        sDragString = sDragString:gsub('SKILL','TASK');
        draginfo.setType('task');
        draginfo.setDescription(sDragDesc);
        draginfo.setStringData(sDragString);
        draginfo.setSlotType('task');
        sDragType = "task";

        if StringManager.contains(GameSystem.targetactions, sDragType) then
            ActionsManager.actionDrop(draginfo, rTarget);
            return true;
        end
    end
end

--
-- EVENTS
--

function modTask(rSource, rTarget, rRoll)
	local bAssist = Input.isShiftPressed();
	if bAssist then
		rRoll.sDesc = rRoll.sDesc .. " [ASSIST]";
	end

	if rSource then
		local bEffects = false;

		-- Determine skill used
		local sSkillLower = "";
		local sSkill = string.match(rRoll.sDesc, "%[TASK%] ([^[]+)");
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

        -- Task Modifier
        local taskNode = DB.findNode(TASK);
		local sSourceNode = ActorManager.getCreatureNodeName(rSource);

        local sOverrideStat = DB.getValue(taskNode, 'statrequired', ''):lower();
        local nOverrideValue = DB.getValue(sSourceNode .. '.attributes.' .. sOverrideStat:lower() .. '_mod', 0);

		-- Determine ability used with this skill
		if sOverrideStat ~= "" then
			rRoll.sDesc = rRoll.sDesc .. " [Using " .. sOverrideStat;
			if nOverrideValue < 0 then
				rRoll.sDesc = rRoll.sDesc .. " = " .. nOverrideValue .. "]";
			else
				rRoll.sDesc = rRoll.sDesc .. " = +" .. nOverrideValue .. "]";
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
			nEffectsMod = nEffectsMod -2;
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


        if taskNode then
            local nTaskModifier = DB.getValue(taskNode, 'mod');
            if nTaskModifier ~= 0 then
                rRoll.nMod = rRoll.nMod + nTaskModifier;
                rRoll.sDesc = rRoll.sDesc .. "[Task Mod " .. nTaskModifier .. "]";
            end
        end

        local nLastEffect = 0;
		local nOrder = DB.getValue(taskNode, 'order', -1);

        for _,v in ipairs(DB.getChildList(DB.getParent(taskNode))) do
			if DB.getValue(v,'order') == (nOrder -1) then
				nLastEffect = DB.getValue(v, 'effect', 0);
				break;
			end
        end

        if nLastEffect ~= 0 then
            rRoll.nMod = rRoll.nMod + nLastEffect;
			if nLastEffect >= 0 then
            	rRoll.sDesc = rRoll.sDesc .. "[DM to check: +" .. nLastEffect .. "]";
			else
				rRoll.sDesc = rRoll.sDesc .. "[DM to check: " .. nLastEffect .. "]";
			end
        end

		CharManager.checkTraits(sSourceNode, rRoll);

	end

	ActionsManager2.encodeDesktopMods(rRoll);
end


function onTaskRoll(rSource, rTarget, rRoll)
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

	-- Show DM for next Roll
	local nDMForNextRoll = 0;
	if nEffect <= -6 then
		nDMForNextRoll = -3;
	elseif nEffect <= -2 then
		nDMForNextRoll = -2;
	elseif nEffect <= -1 then
		nDMForNextRoll = -1;
	elseif nEffect == 0 then
		nDMForNextRoll = 1;
	elseif nEffect <= 5 then
		nDMForNextRoll = 2;		
	elseif nEffect >= 6 then
		nDMForNextRoll = 3;		
	end

	nEffect = nDMForNextRoll;

	local nTotal = ActionsManager.total(rRoll);
	Comm.deliverChatMessage(rMessage);

	local msg = {font = "narratorfont"};
	msg.text = rMessage.effectresulttext;
	msg.secret = rMessage.secret;

	Comm.deliverChatMessage(msg);

	local taskNode = TASK;
	rTarget = taskNode;

	notifyApplyTask(rSource, rTarget, rRoll.sType, rRoll.sDesc, nTotal, nEffect, msg);
end

function applyTask(rSource, rTarget, sTaskType, sDesc, nTotal, nEffect, sResults)
    -- We need to update the task now
    local taskNode = DB.findNode(rTarget);
    if taskNode then
        DB.setValue(taskNode, 'effect', 'number', nEffect);
        DB.setValue(taskNode, 'result', 'number', nTotal);
    end
	-- Check is any remaining tasks, otherwise 'hide'
	local bComplete = true;
	
	for _,v in ipairs(DB.getChildList(DB.getParent(taskNode))) do
		nResults = DB.getValue(v, 'result', 0);
		if nResults == 0 then
			bComplete = false;
			break;
		end
	end	

	-- Shall we hide it
	if bComplete then
		local nodeTaskChain = DB.getChild(taskNode, "...");

		DB.setValue(nodeTaskChain, 'taskvis', 'number', 0);
		-- And clear the DM as it's not going to be used
		DB.setValue(taskNode, 'effect', 'number', 0);
		
		-- Announce
		local sFormat = Interface.getString("tc_completed");
		local msg = {font = "msgfont"};
		msg.text = string.format(sFormat, DB.getValue(nodeTaskChain,'description'));
		Comm.deliverChatMessage(msg);
	else
		local msg = {font = "narratorfont"};
		if tonumber(nEffect) >= -1 then
			msg.text = "(DM for next roll: +" .. nEffect .. ")";
		else
			msg.text = "(DM for next roll: " .. nEffect .. ")";
		end
		
		Comm.deliverChatMessage(msg);
	end
end

