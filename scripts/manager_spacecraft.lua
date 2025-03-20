--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function dragSpaceShip(draginfo, nodeTarget)
    local sClass, sRecord = draginfo.getShortcutData();

	if sClass == "spacecraft" then
		local nodeSource = DB.findNode(sRecord);
		if not nodeSource then
			ChatManager.SystemMessage(Interface.getString("char_error_missingrecord"));
			return;
		end

		-- Let's keep certain things
		local sOriginalName = DB.getValue(nodeTarget, "name", "")

		DB.copyNode(nodeSource, nodeTarget);
		DB.setValue(nodeTarget, 'name', 'string', sOriginalName);
		DB.setValue(nodeTarget, 'crew_requirements', 'string', DB.getValue(nodeSource, 'crew', ''));
	end
end

--
-- Helper Functions
--
function getDetail(sDetailToFind, nodeCraft)
	local sResult = nil;

	for _,v in ipairs(DB.getChildList(nodeCraft, "details")) do
		sDetail = DB.getValue(v, "detail", "");
		if sDetail:lower():find(sDetailToFind:lower()) then
			sResult = sDetail;
		end
	end

	return sResult;
end

function getDetailSection(sDetailToFind, nodeCraft)

	local aResult = {};
	local bSectionFound = false;

	for _,v in ipairs(DB.getChildList(nodeCraft, "details")) do
		sSection = DB.getValue(v, "name", "");
		if sSection:lower():find(sDetailToFind:lower()) or (sSection == "" and bSectionFound)  then
			sDetail = DB.getValue(v, "detail", "");
			table.insert(aResult,sDetail);
			bSectionFound = true;
		else
			if sSection == "" and bSectionFound then
				sDetail = DB.getValue(v, "detail", "");
				table.insert(aResult,sDetail);
			else
				bSectionFound = false;
			end
		end
	end

	return aResult;
end

function getArmour(nodeCraft)

	local sArmourDetail;

	sArmourDetail = getDetail('%(armour', nodeCraft);

	if sArmourDetail == nil or sArmourDetail == "" then
		sArmourDetail = getDetail('armour:', nodeCraft);
	else
		return sArmourDetail;
	end
	if sArmourDetail == nil or sArmourDetail == "" then
		sArmourDetail = getDetail('%(armor', nodeCraft);
	else
		return sArmourDetail;
	end
	if sArmourDetail == nil or sArmourDetail == "" then
		sArmourDetail = getDetail('armor:', nodeCraft);
	else
		return sArmourDetail;
	end
	return sArmourDetail;
end


function onWeaponDrop(draginfo, nodeCraft)
	if draginfo.isType("shortcut") then
		local sClass,sRecord = draginfo.getShortcutData();
		local nodeRecord = DB.findNode(sRecord);
		local sTypeLower = DB.getValue(nodeRecord, "type", ""):lower();
		local bSpacecraftWeapon = sTypeLower == "spacecraft scale weapons";

		if bSpacecraftWeapon then
			local actionsNode = DB.createChild(nodeCraft, 'actions');
			local actionsWeaponsNode = DB.createChild(actionsNode);
			local weaponNode = DB.findNode(sRecord);

			DB.copyNode(weaponNode, actionsWeaponsNode);

			DB.setValue(actionsWeaponsNode, "link", "windowreference", "item");
			DB.setValue(actionsWeaponsNode, "isidentified", "number", 1);
			DB.setValue(actionsWeaponsNode, "locked", "number", 1);

			-- Next we set the attack
			local sFireControl = getDetail('fire control', nodeCraft);
			local nAutoAttackLevel = -3;

			if sFireControl then
				nAutoAttackLevel = string.match(sFireControl,"%d+");
			end

			DB.setValue(actionsWeaponsNode, "attack", "string", nAutoAttackLevel);
		end

	end

end

function addLinkToBattle(nodeBattle, sLinkClass, sLinkRecord, nCount)
	local sTargetSpacecraftList = LibraryData.getCustomData("battle", "spacecraftlist") or "spacecraftlist";

	if sLinkClass == "battle" then
		local nodeTargetSpacecraftList = DB.createChild(nodeBattle, sTargetSpacecraftList);
		for _,nodeSrcSpacecraft in ipairs(DB.getChildList(DB.getPath(sLinkRecord, sTargetSpacecraftList))) do
			local nodeTargetSpacecraft = DB.createChild(nodeTargetSpacecraftList);
			DB.copyNode(nodeSrcSpacecraft, nodeTargetSpacecraft);
			if nCount then
				DB.setValue(nodeTargetSpacecraft, "count", "number", DB.getValue(nodeTargetSpacecraft, "count", 1) * nCount);
			end
		end
	else
		local bHandle = false;
		local sLinkSourceType = getSpacecraftSourceType(sLinkRecord);
		if sLinkSourceType == "spacecraft" then
			bHandle = true;
		else
			local aCombatClasses = LibraryData.getCustomData("battle", "acceptdrop") or { "spacecraft" };
			if StringManager.contains(aCombatClasses, sLinkSourceType) then
				bHandle = true;
			elseif StringManager.contains(aCombatClasses, sLinkClass) then
				ChatManager.SystemMessage(Interface.getString("battle_message_wrong_source"));
				return false;
			end
		end

		if bHandle then
			local sName = DB.getValue(DB.getPath(sLinkRecord, "name"), "");
			local nodeTargetSpacecraftList = DB.createChild(nodeBattle, sTargetSpacecraftList);
			local nodeTargetSpacecraft = DB.createChild(nodeTargetSpacecraftList);
			DB.setValue(nodeTargetSpacecraft, "count", "number", nCount or 1);
			DB.setValue(nodeTargetSpacecraft, "name", "string", sName);
			DB.setValue(nodeTargetSpacecraft, "link", "windowreference", sLinkClass, sLinkRecord);

			local nodeID = DB.getChild(sLinkRecord, "isidentified");
			if nodeID then
				DB.setValue(nodeTargetSpacecraft, "isidentified", "number", DB.getValue(nodeID));
			end

			local sToken = DB.getValue(DB.getPath(sLinkRecord, "token"), "");
			sToken = UtilityManager.resolveDisplayToken(sToken, sName);
			DB.setValue(nodeTargetSpacecraft, "token", "token", sToken);
		else
			return false;
		end
	end

	return true;
