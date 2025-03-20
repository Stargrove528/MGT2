--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	-- Register the deletion menu item for the host
	registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);

	-- Update the displays
	toggleSubTasks();
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		delete();
	end
end

function delete()
	UtilityManager.safeDeleteWindow(self);
end

function onVisibilityChanged()
	windowlist.onVisibilityToggle();
end

function toggleSubTasks()
	local bShow = (activatesubtasks.getValue() == 0);

	subtasklist.setVisible(bShow);
	subtasks_iadd.setVisible(bShow);
	subtasks_iedit.setVisible(bShow);
	label_skillrequired.setVisible(bShow);
	label_statrequired.setVisible(bShow);
	label_taskdifficulty.setVisible(bShow);
	label_taskmod.setVisible(bShow);
	label_result.setVisible(bShow);
	label_effect.setVisible(bShow);
	scrollbar_subtasklist.setVisible(bShow);
end
