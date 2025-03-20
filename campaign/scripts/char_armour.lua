--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Character Armour

function isArmour()
    local bIsArmour = false;
	local nodeChar = DB.getChild(getDatabaseNode(), "...")
    local nRecordtype = recordtype.getValue();
    local sType = type.getValue():lower();

    if nRecordtype == 0 and sType == 'armour' then
        if carried.getValue() == 2 then
            bIsArmour = true;
        end
    end

    if nRecordtype == 1 and (sType == 'augments' or sType == 'personal augmentation') and string.find(name.getValue(), 'Subdermal') then
        bIsArmour = true;
    end

    if bIsArmour then
        CharManager.calculateArmourRating(nodeChar);
    end
    return bIsArmour;
end
