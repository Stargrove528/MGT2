--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYDMG = "applydmg";
OOB_MSGTYPE_APPLYDMGSTATE = "applydmgstate";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMG, handleApplyDamage);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMGSTATE, handleApplyDamageState);

	ActionsManager.registerModHandler("damage", modDamage);
	ActionsManager.registerPostRollHandler("damage", onDamageRoll);
	ActionsManager.registerResultHandler("damage", onDamage);
end

function handleApplyDamage(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	if rTarget then
		rTarget.nOrder = msgOOB.nTargetOrder;
	end

	local nTotal = tonumber(msgOOB.nTotal) or 0;

	applyDamage(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sDamage, nTotal);
end

function notifyApplyDamage(rSource, rTarget, bSecret, sDesc, nTotal)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDMG;

	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end

	msgOOB.nTotal = nTotal;
	msgOOB.sDamage = sDesc;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
	msgOOB.nTargetOrder = rTarget.nOrder;

	Comm.deliverOOBMessage(msgOOB, "");
end

function getDamageAction(vAttack, bSpacecraft)
	local rAction = {
		sType = "damage",
		nMod = 0,
		clauses = {},
	};
	local sDamage;

	if type(vAttack) == "databasenode" then
		rAction.label = DB.getValue(vAttack, "name", "");
		rAction.sTraits = DB.getValue(vAttack, "traits", "");
		rAction.range = DB.getValue(vAttack, "range", "");
		sDamage = DB.getValue(vAttack, "damage", "");

		rAction.node = DB.getPath(vAttack);

	else -- "windowinstance"
		rAction.label = vAttack.name.getValue();
		rAction.sTraits = vAttack.traits.getValue();
		rAction.range = vAttack.range.getValue();
		sDamage = vAttack.damage.getValue();

		local _,sWeaponRecord = vAttack.link.getValue();
		rAction.node = sWeaponRecord;
	end

	local sDefaultDmgType;
	if bSpacecraft then
		sDefaultDmgType = SpacecraftManager.getSpacecraftDamageType(rAction.sTraits);
	else
		sDefaultDmgType = "kinetic";
	end
	local aDice, nMod, sDamageType = parseDamageString(sDamage, sDefaultDmgType);
	table.insert(rAction.clauses, { sDamage = sDamage, dice = aDice, modifier = nMod, dmgtype = sDamageType });
	rAction.aDice = aDice;

	return rAction;
end
function parseDamageString(sDamage, sDefault)
	if (sDamage or "") == "" then
		return {}, 0, "";
	end
	
	local aWords = StringManager.parseWords(sDamage);
	local aDice, nMod = DiceManagerTraveller.convertDamageStringToDice(aWords[1]);

	-- Determine damage type
	local sDamageType = nil;
	local i = 1;
	while aWords[i] do
		if StringManager.contains(DataCommon.dmgtypes, aWords[i]:lower()) then
			sDamageType = aWords[i]:lower()
		end
		i = i + 1;
	end

	return aDice, nMod, sDamageType or sDefault;
end

function getRoll(rActor, rAction)
	local rRoll = {};

	rRoll.sType = "damage";
	rRoll.aDice = {};
	rRoll.nMod = rAction.nMod or 0;
	rRoll.range = rAction.range;
	rRoll.node = rAction.node;

	rRoll.sDesc = "[DAMAGE";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] "
	rRoll.sDesc = rRoll.sDesc .. "\n" .. StringManager.capitalizeAll(rAction.label);

	-- Save the damage clauses in the roll structure
	rRoll.clauses = rAction.clauses;

	-- Add the dice and modifiers
	local nDamageModifier = 0;
	for _,vClause in pairs(rRoll.clauses) do
		-- Any additional damage from this weapon
		nDamageModifier = nDamageModifier + vClause.modifier
		if vClause.sDamage:upper():match("DD") then
			rRoll.bDestructive = true;
		end
		for _,vDie in ipairs(vClause.dice) do
			table.insert(rRoll.aDice, vDie);
		end
	end

	-- Encode the damage types
	encodeDamageTypes(rRoll);

	if rRoll.bDestructive then
		rRoll.sDesc = rRoll.sDesc .. " [DESTRUCTIVE]";
		nDamageModifier = 0;  -- no effect damage can be added
	end

	local sAPWeapon = string.match(rAction.sTraits, "AP %d+");
	if sAPWeapon ~= "" and sAPWeapon ~= nil then
		nAPValue = string.match(sAPWeapon, "%d+")
		rRoll.sDesc = rRoll.sDesc .. " [AP " .. nAPValue .. "]";
	end

	-- Any additional desktop damage
	if rRoll.nMod ~= 0 and rRoll.nMod ~= nil then
		if rRoll.nMod < 0 then
			rRoll.sDesc = rRoll.sDesc .. " [".. rRoll.nMod .. " DMG]";
		else
			rRoll.sDesc = rRoll.sDesc .. " [+".. rRoll.nMod .. " DMG]";
		end
	end

	local nStrengthModifier = 0;
	if rRoll.range:sub(1,1) == "M" then
		local nodeActor = ActorManager.getCreatureNode(rActor);
		local sTypeLower = DB.getValue(nodeActor, "type", ""):lower();
		if (sTypeLower == "") or (sTypeLower == "humanoid") then
			nStrengthModifier = DB.getValue(nodeActor, "attributes.str_mod", 0);
		end
	end
	if nStrengthModifier ~= 0 then
		if rRoll.nMod < 0 then
			rRoll.sDesc = rRoll.sDesc .. " [STR ".. nStrengthModifier .. " DMG]";
		else
			rRoll.sDesc = rRoll.sDesc .. " [STR +".. nStrengthModifier .. " DMG]";
		end
	end

	rRoll.nMod = rRoll.nMod + nDamageModifier + nStrengthModifier;

	return rRoll;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modDamage(rSource, rTarget, rRoll)
	decodeDamageTypes(rRoll);
	-- Set up
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

	-- Build attack type filter
	local aAttackFilter = {};
	if rRoll.range == "R" then
		table.insert(aAttackFilter, "ranged");
	elseif rRoll.range == "M" then
		table.insert(aAttackFilter, "melee");
	elseif rRoll.range == "P" then
		table.insert(aAttackFilter, "psionic");
	end

	-- Determine critical
	local bCritical = Input.isShiftPressed();
	local bisCritial, nEffectModifier = ActionAttack.isCrit(rSource)

	if bisCritial then
		bCritical = true;
	end

	if nEffectModifier and nEffectModifier > 0 then
		table.insert(aAddDesc, "[+".. nEffectModifier .. " DMG]");
		rRoll.nMod = rRoll.nMod + nEffectModifier
	end

	-- Handle critical
	if bCritical then
		if nEffectModifier and nEffectModifier >= 6 then
			table.insert(aAddDesc, "[MIN DAMAGE 1]");
		end
	end

	-- Add notes to roll description
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end	

	ActionsManager2.encodeDesktopMods(rRoll, true);
