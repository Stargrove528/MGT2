--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ItemManager.setCustomCharAdd(onCharItemAdd);
	ItemManager.setCustomCharRemove(onCharItemDelete);

	if Session.IsHost then
		CharInventoryManager.enableInventoryUpdates();
		CharInventoryManager.enableSimpleLocationHandling();

		CharInventoryManager.registerFieldUpdateCallback("carried", CharManager.onCharInventoryCarriedChange);
	end
end

--
--	CALLBACK REGISTRATIONS
--

function onCharItemAdd(nodeItem)
	local nCarriedStatus = 1;

	-- If this is a Heavy Weapon...
	local sType = DB.getValue(nodeItem, "type", "");
	local bHeavyWeapon = false;
	if sType == "Heavy Weaponry" then
		local nMass = DB.getValue(nodeItem, "mass", 0);
		if nMass >= 100 then
			local bOptionEHW = OptionsManager.isOption("EHW", "yes");
			bHeavyWeapon = true;

			if bOptionEHW == false then
				local msg = {font = "msgfont"};
				local sItemName = DB.getValue(nodeItem,"name","");

				local sFormat = Interface.getString("char_add_heavy_weaponry");
				msg.text = string.format(sFormat, sItemName);

				Comm.deliverChatMessage(msg);
				DB.deleteNode(nodeItem);
				return false;
			end

			nCarriedStatus = 0;
		end
	end

	if ItemManager2.isWeapon("item", nodeItem) or ItemManager2.isAugment(nodeItem, "item") then
		nCarriedStatus = 2;
	end

	DB.setValue(nodeItem, "carried", "number", nCarriedStatus);
	addToWeaponDB(nodeItem);
end
function onCharItemDelete(nodeItem)
	removeFromWeaponDB(nodeItem);
end

function onCharInventoryCarriedChange(nodeItem, sField)
	local nodeChar = DB.getChild(nodeItem, "...");

	if ItemManager2.isWeapon("item", nodeItem) then
		local nodeWeaponList = CharManager.getWeaponListNode(nodeChar, DB.getValue(nodeItem, "name", ""));
		if nodeWeaponList then
			DB.setValue(nodeWeaponList, "carried", "number", nCarried);
		end
	end

	CharManager.calculateArmourRating(nodeChar);
	CharManager.calculateItemModifiers(nodeChar);
end

--
--	OTHER FUNCTIONS
--

function calculateItemModifiers(nodeChar)
	local aModifiers = {};
	local nModifiers = 1;
	local aWords;

	for _, vNode in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		nCarriedState = DB.getValue(vNode, "carried", 0);
		if nCarriedState == 2 then --carried only
			sModifiers = DB.getValue(vNode, "modifiers");
			if sModifiers then
				aWords = StringManager.split(sModifiers:lower(),",");

				local i = 1;
				while aWords[i] do
					aModifiers[nModifiers] = aWords[i];
					nModifiers = nModifiers + 1;
					i = i + 1;
				end
			end
		end
	end

	-- reset all equipment modifiers
	local aAllCharacteristics = DataCommon.allcharacteristics;

	i = 1;
	while aAllCharacteristics[i] do
		DB.setValue(nodeChar, "attributes." .. aAllCharacteristics[i]:lower() .. "_equipment"  , "number", 0);
		DB.setValue(nodeChar, "attributes." .. aAllCharacteristics[i]:lower() .. "_equipmenttext", "string", "");
		i = i + 1;
	end

	i = 1;
	while aModifiers[i] do
		local sCharacteristic, nModifier = aModifiers[i]:match("(%a+)%s([%+%-]?%s*%d+)");

		if nModifier then
			nModifier = nModifier:gsub(" ", "");

			local nCurrentValue = DB.getValue(nodeChar, "attributes." .. sCharacteristic .. "_equipment", 0);
			sEquipmentNode = DB.setValue(nodeChar, "attributes." .. sCharacteristic .. "_equipment", "number", nCurrentValue + nModifier);
		end

		i = i + 1;
	end

	-- update all equipment modifiers texts
	i = 1;
	while aAllCharacteristics[i] do
		local nCurrentValue = DB.getValue(nodeChar, "attributes." .. aAllCharacteristics[i]:lower() .. "_equipment", 0);

		if nCurrentValue ~= 0 then
			if nCurrentValue < 0 then
				sNewText = "-" .. nCurrentValue
			else
				sNewText = "+" .. nCurrentValue
			end
			DB.setValue(nodeChar, "attributes." .. aAllCharacteristics[i]:lower() .. "_equipmenttext", "string", sNewText);
		end
		i = i + 1;
	end

end

--
-- Conversions
--
--
-- CHARACTER SHEET DROPS
--
function addInfoDB(nodeChar, nodeSource, sClass, sTalent)
	-- Validate parameters
	if not nodeChar or not nodeSource then
		return false;
	end

	if sClass == "reference_homeworld" then
		addHomeworldDB(nodeChar, nodeSource, sClass);
	elseif sClass == "reference_race" or sClass == "reference_subrace" then
		addRaceRef(nodeChar, nodeSource, sClass);
	elseif sClass == "reference_career" then
		addCareerDB(nodeChar, nodeSource, sClass);
	elseif sClass == "reference_skill" then
		addSkillRef(nodeChar, nodeSource, sClass);
	elseif sClass == "reference_psionic" then
		addPsionicRef(nodeChar, nodeSource, sClass, sTalent)
	else
		return false;
	end

	return true;
