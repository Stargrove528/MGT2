-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("worlds_menu_addport"), "insert", 5);
end
function onMenuSelection(selection)
	if selection == 5 then
		createWindow(nil, true);
	end
end

function update(bReadOnly)
	for _,w in pairs(getWindows()) do
		w.update(bReadOnly);
	end
end
