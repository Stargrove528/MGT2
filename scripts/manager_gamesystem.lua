--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Ruleset action types
actions = {
	["dice"] = { bUseModStack = true },
	["table"] = { },
	["attack"] = { sIcon = "action_attack", sTargeting = "each", bUseModStack = true },
	["damage"] = { sIcon = "action_damage", sTargeting = "each", bUseModStack = true },
	["heal"] = { sIcon = "action_heal", sTargeting = "all", bUseModStack = true },
	["skill"] = { bUseModStack = true },
	["ability"] = { bUseModStack = true },
	["psiability"] = { bUseModStack = true },
	["effects"] = { bUseModStack = true },
	["tactics"] = { bUseModStack = true },
	["task"] = { bUseModStack = true },
	-- SHIP RELATED
	["shipattack"] = { sIcon = "action_attack", sTargeting = "each", bUseModStack = true },
	["shipdamage"] = { sIcon = "action_damage", sTargeting = "each", bUseModStack = true },
	["shipaction"] = { bUseModStack = true },
	["shipcritical"] = { },
	["crewmorale"] = { bUseModStack = true },
	["combatmishap"] = { sIcon = "action_mishap" },
	["combathitlocation"] = { sIcon = "action_hitloction" },
	["combatdisablingwoundeffect"] = { sIcon = "action_disablingwoundeffect" },
};

targetactions = {
	"attack",
	"damage",
	"heal",
	"effect",
	"tactics",
	"task",
};

spacecrafttargetactions = {
	"shipattack",
	"shipdamage",
	"shipcritical",
	"effect",
};

currencies = { 
	{ name = "MCr", weight = 0, value = 1000000 },
	{ name = "Cr", weight = 0, value = 1 },
};
currencyDefault = "Cr";

function onInit()
	CombatListManager.registerStandardInitSupport();
	registerDeathMarkers();
	SoundsetManager.registerSimpleSettingsAttack();
end

function getCharSelectDetailHost(nodeChar)
	return "";
end

function requestCharSelectDetailClient()
	return "name";
end

function receiveCharSelectDetailClient(vDetails)
	return vDetails, "";
end

function getDistanceUnitsPerGrid()
	return 1;
end

function registerDeathMarkers()
	ImageDeathMarkerManager.setEnabled(true);
	
	ImageDeathMarkerManager.registerGetCreatureTypeFunction(getCreatureType);

	ImageDeathMarkerManager.registerCreatureTypes(DataCommon.creaturetype);
	ImageDeathMarkerManager.setCreatureTypeDefault("Robot", "blood_black");
end
function getCreatureType(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return nil;
	end
	return DB.getValue(nodeActor, "type", "");
end

function calculateCharacteristicDM(nValue)
	local nModValue = -3
	if nValue > 0 then
		-- nModValue = math.floor(5 + (nValue - 21)/3)
		nModValue = math.floor((nValue/3)-2);
	end
	return nModValue
end

function checkModuleIsLoaded(sModule)
	local bModuleIsLoaded = false;
	local modules = Module.getModules();
	for _, v in ipairs(modules) do
		if v == sModule then
			local aModuleInfo = Module.getModuleInfo(v);
			if aModuleInfo.loaded then
				bModuleIsLoaded = true;
			end
		end
	end

	return bModuleIsLoaded;
end

function buildSkillsList(window)
	local aSkills = {}

	-- Add skills from any loaded modules
	local modules = Module.getModules();
	for _, v in ipairs(modules) do
		local aModuleInfo = Module.getModuleInfo(v);
		if aModuleInfo.loaded then
			nodeSource = DB.findNode("reference.skilldata@" ..v);
			if type(nodeSource) == "databasenode" then
				for _, vSkill in ipairs(DB.getChildList(nodeSource)) do
					sEachSkill = DB.getValue(vSkill, "name", "");
					table.insert(aSkills, sEachSkill);
				end
			end
		end
	end

	-- Add on any Players Skills not already in the list
	local tParty = PartyManager.getPartyActors();
	for _,v in pairs(tParty) do
		local nodeChar = DB.findNode(ActorManager.getCreatureNodeName(v) .. ".skilllist");
		if nodeChar then
			for _, vSkill in ipairs(DB.getChildList(nodeChar)) do
				sEachSkill = DB.getValue(vSkill, "name", "");

				local bSkillFound = false;
				for _,v2 in pairs(aSkills) do
					if v2:lower() == sEachSkill:lower() then
						bSkillFound = true;
						break
					end
				end
				if not bSkillFound then
					table.insert(aSkills, sEachSkill);
				end
			end
		end
	end
	
	return aSkills;
end
