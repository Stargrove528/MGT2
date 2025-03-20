--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
    super.onInit();

	local nodeWin = DB.getChild(getDatabaseNode(), "...woundtrack");
    if nodeWin then
        DB.addHandler(DB.getPath(nodeWin, 'dex_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'str_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'end_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'int_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'soc_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'edu_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'psi_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'luc_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'mor_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'san_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'wea_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'cha_mod'), "onUpdate", onSourceUpdate);
        DB.addHandler(DB.getPath(nodeWin, 'ter_mod'), "onUpdate", onSourceUpdate);
    end

    local sOptionalCharacteristics = '';
    local sOptionalCharacteristicsValues = '';
    local sOption;
    local aAllCharacteristics = DataCommon.allcharacteristics;
    local wTop = UtilityManager.getTopWindow(window);
    local sPCNode = wTop.getDatabaseNode();
    local bAslan, bHiver = false;
    local sRace = DB.getValue(sPCNode, 'race', 'unknown'):lower();

    if sRace == "aslan" then
        bAslan = true;
    end
    if sRace == "hiver" then
        bHiver = true;
    end

    local sCharacteristic = '';

    i = 1;
    while aAllCharacteristics[i] do
        sCharacteristic = aAllCharacteristics[i];
        sOption = OptionsManager.getOption("CHAR" .. sCharacteristic:upper());
        if sOption:lower() == 'yes' then
            if sCharacteristic:lower() == 'ter' then
                if bAslan == true then
                    sOptionalCharacteristics = sOptionalCharacteristics .. '|' .. StringManager.capitalize(sCharacteristic:lower());
                    sOptionalCharacteristicsValues = sOptionalCharacteristicsValues  .. '|' .. sCharacteristic:lower() .. '_mod' ;
                end
            elseif sCharacteristic:lower() == 'res' then
                if bHiver == true then
                    sOptionalCharacteristics = sOptionalCharacteristics .. '|' .. StringManager.capitalize(sCharacteristic:lower());
                    sOptionalCharacteristicsValues = sOptionalCharacteristicsValues  .. '|' .. sCharacteristic:lower() .. '_mod' ;
                end
            else
                sOptionalCharacteristics = sOptionalCharacteristics .. '|' .. StringManager.capitalize(sCharacteristic:lower());
                sOptionalCharacteristicsValues = sOptionalCharacteristicsValues  .. '|' .. sCharacteristic:lower() .. '_mod' ;
            end
        end
        i = i + 1;
    end

    sDefaultLabel = ' - ';
    sLabels = 'Str|Dex|End|Int|Edu|Soc' .. sOptionalCharacteristics;
    sValues = 'str_mod|dex_mod|end_mod|int_mod|edu_mod|soc_mod' .. sOptionalCharacteristicsValues;

    super.initialize(sLabels, sValues, sDefaultLabel);
    super.updateDisplay();
end

function onClose()
	local nodeWin = DB.getChild(getDatabaseNode(), "...woundtrack");
    if nodeWin then
        DB.removeHandler(DB.getPath(nodeWin, 'dex_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'str_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'end_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'int_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'soc_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'edu_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'psi_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'luc_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'mor_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'san_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'wea_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'cha_mod'), "onUpdate", onSourceUpdate);
        DB.removeHandler(DB.getPath(nodeWin, 'ter_mod'), "onUpdate", onSourceUpdate);
    end
end

function onSourceUpdate(nodeUpdated)
    onValueChanged();
end

function onValueChanged()
    local sValue = getStringValue();
    local nodeWin = window.getDatabaseNode();
    if nodeWin then
        nDBtoapply = DB.getValue(nodeWin, "...woundtrack." ..sValue, 0);
        window.characteristicDM.setValue(nDBtoapply);
    end
end