end

function getSpacecraftSourceType(vNode)
	local sNodePath = nil;
	if type(vNode) == "databasenode" then
		sNodePath = DB.getPath(vNode);
	elseif type(vNode) == "string" then
		sNodePath = vNode;
	end
	if not sNodePath then
		return "";
	end

	for _,vMapping in ipairs(LibraryData.getMappings("spacecraft")) do
		if StringManager.startsWith(sNodePath, vMapping) then
			return "spacecraft";
		end
	end

	return "";
end

-- This function takes a string of crew required, and returns it as a table
function getRequiredCrewList(sRequiredCrew)
	local aCrewRequired = {}
	for match in string.gmatch(sRequiredCrew:lower(), "[^,]+") do
		sRole = match:gsub(" x ","");
		sRole = sRole:gsub('%d+',"");

		if string.sub(sRole, -1) == 's' then
			sRole = sRole:sub(1, #sRole - 1);
		end

		local sShipRole = StringManager.capitalize(StringManager.trim(sRole));

		table.insert(aCrewRequired, sShipRole);
	end

	return aCrewRequired;
end

function getSpacecraftDamageType(sTraits)
	local sTraitsLower = sTraits:lower();
	
	local sDamageType = 'Laser' -- this is default only
	if sTraitsLower:match('missile') then
		sDamageType = 'Missile';
	end
	if sTraitsLower:match('radiation') then
		sDamageType = 'Radiation';
	end

	return sDamageType;

end

function getPowerTotalFromSystem(nodeShip)
	local nTotalPower = DB.getValue(nodeShip,'power.total', -1);
	local bGetPower = false;
	local nPowerTotal = 0;
	local sName = '';
	local sDetail = '';

	if not nTotalPower or nTotalPower == -1 or nTotalPower == 0 then
		bGetPower = true;
	else
		return nPowerTotal;
	end

	if bGetPower then
		for _,vSystem in ipairs(DB.getChildList(nodeShip, "details")) do

			sName = DB.getValue(vSystem, "name", ""):lower();
			sDetail = DB.getValue(vSystem, "detail", ""):lower();

			if sName and sName:match('power%splant') then
				nPowerTotal = sDetail:match('%s(%d+)');

				if nPowerTotal then
					nPowerTotal = tonumber(nPowerTotal);
				end
			end
		end
	end

	return nPowerTotal

end

function updateCargoTotals(nodeShip, bRecalc)
	local nCargoTotal = 0;
    local nTons;

    for _, vNode in ipairs(DB.getChildList(nodeShip, "cargolist")) do
        nTons = DB.getValue(vNode, "tons", 0);
        nCargoTotal = nCargoTotal + nTons;
    end

    DB.setValue(nodeShip, "cargo.total", "number", nCargoTotal);

	local nCargoSpace = DB.getValue(nodeShip, "cargo.space", -1);
	if nCargoSpace == -1 or nCargoSpace == 0 or bRecalc then
		-- Need to get the Cargo Space available
		nCargoSpace = 0;
		for _,vItem in ipairs(DB.getChildList(nodeShip, "details")) do
			local sDetail = DB.getValue(vItem, "name", ""):lower();

			if sDetail == "cargo" then
				nCargoSpace = nCargoSpace + DB.getValue(vItem, "tons", "");

				DB.setValue(nodeShip, "cargo.space", "number", nCargoSpace);
			end
		end
	end
end

function updatePSCargoTotals(nodePSShip, nodeShip)
	local nCargoTotal = 0;
    local nTons;

    for _, vNode in ipairs(DB.getChildList(nodeShip, "cargolist")) do
        nTons = DB.getValue(vNode, "tons", 0);
        nCargoTotal = nCargoTotal + nTons;
    end

    DB.setValue(nodeShip, "cargo.total", "number", nCargoTotal);
	DB.setValue(nodePSShip, "cargo.total", "number", nCargoTotal);

end