end

function onDamageRoll(rSource, rRoll)
	-- Handle max damage or other types of special damage
	decodeDamageTypes(rRoll, true);
end

function onDamage(rSource, rTarget, rRoll)
	local bMinDamageApplies = false;

	-- Do we have a critical hit?
	-- But did we do any damage....
	local isCritHit = ActionAttack.isCrit(rSource,true);
	if isCritHit then
		bMinDamageApplies = true;
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");

	-- Send the chat message
	local bShowMsg = true;
	if rTarget and rTarget.nOrder and rTarget.nOrder ~= 1 then
		bShowMsg = false;
	end
	if bShowMsg then
		Comm.deliverChatMessage(rMessage);
	end

	-- Apply damage to the PC or CT entry referenced
	local nTotal = ActionsManager.total(rRoll);

	notifyApplyDamage(rSource, rTarget, rMessage.secret, rMessage.text, nTotal);

	local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);

	if rRoll.node then

		local vNode = rRoll.node;
		local sWeaponTraits = StringManager.trim(DB.getValue(DB.getPath(vNode, "traits"), ""):lower());

		if sWeaponTraits:find('one use') then

			local _, sRecord = DB.getValue(DB.getPath(vNode, "shortcut"));
			local nQuantity = DB.getValue(DB.getPath(sRecord, "count"), 0);

			if nQuantity > 1 then
				DB.setValue(DB.getPath(sRecord, "count"), "number", nQuantity-1);
				local sFormat = Interface.getString("char_message_reducedweaponcount");
				local sMsg = string.format(sFormat, DB.getValue(DB.getPath(vNode, "name"), ""), nQuantity -1);
				ChatManager.SystemMessage(sMsg);
				return
			end

			local sFormat = Interface.getString("char_message_removeweapon");
			local sMsg = string.format(sFormat, DB.getValue(DB.getPath(vNode, "name"), ""));
			ChatManager.SystemMessage(sMsg);

			DB.deleteNode(sRecord);
			DB.deleteNode(vNode);
		end
	end
end

--
-- UTILITY FUNCTIONS
--

function encodeDamageTypes(rRoll)
	for _,vClause in ipairs(rRoll.clauses) do
		if vClause.dmgtype and vClause.dmgtype ~= "" then
			local sDice = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
			rRoll.sDesc = rRoll.sDesc .. string.format(" [TYPE: %s (%s)]", vClause.dmgtype, sDice);
		end
	end
end

function decodeDamageTypes(rRoll, bFinal)
	-- Process each type clause in the damage description (INITIAL ROLL)
	local nMainDieIndex = 0;

	if rRoll.sDesc:find('%[DESTRUCTIVE%]') then
		rRoll.bDestructive = true;
	end

	rRoll.clauses = {};
	for sDamageType, sDamageDice in string.gmatch(rRoll.sDesc, "%[TYPE: ([^(]*) %(([^)]*)%)%]") do
		local rClause = {};
		rClause.dmgtype = StringManager.trim(sDamageType);
		rClause.dice, rClause.modifier = StringManager.convertStringToDice(sDamageDice:lower());
		rClause.nTotal = rClause.modifier;

		for kDie,vDie in ipairs(rClause.dice) do
			nMainDieIndex = nMainDieIndex + 1;
			if rRoll.aDice[nMainDieIndex] then

				if rRoll.aDice[nMainDieIndex].result and (rRoll.bDestructive == true or rRoll.bDestructive == "true") then
					rRoll.aDice[nMainDieIndex].result = rRoll.aDice[nMainDieIndex].result * 10;
				end
				rClause.nTotal = rClause.nTotal + (rRoll.aDice[nMainDieIndex].result or 0);
				if rRoll.aDice[nMainDieIndex].value then
					rRoll.aDice[nMainDieIndex].value = nil;
				end
			end
		end

		table.insert(rRoll.clauses, rClause);
	end

	-- Process each type clause in the damage description (DRAG ROLL RESULT)
	local nClauses = #(rRoll.clauses);
	for sDamageType, sDamageDice in string.gmatch(rRoll.sDesc, "%[TYPE: ([^(]*) %(([^)]*)%)]") do
		local sTotal = string.match(sDamageDice, "=(%d+)");
		if sTotal then
			local nTotal = tonumber(sTotal) or 0;

			local rClause = {};
			rClause.dmgtype = StringManager.trim(sDamageType);
			rClause.stat = "";
			rClause.dice = {};
			rClause.modifier = nTotal;
			rClause.nTotal = nTotal;

			table.insert(rRoll.clauses, rClause);
		end
	end

	if #(rRoll.clauses) == 0 then
		local rClause = {};
		rClause.dmgtype = "";
		rClause.stat = "";
		rClause.dice = {};
		rClause.modifier = rRoll.nMod;
		rClause.nTotal = rRoll.nMod;
		for _,vDie in ipairs(rRoll.aDice) do
			if type(vDie) == "table" then
				table.insert(rClause.dice, vDie.type);
				rClause.nTotal = rClause.nTotal + (vDie.result or 0);
			else
				table.insert(rClause.dice, vDie);
			end
		end

		table.insert(rRoll.clauses, rClause);
	end

	if bFinal then
		-- Remove damage type information from roll description
		rRoll.sDesc = string.gsub(rRoll.sDesc, " %[TYPE:[^]]*%]", "");
		local nFinalTotal = ActionsManager.total(rRoll);

		-- Handle minimum damage
		if nFinalTotal < 0 and rRoll.aDice and #rRoll.aDice > 0 then
			-- rRoll.sDesc = rRoll.sDesc .. " [MIN DAMAGE 1]";
			rRoll.nMod = rRoll.nMod - nFinalTotal;
			nFinalTotal = 0;
		end

		-- Capture any manual modifiers and adjust damage types accordingly
		-- NOTE: Positive values are added to first damage clause, Negative values reduce damage clauses until none remain
		local nClausesTotal = 0;
		for _,vClause in ipairs(rRoll.clauses) do
			nClausesTotal = nClausesTotal + vClause.nTotal;
		end
		if nFinalTotal ~= nClausesTotal then
			local nRemainder = nFinalTotal - nClausesTotal;
			if nRemainder > 0 then
				if #(rRoll.clauses) == 0 then
					table.insert(rRoll.clauses, { dmgtype = "", stat = "", dice = {}, modifier = nRemainder, nTotal = nRemainder})
				else
					rRoll.clauses[1].modifier = rRoll.clauses[1].modifier + nRemainder;
					rRoll.clauses[1].nTotal = rRoll.clauses[1].nTotal + nRemainder;
				end
			else
				for _,vClause in ipairs(rRoll.clauses) do
					if vClause.nTotal >= -nRemainder then
						vClause.modifier = vClause.modifier + nRemainder;
						vClause.nTotal = vClause.nTotal + nRemainder;
						break;
					else
						vClause.modifier = vClause.modifier - vClause.nTotal;
						nRemainder = nRemainder + vClause.nTotal;
						vClause.nTotal = 0;
					end
				end
			end
		end

		-- Collapse damage clauses into smallest set, then add to roll description as text
		local aDamage = getDamageStrings(rRoll.clauses);
		for _, rDamage in ipairs(aDamage) do
			local sDice = StringManager.convertDiceToString(rDamage.aDice, rDamage.nMod);
			local sDmgTypeOutput = rDamage.sType:lower();
			if sDmgTypeOutput == "" then
				sDmgTypeOutput = "kinetic";
			end
			rRoll.sDesc = rRoll.sDesc .. string.format(" [TYPE: %s (%s=%d)]", sDmgTypeOutput, sDice, rDamage.nTotal);
		end
	end
