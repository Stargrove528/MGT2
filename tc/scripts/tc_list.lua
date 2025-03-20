--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local enablevisibilitytoggle = true;

function onInit()
    self.onVisibilityToggle();
end

function toggleVisibility()
	if not enablevisibilitytoggle then
		return;
	end

	local bVisibility = WindowManager.getInnerControlValue(window, "button_global_visibility");
	for _,v in pairs(getWindows()) do
		if bVisibility ~= v.taskvis.getValue() then
			v.taskvis.setValue(bVisibility);
        end
	end
end

function onVisibilityToggle()
	local bAnyVisible = 0;
	for _,v in pairs(getWindows()) do
		bAnyVisible = 1;
	end

	enablevisibilitytoggle = false;
	WindowManager.setInnerControlValue(window, "button_global_visibility", bAnyVisible)
	enablevisibilitytoggle = true;
end
