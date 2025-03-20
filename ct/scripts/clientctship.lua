--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onSortCompare(w1, w2)
	return CombatManager.onTrackerSortCompare("ship", w1.getDatabaseNode(), w2.getDatabaseNode());
end

function onDrop(x, y, draginfo)
	local sCTNode = UtilityManager.getWindowDatabasePath(getWindowAt(x,y));
	if SpacecraftCombatManager.handleDrop(draginfo, sCTNode) then
		return true;
	end
	return CombatDropManager.handleAnyDrop(draginfo, sCTNode);
end

function onClickDown(button, x, y)
	if button == 1 then
		return true;
	end
end
function onClickRelease(button, x, y)
	if button == 1 then
		local w = getWindowAt(x, y);
		if w then
			return CombatManager.handleCTTokenPressed(w.getDatabaseNode());
		end
	end
end
