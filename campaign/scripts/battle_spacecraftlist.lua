--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	if isReadOnly() then
		return;
	end

	if draginfo.isType("shortcut") then
        local sClass,sRecord = draginfo.getShortcutData();
		SpacecraftManager.addLinkToBattle(window.getDatabaseNode(), sClass, sRecord);
		return true;
	end
end