end

-- Collapse damage clauses by damage type (in the original order, if possible)
function getDamageStrings(clauses)
	local aOrderedTypes = {};
	local aDmgTypes = {};
	for _,vClause in ipairs(clauses) do
		local rDmgType = aDmgTypes[vClause.dmgtype];
		if not rDmgType then
			rDmgType = {};
			rDmgType.aDice = {};
			rDmgType.nMod = 0;
			rDmgType.nTotal = 0;
			rDmgType.sType = vClause.dmgtype;
			aDmgTypes[vClause.dmgtype] = rDmgType;
			table.insert(aOrderedTypes, rDmgType);
		end

		for _,vDie in ipairs(vClause.dice) do
			table.insert(rDmgType.aDice, vDie);
		end
		rDmgType.nMod = rDmgType.nMod + vClause.modifier;
		rDmgType.nTotal = rDmgType.nTotal + (vClause.nTotal or 0);

	end

	return aOrderedTypes;
end

--
-- DAMAGE APPLICATION
--

function checkReductionTypeHelper(rMatch, aDmgType)
	if not rMatch or (rMatch.mod ~= 0) then
		return false;
	end
	if #(rMatch.aNegatives) > 0 then
		local bMatchNegative = false;
		for _,vNeg in pairs(rMatch.aNegatives) do
			if StringManager.contains(aDmgType, vNeg) then
				bMatchNegative = true;
				break;
			end
		end
		return not bMatchNegative;
	end
	return true;
end

function checkReductionType(aReduction, aDmgType)
	for _,sDmgType in pairs(aDmgType) do
		-- very important that the damage type is lower case --
		sDmgType = string.lower(sDmgType);
		if checkReductionTypeHelper(aReduction[sDmgType], aDmgType) then
			return true;
		end
	end

	return false;
end

function checkVulnerability(aVuln, aDmgType)
	for _,sDmgType in pairs(aDmgType) do
		-- very important that the damage type is lower case --
		sDmgType = string.lower(sDmgType);

		-- swap out Psionic attacks for 'mental attacks'
		if sDmgType == "psionic" then
			sDmgType = "mental attacks";
		end

		-- now check through the Vulnerabilities
		for _,sType in pairs(aVuln) do
			if sType.type == sDmgType then
				return true, sType.mod;
			end
		end
	end

	return false, 0;
end

function checkImmunities(aImmune, aDmgType)
	for _,sDmgType in pairs(aDmgType) do
		-- very important that the damage type is lower case --
		sDmgType = string.lower(sDmgType);

		-- swap out Psionic attacks for 'mental attacks'
		if sDmgType == "psionic" then
			sDmgType = "mental attacks";
		end

		-- now check through the Immunities
		for _,sType in pairs(aImmune) do
			sType = string.lower(sType);
			if sType == sDmgType then
				return true;
			end
		end
	end

	return false;
end

function decodeDamageText(nDamage, sDamageDesc)
	local rDamageOutput = {};

	if string.match(sDamageDesc, "%[HEAL") then
		if string.match(sDamageDesc, "%[TEMP%]") then
			rDamageOutput.sType = "temphp";
			rDamageOutput.sTypeOutput = "Temporary hit points";
		else
			rDamageOutput.sType = "heal";
			rDamageOutput.sTypeOutput = "Heal";
		end
		rDamageOutput.sVal = string.format("%01d", nDamage);
		rDamageOutput.nVal = nDamage;

	elseif nDamage < 0 then
		rDamageOutput.sType = "heal";
		rDamageOutput.sTypeOutput = "Heal";
		rDamageOutput.sVal = string.format("%01d", (0 - nDamage));
		rDamageOutput.nVal = 0 - nDamage;

	else
		rDamageOutput.sType = "damage";
		rDamageOutput.sTypeOutput = "Damage";
		rDamageOutput.sVal = string.format("%01d", nDamage);
		rDamageOutput.nVal = nDamage;

		-- Determine critical
		rDamageOutput.bCritical = string.match(sDamageDesc, "%[CRITICAL%]");

		-- Determine range
		rDamageOutput.sRange = string.match(sDamageDesc, "%[DAMAGE %((%w)%)%]") or "";
		rDamageOutput.aDamageFilter = {};
		if rDamageOutput.sRange == "M" then
			table.insert(rDamageOutput.aDamageFilter, "melee");
		elseif rDamageOutput.sRange == "R" then
			table.insert(rDamageOutput.aDamageFilter, "ranged");
		end

		-- Determine damage energy types
		local nDamageRemaining = nDamage;
		rDamageOutput.aDamageTypes = {};
		for sDamageType, sDamageDice, sDamageSubTotal in string.gmatch(sDamageDesc, "%[TYPE: ([^(]*) %(([%d%+%-dD]+)%=(%d+)%)%]") do
			local nDamageSubTotal = (tonumber(sDamageSubTotal) or 0);
			rDamageOutput.aDamageTypes[sDamageType] = nDamageSubTotal + (rDamageOutput.aDamageTypes[sDamageType] or 0);
			if not rDamageOutput.sFirstDamageType then
				rDamageOutput.sFirstDamageType = sDamageType;
			end

			nDamageRemaining = nDamageRemaining - nDamageSubTotal;
		end
		if nDamageRemaining > 0 then
			rDamageOutput.aDamageTypes[""] = nDamageRemaining;
		elseif nDamageRemaining < 0 then
			ChatManager.SystemMessage("Total mismatch in damage type totals");
		end
	end

	return rDamageOutput;
