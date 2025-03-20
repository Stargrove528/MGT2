--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Character Characteristics

function onInit()
	OptionsManager.registerCallback("CHARPSI", update);
	update();
end
function onClose()
	OptionsManager.unregisterCallback("CHARPSI", onUpdate);
end

function onDrop(x, y, draginfo)
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	if bReadOnly then
		return;
	end

	local nodeNPC = getDatabaseNode();
	local sTypeLower = DB.getValue(nodeNPC, "type", ""):lower();
	local bAnimal = sTypeLower == "animal";
	local bRobot = sTypeLower == "robot";
	if draginfo.isType("shortcut") then
		local sClass,sRecord = draginfo.getShortcutData();
		if RecordDataManager.isRecordTypeDisplayClass("item", sClass) and not bAnimal and 
			not bRobot then

			self.handleDropItem(nodeNPC, sClass, sRecord);
		elseif sClass == "reference_skill" then
			self.handleDropSkill(sClass, sRecord);
		elseif sClass == "reference_psionic" then
			self.handleDropPSISkill(nodeNPC, sClass, sRecord);
		end
	end

	return false;
end
function handleDropItem(nodeNPC, sClass, sRecord)
	local nodeItem = DB.findNode(sRecord);
	local sType = DB.getValue(nodeItem, "type"):lower();
	if (sClass == "reference_weapons" or sType == "weapons" or sType == "heavy weaponry") then
		nodeTarget = DB.createChild(DB.getChild(nodeNPC, "actions"))
		DB.setValue(nodeTarget, "name", "string", DB.getValue(nodeItem, "name"));
		DB.setValue(nodeTarget, "attack", "string", "0");
		DB.setValue(nodeTarget, "damage", "string", DB.getValue(nodeItem, "damage", ""));
		DB.setValue(nodeTarget, "range", "string", DB.getValue(nodeItem, "range", ""));
		DB.setValue(nodeTarget, "traits", "string", DB.getValue(nodeItem, "traits", ""));
		return true;
	end
	if (sClass == "reference_armor" or sType == "armour") then
		DB.setValue(nodeNPC, "armour", "string", DB.getValue(nodeItem, "name"));
		DB.setValue(nodeNPC, "armour_protection", "string", DB.getValue(nodeItem, "resistances", ""));
		return true;
	end
	if sClass == "reference_equipment" then
		local tItems = {};
		local sCurItems = DB.getValue(nodeNPC, "items");
		if (sCurItems or "") ~= "" then
			table.insert(tItems, sCurItems);
		end

		local sItem = DB.getValue(nodeItem, "name");
		if (sItem or "") ~= "" then
			table.insert(tItems, sItem);
		end

		DB.setValue(nodeNPC, "items", "string", table.concat(tItems, ", "));
		return true;
	end
