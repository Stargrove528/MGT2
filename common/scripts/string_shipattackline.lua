--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local parsed = false;
local rAttackRolls = {};
local rDamageRolls = {};
local rAttackCombos = {};

local hoverDamage = nil;
local hoverAttack = nil;
local clickDamage = nil;
local clickAttack = nil;
local bRanged = false;


function onValueChanged()
	parsed = false;
end

function onHover(oncontrol)
	if dragging then
		return;
	end

	-- Reset selection when the cursor leaves the control
	if not oncontrol then
		-- Clear hover tracking
		hoverDamage = nil;
		hoverAttack = nil;

		-- Clear any selections
		setSelectionPosition(0);
	end
end

function onHoverUpdate(x, y)
	-- If we're typing or dragging, then exit
	if dragging then
		return;
	end

	-- Compute the locations of the relevant phrases, and the mouse
	local nMouseIndex = getIndexAt(x, y);
	--local sAtk = window.value.getValue();
	local nodeNPC = DB.getChild(window.getDatabaseNode(), "...");
	--if ranged or window.type.getValue() == 2 then
	if ranged then
		bRanged = true;
	else
		bRanged = false;

	end

	if not parsed then
		parsed = true;
		rAttackRolls, rDamageRolls, rAttackCombos = parseAttackLine(getActor(), getValue(), bRanged);
	end

	hoverDamage = nil;
	hoverAttack = nil;

	for i = 1, #rDamageRolls do
		if rDamageRolls[i].startpos < nMouseIndex and rDamageRolls[i].endpos > nMouseIndex then
			hoverDamage = i;
			setCursorPosition(rDamageRolls[i].startpos);
			setSelectionPosition(rDamageRolls[i].endpos);

			setHoverCursor("hand");
			return;
		end
	end

	for i = 1, #rAttackRolls do
		if rAttackRolls[i].startpos < nMouseIndex and rAttackRolls[i].endpos > nMouseIndex then
			hoverAttack = i;
			setCursorPosition(rAttackRolls[i].startpos);
			setSelectionPosition(rAttackRolls[i].endpos);

			setHoverCursor("hand");
			return;
		end
	end

	-- Reset the cursor
	setHoverCursor("arrow");
end

function onClickDown(button, x, y)
	-- Suppress default processing to support dragging
	clickDamage = hoverDamage;
	clickAttack = hoverAttack;

	return true;
end

function onClickRelease(button, x, y)
	-- Enable edit mode on mouse release
	setFocus();

	local n = getIndexAt(x, y);

	setSelectionPosition(n);
	setCursorPosition(n);

	return true;
end

function getActor()
	local nodeActor = nil;
	local node = getDatabaseNode();
	if node then
		nodeActor = DB.getChild(node, actorpath[1]);
	end

	return ActorManager.resolveActor(nodeActor);
end

function actionDamage(draginfo, rDamage)
	ActionShipDamage.performRoll(draginfo, getActor(), rDamage);
	return true;
end

function actionAttack(draginfo, rAttackRolls)
	local nodeWin = window.getDatabaseNode();
	local nodeActor = DB.getChild(nodeWin, "...");
	local rActor = getActor();
	local nGunnery = 0;
	local sName,nGunnerySelected,sBonuses,sGunnery;

	local nControl = 0;
	for _,vCrew in ipairs(DB.getChildList(nodeActor, "crew")) do
		nGunnerySelected = DB.getValue(vCrew, "gunnerselected", 0);
		if nGunnerySelected == 1 then
			nControl = 1;
			sBonuses = string.lower(DB.getValue(vCrew, "bonuses", ""));
			sGunnery = string.match(sBonuses, "gunnery %+%d*" or "Gunnery %+%d*");
			sPiloting = string.match(sBonuses, "piloting %+%d*" or "Piloting %+%d*");
			if sGunnery then
				nGunnery = tonumber(string.match(sGunnery, "%d+"));
			elseif sPiloting then
				nGunnery = tonumber(string.match(sPiloting, "%d+"));
			end
			break
		end
	end
	if nContol == 0 then
		for _,vCrew in ipairs(DB.getChildList(nodeActor, "crew")) do
			sName = string.lower(DB.getValue(vCrew, "name", ""));
			if sName == "gunnner" or sName == "gunners" then
				nControl = 1;
				nGunnerySelected = DB.setValue(vCrew, "gunnerselected", "number", 1);
				sBonuses = string.lower(DB.getValue(vCrew, "bonuses", ""));
				sGunnery = string.match(sBonuses, "gunnery %+%d*" or "Gunnery %+%d*");
				nGunnery = tonumber(string.match(sGunnery, "%d+"));
				break
			end
		end
		if nControl == 0 then
			for _,vCrew in ipairs(DB.getChildList(nodeActor, "crew")) do
				sName = string.lower(DB.getValue(vCrew, "name", ""));
				if sName == "pilot" or sName == "pilots" and nControl == 0 then
					nControl = 1;
					nGunnerySelected = DB.setValue(vCrew, "gunnerselected", "number", 1);
					sBonuses = string.lower(DB.getValue(vCrew, "bonuses", ""));
					sPiloting = string.match(sBonuses, "piloting %+%d*" or "Piloting %+%d*");
					nGunnery = tonumber(string.match(sPiloting, "%d+"));
					break
				end
			end
		end
	end
	rAttackRolls.modifier = nGunnery;

	ActionShipAttack.performRoll(draginfo, rActor, rAttackRolls)

	return true;