end

function applyDamage(rSource, rTarget, bSecret, sDamage, nTotal)

	local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if not nodeTarget then
		return;
	end
	if (sTargetNodeType ~= "pc") and (sTargetNodeType ~= "ct") then
		return;
	end

	local sDamageType;
	local sNPCType = DB.getValue(nodeTarget, "type", 'Humanoid'):lower()
	local nArmourProtection = 0;

	if sNPCType:lower() ~= "animal" and sNPCType:lower() ~= "robot" then
		nTotalEnd = DB.getValue(nodeTarget, "woundtrack.end", 0);
		nTotalDex = DB.getValue(nodeTarget, "woundtrack.dex", 0);
		nTotalStr = DB.getValue(nodeTarget, "woundtrack.str", 0);
	else
		nTotalHits = DB.getValue(nodeTarget, "woundtrack.hits", 0);
	end

	if string.match(sDamage, "%[HEAL") then
		sDamageType = "heal"
	else
		sDamageType = "damage"
	end

	local rDamageOutput;
	-- Prepare for notifications
	local aNotifications = {};
	local aAttributes;
	local bApplyKnockOutBlow = false;
	local bApplyWoundEffect = false;
	local sWoundToApply = "";
	local sOldWoundToRemove = "";

	if sDamageType == "heal" then
		if string.match(sDamage, "%[No Healing") or string.match(sDamage, "%[0 Healing") then
			return
		end

		local sHealingString = string.match(sDamage, "%[%d+ Healing]")
		local nHealingAmount = tonumber(string.match(sHealingString,"%d+"))

		if sNPCType:lower() ~= "animal" and sNPCType:lower() ~= "robot" then

			-- need to find 'how' injured they are
			local nOriginalTotalEnd = DB.getValue(nodeTarget, "attributes.endurance", 0);
			local nOriginalTotalDex = DB.getValue(nodeTarget, "attributes.dexterity", 0);
			local nOriginalTotalStr = DB.getValue(nodeTarget, "attributes.strength", 0);
			local nTotalWounds = nOriginalTotalEnd + nOriginalTotalDex + nOriginalTotalStr - nTotalEnd - nTotalDex - nTotalStr

			if nHealingAmount > nTotalWounds then
				nHealingAmount = nTotalWounds
			end

			-- Decode damage/heal description
			rDamageOutput = decodeDamageText(nHealingAmount, sDamage);

			if sTargetNodeType == "pc" then
				local sOptHDCV = OptionsManager.getOption("HDCV"):lower()
				aAttributes = StringManager.split(sOptHDCV, " ", true);
			else
				aAttributes = StringManager.split("end str dex", " ", true);
			end

			for i = 1, #aAttributes do
				sCurrentAttribute = aAttributes[i]:lower()
				sCurrentAttribute = ActionsCharacteristics.getFullAttribute(sCurrentAttribute);
				if sCurrentAttribute == 'strength' then
					nTotalAttribute = nTotalStr
					nAttributeDamage = nOriginalTotalStr - nTotalStr
				elseif sCurrentAttribute == 'dexterity' then
					nTotalAttribute = nTotalDex
					nAttributeDamage = nOriginalTotalDex - nTotalDex
				elseif sCurrentAttribute == 'endurance' then
					nTotalAttribute = nTotalEnd
					nAttributeDamage = nOriginalTotalEnd - nTotalEnd
				end

				if nAttributeDamage > 0 then
					nHealingAmount = healWoundTrack(nodeTarget, nHealingAmount, sCurrentAttribute, nAttributeDamage, sNPCType);
				end
			end
		else

			-- need to find 'how' injured they are
			local nOriginalTotalHits = DB.getValue(nodeTarget, "hits", 0);
			local nTotalWounds = nOriginalTotalHits - nTotalHits

			if nHealingAmount > nTotalWounds then
				nHealingAmount = nTotalWounds
			end

			-- Decode damage/heal description
			rDamageOutput = decodeDamageText(nHealingAmount, sDamage);

			healWoundTrack(nodeTarget, nHealingAmount, sCurrentAttribute, nTotalWounds, sNPCType);
		end

	else
		sDamageType = sDamage:match("TYPE: .* ")
		sDamageType = StringManager.trim(string.sub(sDamageType, 6))

		local bSubdermalArmourWorn = false;
		local nSubdermalArmourProtection = 0;

		if sDamageType == "" then
			sDamageType = "kinetic"
		end

		if sTargetNodeType == "pc" then
			-- Iterate through worn armour
			for _,vItem in ipairs(DB.getChildList(nodeTarget, "inventorylist")) do

				local sItemType = DB.getValue(vItem, "type", ""):lower();

				if sItemType == "armour" then
					local nCarried = DB.getValue(vItem, "carried", 0);
					if nCarried == 2 then
						sArmourLink = DB.getValue(vItem, "resistances", "");
						aArmourList = StringManager.split(sArmourLink, ",", true)
						nArmourProtection = nArmourProtection + getArmourProtection(aArmourList, sDamageType)
					end
				end
				if (sItemType == 'augments' or sItemType == 'personal augmentation') and string.find(DB.getValue(vItem, "name", ""), 'Subdermal') then
					bSubdermalArmourWorn = true;
				end
			end

			if bSubdermalArmourWorn and sDamageType:lower() ~= "radiation" then
				nSubdermalArmourProtection = getSubdermalArmourProtection(nodeTarget);
			end

			if nSubdermalArmourProtection > 0 then
				nArmourProtection = nArmourProtection + nSubdermalArmourProtection;
			end

		else
			-- Find the armour
			local sArmourList = DB.getValue(nodeTarget, "armour_protection", 0)

			aArmourList = StringManager.split(sArmourList, ",", true)

			nArmourProtection = getArmourProtection(aArmourList, sDamageType)
		end

		-- Remember current health status
		local _,sOriginalStatus = ActorManagerTraveller.getWoundPercent(rTarget);

		-- Decode damage/heal description
		rDamageOutput = decodeDamageText(nTotal, sDamage);

		-- Handle Minimum Damage
		local sAttack = string.match(sDamage, "%[DAMAGE[^]]*%] ([^[]+)");
		local nMinDamage = 0;
		if sAttack then
			local sDamageState = getDamageState(rSource, rTarget, StringManager.trim(sAttack));
			if sDamageState == "none" then
				isAvoided = true;
			end
		end

		-- Handle AP X weapon trait
		local sAPWeapon = string.match(sDamage, "%[AP %d+]");

		if sAPWeapon ~= "" and sAPWeapon ~= nil then
			nAPValue = string.match(sAPWeapon, "%d+")
			if nArmourProtection > 0 then
				nArmourProtection = math.floor(nArmourProtection - nAPValue, 0);
			end
        end

		-- Do we have minimum damage
		if string.find(sDamage,"%[MIN DAMAGE") then
			local sMinDamage = string.match(sDamage,"%[MIN DAMAGE %d%]");
			nMinDamage = tonumber(string.match(sMinDamage, "%d+"));
		end

		-- Now we reduce damage by the (Armour) amount
		if nArmourProtection > 0 then
			nTotal = nTotal - nArmourProtection;
			if nTotal < 0 and nMinDamage == 0 then
				if OptionsManager.isOption("SAV", "no") then
					table.insert(aNotifications, Interface.getString("char_message_armourpreventeddamage"));
				end
				nTotal = 0
			else
				if OptionsManager.isOption("SAV", "no") then
					table.insert(aNotifications, Interface.getString("char_message_armourreduceddamage"));
				end
			end

			if sDamageType == 'laser' then
				reduceAblatArmourValue(nodeTarget, rTarget, aNotifications);
			end
		end

		local nKnockOutBlowDamageNeeded = 0;
		
		if GameSystem.checkModuleIsLoaded('MGT2 Traveller Companion') then
			local nOriginalEnd = DB.getValue(nodeTarget, "attributes.endurance", 0);
			-- Natural Resilience
			if OptionsManager.isOption("COMPNR", "yes") then
				if sNPCType:lower() ~= "animal" and sNPCType:lower() ~= "robot" then
					if sDamageType:lower() ~= "radiation" then
						local nOriginalEndDM = GameSystem.calculateCharacteristicDM(nOriginalEnd);
						if nOriginalEndDM > 0 then
							table.insert(aNotifications, Interface.getString("char_message_naturalresiliencereduceddamage") .. " -" .. nOriginalEndDM .. "]");
						elseif nOriginalEndDM < 0 then
							table.insert(aNotifications, Interface.getString("char_message_naturalresilienceincreaseddamage") .. " +" .. -nOriginalEndDM .. "]");
						end
						nTotal = nTotal - nOriginalEndDM;
					end
				end
			end
			-- Traveller Companion - Knockout Blow rule
			if OptionsManager.isOption("COMPKB", "yes") then
				-- Does the character have their original Endurance still (ie not hurt)
				-- We check the Woundtrack is equal to the characters end plus have equipment or mods
				local nTotalofEnd = nOriginalEnd + DB.getValue(nodeTarget, "attributes.end_mod2", 0) + DB.getValue(nodeTarget, "attributes.end_equipment", 0);
				if DB.getValue(nodeTarget, "woundtrack.end", 0) == nTotalofEnd then
					nKnockOutBlowDamageNeeded = nOriginalEnd;
				end
			end
		end

		-- Apply damage type adjustments
		local nAdjustedDamage = nTotal
		local bStopStatusUpdate = false;
		
		-- Now check Minimum Damage
		if nMinDamage > 0 then
			if nAdjustedDamage < nMinDamage then
				nAdjustedDamage = nMinDamage;
			end
		end

		-- Apply remaining damage - unless it's Radiation
		if nAdjustedDamage > 0 then

			local nDamageToApply = nAdjustedDamage

			if sNPCType:lower() ~= "animal" and sNPCType:lower() ~= "robot" then
				if sDamageType:lower() == "radiation" then
					applyRadiationDamage(nodeTarget, nDamageToApply, aNotifications);
					nDamageToApply = 0;
				else

					if GameSystem.checkModuleIsLoaded('MGT2 Traveller Companion') then
						if OptionsManager.isOption("COMPHL", "yes") and OptionsManager.isOption("COMPWE", "yes") then
							-- Hit Locations
							local nodeTargetCT = ActorManager.getCTNode(rTarget);
							sLastHitLocation = DB.getValue(nodeTargetCT, "last_hit_location", "");
							if sLastHitLocation == "" then
								table.insert(aNotifications, "\n[NO HIT LOCATION SET]");
							else
								local nTotalofEnd = DB.getValue(nodeTarget, "attributes.endurance", 0) + DB.getValue(nodeTarget, "attributes.end_mod2", 0) + DB.getValue(nodeTarget, "attributes.end_equipment", 0);

								-- A Minor Wound is inflicted if damage is less than half the Traveller’s END score.
								if nAdjustedDamage <= (nTotalofEnd/2) then
									table.insert(aNotifications, "\n[MINOR WOUND: " .. sLastHitLocation .. "]");
								-- A Major Wound is inflicted if the Traveller receives between half his END score and his full END score in a single instance.
								elseif nAdjustedDamage <= nTotalofEnd then
									table.insert(aNotifications, "\n[MAJOR WOUND: " .. sLastHitLocation .. "]");
									sWoundToApply = sLastHitLocation .. " major wound";
								-- A Severe Wound is inflicted if the Traveller receives more than his END score.
								elseif nAdjustedDamage < (nTotalofEnd * 2) then
									table.insert(aNotifications, "\n[SEVERE WOUND: " .. sLastHitLocation .. "]");
									sWoundToApply = sLastHitLocation .. " severe wound";
									sOldWoundToRemove = sLastHitLocation .. " major wound";
								-- A Crippling wound results from taking at least twice the Traveller’s END score in one attack.
								elseif nAdjustedDamage < (nTotalofEnd * 3) then
									table.insert(aNotifications, "\n[CRIPPLING WOUND: " .. sLastHitLocation .. "]");
									sWoundToApply = sLastHitLocation .. " severe wound";
									sOldWoundToRemove = sLastHitLocation .. " major wound";
								-- A Critical wound results from taking at least three times the Traveller’s END score in one attack.
								elseif nAdjustedDamage < (nTotalofEnd * 4) then
									table.insert(aNotifications, "\n[CRITICAL WOUND: " .. sLastHitLocation .. "]");
									sWoundToApply = sLastHitLocation .. " severe wound";
									sOldWoundToRemove = sLastHitLocation .. " major wound";
								-- A Mortal wound results from taking at least four times the Traveller’s END score in one attack.
								elseif nAdjustedDamage < (nTotalofEnd * 5) then
									table.insert(aNotifications, "\n[MORTAL WOUND: " .. sLastHitLocation .. "]");
									sWoundToApply = sLastHitLocation .. " severe wound";
									sOldWoundToRemove = sLastHitLocation .. " major wound";
								-- A Devastating wound results from taking at least five times the target’s END score or more in a single attack.
								elseif nAdjustedDamage >= (nTotalofEnd * 5) then
									table.insert(aNotifications, "\n[DEVASTATING WOUND: " .. sLastHitLocation .. "]");	
									sWoundToApply = sLastHitLocation .. " severe wound";
									sOldWoundToRemove = sLastHitLocation .. " major wound";
								end

								if sWoundToApply ~= "" then
									bApplyWoundEffect = true;
								end
							end
						end
					end

					if sTargetNodeType == "pc" then
						local sOptDDCV = OptionsManager.getOption("DDCV"):lower()
						aAttributes = StringManager.split(sOptDDCV, " ", true);
					else
						aAttributes = StringManager.split("end str dex", " ", true);
					end

					-- Traveller Companion - Random First Blood rule
					if GameSystem.checkModuleIsLoaded('MGT2 Traveller Companion') and OptionsManager.isOption("COMPRFB", "yes") then
						if CharManager.isFullyHealthy(nodeTarget) then
							aAttributes = shuffle(aAttributes);
						end
					end

					for i = 1, #aAttributes do
						sCurrentAttribute = aAttributes[i]:lower()
						sCurrentAttribute = ActionsCharacteristics.getFullAttribute(sCurrentAttribute);
						if sCurrentAttribute == 'strength' then
							nTotalAttribute = nTotalStr
						elseif sCurrentAttribute == 'dexterity' then
							nTotalAttribute = nTotalDex
						elseif sCurrentAttribute == 'endurance' then
							nTotalAttribute = nTotalEnd
						end

						if nDamageToApply > 0 then
							nDamageToApply = reduceWoundTrack(nodeTarget, nDamageToApply, sCurrentAttribute, nTotalAttribute, sNPCType);
						end
					end

					-- Get the latest values for the 3 attributes
					nTotalEnd = DB.getValue(nodeTarget, "woundtrack.end", 0);
					nTotalDex = DB.getValue(nodeTarget, "woundtrack.dex", 0);
					nTotalStr = DB.getValue(nodeTarget, "woundtrack.str", 0);

					-- This person has had a knock out blow!
					if nKnockOutBlowDamageNeeded > 0 and nTotalEnd == 0 then
						table.insert(aNotifications, "\n[KNOCKOUT BLOW!]");
						bStopStatusUpdate = true;
						bApplyKnockOutBlow = true;
					end

					-- Now we check to see if the PC/NPC is unconscious or dead...
					if nTotalEnd == 0 and nTotalDex == 0 and nTotalStr == 0 then
						-- Traveller Companion - Disabling Wound Effect rule
						if GameSystem.checkModuleIsLoaded('MGT2 Traveller Companion') and OptionsManager.isOption("COMPDWE", "yes") then
							if rTarget and rTarget.sType == "charsheet" then
								if not bStopStatusUpdate then
									table.insert(aNotifications, "\n[UNCONSCIOUS]");
									bApplyKnockOutBlow = true;
								end

								-- If the final attack caused less than 3 points of damage: DM+4
								-- If the final attack caused 4-6 points of damage: DM+2
								-- If the final attack caused more than 6 points of damage: DM-2
								local nDMDisablingWoundEffect = 0;
								if nAdjustedDamage <= 3 then
									nDMDisablingWoundEffect = 4;
								elseif nAdjustedDamage <= 6 then
									nDMDisablingWoundEffect = 2;
								else
									nDMDisablingWoundEffect = -2;
								end

								ActionDisablingWoundEffect.rollForDisablingWoundEffect(ActorManager.getCTNodeName(rTarget), nDMDisablingWoundEffect);
								bStopStatusUpdate = true;
							end
						else
							table.insert(aNotifications, "\n[" .. rTarget.sName .. " is DEAD]");
						end
					else

						-- EffectManager.addEffect("", "", ActorManager.getCTNode(rTarget), { sName = "Head major wound", nDuration = 0}, true);
						if nTotalEnd == 0 and (nTotalDex == 0 or nTotalStr == 0) then
							table.insert(aNotifications, "\n[UNCONSCIOUS]");
							bApplyKnockOutBlow = true;
						end
					end
				end
			else

				nTotalHits = DB.getValue(nodeTarget, "woundtrack.hits", 0);
				local nOriginalHits = DB.getValue(nodeTarget, "hits", 0);

				-- Now we check to see if the PC/NPC is unconscious or dead...
				nDamageToApply = reduceWoundTrack(nodeTarget, nDamageToApply, "hits", nTotalHits, sNPCType);

				if nTotalHits == 0 then
					table.insert(aNotifications, "\n[" .. rTarget.sName .. " is DEAD]");
				else
					-- If we're down to 10% or less
					if (nTotalHits/nOriginalHits)*100 <= 10  then
						table.insert(aNotifications, "\n[UNCONSCIOUS]");
						bApplyKnockOutBlow = true;
					end
				end

			end
			-- Prepare for calcs
			local nodeTargetCT = ActorManager.getCTNode(rTarget);

			-- Deal with remainder damage
			if nDamageToApply > 0 then
				if sNPCType:lower() ~= "animal" and sNPCType:lower() ~= "robot" then
					table.insert(aNotifications, "\n[DAMAGE EXCEEDS WOUNDTRACK BY " .. nDamageToApply .. "]");
				else
					table.insert(aNotifications, "\n[DAMAGE EXCEEDS HITS BY " .. nDamageToApply .. "]");
				end
			end
		end

		-- Update the damage output variable to reflect adjustments
		rDamageOutput.nVal = nAdjustedDamage;
		rDamageOutput.sVal = string.format("%01d", nAdjustedDamage);

		-- Check for status change
		local bShowStatus = false;
		if ActorManager.isFaction(rTarget, "friend") then
			bShowStatus = not OptionsManager.isOption("SHPC", "off");
		else
			bShowStatus = not OptionsManager.isOption("SHNPC", "off");
		end
		if bShowStatus and not bStopStatusUpdate then
			local _,sNewStatus = ActorManagerTraveller.getWoundPercent(rTarget);
			if sOriginalStatus ~= sNewStatus then
				table.insert(aNotifications, string.format("[%s: %s]", Interface.getString("combat_tag_status"), sNewStatus));
			end
		end

		if sDamageType:lower() == "radiation" then
			rDamageOutput.sTypeOutput = 'Radiation'
		end
	end

	-- Output results
	messageDamage(rSource, rTarget, bSecret, rDamageOutput.sTypeOutput, sDamage, rDamageOutput.sVal, table.concat(aNotifications, " "), nArmourProtection, sSoakType);

	-- Add any effects
	if bApplyKnockOutBlow then
		if not EffectManagerTraveller.hasEffectCondition(ActorManager.getCTNode(rTarget), "Unconscious") then
			EffectManager.addEffect("", "", ActorManager.getCTNode(rTarget), { sName = "Unconscious", nDuration = 0}, true);
		end
	end
	if bApplyWoundEffect then
		if not EffectManagerTraveller.hasEffectCondition(ActorManager.getCTNode(rTarget), sWoundToApply) then
			EffectManager.addEffect("", "", ActorManager.getCTNode(rTarget), { sName = sWoundToApply, nDuration = 0}, true);
		end
		if sOldWoundToRemove ~= "" then
			EffectManager.removeEffect(ActorManager.getCTNode(rTarget), sOldWoundToRemove);
		end
	end
