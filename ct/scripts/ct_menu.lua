-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	setColor(ColorManager.getButtonTextColor());
	if Session.IsHost then
		registerMenuItem(Interface.getString("menu_init"), "turn", 7);
		registerMenuItem(Interface.getString("menu_initall"), "shuffle", 7, 8);
		registerMenuItem(Interface.getString("menu_initnpc"), "mask", 7, 7);
		registerMenuItem(Interface.getString("menu_initpc"), "portrait", 7, 6);
		registerMenuItem(Interface.getString("menu_initclear"), "pointer_circle", 7, 4);

		registerMenuItem(Interface.getString("ct_menu_itemdelete"), "delete", 3);
		registerMenuItem(Interface.getString("ct_menu_itemdeletenonfriendly"), "delete", 3, 1);
		registerMenuItem(Interface.getString("ct_menu_itemdeletefoe"), "delete", 3, 3);
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
				CombatManager.resetInit();
			elseif subselection == 8 then
				CombatManager2.rollInit();
			elseif subselection == 7 then
				CombatManager2.rollInit("npc");
			elseif subselection == 6 then
				CombatManager2.rollInit("pc");
			end
		end
		if selection == 5 then
			if subselection == 7 then
				CombatManager2.resetEffects();
			elseif subselection == 5 then
				CombatManager2.clearExpiringEffects();
			end
		end
		if selection == 3 then
			if subselection == 1 then
				CombatManager.deleteNonFaction("friend");
			elseif subselection == 3 then
				CombatManager.deleteFaction("foe");
			end
		end
	end
end
