sSettingName = "";
sFullControlName = "";
sShortControlName = "";

function onInit()
    sSettingName = "CHAR" .. getName():sub(7,9):upper();
    sFullControlName = getName():sub(7):lower();
    sFullControlName = sFullControlName:gsub('_label', '');
    sShortControlName = getName():sub(7,9):lower();

    OptionsManager.registerCallback(sSettingName, onUpdate);
    onUpdate()
end
function onUpdate()
    if not window then
        return
    end

    local sCHAROption = OptionsManager.getOption(sSettingName);
    local bVisible = sCHAROption:lower() == "yes"

    if sFullControlName == "territory" then
        local nCharacterNode = window.getDatabaseNode();
        local sRace = DB.getValue(nCharacterNode, 'race', 'unknown'):lower();

        if sRace ~= "aslan" then
            bVisible = false;
        end
    end

    if sFullControlName == "resolve" then
        local nCharacterNode = window.getDatabaseNode();
        local sRace = DB.getValue(nCharacterNode, 'race', 'unknown'):lower();

        if sRace ~= "hiver" then
            bVisible = false;
        end
    end

    window[sFullControlName].setVisible(bVisible);
    window[sShortControlName .. "_dm"].setVisible(bVisible);
    window[sShortControlName .. "_mod"].setVisible(bVisible);
    window[sShortControlName .. "_equipment"].setVisible(bVisible);
    if window["label_" .. sShortControlName .. "_dm"] then
        window["label_" .. sShortControlName .. "_dm"].setVisible(bVisible);
        -- window[sFullControlName .. "_spacer"].setVisible(bVisible);
    end

    setVisible(bVisible)
end