end

function getArmourProtection(aArmourList, sDamageType)
	local nArmourProtection = 0;

	if #aArmourList > 0 then
		for i = 1, #aArmourList do
			sArmourType = aArmourList[i]:lower();
			if string.match(aArmourList[i]:lower(), "%s+") == nil and sDamageType:lower() ~= "radiation" then
				-- this is default for any non radiation damage
				local nProtection = tonumber(string.match(aArmourList[i]:lower(), "%d+"))
				nArmourProtection = math.max(nArmourProtection, nProtection)
			else
				if string.find(sArmourType, sDamageType) then
					local nProtection = tonumber(string.match(aArmourList[i]:lower(), "%d+"))
					nArmourProtection = math.max(nArmourProtection, nProtection)
				end
			end
		end
	end
	return nArmourProtection
end

function getSubdermalArmourProtection(nodeTarget)
	local nSubdermalArmourProtection = 0;

	for _,vItem in ipairs(DB.getChildList(nodeTarget, "inventorylist")) do

		local sItemType = DB.getValue(vItem, "type", ""):lower();

		if sItemType == 'augments' or sItemType == 'personal augmentation' then
			local sItemName = DB.getValue(vItem, "name", ""):lower();

			if sItemName:find('subdermal armour') ~= nil and sItemName:find('subdermal armour') > 0 then

				local nProtection = tonumber(string.match(DB.getValue(vItem, "description", ""):lower(), "%d+"))
				nSubdermalArmourProtection = math.max(nSubdermalArmourProtection, nProtection)
			end
		end
	end

	return nSubdermalArmourProtection
