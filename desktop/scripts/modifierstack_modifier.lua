--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--
function onGainFocus()
	ModifierStack.setAdjustmentEdit(true);
end

function onLoseFocus()
	ModifierStack.setAdjustmentEdit(false);
end

function onWheel(notches)
	if not hasFocus() then
		ModifierStack.adjustFreeAdjustment(notches);
	end

	return true;
end

function onValueChanged()
	if hasFocus() and ModifierStack.adjustmentedit then
		ModifierStack.setFreeAdjustment(getValue());
	end
end

function onClickDown(button, x, y)
	if button == 2 then
		ModifierStack.reset();
		return true;
	end
end

function onDrop(x, y, draginfo)
    local sEffect = string.match(draginfo.getStringData(), "(%-?%d+%sEffect%])");

    if sEffect ~= "" and sEffect ~= nil then
        local nEffectValue = tonumber(string.match(sEffect, "%-?%d+"));

        ModifierStack.setFreeAdjustment(nEffectValue);
        return window.modifier.setValue(nEffectValue);
    else
        return window.base.onDrop(x, y, draginfo);
    end
end

function onDragStart(button, x, y, draginfo)
	draginfo.setType("number");
	draginfo.setDescription(ModifierStack.getDescription());
	draginfo.setNumberData(ModifierStack.getSum());
	return true;
end

function onDragEnd(draginfo)
	ModifierStack.reset();
end