end

function onDoubleClick(x, y)
	if hoverDamage then
		return actionDamage(nil, rDamageRolls[hoverDamage]);
	end

	if hoverAttack then
		return actionAttack(nil, rAttackRolls[hoverAttack]);
	end

	return false;
end

function onDragStart(button, x, y, draginfo)
	if clickAttack or clickDamage then
		if clickDamage then
			actionDamage(draginfo, rDamageRolls[clickDamage]);
		end

		if clickAttack then
			actionAttack(draginfo, rAttackRolls[clickAttack]);
		end

		clickDamage = nil;
		clickAttack = nil;
		dragging = true;
	end

	return true;
end

function onDragEnd(dragdata)
	setCursorPosition(0);
	dragging = false;
end

function parseAttackLine(rActor, sLine, bRanged)
	local rAttackRolls = {}
	local rDamageRolls = {}
	local rAttackCombos = {}

	local nOffset = 0;
	if sLine:match("%,") then
		local sPrefix, sAttackLine;
		sPrefix,sAttackLine = sLine:match("(.*),(.*)");
		if (sAttackLine or "") == "" then
			return;
		end
		local nPrefix = #sPrefix;
		nOffset = nPrefix + 2;
	end

	-- Get the comma-separated strings
	local aClauses, aClauseStats = StringManager.split(sLine, ",;\r", true);
	-- PARSE EACH ATTACK
	for i = 1, #aClauses do
		local nAttackIndex = 1
		local nLineIndex = 1
		local aCurrentCombo = {}
		local nStarts,
			nEnds,
			sAll,
			sAttackLabel,
			nDamageStart,
			sDamage,
			nDamageEnd = aClauses[i]:find("(([%w%s,%[%]%(%)%+%-]*)%(()([^%)]*)()%))");
		if nStarts then
			local rAttack = {}
			if i == 1 then
				rAttack.startpos = nStarts;
				rAttack.endpos =  nEnds;
			elseif i > 1 then
				rAttack.startpos = nStarts + nOffset;
				rAttack.endpos =  nEnds + nOffset;
			end

			local rDamage = {}
			if i == 1 then
				rDamage.startpos = nDamageStart;
				rDamage.endpos = nDamageEnd;
			elseif i > 1 then
				rDamage.startpos = nOffset + nDamageStart;
				rDamage.endpos = nOffset + nDamageEnd;
				nOffset = nOffset + (nStarts - nEnds);
			end

			-- Check for implicit damage types
			local aImplicitDamageType = {};

			local aDamage = StringManager.split(sDamage, ";");
			local sCritical = aDamage[2];
			local aLabelWords = StringManager.parseWords(aDamage[1]:lower());
			--local i = 1;


			-- Clean up the attack count field (i.e. magical weapon bonuses up front, no attack count)
			local nAttackCount = 1

			-- Capitalize first letter of label
			sAttackLabel = StringManager.capitalize(sAttackLabel)

			rAttack.arc = DB.getValue(window.getDatabaseNode(), "name", "");
			rAttack.label = sAttackLabel
			rAttack.count = nAttackCount
			rAttack.modifier = sAttackModifier or 0

			rDamage.label = sAttackLabel

			-- Determine if vs AC or TL
			local bAC = true

			--check for tracking weapon (TL if tracking)
			local sTracking = string.match(sAttackLabel, "launcher" or "battery");
			if sTracking then
				bAC = false;
				rAttack.tracking = true;
			else
				rAttack.direct = true;
			end

			-- Determine damage clauses
			rDamage.clauses = {}

			local aClausesDamage = {}
			local nIndexDamage = 1
			local nStartDamage,
				nEndDamage
			while nIndexDamage < #sDamage do
				nStartDamage,
					nEndDamage = string.find(sDamage, " plus ", nIndexDamage)
				if nStartDamage then
					table.insert(aClausesDamage, string.sub(sDamage, nIndexDamage, nStartDamage - 1))
					nIndexDamage = nEndDamage
				else
					table.insert(aClausesDamage, string.sub(sDamage, nIndexDamage))
					nIndexDamage = #sDamage
				end
			end

			for kClause, sClause in pairs(aClausesDamage) do
				local aDamageAttrib = StringManager.split(sClause, ";", true)
				local aWordType = {}
				local sDamageRoll,
					sDamageTypes = string.match(aDamageAttrib[1], "^([d%d%+%-x%s]+)([%w%s,%&]*)")
				if not sDamageRoll then
					sDamageRoll,
						sDamageTypes = string.match(aDamageAttrib[1], "^[%w%s%[]+%d+%s?ft%.%,%s([d%d%+%-%s]+)([%w%s,]*)")
				end

				if sDamageRoll then
					if sDamageTypes then
						if string.match(sDamageTypes, " and ") then
							sDamageTypes = string.gsub(sDamageTypes, " and .*$", "")
						end
						table.insert(aWordType, sDamageTypes)
					end

					local sCrit
					for nAttrib = 2, #aDamageAttrib do
						sCrit,
							sDamageTypes = string.match(aDamageAttrib[nAttrib], "^(%s)([%w%s,]*)")
						if not sCrit then
							sDamageTypes = string.match(aDamageAttrib[nAttrib], "^%d+%-20%s?([%w%s,]*)")
						end

						if sDamageTypes then
							table.insert(aWordType, sDamageTypes)
						end
					end

					local nWordMulti, sDamageAttrib;
					local sRemainder, sModMulti = aDamageAttrib[1]:match("x(%d+)$");
					if sModMulti then
						nWordMulti = tonumber(sModMulti) or 0;
						sDamageAttrib = sRemainder;
					else
						nWordMulti = 0;
						sDamageAttrib = aDamageAttrib[1];
					end
					local aWordDice, nWordMod = DiceManager.convertStringToDice(sDamageAttrib:lower())
					if #aWordDice > 0 or nWordMod ~= 0 then
						local rDamageClause = {dice = {}}
						for kDie, vDie in ipairs(aWordDice) do
							table.insert(rDamageClause.dice, vDie)
						end
						if nWordMulti > 0 then
							rDamageClause.nMulti = nWordMulti
							rDamageClause.modifier = 0
						else
							rDamageClause.modifier = nWordMod
						end

						local aDamageType = ActionShipDamage.getDamageTypesFromString(table.concat(aWordType, ","))
						if #aDamageType == 0 then
							for kType, sType in ipairs(aImplicitDamageType) do
								table.insert(aDamageType, sType)
							end
						end

						rDamageClause.dmgtype = table.concat(aDamageType, ",")

						table.insert(rDamage.clauses, rDamageClause)
					end
				end
			end

			if #(rDamage.clauses) > 0 then
			end

			-- Add to roll list
			table.insert(rAttackRolls, rAttack)
			table.insert(rDamageRolls, rDamage)

			-- Add to combo
			table.insert(aCurrentCombo, nAttackIndex)
			nAttackIndex = nAttackIndex + 1
		end
		nLineIndex = nLineIndex + #sLine

		-- Finish combination
		if #aCurrentCombo > 0 then
			table.insert(rAttackCombos, aCurrentCombo)
			aCurrentCombo = {}
		end
	end
	return rAttackRolls, rDamageRolls, rAttackCombos
end