end

function messageDamage(rSource, rTarget, bSecret, sDamageType, sDamageDesc, sTotal, sExtraResult, nArmourProtection, sSoakType)
	if not (rTarget or sExtraResult ~= "") then
		return;
	end

	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};

	if sDamageType == "Recovery" then
		msgShort.icon = "roll_heal";
		msgLong.icon = "roll_heal";
	elseif sDamageType == "Heal" then
		msgShort.icon = "roll_heal";
		msgLong.icon = "roll_heal";
	else
		msgShort.icon = "roll_damage";
		msgLong.icon = "roll_damage";
	end

	msgShort.text = sDamageType .. " ->";
	msgLong.text = sDamageType .. " [" .. sTotal .. "] ->";
	if rTarget then
		msgShort.text = msgShort.text .. " [to " .. rTarget.sName .. "]";
		msgLong.text = msgLong.text .. " [to " .. rTarget.sName .. "]";
	end

	if OptionsManager.isOption("SAV", "yes") and nArmourProtection > 0 then
		msgLong.text = msgLong.text .. " [ARMOUR " .. nArmourProtection .. "]";
	end

	if sExtraResult and sExtraResult ~= "" then
		msgLong.text = msgLong.text .. " " .. sExtraResult;
	end

	ActionsManager.messageResult(bSecret, rSource, rTarget, msgLong, msgShort);
