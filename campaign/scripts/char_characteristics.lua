--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Character Characteristics

function onSourceUpdate()
	local nValue = calculateSources();
	setValue(GameSystem.calculateCharacteristicDM(nValue))
end

function action(draginfo)
	local nTotal = getValue();
	local sAttribute = getName();
	local nEncModifier = DB.getValue(window.getDatabaseNode(), "encumbrance.mod", 0);

	-- Get the DM for the value
	if string.find(sAttribute, "woundtrack") then
		sAttribute = string.sub(sAttribute:upper(),11,13);
		nTotal = DB.getValue(window.getDatabaseNode(), "woundtrack." .. sAttribute:lower() .. "_mod", 0);
	else
		sAttribute = string.sub(sAttribute:upper(),1,3);
	end

	if StringManager.contains(DataCommon.nonphysicalcharacteristics, sAttribute) then
		nEncModifier = 0;
	end

	local rActor = ActorManager.resolveActor(window.getDatabaseNode());

	ActionsCharacteristics.performRoll(draginfo, rActor, 2, sAttribute, nTotal, nEncModifier);
end

function onDoubleClick(x, y)
	action();
	return true;
end

function onDragStart(button, x, y, draginfo)
	action(draginfo);
	return true;
end