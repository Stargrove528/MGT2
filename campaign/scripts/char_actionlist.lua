-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    registerMenuItem(Interface.getString("char_menu_addaction"), "insert", 5);
end
function onMenuSelection(selection)
	if selection == 5 then
		createWindow(nil, true);
	end
end
