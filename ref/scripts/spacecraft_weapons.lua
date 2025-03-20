--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	update()

	WindowManager.setInitialOrder(self);

	local spacecraftType = DB.getName(DB.getChild(getDatabaseNode(), "...."))
	if spacecraftType == "charspacecraftsheet" then
		link.setVisible(true);
	else
		link.setVisible(false);
	end
end

function onDrop(x, y, draginfo)
	return WindowManager.handleDropReorder(self, draginfo);
end

function update()
	local nodeShip = DB.getChild(getDatabaseNode(), "...");
	local bReadOnly = WindowManager.getReadOnlyState(nodeShip);

    name.setReadOnly(bReadOnly);
    attack.setReadOnly(bReadOnly);
    damage.setReadOnly(bReadOnly);
    range.setReadOnly(bReadOnly);
    tl.setReadOnly(bReadOnly);
    traits.setReadOnly(bReadOnly);

    if traits.getValue() == "" and bReadOnly then
        traits.setVisible(false);
        label_actions_traits.setVisible(false);
    else
        traits.setVisible(true);
        label_actions_traits.setVisible(true);
     end
end

function actionAttack(draginfo)
    local node = getDatabaseNode();
    local sName = name.getValue();
	local nTotal = attack.getValue();
	local sDamage = damage.getValue();
	local aDice, nMod = StringManager.convertStringToDice(nTotal:lower());
	local sWeaponTraits = traits.getValue();
	local sAttackType = range.getValue();

	-- add Modifier dice
	local bDescNotEmpty = true;
	local sStackDesc, nStackMod = ModifierStack.getStack(bDescNotEmpty);
	local rActor = ActorManager.resolveActor(DB.getChild(node, "..."));
	local sDesc;

	if sAttackType:lower() ~= "melee" then
		sAttackType = "R";
	else
		sAttackType = string.sub(sAttackType,1,1);
	end

	-- Make sure it's a number
	if StringManager.isNumberString(nTotal) then
		nTotal = tonumber(nTotal);
		if (nTotal > 0) then
			sDesc = "[SHIP ATTACK (" .. sAttackType .. ")] " .. sName .. " (2D+" .. nTotal .. ")";
		elseif (nTotal < 0) then
			sDesc = "[SHIP ATTACK (" .. sAttackType .. ")] " .. sName .. " (2D+" .. nTotal .. ")";
		else
			sDesc = "[SHIP ATTACK (" .. sAttackType .. ")] " .. sName;
		end

		-- Add any modifier used (via the Modifier box on the desktop)
		if nStackMod > 0 then
			sDesc = sDesc .. "\n + [MOD] (+" .. nStackMod .. ")"
		elseif nStackMod < 0 then
			sDesc = sDesc .. "\n + [MOD] (" .. nStackMod .. ")"
		end

		local rAction = {};
		rAction.modifier = nStackMod + nMod;
		rAction.label = sName;
        rAction.arc = "Forward";
        rAction.weaponTraits = sWeaponTraits

		ActionShipAttack.performRoll(draginfo, rActor, rAction);
	end
end

function actionDamage(draginfo)
	local node = getDatabaseNode();
	local rActor = ActorManager.resolveActor(DB.getChild(node, "..."));
	local rAction = ActionDamage.getDamageAction(node, true);
	ActionShipDamage.performRoll(draginfo, rActor, rAction);
end
