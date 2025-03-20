--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
    local nodeWin = getDatabaseNode();
    DB.addHandler(DB.getPath(nodeWin, "traits"), "onUpdate", updateWindow);

    updateWindow()
end

function onClose()
    local nodeWin = getDatabaseNode();
    DB.removeHandler(DB.getPath(nodeWin, "traits"), "onUpdate", updateWindow);
end

function updateWindow()
	local sTraits = traits.getValue():lower()
    local showrateoffire = false;

    if string.find (sTraits, "auto", 0, true) then
        showrateoffire = true;
    end

    ammorateoffire.setVisible(showrateoffire);

    if (showrateoffire) then
        if ammorateoffire.getValue() == "" then
            ammorateoffire.setStringValue("single")
        end
    end
end

function actionAttack(draginfo)
	local node = DB.getChild(getDatabaseNode(), "...");
	local thisNode = getDatabaseNode();
	local sName = DB.getValue(node,'name', '');
	local nTotal = attack.getValue();
	local sAmmoType = ammotype.getValue();
    local sAttackType = DB.getValue(node,'range', '');
    local sSubType = DB.getValue(node,'subtype', '');
    local thisAttribute = DB.getValue(node,'characteristic', '');
    local thisAttributeDM = DB.getValue(node,'characteristicDM', '');
	local sDamage = damage.getValue();

	if sAttackType:lower() ~= "melee" then
		sAttackType = "R";
	else
		sAttackType = string.sub(sAttackType,1,1);
	end

    -- add Modifier dice
	local bDescNotEmpty = true;
    local sStackDesc, nStackMod = ModifierStack.getStack(bDescNotEmpty);

    local rActor = ActorManager.resolveActor(DB.getChild(node, "..."));
	local sDesc = "[ATTACK (".. sAttackType ..")] " .. sName;

	sDesc = sDesc .. " [AMMO: " .. sAmmoType ..  "] [2D";

    if (nTotal > 0) then
        sDesc = sDesc .. "+" .. nTotal .."]";
    elseif (nTotal < 0) then
        sDesc = sDesc .. nTotal .."]";
    else
        sDesc = sDesc .."]";
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
		sDesc = sDesc,
		aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor),
		nMod = nStackMod,
		nTotal = nTotal,
	};

    rRoll.sSkillStat = thisAttribute;
	rRoll.nSkillMod = 0;
    rRoll.nStatMod = thisAttributeDM;
    rRoll.sWeaponTraits = traits.getValue();
	rRoll.sWeaponrateoffire = ammorateoffire.getValue():lower();

    -- Boon/Bane
    ActionsManager2.encodeAdvantage(rRoll);

	-- Decrement ammo
    local nMagazine = DB.getValue(node, "magazine", 0);

    if (nMagazine ~= nil and nMagazine ~= "" and nMagazine > 0) then
        local nCurrentAmmo = DB.getValue(getDatabaseNode(), "ammo", 0);
        local nAmmoUsedThisAttack = 1
        local sTraits = rRoll.sWeaponTraits
		local sAutoTrait = string.match(sTraits, "%auto %d+")

        if sAutoTrait ~= "" and sAutoTrait ~= nil then
            local srateoffire = rRoll.sWeaponrateoffire
            if srateoffire == "burst" then
                nAmmoUsedThisAttack = string.match(sAutoTrait, "%d+")
            end
            if srateoffire == "full_auto" then
                nAmmoUsedThisAttack = 3
            end
        end

        if (nCurrentAmmo - nAmmoUsedThisAttack) <= 0 then
            if nCurrentAmmo - nAmmoUsedThisAttack == 0 then
                ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
            else
                ChatManager.Message(Interface.getString("char_message_atkwithoutenoughammo"), true, rActor);
            end
            DB.setValue(getDatabaseNode(), "ammo", "number", 0);
		else
			DB.setValue(getDatabaseNode(), "ammo", "number", nCurrentAmmo - nAmmoUsedThisAttack);
		end
	end

    -- Now we 'make the roll'
    ActionsManager.performAction(draginfo, rActor, rRoll);
end

function actionDamage(draginfo)
	local node = getDatabaseNode();
	local rActor = ActorManager.resolveActor(DB.getChild(node, "..."));
	ActionDamage.performRoll(draginfo, rActor, ActionDamage.getDamageAction(node));
end
