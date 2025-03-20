--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function linkPCFields(nodePS)
	local sClass, sRecord = DB.getValue(nodePS, "link", "", "");
	if sRecord == "" then
		return;
	end
	local nodeChar = DB.findNode(sRecord);
	if not nodeChar then
		return;
	end

	PartyManager.linkRecordField(nodeChar, nodePS, "name", "string");
	PartyManager.linkRecordField(nodeChar, nodePS, "token", "token", "token");

	PartyManager.linkRecordField(nodeChar, nodePS, "race", "string");

	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.str", "number", "strength");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.dex", "number", "dexterity");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.end", "number", "endurance");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.int", "number", "intelligence");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.edu", "number", "education");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.soc", "number", "social");

	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.str_mod", "number", "strdice");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.dex_mod", "number", "dexdice");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.end_mod", "number", "enddice");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.int_mod", "number", "intdice");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.edu_mod", "number", "edudice");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.soc_mod", "number", "socdice");

	PartyManager.linkRecordField(nodeChar, nodePS, "armour", "string", "armourname");
	PartyManager.linkRecordField(nodeChar, nodePS, "armour_rating", "number", "armourrating");

	PartyManager.linkRecordField(nodeChar, nodePS, "attributes.endurance", "number", "maxend");
	PartyManager.linkRecordField(nodeChar, nodePS, "attributes.strength", "number", "maxstr");
	PartyManager.linkRecordField(nodeChar, nodePS, "attributes.dexterity", "number", "maxdex");

	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.end", "number", "wtend");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.str", "number", "wtstr");
	PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack.dex", "number", "wtdex");

	-- Optionals
	tOptions = {
		"CHARPSI",
		"CHARMOR",
		"CHARLUC",
		"CHARSAN",
		"CHARWEA",
		"CHARCHA",
	};
	for _,v in ipairs(tOptions) do
		local bVisible = (OptionsManager.getOption(v) == "yes");
		if bVisible then
			local sStat = v:gsub("CHAR", ""):lower();
			local sFullStat = DataCommon.optional_characterisics_stol[sStat]:lower();

			PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack." .. sStat, "number", sFullStat);
			PartyManager.linkRecordField(nodeChar, nodePS, "woundtrack." .. sStat .. "_mod", "number", sStat .. "dice");
		end
	end
end