end
function handleDropSkill(sClass, sRecord)
	local nodeSkill = DB.findNode(sRecord);
	local sSkillsCurrently = StringManager.trim(skills.getValue());
	local sNewSkill = DB.getValue(nodeSkill, "name", "");
	local nSpecialitySkill = DB.getValue(nodeSkill, "speciality");
	local nSkillLevel = 0;
	local bSkillBaseSkillFound = false;
	local bSkillSpecialismFound = false;

	local sBaseSkill, sSkillSpecialism = string.match(sNewSkill, "(%w+) %((.-)%)");
	if sSkillSpecialism == nil then
		sBaseSkill = sNewSkill;
		if sSkillsCurrently:find("(" .. sBaseSkill ..") (%d*)") then
			bSkillBaseSkillFound = true;
			_,nSkillLevel = string.match(sSkillsCurrently, "(" .. sBaseSkill .. ") (%d*)");
		end
	else
		-- we need to look for the specialism
		if sSkillsCurrently:find("(" .. sBaseSkill .. ") %((" .. sSkillSpecialism .. ")%) (%d*)") then
			bSkillSpecialismFound = true;
			_,_,nSkillLevel = string.match(sSkillsCurrently, "(" .. sBaseSkill .. ") %((" .. sSkillSpecialism .. ")%) (%d*)");
		end
		-- we need to look for the base skill
		if sSkillsCurrently:find("(" .. sBaseSkill .. " 0)") then
			bSkillBaseSkillFound = true;
		end
	end

	if skills.getValue() ~= nil and skills.getValue() ~= "" then
		sSkillsCurrently = skills.getValue() .. ", ";
	end

	if bSkillBaseSkillFound == false then
		if skills.getValue() ~= "" then
			skills.setValue(StringManager.trim(skills.getValue()) .. ', ' .. sBaseSkill .. ' 0');
		else
			skills.setValue(StringManager.trim(sBaseSkill .. ' 0'));
		end
	end

	if sSkillSpecialism == nil or sSkillSpecialism == false then
		if bSkillBaseSkillFound  then
			-- increase the skill level IF it's not a specialist skill
			if nSpecialitySkill == 0 then
				-- not a skill with specialisms we can increase this
				local nNewSkillLevel = nSkillLevel + 1;

				local sCurrentSkills = StringManager.trim(skills.getValue());

				local sOldSkillLevel = sBaseSkill .. " " .. nSkillLevel;
				local sNewSkillLevel = sBaseSkill .. " " .. nNewSkillLevel;

				skills.setValue(sCurrentSkills:gsub(sOldSkillLevel, sNewSkillLevel));

			end
		end
	else
		if bSkillSpecialismFound then

			local sCurrentSkills = StringManager.trim(skills.getValue());

			local nNewSkillLevel = nSkillLevel + 1;

			local sOldSkillLevel = sBaseSkill .. " %(" .. sSkillSpecialism .. "%) " .. nSkillLevel;
			local sNewSkillLevel = sBaseSkill .. " (" .. sSkillSpecialism ..") " .. nNewSkillLevel;

			skills.setValue(sCurrentSkills:gsub(sOldSkillLevel, sNewSkillLevel));
		else
			-- We need to add it
			if skills.getValue() ~= "" then
				skills.setValue(StringManager.trim(skills.getValue()) .. ', ' .. sBaseSkill .. ' (' .. sSkillSpecialism .. ') 1');
			else
				skills.setValue(StringManager.trim(sBaseSkill .. '(' .. sSkillSpecialism .. ') 1'));
			end
		end
	end
	-- Now make sure the drag and drop highlight correctly
	skills.onChar(32);
	return true;
end
function handleDropPSISkill(nodeChar, sClass, sRecord)
	local sCHARPSI = OptionsManager.getOption("CHARPSI");
	local bVisible = (sCHARPSI:lower() == "yes");
	if not bVisible then
		return;
	end
	local nodeChild = DB.createChild(DB.getPath(nodeChar, "psiabilitieslist"));
	if not nodeChild then
		return;
	end
	local nodePSI = DB.findNode(sRecord);
	if not nodePSI then
		return;
	end
	local sCost = DB.getValue(nodePSI, "psicost", "");
	local nCost = tonumber(StringManager.trim(sCost:gsub("%W+", ""):gsub("%a+", "")));
	DB.setValue(nodeChild, "ability_cost", "number", (nCost or 0));
	DB.setValue(nodeChild, "name", "string", DB.getValue(nodePSI, "name", ""));

	--set the PSI strength (add enough points to use it once)
	DB.setValue(nodeChar, "woundtrack.psi", "number", DB.getValue(nodeChar, "woundtrack.psi", 0) + (nCost or 0));
	return true;
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("npc", nodeRecord);
	local sTypeLower = type.getValue():lower();
	local bAnimal = (sTypeLower == "animal");
	local bRobot = (sTypeLower == "robot");

	WindowManager.setControlVisibleWithLabel(self, "space", not bReadOnly);
	WindowManager.setControlVisibleWithLabel(self, "reach", not bReadOnly);
	WindowManager.setControlVisibleWithLabel(self, "senses", not bReadOnly);
	divider2.setVisible(not bReadOnly);

	type.setComboBoxReadOnly(bReadOnly);

	if bAnimal then
		sub_details.setValue("npc_main_animal", nodeRecord);
	elseif bRobot then
		sub_details.setValue("npc_main_robot", nodeRecord);
	else
		sub_details.setValue("npc_main_humanoid", nodeRecord);
	end
	sub_details.update(bReadOnly);

	WindowManager.callSafeControlUpdate(self, "skills", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "traits", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "armour", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "armour_protection", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "actions", bReadOnly);

	range_label.setVisible(actions.isVisible());
	damage_label.setVisible(actions.isVisible());
	attack_label.setVisible(actions.isVisible());
	weapon_label.setVisible(actions.isVisible());

	local sCHARPSI = OptionsManager.getOption("CHARPSI");
	local bVisible = (sCHARPSI:lower() == "yes");
	if not bVisible then
		return;
	end
	if psionic_abilities then
		psionic_abilities.setVisible(bVisible);
	end
	WindowManager.callSafeControlUpdate(self, "psionic_abilities", bReadOnly);
end