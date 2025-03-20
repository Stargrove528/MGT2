--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Character Weapons
function onInit()
    updateWindow();
end

function updateWindow()
    local sClass,sRecord = shortcut.getValue();
    local bWeapon = ItemManager2.isWeapon(sClass, sRecord);
    local nMagazine = DB.getValue(getDatabaseNode(), "magazine", -1);
    local bShowAmmo = false
    local bShowROF = false
    local sTraits = DB.getValue(getDatabaseNode(), "traits", ""):lower();

    if (nMagazine or 0) > 0 then
        bShowAmmo = true
    end

    if string.find (sTraits, "auto", 0, true) then
        bShowROF = true;
    end

	label_ammo.setVisible(bShowAmmo);
	ammo.setVisible(bShowAmmo);
    resetammo.setVisible(bShowAmmo);
    label_rateoffire.setVisible(bShowROF);
    rateoffire.setVisible(bShowROF);

    if (bshowrateoffire) then
        if rateoffire.getValue() == "" then
            rateoffire.setStringValue("single")
        end
    end
end

function onDrop(x, y, draginfo)
    local sClass,sRecord = draginfo.getShortcutData();

    -- find the type
    sType = DB.getValue(DB.findNode(sRecord), 'type', 'notammo');
    if sClass == "reference_ammunition" or sClass == "referenceammunition" or sType:lower() == "ammunition" then
        -- Check this ammo is applicable for dragging onto that weapon
        if ItemManager2.checkAmmunitionIsValid(getDatabaseNode(), draginfo, sClass, sRecord) then
            ItemManager2.addAmmunitionDamageAction(getDatabaseNode(), draginfo, sClass, sRecord);

            if self.damageactions.checkHaveRecords() > 0 then
                self.damageactions.showHeader();
                self.damageactions.showDamageActions();
                self.damageactions.updateRofFields();
            end
        end
    end
end

function actionAttack(draginfo)
    local node = getDatabaseNode();
    local sName = DB.getValue(node, "name", "");
    local sAttackType = DB.getValue(node, "range", "");
    local sSubType = DB.getValue(node, "subtype", "");
    local nTotal = attack.getValue();
    local sAttribute = characteristic.getValue();
    local sAttributeDM = characteristicDM.getValue();
    local sDamage = DB.getValue(node, "damage", "");

    if sAttackType:lower() ~= "melee" then
		sAttackType = "R";
	else
		sAttackType = string.sub(sAttackType,1,1);
	end

    -- add Modifier dice
	local bDescNotEmpty = true;
    local sStackDesc, nStackMod = ModifierStack.getStack(bDescNotEmpty);

    local rActor = ActorManager.resolveActor(DB.getChild(node, "..."));
    local sDesc = "[ATTACK (".. sAttackType ..")] " .. sName .. " [2D";

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

    rRoll.sSkillStat = sAttribute
	rRoll.nSkillMod = 0
    rRoll.nStatMod = sAttributeDM
    rRoll.sWeaponTraits = DB.getValue(node, "traits", ""):lower();
    rRoll.sWeaponrateoffire = DB.getValue(node, "rateoffire", ""):lower();

    -- Boon/Bane
    ActionsManager2.encodeAdvantage(rRoll);

	-- Decrement ammo
    local nMagazine = DB.getValue(node, "magazine", 0);

    if (nMagazine ~= nil and nMagazine ~= "" and nMagazine > 0) then
        local nCurrentAmmo = DB.getValue(node, "ammo", 0);
        local nAmmoUsedThisAttack = 1
        local sTraits = rRoll.sWeaponTraits
        local sAutoTrait = string.match(sTraits, "%auto %d+")

        if sAutoTrait ~= "" then
            local srateoffire = rRoll.sWeaponrateoffire
            if srateoffire == "burst" then
                nAmmoUsedThisAttack = string.match(sAutoTrait, "%d+")
            end
            if srateoffire == "full_auto" then
                nAmmoUsedThisAttack = 3;
            end
        end

        if (nCurrentAmmo - nAmmoUsedThisAttack) <= 0 then
            if nCurrentAmmo - nAmmoUsedThisAttack == 0 then
                ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
            else
                ChatManager.Message(Interface.getString("char_message_atkwithoutenoughammo"), true, rActor);
            end
            DB.setValue(node, "ammo", "number", 0);
		else
			DB.setValue(node, "ammo", "number", nCurrentAmmo - nAmmoUsedThisAttack);
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