end

local aDamageState = {};

function applyDamageState(rSource, rTarget, sAttack, sState)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDMGSTATE;

	msgOOB.sSourceNode = ActorManager.getCTNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCTNodeName(rTarget);

	msgOOB.sAttack = sAttack;
	msgOOB.sState = sState;

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyDamageState(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);

	if Session.IsHost then
		setDamageState(rSource, rTarget, msgOOB.sAttack, msgOOB.sState);
	end
end

function setDamageState(rSource, rTarget, sAttack, sState)
	if not Session.IsHost then
		applyDamageState(rSource, rTarget, sAttack, sState);
		return;
	end

	local sSourceCT = ActorManager.getCTNodeName(rSource);
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sSourceCT == "" or sTargetCT == "" then
		return;
	end

	if not aDamageState[sSourceCT] then
		aDamageState[sSourceCT] = {};
	end
	if not aDamageState[sSourceCT][sAttack] then
		aDamageState[sSourceCT][sAttack] = {};
	end
	if not aDamageState[sSourceCT][sAttack][sTargetCT] then
		aDamageState[sSourceCT][sAttack][sTargetCT] = {};
	end
	aDamageState[sSourceCT][sAttack][sTargetCT] = sState;
end

function getDamageState(rSource, rTarget, sAttack)
	local sSourceCT = ActorManager.getCTNodeName(rSource);
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sSourceCT == "" or sTargetCT == "" then
		return "";
	end

	if not aDamageState[sSourceCT] then
		return "";
	end
	if not aDamageState[sSourceCT][sAttack] then
		return "";
	end
	if not aDamageState[sSourceCT][sAttack][sTargetCT] then
		return "";
	end

	local sState = aDamageState[sSourceCT][sAttack][sTargetCT];
	aDamageState[sSourceCT][sAttack][sTargetCT] = nil;
	return sState;
end

-- Function to reduce one of three attributes
function reduceWoundTrack(nodeTarget, nDamageToApply, sAttribute, nAttributeValue, sNPCType)
	local nodeToReduce

	if sNPCType ~= "animal" and sNPCType ~= "robot" then
		nodeToReduce = "woundtrack." .. string.sub(sAttribute,1,3);
		if nDamageToApply > nAttributeValue then
			nDamageToApply = nDamageToApply - nAttributeValue
			DB.setValue(nodeTarget, nodeToReduce, "number", 0);
		else
			DB.setValue(nodeTarget, nodeToReduce, "number", nAttributeValue - nDamageToApply);
			nDamageToApply = 0;
		end
	else
		nodeToReduce = "woundtrack.hits"

		if nDamageToApply > nAttributeValue then
			nDamageToApply = nDamageToApply - nAttributeValue
			DB.setValue(nodeTarget, nodeToReduce, "number", 0);
		else
			DB.setValue(nodeTarget, nodeToReduce, "number", nAttributeValue - nDamageToApply);
			nDamageToApply = 0;
		end
	end

	return nDamageToApply
