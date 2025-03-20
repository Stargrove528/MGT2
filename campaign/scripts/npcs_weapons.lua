--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- NPC Weapons

function onInit()
	local bReadOnly = true;
	local node = DB.getChild(getDatabaseNode(), "...");

	if node then
		local nLocked = DB.getValue(node, 'locked', 0);
		if nLocked == 0 then
			bReadOnly = false;
		end
	end
	update(bReadOnly);
end

function onDrop(x, y, draginfo)

	vTarget = getDatabaseNode();

	if draginfo.isType("shortcut") then
		local sClass,sRecord = draginfo.getShortcutData();

		if RecordDataManager.isRecordTypeDisplayClass("item", sClass) then
			local weaponNode = DB.findNode(sRecord);
			local sType = DB.getValue(weaponNode, "type"):lower();

			if (sClass == "reference_weapons" or sType == "weapons") then

				DB.setValue(vTarget, "name", "string", DB.getValue(weaponNode, "name"));
				DB.setValue(vTarget, "attack", "string", "0");
				DB.setValue(vTarget, "damage", "string", DB.getValue(weaponNode, "damage", ""));
				DB.setValue(vTarget, "range", "string", DB.getValue(weaponNode, "range", ""));
				DB.setValue(vTarget, "traits", "string", DB.getValue(weaponNode, "traits", ""));

				return true;
			end
		end
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
	local sStackDesc, nStackMod = ModifierStack.getStack(true);
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
			sDesc = "[ATTACK (" .. sAttackType .. ")] " .. sName .. " [2D+" .. nTotal .. "]";
		elseif (nTotal < 0) then
			sDesc = "[ATTACK (" .. sAttackType .. ")] " .. sName .. " [2D" .. nTotal .. "]";
		else
			sDesc = "[ATTACK (" .. sAttackType .. ")] " .. sName;
		end

		-- Add any modifier used (via the Modifier box on the desktop)
		if nStackMod > 0 then
			sDesc = sDesc .. "\n + [MOD +" .. nStackMod .. "]"
		elseif nStackMod < 0 then
			sDesc = sDesc .. "\n + [MOD " .. nStackMod .. "]"
		end

		-- Add the skill level to the modifiers
		nStackMod = nStackMod + nTotal

		local rRoll = {
			sType = "attack",
			sDamage = sDamage,
			sWeaponTraits = sWeaponTraits, 
			sDesc = sDesc,
			aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor),
			nMod = nStackMod,
			nTotal = nTotal,
		};

		-- Boon/Bane
		ActionsManager2.encodeAdvantage(rRoll);

		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end

function actionDamage(draginfo)
	local node = getDatabaseNode();
	local rActor = ActorManager.resolveActor(DB.getChild(node, "..."));
	ActionDamage.performRoll(draginfo, rActor, ActionDamage.getDamageAction(node));
end

function update(bReadOnly)
	name.setReadOnly(bReadOnly);
	attack.setReadOnly(bReadOnly);
	damage.setReadOnly(bReadOnly);
	range.setReadOnly(bReadOnly);
	traits.setReadOnly(bReadOnly);
	if bReadOnly and traits.getValue() == "" then
		traits.setVisible(false);
		traits_label.setVisible(false);
	else
		traits.setVisible(true);
		traits_label.setVisible(true);
	end
 end