end

function addMiscActionRef(nodeChar, nodeSource, sClass)
	-- Validate parameters
	if not nodeChar or not nodeSource then
		return;
	end

	-- Add action entry
	local nodeAction = addMiscActionDB(nodeChar, DB.getValue(nodeSource, "name", ""));
	if nodeAction then
		DB.setValue(nodeAction, "text", "formattedtext", DB.getValue(nodeSource, "text", ""));
	end
end

function addMiscActionDB(nodeChar, sSkill)

	-- Get the list we are going to add to
	local nodeList = DB.createChild(nodeChar, "miscactions");
	if not nodeList then
		return nil;
	end

	-- Make sure this item does not already exist
	local nodeSkill = nil;
	for _, vSkill in ipairs(DB.getChildList(nodeList)) do
		if DB.getValue(vSkill, "name", "") == sSkill then
			nodeSkill = vSkill;
			break;
		end
	end

	-- Add the item
	if not nodeSkill then
		nodeSkill = DB.createChild(nodeList);
		DB.setValue(nodeSkill, "name", "string", sSkill);
		DB.setValue(nodeSkill, "noedit", "number", 1);
		DB.setValue(nodeSkill, "locked", "number", 1);
		DB.setValue(nodeSkill, "action","string","skill");
	else
		return false;
	end

	-- Announce
	local sFormat = Interface.getString("char_actions_message_actionsadd");
	local sMsg = string.format(sFormat, DB.getValue(nodeSkill, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);

	return nodeSkill;
end

function addRaceRef(nodeChar, nodeSource, sClass)
	-- Validate parameters
	if not nodeChar or not nodeSource then
		return;
	end

	if sClass == "reference_race" then
		local aTable = {};
		aTable["char"] = nodeChar;
		aTable["class"] = sClass;
		aTable["record"] = nodeSource;

		addRaceSelect(nil, aTable);
	end
end

function addRaceSelect(aSelection, aTable)
	-- If subraces available, make sure that exactly one is selected
	if aSelection then
		if #aSelection ~= 1 then
			ChatManager.SystemMessage(Interface.getString("char_error_addsubrace"));
			return;
		end
	end

	local nodeChar = aTable["char"];
	local nodeSource = aTable["record"];

	-- Determine race to display on sheet and in notifications
	local sRace = DB.getValue(nodeSource, "name", "");
	local sAttributes = DB.getValue(nodeSource, "characteristics", "");

	-- Notify
	local sFormat = Interface.getString("char_abilities_message_raceadd");
	local sMsg = string.format(sFormat, sRace, DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);

	if sAttributes ~= "" then
		ChatManager.SystemMessage("Attribute Bonuses:");
		ChatManager.SystemMessage(sAttributes);
		sAttributes = sAttributes:gsub(" ", "");

		for attribute in string.gmatch(sAttributes, "([^,]+)") do
			-- strip any spaces from the start/end

			attribute = attribute:match("^%s*(.-)%s*$");

			local attributeName = string.sub(attribute, 1, 3);
			local attributeBonus = string.sub(attribute, 4, 5)
			local attributeValue = 0;
			local attributeBonusSign = string.sub(attributeBonus,1,1);
			local attributeBonusValue = 0;
			local attributeNode = "";
			local statusNode = "";
			local isAttribute = true;

			if attribute:len() == 5 then
				attributeBonusValue = tonumber(string.sub(attributeBonus,2,2));
			end

			if (attributeName == "STR") then
				targetNode = "strength"
			elseif (attributeName == "DEX") then
				targetNode = "dexterity"
			elseif (attributeName == "END") then
				targetNode = "endurance"
			elseif (attributeName == "INT") then
				targetNode = "intelligence"
			elseif (attributeName == "EDU") then
				targetNode = "education"
			elseif (attributeName == "SOC") then
				targetNode = "social"
			else
				isAttribute = false;
			end

			if isAttribute ~= false and attributeBonusValue ~= 0 then

				attributeNode = "attributes." .. targetNode;
				statusNode = "woundtrack." .. string.sub(targetNode,1,3) ;

				attributeValue = DB.getValue(nodeChar, attributeNode, "0");

				if attributeBonusSign == "+" then
					attributeValue = attributeValue + attributeBonusValue
				else
					if attributeBonusValue == 0 then
						attributeValue = 0;
					else
						attributeValue = attributeValue - attributeBonusValue
						if attributeValue < 0 then
							attributeValue = 0;
						end
					end
				end

				DB.setValue(nodeChar, attributeNode, "number", attributeValue);
				DB.setValue(nodeChar, statusNode, "number", attributeValue);

			end
		end
	end

	-- Are there any Racial Traits
	local nodeTraits = DB.getChild(nodeSource, "traits");
	local nodeRacialTraits = DB.getChild(nodeChar, "racialtraitslist");

	-- Remove any existing racial traits
	if DB.getChildCount(nodeRacialTraits) > 0 then
		for _, vTrait in ipairs(DB.getChildList(nodeRacialTraits)) do
			DB.deleteNode(vTrait);
		end
	end

	if nodeTraits and DB.getChildCount(nodeTraits) > 0 then
		ChatManager.SystemMessage("Traits:");

		for _, vTrait in ipairs(DB.getChildList(nodeTraits)) do

			local sTraitName = DB.getValue(vTrait, "name", "");
			local sTraitDescription = DB.getValue(vTrait, "description", "");

			ChatManager.SystemMessage("Adding: " .. sTraitName);

			local newRacialNode = DB.createChild(nodeRacialTraits);

			DB.setValue(newRacialNode, "name", "string", sTraitName);
			DB.setValue(newRacialNode, "details", "string", sTraitDescription);

			specialActionForTrait(nodeChar, sTraitName, sTraitDescription);
		end
	end

	-- Add the name and link to the main character sheet
	DB.setValue(nodeChar, "race", "string", sRace);
	DB.setValue(nodeChar, "racelink", "windowreference", aTable["class"], DB.getPath(nodeSource));
end

-- Do we need to add a special action for a trait, ie a weapon
function specialActionForTrait(nodeChar, sTraitName, sTraitDetails)

	if sTraitName:lower() == "dewclaw" or sTraitName:lower() == "bite" then
		-- Aslan Dewclaw or Vargr Bite

		local sTraitWeaponToFindAdd = sTraitName:lower();
		local sTraitWeaponName = sTraitName;
		local sTraitWeaponDamage;

		if sTraitName:lower() == "dewclaw" then
			sTraitWeaponDamage = "1D6+2"
		elseif sTraitName:lower() == "bite" then
			sTraitWeaponDamage = "1D6+1"
		end

		local nodeWeapons = DB.createChild(nodeChar, "weaponlist");
		if not nodeWeapons then
			return;
		end

		local bTraitWeaponFound = false;
		local nodeTraitWeapon = null;

		for _,v in ipairs(DB.getChildList(nodeChar, "weaponlist")) do
			local sName = DB.getValue(v, "name", "");
			if sName:lower() == sTraitWeaponToFindAdd then
				bTraitWeaponFound = true;
				nodeTraitWeapon = v;
				break;
			end
		end

		if not bTraitWeaponFound then
			nodeTraitWeapon = DB.createChild(nodeWeapons);
		end

		-- Lets get the STR MOD
		local nStr = DB.getValue(nodeChar, "woundtrack.str", 0);
		local nStrMod = GameSystem.calculateCharacteristicDM(nStr);

		DB.setValue(nodeTraitWeapon, "actionMod", "number", 0);
		DB.setValue(nodeTraitWeapon, "ammo", "number", 0);
		DB.setValue(nodeTraitWeapon, "attack", "number", 0);
		DB.setValue(nodeTraitWeapon, "characteristic", "string", "str_mod");
		DB.setValue(nodeTraitWeapon, "characteristicDM", "number", nStrMod);
		DB.setValue(nodeTraitWeapon, "damage", "string", sTraitWeaponDamage);
		DB.setValue(nodeTraitWeapon, "magazine", "number", 0);
		DB.setValue(nodeTraitWeapon, "mass", "number", 0);
		DB.setValue(nodeTraitWeapon, "name", "string", sTraitWeaponName);
		DB.setValue(nodeTraitWeapon, "notes", "string", sTraitDetails);
		DB.setValue(nodeTraitWeapon, "recordtype", "number", 0);
		DB.setValue(nodeTraitWeapon, "skill", "string", "Melee (natural)");
		DB.setValue(nodeTraitWeapon, "tl", "number", 0);
		DB.setValue(nodeTraitWeapon, "locked", "number", 1);
	end
end

function addPsionicRef(nodeChar, nodeSource, sClass, sTalent)
	-- Validate parameters
	if not nodeChar or not nodeSource then
		return;
	end

	local sCHARPSI = OptionsManager.getOption("CHARPSI");
	if sCHARPSI:lower() ~= "yes" then
		return;
	end

	-- Add Psionic Talent entry
	local nodeTalent
	if DB.getName(DB.getParent(nodeSource)) == "psionic" then
		nodeTalent = addPsionicDB(nodeChar, DB.getValue(nodeSource, "talent", ""), DB.getParent(nodeSource));
	else
		nodeTalent = addPsionicDB(nodeChar, DB.getValue(nodeSource, "talent", ""), DB.getChild(nodeSource, "...psionicdata"));
	end

	if nodeTalent then
		DB.setValue(nodeTalent, "text", "formattedtext", DB.getValue(nodeSource, "text", ""));
	end
end

function addPsionicDB(nodeChar, sSkill, nodePsionicData)
	local sSkill = StringManager.capitalize(sSkill);
	local bNewTalent = false;

	-- Get the list we are going to add to
	local nodeList = DB.createChild(nodeChar, "psitalentlist");
	if not nodeList then
		return nil;
	end

	local nodeAbilitiesList = DB.createChild(nodeChar, "psiabilitieslist");
	if not nodeAbilitiesList then
		return nil;
	end

	-- Make sure this item does not already exist
	local nodeTalent = nil;
	for _, vTalent in ipairs(DB.getChildList(nodeList)) do
		if DB.getValue(vTalent, "name", "") == sSkill then
			nodeTalent = vTalent;
			break;
		end
	end

	-- Add the Talent
	if not nodeTalent then
		bNewTalent = true;
		nodeTalent = DB.createChild(nodeList);
		DB.setValue(nodeTalent, "name", "string", sSkill);
		DB.setValue(nodeTalent, "noedit", "number", 1);
		DB.setValue(nodeTalent, "locked", "number", 1);
	end

	-- Add the Abilities
	for _, vAbility in ipairs(DB.getChildList(nodePsionicData)) do
		if DB.getValue(vAbility, "talent", "") == sSkill then
			local sAbilityName = DB.getValue(vAbility, "name", "")
			local sAbilityText = DB.getValue(vAbility, "text", "")
			local sAbilityAttributes = DB.getValue(vAbility, "attributes", "")
			local sPSICost = DB.getValue(vAbility, "psicost", 0)
			local nPSICost = 0
			local nodeAbility = false
			if sPSICost ~= "" and sPSICost ~= nil then
				nPSICost = string.match(sPSICost, "%d+")
			end

			for _, vThisAbility in ipairs(DB.getChildList(nodeAbilitiesList)) do
				if DB.getValue(vThisAbility, "name", "") == sAbilityName then
					nodeAbility = vThisAbility
					break;
				end
			end

			local nodeReference = DB.getPath(vAbility)

			if not nodeAbility then
				nodeAbility = DB.createChild(nodeAbilitiesList);
				DB.copyNode(vAbility, nodeAbility);
				DB.setValue(nodeAbility, "name", "string", sAbilityName);
				DB.setValue(nodeAbility, "noedit", "number", 1);
				DB.setValue(nodeAbility, "locked", "number", 1);
				DB.setValue(nodeAbility, "talent", "string", sSkill);
				DB.setValue(nodeAbility, "text", "formattedtext", sAbilityText);
				DB.setValue(nodeAbility, "ability_cost", "number", nPSICost);

				-- DB.setValue(nodeAbility, "attributes", "formattedText", sAbilityAttributes);
				DB.setValue(nodeAbility, "shortcut", "windowreference", "reference_psionic", nodeReference);
			end
		end
	end

	if not bNewTalent then
		return false;
	else
		-- Announce
		local sFormat = Interface.getString("char_abilities_message_psitalentadd") .. " at Level 0";
		local sMsg = string.format(sFormat, DB.getValue(nodeTalent, "name", ""), DB.getValue(nodeChar, "name", ""));
		ChatManager.SystemMessage(sMsg);

		return nodeTalent;
	end
end

-- This removes the Psionic abilities for a talent from the Actions Tab
function removePsionicActions(node)
	local sTalentName = DB.getValue(node, "name", "string")
	local nodeAbilitiesList = DB.getChild(node, "...psiabilitieslist")

	-- Remove the abilities
	for _, vAbility in ipairs(DB.getChildList(nodeAbilitiesList)) do
		if DB.getValue(vAbility, "talent", "") == sTalentName then
			DB.deleteNode(vAbility);
		end
	end
end

function addSkillRef(nodeChar, nodeSource, sClass)
	-- Validate parameters
	if not nodeChar or not nodeSource then
		return;
	end

	-- Add skill entry
	local nodeSkill, nodeBasicSkill, sBaseSkill = addSkillDB(nodeChar, DB.getValue(nodeSource, "name", ""), DB.getValue(nodeSource, "speciality", "0"));
	if nodeSkill then
		DB.setValue(nodeSkill, "text", "formattedtext", DB.getValue(nodeSource, "text", ""));
	end
	if nodeBasicSkill then
		local nodeBaseSkill = DB.getChild(nodeSource, ".." .. sBaseSkill:lower())

		DB.setValue(nodeBasicSkill, "text", "formattedtext", DB.getValue(nodeBaseSkill, "text", ""));
	end
end

function addSkillDB(nodeChar, sSkill, nSpeciality, bFromHomeworld)

	-- Get the list we are going to add to
	local nodeList = DB.createChild(nodeChar, "skilllist");
	if not nodeList then
		return nil;
	end

	local sSpecialism = sSkill:match("(%b())");
	local nLevel = 0;
	local sBaseSkill = StringManager.trim(sSkill:gsub("(%b())", ""):lower())
	local bBaseSkillExists = false;
	local nodeBaseSkill;

	local sBaseSkill = StringManager.capitalize(sBaseSkill)
	local sOriginalBaseSkill = StringManager.trim(sSkill:gsub("(%b())", ""));

	if sSpecialism ~= nil then
		nLevel = 1;
	end

	-- Make sure this item does not already exist
	local nodeSkill = nil;
	for _, vSkill in ipairs(DB.getChildList(nodeList)) do
		if DB.getValue(vSkill, "name", ""):lower() == sSkill:lower() then
			nodeSkill = vSkill;
			break;
		end
		if DB.getValue(vSkill, "name", ""):lower() == sBaseSkill:lower() then
			bBaseSkillExists = true;
			break;
		end
	end

	-- Add the item
	if not nodeSkill then
		nodeSkill = DB.createChild(nodeList);
		DB.setValue(nodeSkill, "name", "string", sSkill);
		DB.setValue(nodeSkill, "noedit", "number", 1);
		DB.setValue(nodeSkill, "locked", "number", 1);
		DB.setValue(nodeSkill, "speciality", "number", nSpeciality);
		DB.setValue(nodeSkill, "level", "number", nLevel);

		if nLevel == 1 and bBaseSkillExists == false then
			-- Now we see if the base skill exists, if not add it!
			nodeBaseSkill = DB.createChild(nodeList);
			DB.setValue(nodeBaseSkill, "name", "string", sOriginalBaseSkill);
			DB.setValue(nodeBaseSkill, "noedit", "number", 1);
			DB.setValue(nodeBaseSkill, "locked", "number", 1);
			DB.setValue(nodeBaseSkill, "speciality", "number", 0);
			DB.setValue(nodeBaseSkill, "level", "number", 0);

			local sFormat = Interface.getString("char_abilities_message_skilladd") .. " at Level 0";
			local sMsg = string.format(sFormat, DB.getValue(nodeBaseSkill, "name", ""), DB.getValue(nodeChar, "name", ""));
			ChatManager.SystemMessage(sMsg);
		end

	else
		if not bFromHomeworld then
			local nCurrentLevel = DB.getValue(nodeSkill, "level", 0);
			local nNewLevel = nCurrentLevel + 1;

			-- Announce
			local sFormat = Interface.getString("char_abilities_message_skillincrease");
			local sMsg = string.format(sFormat, DB.getValue(nodeSkill, "name", ""), nNewLevel);
			DB.setValue(nodeSkill, "level", "number", nNewLevel);

			ChatManager.SystemMessage(sMsg);

			checkSkillHasMiscActions(nodeChar, sSkill, nNewLevel)

		end
		return false, false, false;
	end

	-- Announce
	local sFormat = Interface.getString("char_abilities_message_skilladd") .. " at Level " .. nLevel;
	local sMsg = string.format(sFormat, DB.getValue(nodeSkill, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);

	checkSkillHasMiscActions(nodeChar, sSkill, 0)

	return nodeSkill, nodeBaseSkill, sBaseSkill;
end

function checkSkillHasMiscActions(nodeChar, sSkill, nSkillLevel)
	if sSkill == "" then
		return
	end

	if sSkill:lower() == "medic" then
		addSkillMiscActions(nodeChar, "First Aid", "heal", "edu", sSkill, nSkillLevel)
		addSkillMiscActions(nodeChar, "Treat Poison or Disease", "skill", "edu", sSkill, nSkillLevel)
		addSkillMiscActions(nodeChar, "Long-term Care", "skill", "edu", sSkill, nSkillLevel)
	end

	if sSkill:lower() == "tactics (military)" or sSkill:lower() == "tactics" then
		addSkillMiscActions(nodeChar, "Tactics (military)", "tactics", "int", sSkill, nSkillLevel)
	end
end

function addSkillMiscActions(nodeChar, sSkill, sAction, sCharacteristic, sParent, nSkillLevel)
	if sSkill == "" then
		return
	end

	-- Get the list we are going to add to
	local nodeList = DB.createChild(nodeChar, "miscactions");
	if not nodeList then
		return nil;
	end

	-- Make sure this item does not already exist
	local nodeSkill = nil;
	for _, vSkill in ipairs(DB.getChildList(nodeList)) do
		if DB.getValue(vSkill, "name", "") == sSkill then
			nodeSkill = vSkill;
			break;
		end
	end

	-- Add the item
	if not nodeSkill then
		nodeSkill = DB.createChild(nodeList);
		DB.setValue(nodeSkill, "name", "string", sSkill);
		DB.setValue(nodeSkill, "noedit", "number", 1);
		DB.setValue(nodeSkill, "locked", "number", 1);
		DB.setValue(nodeSkill, "action", "string", sAction);
		DB.setValue(nodeSkill, "parent", "string", sParent);
		DB.setValue(nodeSkill, "characteristic","string", sCharacteristic .. "_mod");

		nDBtoapply = DB.getValue(nodeChar, "attributes." .. sCharacteristic .."_mod", 0);
		DB.setValue(nodeSkill, "characteristicDM", "number", nDBtoapply);
	else
		if nSkillLevel > 0 then
			DB.setValue(nodeSkill, "skill", "number", nSkillLevel);
		end
		return false;
	end

	-- Announce
	local sFormat = Interface.getString("char_actions_message_actionsadd") .. " added to Misc Actions";
	local sMsg = string.format(sFormat, DB.getValue(nodeSkill, "name", ""), DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);

end

function showEffect(nEffect, nTotal, nTarget, rMessage)
	local sEffectStatus

	rMessage.effectresulttext = "";

	if nEffect >= 0 then
		if nEffect == 0 then
			sEffectStatus = "Marginal";
		elseif (nEffect >= 1) and (nEffect <= 5) then
			sEffectStatus = "Average";
		elseif nEffect >= 6 then
			sEffectStatus = "Exceptional";
		end
		rMessage.effectresulttext = rMessage.effectresulttext .. " [ +" .. nEffect .. " Effect]";
	else
		if nEffect == -1 then
			sEffectStatus = "Marginal";
		elseif nEffect <= -2 and nEffect >= -5 then
			sEffectStatus = "Average";
		elseif nEffect <= -6 then
			sEffectStatus = "Exceptional";
		end

		rMessage.effectresulttext = rMessage.effectresulttext .. " [ " .. nEffect .. " Effect]";
	end

	if nTotal >= nTarget then
		rMessage.effectresulttext = rMessage.effectresulttext .. " [" .. sEffectStatus .. " SUCCESS]";
	else
		rMessage.effectresulttext = rMessage.effectresulttext .. " [" .. sEffectStatus .. " FAILURE]";
	end
end

function addHomeworldDB(nodeChar, nodeSource, sClass)

	local sHomeland = DB.getValue(nodeSource, "name", "");
	local sSkill = DB.getValue(nodeSource, "skill", "");

	-- Announce
	local sFormat = Interface.getString("char_abilities_message_homeworldadd");
	local sMsg = string.format(sFormat, sHomeland, DB.getValue(nodeChar, "name", ""));
	ChatManager.SystemMessage(sMsg);

	-- And the skill
	addSkillDB(nodeChar, sSkill, 0, true);

	DB.setValue(nodeChar, "homeworld", "string", sHomeland);
	DB.setValue(nodeChar, "homeworldlink", "windowreference", sClass, DB.getPath(nodeSource));

	return true;
end

-- Weapons

function removeFromWeaponDB(nodeItem)
	if not ItemManager2.isWeapon("item", nodeItem) then
		return;
	end

	-- Check to see if any of the weapon nodes linked to this item node should be deleted
	local sItemNode = DB.getPath(nodeItem);
	local sItemNode2 = "....inventorylist." .. DB.getName(nodeItem);
	local bFound = false;
	for _,v in ipairs(DB.getChildList(nodeItem, "...weaponlist")) do
		local sClass, sRecord = DB.getValue(v, "shortcut", "", "");
		if sRecord == sItemNode or sRecord == sItemNode2 then
			bFound = true;
			DB.deleteNode(v);
		end
	end

	return bFound;
end


function addToWeaponDB(nodeItem)
	-- Parameter validation
	if not ItemManager2.isWeapon("item", nodeItem) then
		return;
	end

--[[	
	-- Get the weapon list we are going to add to
	local nodeChar = DB.getChild(nodeItem, "...");
	local nodeWeapons = DB.createChild(nodeChar, "weaponlist");
	if not nodeWeapons then
		return;
	end
--]]
	--local nodeWeapon = DB.createChild(nodeWeapons);
	--[[
	-- Determine identification
	local nItemID = 0;
	if ItemManager.getIDState(nodeItem, true) then
		nItemID = 1;
	end

	-- Grab some information from the source node to populate the new weapon entries
	local sName;
	if nItemID == 1 then
		sName = DB.getValue(nodeItem, "name", "");
	else
		sName = DB.getValue(nodeItem, "nonid_name", "");
		sName = "** " .. sName .. " **";
	end

	local nBonus = 0;
	local bMelee = true;
	local bRanged = false;

	-- Parse item fields
	local sDamage = DB.getValue(nodeItem, "damage", "");
	local nTL = DB.getValue(nodeItem, "tl", 0);
	local sRange = DB.getValue(nodeItem, "range", "");
	local fNotes = DB.getValue(nodeItem, "notes", "");
	local sSubtype = DB.getValue(nodeItem, "subtype", "");
	local sType = DB.getValue(nodeItem, "type", "");
	local sCost = DB.getValue(nodeItem, "cost", "");
	local nMass = DB.getValue(nodeItem, "mass", 0);
	local nMagazine = DB.getValue(nodeItem, "magazine", 0);
	local nRecordType = DB.getValue(nodeItem, "recordtype", 0);
	local sAmmoCost = DB.getValue(nodeItem, "ammocost", "");
	local sWeaponSkill = DB.getValue(nodeItem, "skill", "");
	local sTraits = DB.getValue(nodeItem, "traits", "");
	local nCarried = DB.getValue(nodeItem, "carried", 0);
	local sSkillLink = ""

	-- Work out what kind of weapon this is
	if (string.match(sSubtype:lower(), "slug") or string.match(sSubtype:lower(), "energy") or string.match(sSubtype:lower(), "grenades") or string.match(sSubtype:lower(), "heavy weapons")) then
	-- if (sSubtype == "Slug Throwers - Rifles" or sSubtype == "Energy Weapons" or sSubtype == "Greandes" or sSubtype == "Heavy Weapons") then
		bRanged = true;
		bMelee = false;
	end

	local nAttack = 0;

	nAttack, sSkillLink = getWeaponSkill(nodeChar, sWeaponSkill, sName)

	local nodeWeapon = DB.createChild(nodeWeapons);
	if nodeWeapon then
		DB.setValue(nodeWeapon, "isidentified", "number", nItemID);
		DB.setValue(nodeWeapon, "shortcut", "windowreference", "reference_weapons", DB.getPath(nodeItem));
		DB.setValue(nodeWeapon, "attack", "number", nAttack)
		DB.setValue(nodeWeapon, "name", "string", sName);

		DB.setValue(nodeWeapon, "range", "string", sRange);
		DB.setValue(nodeWeapon, "damage", "string", sDamage);
		DB.setValue(nodeWeapon, "tl", "number", nTL);
		DB.setValue(nodeWeapon, "notes", "formattedtext", fNotes);
		DB.setValue(nodeWeapon, "subtype", "string", sSubtype);
		DB.setValue(nodeWeapon, "type", "string", sType);
		DB.setValue(nodeWeapon, "cost", "string", sCost);
		DB.setValue(nodeWeapon, "mass", "number", nMass);
		DB.setValue(nodeWeapon, "skillDM", "number", nAttack);
		DB.setValue(nodeWeapon, "traits", "string", sTraits);
		DB.setValue(nodeWeapon, "carried", "number", nCarried);

		if bMelee then
			DB.setValue(nodeWeapon, "ranged", "number", 0);
		else
			-- This IS a ranged weapon
			DB.setValue(nodeWeapon, "ranged", "number", 1);
			DB.setValue(nodeWeapon, "magazine", "number", nMagazine);
			DB.setValue(nodeWeapon, "maxammo", "number", nMagazine);
			DB.setValue(nodeWeapon, "ammo", "number", nMagazine);
			DB.setValue(nodeWeapon, "ammocost", "string", sAmmoCost);
		end
		-- Do this before the skilllink so it update onCharItemAdd with the MaxAmmo/Magazine
		DB.setValue(nodeWeapon, "recordtype", "number", nRecordType);
		-- Do this last so it only does the skill number update onCharItemAdd
		DB.setValue(nodeWeapon, "skill", "string", sWeaponSkill);
		DB.setValue(nodeWeapon, "skilllink", "string", sSkillLink)
	end
--]]
end

function getWeaponSkill(nodeChar, sSkillToFind, sName)
	local sSkillLink = ""
	local sSkillExpertise = sSkillToFind:match("(%b())")
	local bJoaT = false;

	if sSkillToFind == "" then
		-- Display in chat window that Item is missing the skill
		--ChatManager.SystemMessage("The weapon (".. sName .. ") is missing the associated skill");
		return 0, "", bJoaT
	end

	sBasicSkill, sSkillExpertise = sSkillToFind:match("(.-)%((%a+)%)");

	if sBasicSkill == nil then
		sBasicSkill = StringManager.trim(sSkillToFind:gsub("(%b())", ""):lower())
		sSkillExpertise = "";
	else
		sBasicSkill = StringManager.trim(sBasicSkill):lower();
		sSkillExpertise = StringManager.trim(sSkillExpertise):lower();
	end

	local sSkillExpertise2 = sBasicSkill .. "(" .. sSkillExpertise .. "s)"
	sSkillExpertise = sSkillToFind:lower()

	local nCurrentLevel = -3;
	local sEachSkill = "";
	local nBaseSkill = -3;
	local nSpecialisedSkill = -3;

	-- Get the list we are going to add to
	local nodeList = DB.getChild(nodeChar, "skilllist");
	if not nodeList then
		return nil;
	end

	-- Let's look for the skill we require
	local nodeSkill = nil;
	for _, vSkill in ipairs(DB.getChildList(nodeList)) do
		sEachSkill = DB.getValue(vSkill, "name", ""):lower()
		if (sEachSkill == sSkillExpertise or sEachSkill == sSkillExpertise2) then
			nSpecialisedSkill = DB.getValue(vSkill, "total", -3);
			sSkillLink = DB.getPath(vSkill);
			break;
		end
	end

	if nSpecialisedSkill == -3 then
		for _, vSkill in ipairs(DB.getChildList(nodeList)) do
			sEachSkill = DB.getValue(vSkill, "name", ""):lower()
			if (sEachSkill == sBasicSkill) then
				nBaseSkill = DB.getValue(vSkill, "total", -3);
				sSkillLink = DB.getPath(vSkill);
				break;
			end
		end
	end

	-- If still at -3, check for Jack of all trades
	if nSpecialisedSkill == -3 and nBaseSkill == -3 then
		nBaseSkill = nil;
		for _, vSkill in ipairs(DB.getChildList(nodeList)) do
			if DB.getValue(vSkill, "name", ""):lower() == "jack of all trades" then
				bJoaT = true;
				nBaseSkill = DB.getValue(vSkill, "total", -3);
				sSkillLink = DB.getPath(vSkill);
				break;
			end
		end

		if nBaseSkill then
			-- Take 3 of this level as JoAT reduces the negative modifier
			nCurrentLevel = nBaseSkill -3;
		end
	else
		nCurrentLevel = nBaseSkill;
		if (nSpecialisedSkill > nCurrentLevel) then
			nCurrentLevel = nSpecialisedSkill;
		end
	end

	return nCurrentLevel, sSkillLink, bJoaT;
end

function DEC_HEX(IN)
	if IN == null or IN == "" then
		IN = "0";
	end

	if StringManager.isNumberString(IN) then
		IN = tonumber(IN);
		local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
		while IN>0 do
			I=I+1
			IN,D=math.floor(IN/B),math.mod(IN,B)+1
			OUT=string.sub(K,D,D)..OUT
		end
		-- if the value is empty, set it "0"
		if OUT == "" then
			OUT = "0";
		end
		return OUT
	else
		return IN
	end
end

function checkHasSkill(nodeChar, sRequiredSkill)
	local nSkillLevel = -3;

	-- Get the list we are going to check
	local nodeList = DB.getChild(nodeChar, "skilllist");
	if not nodeList then
		return nil;
	end

	-- Let's look for the skill we require
	local nodeSkill = nil;
	for _, vSkill in ipairs(DB.getChildList(nodeList)) do
		sEachSkill = DB.getValue(vSkill, "name", ""):lower()
		if (sEachSkill == sRequiredSkill) then
			nSkillLevel = DB.getValue(vSkill, "level", -3);
			break;
		end
	end

	return nSkillLevel;
end

function getJackOfAllTradesSkillLevel(nodeChar)

	local nodeList = DB.getChild(nodeChar, "skilllist");
	if not nodeList then
		return nil;
	end

	nJoaTSkill = nil;
	for _, vSkill in ipairs(DB.getChildList(nodeList)) do
		if DB.getValue(vSkill, "name", ""):lower() == "jack of all trades" then
			nJoaTSkill = DB.getValue(vSkill, "level", -3);
			break;
		end
	end

	if nJoaTSkill then
		return nJoaTSkill;
	else
		return 0;
	end
end

function getArmourWornModifier(sSourceNode)
	local nSkillDifferenceDM = 0;

	-- Check armour worn and check skill required
	for _,vItem in ipairs(DB.getChildList(DB.findNode(sSourceNode), "inventorylist")) do

		local sItemType = DB.getValue(vItem, "type", ""):lower();

		if sItemType == "armour" then
			local nCarried = DB.getValue(vItem, "carried", 0);
			if nCarried == 2 then
				sArmourSkill = DB.getValue(vItem, "skill", "");
				nDifferenceDM = 0;
				if sArmourSkill:lower() ~= "none" and sArmourSkill ~= "" then
					sBaseSkill, sRequiredSkillLevel = string.match(sArmourSkill, "([%a%s]*[%a]+)%s*(%d+)");
					nRequiredSkillLevel = tonumber(sRequiredSkillLevel);

					local nCharSkillLevel = checkHasSkill(DB.findNode(sSourceNode), sBaseSkill:lower());

					if nCharSkillLevel == -3 then
						-- check for JoaT
						nDifferenceDM = -3

						local nJoaT = getJackOfAllTradesSkillLevel(DB.findNode(sSourceNode));

						if nJoaT ~= nil and nJoaT > 0 then
							nDifferenceDM = nDifferenceDM + nJoaT;
						end
					else
						if nCharSkillLevel < nRequiredSkillLevel then
							nDifferenceDM = nRequiredSkillLevel - nCharSkillLevel;
						end
					end

					nSkillDifferenceDM = math.min(nSkillDifferenceDM, nDifferenceDM)
				end
			end
		end
	end

	return nSkillDifferenceDM;
end

function checkTraits(sNode, rRoll)
	local sSkill = rRoll.sDesc:match("%s(%a+)"):lower();

	local nodeRacialTraits = DB.getChild(sNode, "racialtraitslist");
	local sRace = DB.getValue(DB.findNode(sNode), "race", ""):lower();

	-- Remove any existing racial traits
	if nodeRacialTraits and DB.getChildCount(nodeRacialTraits) > 0 then
		for _, vTrait in ipairs(DB.getChildList(nodeRacialTraits)) do
			local sTrait = DB.getValue(vTrait, "name", ""):lower();

			if sTrait == "heightened senses" and (sSkill == "survival" or sSkill == "recon") then
				if sRace == "aslan" then
					rRoll.sDesc = rRoll.sDesc .. "[Aslan: Heightened Senses +1 DM]"
					rRoll.nMod = rRoll.nMod + 1;
				elseif sRace == "vargr" then
					-- Doesn't apply at night - be cool if we could check that
					rRoll.sDesc = rRoll.sDesc .. "[Vargr: Heightened Senses +1 DM]"
					rRoll.nMod = rRoll.nMod + 1;
				end
			end
		end
	end
end

function calculateArmourRating(nodeChar)
	local tArmourList = {};
	local nArmourProtection = 0;
	for _,vItem in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		local sType = DB.getValue(vItem, "type", ""):lower();

		if sType == "armour" then
			local nCarried = DB.getValue(vItem, "carried", 0);
			if nCarried == 2 then
				table.insert(tArmourList, DB.getValue(vItem, "name", ""));

				local nProtection = tonumber(DB.getValue(vItem, "resistances", ""):match("%d+")) or 0;
				nArmourProtection = nArmourProtection + nProtection;
			end
		elseif (sType == "augments" or sType == "personal augmentation") then
			local sItem = DB.getValue(vItem, "name", "");
			if sItem:match("Subdermal") then
				table.insert(tArmourList, sItem);

				local nProtection = tonumber(DB.getValue(vItem, "description", ""):match("%d+")) or 0;
				DB.setValue(vItem, "protection", "number", nProtection);
				DB.setValue(vItem, "resistances", "string", nProtection);
				nArmourProtection = nArmourProtection + nProtection;
			end
		end
	end

	DB.setValue(nodeChar, "armour_rating", "number", nArmourProtection);
	DB.setValue(nodeChar, "armour_protection", "string", nArmourProtection);
	if #tArmourList > 1 then
		DB.setValue(nodeChar, "armour", "string", "Stacked: " .. table.concat(tArmourList, ", "));
	else
		DB.setValue(nodeChar, "armour", "string", table.concat(tArmourList, ", "));
	end
end

function getWeaponListNode(nodeChar, sWeapon)
	local sWeaponLower = sWeapon:lower()
	for _,v in ipairs(DB.getChildList(nodeChar, "weaponlist")) do
		if DB.getValue(v, "name", ""):lower() == sWeaponLower then
			return v;
		end
	end
	return nil;
end

function isFullyHealthy(nodeChar)
	local bIsFullyHealthy = false;

	-- Get the latest values for the 3 attributes via the wound track
	local nTotalEnd = DB.getValue(nodeChar, "woundtrack.end", 0);
	local nTotalDex = DB.getValue(nodeChar, "woundtrack.dex", 0);
	local nTotalStr = DB.getValue(nodeChar, "woundtrack.str", 0);

	-- Now get the latest values for the 3 attributes
	local nOriginalEnd = DB.getValue(nodeChar, "attributes.endurance", 0) + DB.getValue(nodeChar, "attributes.end_mod2", 0) + DB.getValue(nodeChar, "attributes.end_equipment", 0);
	local nOriginalDex = DB.getValue(nodeChar, "attributes.dexterity", 0) + DB.getValue(nodeChar, "attributes.dex_mod2", 0) + DB.getValue(nodeChar, "attributes.dex_equipment", 0);
	local nOriginalStr = DB.getValue(nodeChar, "attributes.strength", 0) + DB.getValue(nodeChar, "attributes.str_mod2", 0) + DB.getValue(nodeChar, "attributes.str_equipment", 0);

	if nOriginalEnd + nOriginalDex + nOriginalStr == nTotalEnd + nTotalDex + nTotalStr then
		bIsFullyHealthy = true;
	end

	return bIsFullyHealthy;
end
