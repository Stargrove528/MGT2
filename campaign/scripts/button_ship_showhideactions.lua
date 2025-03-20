--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onButtonPress()
	window.shipweapons.closeAll();
    setValue(1);

	local nodeShip = DB.getChild(window.getDatabaseNode(), "...")
	local _,sCrewRecord = DB.getValue(window.getDatabaseNode(), "link", "");
	local nodeCrew = DB.findNode(sCrewRecord);
	local sRole = string.lower(window.rolelabel.getValue());

    setupWeapons(nodeShip, nodeCrew);
end

function setupWeapons(nodePSShip, nodeCrew)
    local _,sShipRecord = DB.getValue(nodePSShip, "link", "");
    local nodeShip = DB.findNode(sShipRecord);

    for _,vWeapons in ipairs(DB.getChildList(nodeShip, "actions")) do
		local sWeaponName = DB.getValue(vWeapons, "name", "");

		local wTop = UtilityManager.getTopWindow(window);

		local nPCAttack = NPCManagerTraveller.checkHasSkill(nodeCrew, "gunner (turret)");

		-- -- Check they have the base skill to offset the -3
		if nPCAttack == -3 then
			nPCAttack = NPCManagerTraveller.checkHasSkill(nodeCrew, "gunner");
		end
		-- -- if still -3, do they have JoaT?
		if nPCAttack == -3 then
			nPCAttack = nPCAttack + NPCManagerTraveller.checkHasSkill(nodeCrew, "jack of all trades");
		end
		local nPCDexMod = DB.getValue(nodeCrew, 'attributes.dex_mod', 0);

		if sWeaponName ~= "" then
            local v = window.shipweapons.createWindow();
            v.name.setValue(DB.getValue(vWeapons, "name", ""));

			v.skillDM.setValue(nPCAttack);
            v.damage.setValue(DB.getValue(vWeapons, "damage", ""));
            v.range.setValue(DB.getValue(vWeapons, "range", ""));
			v.traits.setValue(DB.getValue(vWeapons, "traits", ""));
			v.characteristic.setValue("Dex");
			v.characteristicDM.setValue(nPCDexMod);
			v.attack.onSourceUpdate();
			v.link.setValue("item", DB.getPath(vWeapons));
			v.npclink.setValue("npc", DB.getPath(nodeCrew));
			v.shortcut.onValueChanged();
        end
    end
    window.shipweapons.setVisible(true);
end
