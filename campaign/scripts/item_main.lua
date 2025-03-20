--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.update();
end

function VisDataCleared()
	self.update();
end
function InvisDataAdded()
	self.update();
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("item", nodeRecord);

	local bWeapon = ItemManager2.isWeapon("item", nodeRecord);
	local bArmor = ItemManager2.isArmor(nodeRecord);
	local bElectronics = ItemManager2.isElectronics(nodeRecord);
	local bAmmo = ItemManager2.isAmmo(nodeRecord);
	local bSpacecraftScale = ItemManager2.isSpacecraftScaleWeapon(nodeRecord);

	local bSection1 = false;
	if (Session.IsHost or not bID) then
		if WindowManager.callSafeControlUpdate(self, "nonid_notes", bReadOnly) then bSection1 = true; end;
	else
		WindowManager.callSafeControlUpdate(self, "nonid_notes", bReadOnly, true);
	end

	type_label_summary.setVisible(bReadOnly);
	type_label_summary.setValue(string.format("[%s]", type.getValue()));
	type.setVisible(not bReadOnly);
	type_label.setVisible(not bReadOnly);
	subtype_label_summary.setVisible(bReadOnly);
	subtype_label_summary.setValue(string.format("[%s]", subtype.getValue()));
	subtype.setVisible(not bReadOnly);
	subtype_label.setVisible(not bReadOnly);

	local bSection2 = false;
	if WindowManager.callSafeControlUpdate(self, "tl", bReadOnly, not bID) then bSection2 = true; end
	if WindowManager.callSafeControlUpdate(self, "cost", bReadOnly, not bID) then bSection2 = true; end

	local bSection3 = true;
	if Session.IsHost or bID then 
		if bWeapon then
			type_stats.setValue("item_main_weapon", nodeRecord);
		elseif bArmor then
			type_stats.setValue("item_main_armor", nodeRecord);
		elseif bAmmo then
			type_stats.setValue("item_main_ammo", nodeRecord);
		elseif bElectronics then
			type_stats.setValue("item_main_electronics", nodeRecord);
		elseif bSpacecraftScale then
			type_stats.setValue("item_main_spacecraft", nodeRecord);
		else
			type_stats.setValue("item_main_other", nodeRecord);
		end
	else
		type_stats.setValue("", "");
		bSection3 = false;
	end
	type_stats.update(bReadOnly, bID);

	divider1.setVisible(bSection2);
	divider2.setVisible(bSection3);

	local bSection4 = bID;
	notes.setVisible(bID);
	notes.setReadOnly(bReadOnly);
	divider3.setVisible(bSection4);
end
