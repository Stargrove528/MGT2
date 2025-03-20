-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("char_menu_addammo"), "insert", 5);

	local node = window.getDatabaseNode();
	DB.addHandler(DB.getPath(node, "damageactions"), "onChildDeleted", damageActionDeleted);
	DB.addHandler(DB.getPath(node, "damageactions"), "onChildAdded", damageActionAdded);

	local sType = DB.getValue(window.getDatabaseNode(), 'type', ''):lower();
	local sSubType = DB.getValue(window.getDatabaseNode(), 'subtype', ''):lower();

	if string.find(sType, "slug") or string.find(sSubType, "slug") then
		-- self.setVisible(true);
	else
		self.setVisible(false);
		window.activatedetail.setVisible(false);
		return
	end

	checkHaveRecords();
end

function onClose()
	local node = window.getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "damageactions"), "onChildDeleted", damageActionDeleted);
	DB.removeHandler(DB.getPath(node, "damageactions"), "onChildAdded", damageActionAdded);
end

function damageActionAdded(vParentNode, vChildNode)
	checkHaveRecords();
	showHeader();
	showDamageActions();
end

function damageActionDeleted(vParentNode)
	checkHaveRecords();
	showHeader();
	showDamageActions();
end

function checkHaveRecords()
	local nRecords = getWindowCount();
	window.activatedetail.setVisible((nRecords > 0));
	return nRecords;
end

function showHeader()
	local bVisible = false;
	if not isEmpty() then
		window.activatedetail.setValue(1);
		bVisible = true;
	else
		window.activatedetail.setValue(0);
	end

	window.label_ammo_damage.setVisible(bVisible);
	window.label_ammo_attack.setVisible(bVisible);
	window.label_ammo_current_ammo.setVisible(bVisible);
	window.label_ammo_name.setVisible(bVisible);
	window.label_ammo_rof.setVisible(bVisible);
end

function showDamageActions()
	local bVisible = false;
	if not isEmpty() then
		bVisible = true;
	else
		hideShowAmmoList(0);
	end

	self.setVisible(bVisible);
end

function hideShowAmmoList(nValue)
	local bVisible = false;
	if nValue == 1 then
		bVisible = true;
	end
	self.setVisible(bVisible);
	window.label_ammo_damage.setVisible(bVisible);
	window.label_ammo_attack.setVisible(bVisible);
	window.label_ammo_current_ammo.setVisible(bVisible);
	window.label_ammo_name.setVisible(bVisible);
	window.label_ammo_rof.setVisible(bVisible);
end

function updateRofFields()
	local sTraits = DB.getValue(window.getDatabaseNode(), "traits", ""):lower();
    local showrateoffire = false;

    if string.find (sTraits, "auto", 0, true) then
        showrateoffire = true;
	end

	window.label_ammo_rof.setVisible(showrateoffire);
end

function onMenuSelection(selection)
	if selection == 5 then
		createWindow(nil, true);
	end
end
