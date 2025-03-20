--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function actionAttack(draginfo)
    local sName = name.getValue();
	local nTotal = attack.getValue();
	local sWeaponTraits = traits.getValue();
	local sAttackType = range.getValue();

	local nodeShip;
	if shipLink then
		nodeShip = shipLink.getValue();
	end

	-- add Modifier dice
	local bDescNotEmpty = true;
	local sStackDesc, nStackMod = ModifierStack.getStack(bDescNotEmpty);
	local sDesc = "[ATTACK (" .. sAttackType .. ")] " .. sName;

	local rActor = ActorManager.resolveActor(nodeShip);

	-- Add any modifier used (via the Modifier box on the desktop)
	if nStackMod > 0 then
		sDesc = sDesc .. "\n + [MOD +" .. nStackMod .. "]"
	elseif nStackMod < 0 then
		sDesc = sDesc .. "\n + [MOD " .. nStackMod .. "]"
	end

	-- Now create the action
	if nTotal then
		local rAction = {};
		rAction.modifier = nStackMod + nTotal;
		rAction.label = sName;
        rAction.arc = "Forward";
        rAction.weaponTraits = sWeaponTraits
		rAction.nMod = nStackMod + nTotal;

		ActionShipAttack.performRoll(draginfo, rActor, rAction);
	end
end

function actionDamage(draginfo)
	local nodeShip;
	if shipLink then
		nodeShip = shipLink.getValue();
	end
	local rActor = ActorManager.resolveActor(nodeShip);
	local rAction = ActionDamage.getDamageAction(getDatabaseNode() or self, true);
	ActionShipDamage.performRoll(draginfo, rActor, rAction);
end
