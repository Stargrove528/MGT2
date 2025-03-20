--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Characteristic Check - checks to see if the woundtrack equivalent exists
function onInit()
    wasValue = 0;

    local nodeName = getName();
    local statNode = nodeName:sub(1,3);
    local nodeValue = getValue();
	local nodeWin = DB.createChild(getDatabaseNode(), "...woundtrack");

    local nodeStat = DB.getChild(nodeWin, statNode);
    local statEquipmentNode = statNode .. "_equipment";
    local statEquipmentNodeText = statNode .. "_equipmenttext";
    local statDMNode = statNode .. "_mod";

    if not nodeStat then
        local nodeDMValue = GameSystem.calculateCharacteristicDM(nodeValue);

        DB.setValue(nodeWin, statNode,'number', nodeValue );
        DB.setValue(nodeWin, statDMNode,'number', nodeDMValue );
        DB.setValue(nodeWin, statEquipmentNode,'number', 0 );
        DB.setValue(nodeWin, statEquipmentNodeText, 'string', ' ');
    else
        -- May not have the new equipment node
        local statEqupmentValue = DB.getValue(nodeWin, statEquipmentNode, null);
        if not statEqupmentValue then
            DB.setValue(nodeWin, statEquipmentNode,'number', 0 );
            DB.setValue(nodeWin, statEquipmentNodeText, 'string', ' ');
        end
    end
end

function onGainFocus()
    wasValue = getValue();
end

function onValueChanged()
    local nValue = getValue();
    local valueChanged = nValue - wasValue
    updateWoundTrack(valueChanged)
    wasValue = nValue + valueChanged;
end

function updateWoundTrack(nChangeValue)

    local nodeName = getName();
    local statNode = nodeName:sub(1,3);
	local nodeWin = DB.getChild(getDatabaseNode(), "...woundtrack");
    local nodeStat = DB.getChild(nodeWin, statNode);
    local nCurrentValue = DB.getValue(nodeWin, statNode, 0);

    local newValue = nCurrentValue + nChangeValue;

    if newValue < 0 then
        newValue = 0;
    end

    DB.setValue(nodeWin, statNode,'number', newValue);
    local nodeDMValue = GameSystem.calculateCharacteristicDM(newValue);
    local statDMNode = statNode .. "_mod";
    DB.setValue(nodeWin, statDMNode,'number', nodeDMValue);

end