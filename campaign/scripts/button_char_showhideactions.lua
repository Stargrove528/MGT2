--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onButtonPress()
	for _,vWindows in pairs(window.windowlist.window.shiplist.getWindows()) do
		vWindows.showhideactions.setValue(0);
	end

	setValue(1);

	window.windowlist.window.shipweapons.closeAll();

	-- local nodeCrew = window.windowlist.window.getDatabaseNode();
	local _,sShipRecord = window.link.getValue();
	local nodeShip = DB.findNode(sShipRecord);

	for _,vWeapons in ipairs(DB.getChildList(nodeShip, "actions")) do
		local sWeaponName = DB.getValue(vWeapons, "name", "");

		local wTop = UtilityManager.getTopWindow(window);
		local nodePC = wTop.getDatabaseNode();

		local nPCAttack = CharManager.checkHasSkill(nodePC, "gunner (turret)");

		-- Check they have the base skill to offset the -3
		if nPCAttack == -3 then
			nPCAttack = CharManager.checkHasSkill(nodePC, "gunner");
		end
		-- if still -3, do they have JoaT?
		if nPCAttack == -3 then
			nPCAttack = nPCAttack + CharManager.getJackOfAllTradesSkillLevel(nodePC);
		end
		local nPCDexMod = DB.getValue(nodePC, 'attributes.dex_mod', 0);

		if sWeaponName ~= "" then
            local v = window.windowlist.window.shipweapons.createWindow();
            v.name.setValue(DB.getValue(vWeapons, "name", ""));

			v.skillDM.setValue(nPCAttack);
            v.damage.setValue(DB.getValue(vWeapons, "damage", ""));
            v.range.setValue(DB.getValue(vWeapons, "range", ""));
			v.traits.setValue(DB.getValue(vWeapons, "traits", ""));

			if v.traits.getValue():lower():find('missile') then
				v.skillDM.setValue(0);
			end

			v.characteristic.setValue("Dex");
			v.characteristicDM.setValue(nPCDexMod);
			v.attack.onSourceUpdate();
			v.link.setValue("item", DB.getPath(vWeapons));
			v.shipLink.setValue(DB.getPath(nodeShip));
			v.shortcut.onValueChanged();
        end
	end
end
