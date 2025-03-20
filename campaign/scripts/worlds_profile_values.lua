--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
    local sProfile = getName();
    if (sProfile == "bases") then
        updateToolTip(getValue(),'bases', 'basecodes');
    end
    if (sProfile == "trade_codes") then
        updateToolTip(getValue(),'trade_codes', 'tradecodes');
    end
    if (sProfile == "travel_code") then
        updateToolTip(getValue(),'travel_code', 'travelcodes');
    end
end


-- Worlds Profile Value
function onValueChanged()
	local node = window.getDatabaseNode();
	local nSkipUWPAG = DB.getValue(node, "skipUWPAG", 0);
	if OptionsManager.getOption("UWPAG"):lower() == "off" or nSkipUWPAG == 1 then
		return;
	end

    local sProfile = getName();

    if (sProfile == "starport_quality") then
        setLevel(getValue(), 'starport_quality_text', 'starport_quality', 'starportquality', 'No Starport');
    elseif (sProfile == "size") then
        setLevel(getValue(), 'size_text', 'size', 'size', '800 km Asteroid, orbital complex');
    elseif (sProfile == "atmosphere_type") then
        setLevel(getValue(), 'atmosphere_type_text', 'atmosphere_type', 'atmospheretype');
    elseif (sProfile == "hydrographics") then
        setLevel(getValue(), 'hydrographics_text', 'hydrographics', 'hydrographics', '0\\%-5\\% Desert world');
    elseif (sProfile == "population") then
        setLevel(getValue(), 'population_text', 'population', 'population');
    elseif (sProfile == "government_type") then
        setLevel(getValue(), 'government_type_text', 'government_type', 'governmenttype');
    elseif (sProfile == "law_level") then
        setLevel(getValue(), 'law_level_text', 'law_level', 'lawlevel');
    elseif (sProfile == "tech_level") then
        setTechLevel(getValue());
    elseif (sProfile == "bases") then
        updateToolTip(getValue(),'bases', 'basecodes');
    elseif (sProfile == "trade_codes") then
        updateToolTip(getValue(),'trade_codes', 'tradecodes');
    elseif (sProfile == "travel_code") then
        updateToolTip(getValue(),'travel_code', 'travelcodes');
    end

    rebuildUWP();
end

function setLevel(sValue, sTextField, sCodeField, oDataObject, sDefault)
    if sValue == "" then
        return
    else
        local sLevel = "";

        sValue = string.upper(sValue);

        if DataCommon[oDataObject][sValue] then
            sLevel = DataCommon[oDataObject][sValue];
        else
            if sDefault then
                sLevel = sDefault
            else
                sLevel = "None"
            end
        end

        window[sTextField].setValue(sLevel);
        window[sCodeField].setValue(sValue);
    end
end

function setTechLevel(sValue)
    if sValue == "" then
        return
    else
        sValue = string.upper(sValue);

        sTechLevel = tonumber(sValue,16);

        window["tech_level_text"].setValue("Tech Level: " .. sTechLevel);
        window["tech_level"].setValue(sValue);
    end
end

-- Rebuild the UWP from all the values
function rebuildUWP()
	local sStarportQuality = window["starport_quality"].getValue();
	local sSize = window["size"].getValue();
	local sAtmosphereType = window["atmosphere_type"].getValue();
	local sHydrographics = window["hydrographics"].getValue();
	local sPopulation = window["population"].getValue();
	local sGovernmentType = window["government_type"].getValue();
	local sLawLevel = window["law_level"].getValue();
	local sTechLevel = window["tech_level"].getValue();
	local sBases = window["bases"].getValue();
    local sTradeCodes = StringManager.trim(window["trade_codes"].getValue());
    local sTravelCode = window["travel_code"].getValue();
	local sHexCode = window["hexlocation"].getValue();

	-- now to rebuild the UWP
    sStarportQuality = CharManager.DEC_HEX(sStarportQuality);
	sSize = CharManager.DEC_HEX(sSize);
	sAtmosphereType = CharManager.DEC_HEX(sAtmosphereType);
	sHydrographics = CharManager.DEC_HEX(sHydrographics);
	sPopulation = CharManager.DEC_HEX(sPopulation);
    sGovernmentType = CharManager.DEC_HEX(sGovernmentType);
    sLawLevel = CharManager.DEC_HEX(sLawLevel);
    sTechLevel = CharManager.DEC_HEX(sTechLevel);

    local sProfile = sStarportQuality .. sSize .. sAtmosphereType .. sHydrographics .. sPopulation .. sGovernmentType .. sLawLevel .. "-" .. sTechLevel;
    sProfile = StringManager.trim(sProfile);
    sBases = stripchars(sBases,",");
    sTradeCodes = stripchars(sTradeCodes,",");

    if sTravelCode == "* Unknown" or sTravelCode == "-" then
        sTravelCode = "";
    end

    local lcUWP = sHexCode .. " " .. sProfile .. " " .. sBases .. " " .. sTradeCodes .. " " .. sTravelCode;
	window["uwp"].setValue(lcUWP);
end


function stripchars(str, chrs)
    local s = str:gsub("["..chrs:gsub("%W","%%%1").."]", '')
    return s
end

function updateToolTip(sCodes, sFieldToUpdate, oDataObject)

    local aWords = StringManager.parseWords(sCodes);
    local sToolTip = "";
    local sType = "";

    local i = 1;
    while aWords[i] do

        if DataCommon[oDataObject][aWords[i]:lower()] then

            sType = DataCommon[oDataObject][aWords[i]:lower()];

            if sToolTip == "" then
                sToolTip = sType .. " (" .. aWords[i] ..")";
            else
                sToolTip = sToolTip .. "\r\n" .. sType .. " (" .. aWords[i] ..")";
            end
        end
        i = i + 1;
    end

    window[sFieldToUpdate].setTooltipText(sToolTip);

end
