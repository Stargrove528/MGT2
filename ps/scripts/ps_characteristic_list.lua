--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
    super.onInit();
    local aOptional = DataCommon.psoptionalcharacteristicsdata;

    for _,v in pairs(aOptional) do
        local sCharacteristic = v:sub(1,3):upper();
        OptionsManager.registerCallback("CHAR" .. sCharacteristic, onUpdate);
    end
    onUpdate();

end
function onClose()
    local aOptional = DataCommon.psoptionalcharacteristicsdata;
    for _,v in pairs(aOptional) do
        local sCharacteristic = v:sub(1,3):upper();
        OptionsManager.unregisterCallback("CHAR" .. sCharacteristic, onUpdate);
    end
end
function onUpdate()
    clear();
    addItems(DataCommon.psdefaultcharacteristicsdata);

    local aOptional = DataCommon.psoptionalcharacteristicsdata;
    local aExtraCharacteristics = {};

    for _,v in pairs(aOptional) do
        local sCharacteristic = v:sub(1,3):upper();
        local sCHAR = OptionsManager.getOption("CHAR" .. sCharacteristic);

        if sCHAR:lower() == "yes" then
            table.insert(aExtraCharacteristics, v);
        end
    end

    if #aExtraCharacteristics > 0 then
        addItems(aExtraCharacteristics);
    end
end