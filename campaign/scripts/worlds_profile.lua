--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- World Characteristics

function onLoseFocus()
	local node = window.getDatabaseNode();
	local nSkipUWPAG = DB.getValue(node, "skipUWPAG", 0);
	if OptionsManager.getOption("UWPAG"):lower() == "off" or nSkipUWPAG == 1 then
		return;
	end

	local sUWP = getValue();
	if StringManager.contains({""}, sUWP) then
		return;
	end

	sUWP = StringManager.trim(sUWP)
	local sHexCode = nil
	local sProfile = nil
	local sRemainder = nil
	local aUWP = StringManager.split(sUWP, " ", true);

	if string.len(aUWP[1]) == 4 then
		sHexCode = aUWP[1]
		sProfile = aUWP[2]
		table.remove(aUWP, 1);
		table.remove(aUWP, 1);
	else
		sProfile = aUWP[1]
		table.remove(aUWP, 1);
	end

	if sHexCode ~= "" then
		window["hexlocation"].setValue(sHexCode);
	end

	if sProfile ~= nil then
		populateWorldData(sProfile);
	end

	populateRemainder(aUWP);
	return 0;
end

function populateRemainder(aUWP)
	local node = window.getDatabaseNode();
	local nSkipUWPAG = DB.getValue(node, "skipUWPAG", 0);
	if OptionsManager.getOption("UWPAG"):lower() == "off" or nSkipUWPAG == 1 then
		return;
	end

	if aUWP == "" then
		return;
	end

	local sBases = nil;
	local sTradeCodes = nil;
	local sTravelCode = nil;
	local sRemainder = ''

	-- this is not fun
	-- the first chunk, could be a base, or a trade code
	-- check if it's a base, but making sure it's not a trade code!
	if isTradeCode(aUWP[1]) == false then
		-- it's a base
		sBases = aUWP[1];
		table.remove(aUWP, 1);
	end

	for k, v in pairs(aUWP) do
		if isTradeCode(v) then
			if sTradeCodes ~= nil then
				sTradeCodes = sTradeCodes .. " " .. v;
			else
				sTradeCodes = v;
			end
		else
			if isTravelCode(v) then
				if sTravelCode ~= nil then
					sTravelCode = sTravelCode .. " " .. v;
				else
					sTravelCode = v;
				end
			else
				sRemainder = sRemainder .. v;
			end
		end
	end

	if sBases ~= "" then
		window["bases"].setValue(sBases);
	end

	if sTradeCodes ~= "" and sTradeCodes ~= nil then
		window["trade_codes"].setValue(sTradeCodes);
	end

	if sTravelCode ~= "" then
		window["travel_code"].setValue(sTravelCode);
	end

end

function isTradeCode(sUWP)
	if sUWP and DataCommon.tradecodes[sUWP:lower()] then
		return true;
	end
	return false;
end

function isTravelCode(sUWP)
	if DataCommon.travelcodes[sUWP:lower()] then
		return true;
	end
	return false;
end

function populateWorldData(sProfile)
	local node = window.getDatabaseNode();
	local nSkipUWPAG = DB.getValue(node, "skipUWPAG", 0);
	if OptionsManager.getOption("UWPAG"):lower() == "off" or nSkipUWPAG == 1 then
		return;
	end

	sStarport = string.sub(sProfile, 1,1);
	sSize = string.sub(sProfile, 2,2);
	sAtmosphere = string.sub(sProfile, 3,3);
	sHydrographics = string.sub(sProfile, 4,4);
	sPopulation = string.sub(sProfile, 5,5);
	sGovernment = string.sub(sProfile, 6,6);
	sLawLevel = string.sub(sProfile, 7,7);
	sTechLevel = string.sub(sProfile, 9,9);

	window["starport_quality"].setValue(sStarport);
	window["size"].setValue(sSize);
	window["atmosphere_type"].setValue(sAtmosphere);
	window["hydrographics"].setValue(sHydrographics);
	window["population"].setValue(sPopulation);
	window["government_type"].setValue(sGovernment);
	window["law_level"].setValue(sLawLevel);
	window["tech_level"].setValue(sTechLevel);
end