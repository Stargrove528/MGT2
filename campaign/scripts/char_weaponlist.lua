-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("char_menu_addweapon"), "insert", 5);
end
function onMenuSelection(selection)
	if selection == 5 then
		createWindow(nil, true);
	end
end

function onChildWindowCreated(w)
	w.updateWindow();

	local node = w.getDatabaseNode();
	DB.setValue(node, "type", "string", "Weapons");
	DB.setValue(node, "carried", "number", 2);
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		if ItemManager2.isWeapon(sClass, sRecord) then
			return ItemManager.handleAnyDrop(window.getDatabaseNode(), draginfo);
		end
	end
end

function onFilter(w)
	local nodeItem = w.getDatabaseNode();
	local bWeapon = DB.getValue(nodeItem, "type", ""):lower():match("weapon");
	local bCarried = DB.getValue(nodeItem, "carried", 0) == 2;
	if ItemManager2.isWeapon("item", DB.getPath(nodeItem)) and bCarried then
		w.updateWindow();
		w.skillDM.onSourceUpdate();
		return true;
	end

	return false;
end
