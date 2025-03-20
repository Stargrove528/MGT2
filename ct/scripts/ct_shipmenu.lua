--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		registerMenuItem(Interface.getString("menu_init"), "turn", 7);
		registerMenuItem(Interface.getString("menu_initall"), "shuffle", 7, 8);
		registerMenuItem(Interface.getString("menu_initnpc"), "mask", 7, 7);
		registerMenuItem(Interface.getString("menu_initpc"), "portrait", 7, 6);
		registerMenuItem(Interface.getString("menu_initclear"), "pointer_circle", 7, 4);

		registerMenuItem(Interface.getString("menu_restshort"), "pointer_cone", 8, 8);
		registerMenuItem(Interface.getString("menu_restovernight"), "pointer_circle", 8, 6);

		registerMenuItem(Interface.getString("ct_menu_itemdelete"), "delete", 3);
		registerMenuItem(Interface.getString("ct_menu_itemdeletenonfriendly"), "delete", 3, 1);
		registerMenuItem(Interface.getString("ct_menu_itemdeletefoe"), "delete", 3, 3);

		registerMenuItem(Interface.getString("ct_menu_effectdelete"), "hand", 5);
		registerMenuItem(Interface.getString("ct_menu_effectdeleteall"), "pointer_circle", 5, 7);
		registerMenuItem(Interface.getString("ct_menu_effectdeleteexpiring"), "pointer_cone", 5, 5);
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if button == 1 then
		Interface.openRadialMenu();
		return true;
	end
end

function onMenuSelection(selection, subselection)
	if Session.IsHost then
		if selection == 7 then
			if subselection == 4 then
				SpacecraftCombatManager.resetInit();
			elseif subselection == 8 then
				SpacecraftCombatManager.rollInit();
			elseif subselection == 7 then
				SpacecraftCombatManager.rollInit("npc");
			elseif subselection == 6 then
				SpacecraftCombatManager.rollInit("pc");
			end
		end
		if selection == 5 then
			if subselection == 7 then
				CombatManager.resetCombatantEffects("ship");
			elseif subselection == 5 then
				SpacecraftCombatManager.clearExpiringEffects();
			end
		end
		if selection == 3 then
			if subselection == 1 then
				CombatManager.deleteNonFactionFromTracker("ship", "friend");
			elseif subselection == 3 then
				CombatManager.deleteFactionFromTracker("ship", "foe");
			end
		end
	end
end