end

-- Function to heal one of three attributes
function healWoundTrack(nodeTarget, nHealingToApply, sAttribute, nAttributeDamage, sNPCType)
	local nodeToHeal

	if sNPCType ~= "animal" and sNPCType ~= "robot" then
		nodeToHeal = "woundtrack." .. string.sub(sAttribute,1,3);
		if nHealingToApply <= nAttributeDamage then
			nAttributeValue = DB.getValue(nodeTarget, nodeToHeal, "number");
			DB.setValue(nodeTarget, nodeToHeal, "number", nAttributeValue + nHealingToApply);

			nHealingToApply = 0
		else
			nAttributeValue = DB.getValue(nodeTarget, nodeToHeal, "number");
			DB.setValue(nodeTarget, nodeToHeal, "number", nAttributeValue + nAttributeDamage);

			nHealingToApply = nHealingToApply - nAttributeDamage;
		end
	else
		nodeToHeal = "woundtrack.hits"

		if nHealingToApply <= nAttributeDamage then
			nAttributeValue = DB.getValue(nodeTarget, nodeToHeal, "number");
			DB.setValue(nodeTarget, nodeToHeal, "number", nAttributeValue + nHealingToApply);

			nHealingToApply = 0
		else
			nAttributeValue = DB.getValue(nodeTarget, nodeToHeal, "number");
			DB.setValue(nodeTarget, nodeToHeal, "number", nAttributeValue + nAttributeDamage);

			nHealingToApply = 0;
		end
	end

	return nHealingToApply
end

function reduceAblatArmourValue(nodeTarget, rTarget, aNotifications)

	for _,vItem in ipairs(DB.getChildList(nodeTarget, "inventorylist")) do

		local sItemType = DB.getValue(vItem, "type", ""):lower();

		if sItemType == "armour" then
			local nCarried = DB.getValue(vItem, "carried", 0);
			local sName = DB.getValue(vItem, "name", "");
			if nCarried == 2 and string.find(sName:lower(), 'ablat') then

				sResistances = DB.getValue(vItem, "resistances", "");

				if sResistances ~= nil then
					sResistanceValue = sResistances:match("(Laser%s%d*)");
					if sResistanceValue  ~= nil then
						nProtection = tonumber(sResistanceValue:match("(%d)"));
						if nProtection > 0 then
							if nProtection -1 == 0 then
								-- need to remove Laser as a resistance
								sNewResistanceValue = sResistances:gsub("(, Laser%s%d*)", "");
								sNewResistanceValue = sNewResistanceValue:gsub("(,Laser%s%d*)", "");
								sNewResistanceValue = sNewResistanceValue:gsub("(Laser%s%d*)", "");
								table.insert(aNotifications, "[ARMOUR protection removed]");
							else
								sNewResistanceValue = sResistances:gsub("(Laser%s%d*)", "Laser " .. nProtection -1);

								table.insert(aNotifications, "[ARMOUR protection reduced]");
							end

							DB.setValue(vItem, "resistances", "string", sNewResistanceValue);

							local nodeTargetCT = ActorManager.getCTNode(rTarget);

							DB.setValue(nodeTargetCT, "armour_protection", "string", sNewResistanceValue);

						end
					end
				end

				-- aArmourList = StringManager.split(sArmourLink, ",", true)
				-- nArmourProtection = getArmourProtection(aArmourList, sDamageType)
			end
		end
	end
end

function applyRadiationDamage(nodeTarget, nDamageToApply, aNotifications)

	local sCurrentStatus = DB.getValue(nodeTarget, "radiation_status", "");
	local nCurrentStatus = DB.getValue(nodeTarget, "radiation", "0");
	local sRadiationImmediateExposure = '';
	local sRadiationCumulativeExposure = '';
	local nNewStatus = nCurrentStatus + nDamageToApply;
	local nImmediateRadiationToApply = 1;
	local nCumulativeRadiationToApply = 1;

	if nDamageToApply < 51 then
		nImmediateRadiationToApply = 1;
	elseif nDamageToApply < 151 then
		nImmediateRadiationToApply = 2;
	elseif nDamageToApply < 301 then
		nImmediateRadiationToApply = 3;
	elseif nDamageToApply < 501 then
		nImmediateRadiationToApply = 4;
	elseif nDamageToApply < 801 then
		nImmediateRadiationToApply = 5;
	elseif nDamageToApply >= 801 then
		nImmediateRadiationToApply = 6;
	end

	if nNewStatus < 51 then
		nCumulativeRadiationToApply = 1;
	elseif nNewStatus < 151 then
		nCumulativeRadiationToApply = 2;
	elseif nNewStatus < 301 then
		nCumulativeRadiationToApply = 3;
	elseif nNewStatus < 501 then
		nCumulativeRadiationToApply = 4;
	elseif nNewStatus < 801 then
		nCumulativeRadiationToApply = 5
	elseif nNewStatus >= 801 then
		nCumulativeRadiationToApply = 6
	end
	sRadiationImmediateExposure = DataCommon.radiationstatusesimmediate[nImmediateRadiationToApply];
	sRadiationCumulativeExposure = DataCommon.radiationstatusescumulative[nCumulativeRadiationToApply];

	DB.setValue(nodeTarget, "radiation", "number", nNewStatus);
	DB.setValue(nodeTarget, "radiation_status", "string", sRadiationCumulativeExposure);

	if sRadiationImmediateExposure ~= "None" then
		table.insert(aNotifications, "\n[Immediate Radiation Exposure: " .. sRadiationImmediateExposure .. "]");
	end

	if sRadiationCumulativeExposure ~= sCurrentStatus then
		table.insert(aNotifications, "\n[Cumulative Radiation Exposure: " .. sRadiationCumulativeExposure .. "]");
	end

end

function shuffle(array)
    -- fisher-yates
    local output = { };
    local random = math.random;

    for index = 1, #array do
        local offset = index - 1;
        local value = array[index];
        local randomIndex = offset*random();
        local flooredIndex = randomIndex - randomIndex%1;

        if flooredIndex == offset then
            output[#output + 1] = value;
        else
            output[#output + 1] = output[flooredIndex + 1];
            output[flooredIndex + 1] = value;
        end
    end

    return output;
end
