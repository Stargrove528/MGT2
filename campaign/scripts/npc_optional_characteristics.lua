sSettingName = "";
sFullControlName = "";
sShortControlName = "";

function onInit()
    local nodeNPC = window.getDatabaseNode();
    local sTypeLower = DB.getValue(nodeNPC, "type", ""):lower();
    if sTypeLower == "animal" then
		return;
	end
	if sTypeLower == "robot" then
		return;
	end

    sSettingName = "CHAR" .. getName():sub(1,3):upper();
    sFullControlName = getName():lower();
    sFullControlName = sFullControlName:gsub('_label', '');
    sShortControlName = getName():sub(1,3):lower();

    OptionsManager.registerCallback(sSettingName, onUpdate);
    onUpdate()
end

function onClose()
    local nodeNPC = window.getDatabaseNode();
    local sTypeLower = DB.getValue(nodeNPC, "type", ""):lower();
    if sTypeLower == "animal" then
		return;
	end
	if sTypeLower == "robot" then
		return;
	end

    sSettingName = "CHAR" .. getName():sub(1,3):upper();
    sFullControlName = getName():lower();
    sFullControlName = sFullControlName:gsub('_label', '');
    sShortControlName = getName():sub(1,3):lower();

    OptionsManager.unregisterCallback(sSettingName, onUpdate);
end

function onUpdate()
    local sCHAROption = OptionsManager.getOption(sSettingName);
    local bVisible = sCHAROption:lower() == "yes"

    if sFullControlName == "npc_territory" then
        local nCharacterNode = window.getDatabaseNode();
        local sRace = DB.getValue(nCharacterNode, "race", "unknown"):lower();
        sFullControlName = "territory";
        sShortControlName = "ter";

        if sRace ~= "aslan" then
            bVisible = false;
        end
    end

	if window then
		if window[sFullControlName] then
			window[sFullControlName].setVisible(bVisible);
		end

		if window[sShortControlName] then
			window[sShortControlName .. "_mod"].setVisible(bVisible);
		end

		setVisible(bVisible)
	end
end