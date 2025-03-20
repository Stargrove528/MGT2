-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

iscustom = true;
sets = {};

function onInit()
	updateMenu();
end

function updateWindow()
	local aSkills = PsiManager.getPsiTalents();
	local sLabel = label.getValue();
	local t = aSkills[sLabel];
	if t then
		setCustom(false);
	else
		setCustom(true);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		UtilityManager.safeDeleteWindow(self);
	end
end

-- This function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.
function setCustom(state)
	iscustom = state;
	
	if iscustom then
		label.setEnabled(true);
		label.setLine(true);
	else
		label.setEnabled(false);
		label.setLine(false);
	end
	
	updateMenu();
end

function isCustom()
	return iscustom;
end

function updateMenu()
	resetMenuItems();
	
	if iscustom then
		registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
	else
		local aSkills = PsiManager.getPsiTalents();
		local sLabel = label.getValue();
		local rSkill = aSkills[sLabel];
		
	end
end
