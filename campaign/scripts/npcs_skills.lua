--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local bParsed = false;
local aComponents = {};

local bClicked = false;
local bDragging = false;
local nDragIndex = nil;

function getCompletion(s)
	-- Find a matching completion for the given string
	for k,_ in pairs(SkillsManager.getSkills()) do
		if string.lower(s) == string.lower(string.sub(k, 1, #s)) then
			return string.sub(k, #s + 1);
		end
	end

	return "";
end

function parseComponents()
	aComponents = {};

	-- Get the comma-separated strings
	local aClauses, aClauseStats = StringManager.split(getValue(), ",;\r", true);

	-- Check each comma-separated string for a potential skill roll or auto-complete opportunity
	for i = 1, #aClauses do
		local nStarts, nEnds, sLabel, sMod;
		--nStarts, nEnds, sLabel, sMod = string.find(aClauses[i], "([%a%s%(%)]*[%a%(%)]+)%s*(.%d*)");
		nStarts, nEnds, sLabel, sMod = string.find(aClauses[i], "([%a%s%(%)]+)(%d*)");
		if nStarts then
			-- Calculate modifier based on mod value and sign value, if any
			local nAllowRoll = 0;
			local nMod = 0;
			if sMod ~= "" then
				nAllowRoll = 1;
				nMod = tonumber(sMod) or 0;
			end

			-- Insert the possible skill into the skill list
			table.insert(aComponents, { nStart = aClauseStats[i].startpos, nLabelEnd = aClauseStats[i].startpos + nEnds, nEnd = aClauseStats[i].endpos, sLabel = sLabel, nMod = nMod, nAllowRoll = nAllowRoll });
		end
	end

	bParsed = true;
end

function onChar(nKeyCode)
	bParsed = false;
	
	local nCursor = getCursorPosition();
	local sValue = getValue();
	local sCompletion;
	
	-- If alpha character, then build a potential autocomplete
	if ((nKeyCode >= 65) and (nKeyCode <= 90)) or ((nKeyCode >= 97) and (nKeyCode <= 122)) then
		-- Parse the value string
		parseComponents();

		-- Build auto-complete for the current string
		for i = 1, #aComponents, 1 do
			if nCursor == aComponents[i].nLabelEnd then
				sCompletion = getCompletion(aComponents[i].sLabel);
				if sCompletion ~= "" then
					local sNewValue = sValue:sub(1, getCursorPosition()-1) .. sCompletion .. sValue:sub(getCursorPosition());
					setValue(sNewValue);
					setSelectionPosition(nCursor + #sCompletion);
				end

				return;
			end
		end

	-- Or else if space character, then finish the autocomplete
	else
		if ((nKeyCode == 32) and (nCursor >= 2)) then
			-- Parse the value string
			parseComponents();
			
			-- Find any string we may have just auto-completed
			local nLastCursor = nCursor - 1;
			for i = 1, #aComponents, 1 do
				if nCursor - 1 == aComponents[i].nLabelEnd then
					sCompletion = getCompletion(aComponents[i].sLabel);
					if sCompletion ~= "" then
						local sNewValue = string.sub(sValue, 1, nLastCursor - 1) .. sCompletion .. string.sub(sValue, nLastCursor);
						setValue(sNewValue);
						setCursorPosition(nCursor + #sCompletion);
						setSelectionPosition(nCursor + #sCompletion);
					end

					return;
				end
			end
		end
	end
end

-- Reset selection when the cursor leaves the control
function onHover(bOnControl)
	if bDragging or bOnControl or not isReadOnly() then
		return;
	end

	if not bDragging then
		onDragEnd();
	end
end

-- Hilight skill hovered on
function onHoverUpdate(x, y)
	if bDragging or bClicked or not isReadOnly() then
		return;
	end

	if not bParsed then
		parseComponents();
	end
	local nMouseIndex = getIndexAt(x, y);

	for i = 1, #aComponents, 1 do
		if aComponents[i].nStart <= nMouseIndex and aComponents[i].nEnd > nMouseIndex then
			setCursorPosition(aComponents[i].nStart);
			setSelectionPosition(aComponents[i].nEnd);

			nDragIndex = i;
			setHoverCursor("hand");
			return;
		end
	end
	
	nDragIndex = nil;
	setHoverCursor("arrow");
end

function action(draginfo)
	if nDragIndex then
		local rActor = ActorManager.resolveActor(window.getDatabaseNode());

		ActionSkill.performRoll(draginfo, rActor, aComponents[nDragIndex].sLabel, aComponents[nDragIndex].nMod, "", 0);
	end
end
function onDragStart(button, x, y, draginfo)
	action(draginfo);

	bClicked = false;
	bDragging = true;

	return true;
end

function onDragEnd(draginfo)
	bClicked = false;
	bDragging = false;
	nDragIndex = nil;

	setHoverCursor("arrow");
	setCursorPosition(0);
	setSelectionPosition(0);
end

-- Suppress default processing to support dragging
function onClickDown(button, x, y)
	bClicked = true;
	return true;
end

-- On mouse click, set focus, set cursor position and clear selection
function onClickRelease(button, x, y)
	bClicked = false;
	setFocus();

	local n = getIndexAt(x, y);
	setSelectionPosition(n);
	setCursorPosition(n);

	if isReadOnly() then
		action()
	end

	return true;
end
