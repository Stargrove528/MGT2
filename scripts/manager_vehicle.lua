--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

PARTY_VEHICLE_LIST = "partysheet.shipinformation";
OOB_MSGTYPE_APPLYROLECHANGE = "applyrolechange";

local aEntryMap = {};
local aFieldMap = {};

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYROLECHANGE, handleRoleChange);

	if Session.IsHost then
		for _,v in ipairs(DB.getChildList(PARTY_VEHICLE_LIST)) do
			linkVehicleFields(v);

			local _,sShipRecord = DB.getValue(v, "link", "");
			local nodeShip = DB.findNode(sShipRecord);
			DB.setPublic(nodeShip, true);
		end

		DB.addHandler("partysheet.shipinformation.*.name", "onUpdate", updateName);
		DB.addHandler("charspacecraftsheet.*", "onUpdate", addCrew);
		DB.addHandler("charspacecraftsheet.*", "onDelete", onVehicleDelete);
		DB.addHandler("charsheet.*", "onDelete", onCharDelete);
	end
end

function handleRoleChange(msgOOB)
	local nodeCrew = DB.findNode(msgOOB.sSourceNode);
	if not nodeCrew then
		return;
	end

	DB.setValue(nodeCrew, "role", "string", msgOOB.sRole);

	local sName = DB.getValue(nodeCrew, "name", "");
	local _,vShipRecord = DB.getValue(DB.getChild(nodeCrew, "..."), "link", "");
	local nodeShip = DB.findNode(vShipRecord);
	local sMsg = string.format(Interface.getString("charspacecraft_label_change_role"), sName, msgOOB.sRole, DB.getValue(nodeShip, 'name', ''));
	ChatManager.SystemMessage(sMsg);
end

function notifyRoleChange(nodeCrew, sRole)
	if not nodeCrew then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYROLECHANGE;

	msgOOB.sRole = sRole;
  	msgOOB.sSourceNode = DB.getPath(nodeCrew);

	Comm.deliverOOBMessage(msgOOB, "");
end

function onCharDelete(nodeChar)
	local sCharPath = DB.getPath(nodeChar);
	for _,vShip in ipairs(DB.getChildList(PARTY_VEHICLE_LIST)) do
		for _,vCrew in ipairs(DB.getChildList(vShip, "crew")) do
			local _,sLink = DB.getValue(vCrew, "link", "", "")
			if sCharPath == sLink then
				DB.deleteNode(vCrew);
				break
			end
		end
	end
end

function getVehicleCount()
	return DB.getChildCount(PARTY_VEHICLE_LIST);
end

function mapVehicletoPS(nodeVehicle)
	if not nodeVehicle then return nil; end

	local sVehicle = DB.getPath(nodeVehicle);
	for _,v in ipairs(DB.getChildList(PARTY_VEHICLE_LIST)) do
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sVehicle then
			return v;
		end
	end
	return nil;
end

function mapPStoVehicle(nodePS)
	if not nodePS then return nil; end

	local sClass, sRecord = DB.getValue(nodePS, "link", "", "");
	if sRecord == "" then return nil; end
	return DB.findNode(sRecord);
end

function onVehicleDelete(nodeVehicle)
	local nodePS = mapVehicletoPS(nodeVehicle);
	if nodePS then
		DB.deleteNode(nodePS);
	end
end

function onLinkUpdated(nodeField)
	DB.setValue(aFieldMap[DB.getPath(nodeField)], DB.getType(nodeField), DB.getValue(nodeField));
end

function onLinkDeleted(nodeField)
	local sFieldName = DB.getPath(nodeField);
	aFieldMap[sFieldName] = nil;
	DB.removeHandler(sFieldName, 'onUpdate', onLinkUpdated);
	DB.removeHandler(sFieldName, 'onDelete', onLinkDeleted);
end

function onEntryDeleted(nodePS)
	local sRecordName = DB.getPath(nodePS);
	if aEntryMap[sRecordName] then
		DB.removeHandler(sRecordName, "onDelete", onEntryDeleted);
		aEntryMap[sRecordName] = nil;

		for k,v in pairs(aFieldMap) do
			if string.sub(v, 1, sRecordName:len()) == sRecordName then
				aFieldMap[k] = nil;
				DB.removeHandler(k, 'onUpdate', onLinkUpdated);
				DB.removeHandler(k, 'onDelete', onLinkDeleted);
			end
		end
	end
end

function linkRecordField(nodeRecord, nodePS, sField, sType, sPSField)
	if not nodeRecord then return; end

	if not sPSField then
		sPSField = sField;
	end

	local sPath = DB.getPath(nodePS);
	if not aEntryMap[sPath] then
		DB.addHandler(sPath, "onDelete", onEntryDeleted);
		aEntryMap[sPath] = true;
	end

	local nodeField = DB.createChild(nodeRecord, sField, sType);
	DB.addHandler(nodeField, 'onUpdate', onLinkUpdated);
	DB.addHandler(nodeField, 'onDelete', onLinkDeleted);

	aFieldMap[DB.getPath(nodeField)] = DB.getPath(nodePS, sPSField);
	onLinkUpdated(nodeField);
end

