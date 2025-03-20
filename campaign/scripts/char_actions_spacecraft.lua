--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

bInitialize = false;

function onInit()
	DB.addHandler("partysheet.shipinformation.*", "onChildUpdate", update);
	DB.addHandler("partysheet.shipinformation", "onChildDeleted", update);
	DB.addHandler(DB.getPath(getDatabaseNode(), "skilllist.*.total"), "onUpdate", update);
	update();
	bInitialize = true;
	--[[
	DB.addHandler("partysheet.shipinformation.*.crew", "onChildUpdate", update);
	DB.addHandler("charstarshipsheet.*.components", "onChildUpdate", update);
	DB.addHandler(DB.getPath(getDatabaseNode(), "skilllist.*.total"), "onUpdate", update);

	update();
	bInitialize = true;
	--]]
end

function onClose()
	DB.removeHandler("partysheet.shipinformation.*", "onChildUpdate", update);
	DB.removeHandler("partysheet.shipinformation", "onChildDeleted", update);
	DB.removeHandler(DB.getPath(getDatabaseNode(), "skilllist.*.total"), "onUpdate", update);
end

function update()
	shiplist.closeAll();
	--actions.closeAll();
	--minoractions.closeAll();
	shipweapons.closeAll();

	local sCharPath = getDatabasePath();
	local nodeChar = getDatabaseNode();

	for _,vShip in ipairs(DB.getChildList("partysheet.shipinformation")) do
		local sShipClass,sShipRecord = DB.getValue(vShip, "link", "", "");
		if vShipRecord == "" then
			return
		end

		local sShipName = DB.getValue(vShip, "name", "");
		local sShipToken = DB.getValue(vShip, "token", "");
		sShipToken = UtilityManager.resolveDisplayToken(sShipToken, sShipName);

		for _,vCrew in ipairs(DB.getChildList(vShip, "crew")) do
			local _,sCrewRecord = DB.getValue(vCrew, "link", "");
			if sCrewRecord == sCharPath then
				local sRole = DB.getValue(vCrew, "role", "");
				local w = shiplist.createWindow();
				w.token.setPrototype(sShipToken);
				w.link.setValue(sShipClass, sShipRecord);
				w.shipname.setValue(sShipName);
				w.rolelabel.updateLabel();

				if (sRole or "") == "" or sRole == "Passenger" then
					w.rolelabel.setValue(Interface.getString("vehiclerole_passenger"));
					w.showhideactions.setVisible(false);
				else
					w.role.setValue(sRole);
					w.rolelabel.setValue(sRole);
					w.showhideactions.setVisible(true);
				end
			end
		end
	end
end

function roleChange(nodeShip, sRole)
	--DB.setValue(nodeShip, "showhideactions", "number", 1);
	--actions.closeAll();
	--minoractions.closeAll();
	shipweapons.closeAll();

	local nodeChar = getDatabaseNode();
	local sCharName = DB.getPath(nodeChar);
	local sShipName = DB.getPath(nodeShip);

	for _,vShip in ipairs(DB.getChildList("partysheet.shipinformation")) do
		local _,vPSShipRecord = DB.getValue(vShip, "link", "");
		if sShipName == vPSShipRecord then
			for _,vCrew in ipairs(DB.getChildList(vShip, "crew")) do
				local _,vPSCrewRecord = DB.getValue(vCrew, "link", "");
				if sCharName == vPSCrewRecord then
					VehicleManager.notifyRoleChange(vCrew, sRole);
				end
			end
		end
	end
end