function linkVehicleFields(nodePS)
	if VehicleManager2 and VehicleManager2.linkVehicleFields then
		VehicleManager2.linkVehicleFields(nodePS);
		return;
	end

	local nodeVehicle = mapPStoVehicle(nodePS);
	linkRecordField(nodeVehicle, nodePS, "name", "string");
	linkRecordField(nodeVehicle, nodePS, "token", "token");
	linkRecordField(nodeVehicle, nodePS, "tl", "number");
	linkRecordField(nodeVehicle, nodePS, "crew_requirements", "string");
	linkRecordField(nodeVehicle, nodePS, "tons", "number");
	linkRecordField(nodeVehicle, nodePS, "hull_points", "number");
	linkRecordField(nodeVehicle, nodePS, "hull_damage", "number");
	linkRecordField(nodeVehicle, nodePS, "armour", "string");
	linkRecordField(nodeVehicle, nodePS, "armour_rating", "number");
end

function getNodeFromTokenRef(nodeContainer, nId)
	if not nodeContainer then
		return nil;
	end
	local sContainerNode = DB.getPath(nodeContainer);

	for _,v in ipairs(DB.getChildList(PARTY_VEHICLE_LIST)) do
		local sChildContainerName = DB.getValue(v, "tokenrefnode", "");
		local nChildId = tonumber(DB.getValue(v, "tokenrefid", "")) or 0;
		if (sChildContainerName == sContainerNode) and (nChildId == nId) then
			return v;
		end
	end
	return nil;
end

function getNodeFromToken(token)
	local nodeContainer = token.getContainerNode();
	local nID = token.getId();

	return getNodeFromTokenRef(nodeContainer, nID);
end

function linkToken(nodePS, newTokenInstance)
	TokenManager.linkToken(nodePS, newTokenInstance);

	if newTokenInstance then
		newTokenInstance.setActive(false);
		newTokenInstance.setVisible(true);

		newTokenInstance.setName(DB.getValue(nodePS, "name", ""));
	end

	return true;
end

function updateName(nodeName)
	local nodeEntry = DB.getParent(nodeName);
	local tokeninstance = Token.getToken(DB.getValue(nodeEntry, "tokenrefnode", ""), DB.getValue(nodeEntry, "tokenrefid", ""));
	if tokeninstance then
		tokeninstance.setName(DB.getValue(nodeEntry, "name", ""));
	end
end

--
-- DROP HANDLING
--

function addVehicle(nodeVehicle)
	local nodePS = mapVehicletoPS(nodeVehicle)
	if nodePS then
		return;
	end

	nodePS = DB.createChild(PARTY_VEHICLE_LIST);
	DB.setValue(nodePS, "link", "windowreference", "charspacecraftsheet", DB.getPath(nodeVehicle));
	linkVehicleFields(nodePS);
	DB.setPublic(nodeVehicle, true);
end

--
-- Crew Handling
--

function addCrew(nodeShip, sClass, sRecord)
    local nodeCrewList = DB.getChild(nodeShip, "crew");
    local sSrcName = DB.getValue(DB.findNode(sRecord), "name", "");
    local sSrcToken = DB.getValue(DB.findNode(sRecord), "token", "");
    for _,vCrew in ipairs(DB.getChildList(nodeCrewList)) do
        local _,sCrewRecord = DB.getValue(vCrew, "link", "");

        if sCrewRecord == sRecord then
            return false
        end
    end

    local w = DB.createChild(nodeCrewList);
    DB.setValue(w, "name", "string", sSrcName);

	sSrcToken = UtilityManager.resolveDisplayToken(sSrcToken, sSrcName);
    DB.setValue(w, "token", "token", sSrcToken);

    DB.setValue(w, "role", "string", "Passenger");
    DB.setValue(w, "link", "windowreference", sClass, sRecord);

  	-- ActorManagerTraveller.recalcShipDefense(nodeShip);
end

function addNPCCrew(nodeShip, sClass, sRecord)
    local nodeCrewList = DB.getChild(nodeShip, "crew");
    local sSrcName = DB.getValue(DB.findNode(sRecord), "name", "");
    local sSrcToken = DB.getValue(DB.findNode(sRecord), "token", "");

    local w = DB.createChild(nodeCrewList);
    DB.copyNode(DB.findNode(sRecord), w);

	sSrcToken = UtilityManager.resolveDisplayToken(sSrcToken, sSrcName);
	DB.setValue(w, "token", "token", sSrcToken);

    DB.setValue(w, "role", "string", "Passenger");
    DB.setValue(w, "link", "windowreference", sClass, sRecord);

  	-- ActorManagerTraveller.recalcShipDefense(nodeShip);
end
--[[function addCrew(nodeVehicle, sCharPath, sRole)
	local aPath = StringManager.split(sCharPath, ".");
	for _,v in ipairs(DB.getChildList(nodeVehicle, "crew")) do
		local _,sCrewPath = DB.getValue(v, "link", "");
		local sCrewRole = DB.getValue(v, "role", "");
		if aPath[2] == sCrewPath and sCrewRole == sRole then
			return;
		end
	end

	local sName = DB.getValue(DB.getPath(sCharPath, "name"), "");
	local sToken = DB.getValue(DB.getPath(sCharPath, "token"), "");
	local nodeCrew = DB.createChild(nodeVehicle, "crew." .. aPath[2]);
	DB.setValue(nodeCrew, "name", "string", sName);
	DB.setValue(nodeCrew, "token", "token", sToken);
	DB.setValue(nodeCrew, "link", "windowreference", "charsheet", sCharPath);
	DB.setValue(nodeCrew, "role", "string", sRole);

	local _,sShip = DB.getValue(nodeVehicle, "link", "");
	local nodeShip = DB.findNode(sShip)
  	-- ActorManagerTraveller.recalcShipDefense(nodeShip);
end--]]
