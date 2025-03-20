--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ItemManager.addFieldToIgnore("attack");
	ItemManager.addFieldToIgnore("actionMod");
	ItemManager.addFieldToIgnore("skillDM");
	ItemManager.addFieldToIgnore("characteristicDM");
	ItemManager.addFieldToIgnore("characteristic");
	ItemManager.addFieldToIgnore("ammo");
	ItemManager.addFieldToIgnore("activatedetail");
	ItemManager.addFieldToIgnore("damageactions");
end

function isArmor(vRecord)
	local bIsArmor = false;

	local nodeItem;
	if type(vRecord) == "string" then
		nodeItem = DB.findNode(vRecord);
	elseif type(vRecord) == "databasenode" then
		nodeItem = vRecord;
	end
	if not nodeItem then
		return false, "", "";
	end

	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	if (sTypeLower == "armor") or (sTypeLower == "armour") then
		bIsArmor = true;
	end

	return bIsArmor, sTypeLower, sSubtypeLower;
end

function isWeapon(sClass, vRecord)
	local bIsWeapon = false;

	local nodeItem;
	if type(vRecord) == "string" then
		nodeItem = DB.findNode(vRecord);
	elseif type(vRecord) == "databasenode" then
		nodeItem = vRecord;
	end

	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	if sClass == "reference_weapons" then
		bIsWeapon = true;
	elseif sClass == "item" then
		if (sTypeLower == "weapons" or sTypeLower == "weapon" or sTypeLower == "heavy weaponry") or (sSubtypeLower == "weapons" or sSubtypeLower == "weapon") then
			bIsWeapon = true;
		end
		if sSubtypeLower == "ammunition" then
			bIsWeapon = false;
		end
	end

	return bIsWeapon, sTypeLower, sSubtypeLower;
end

function isAugment(vRecord)
	return isWhatClass(vRecord, "Augments");
end

function isElectronics(vRecord)
	return isWhatClass(vRecord, "Electronics");
end

function isAmmo(vRecord)
	return isWhatClass(vRecord, "Ammunition");
end

function isSpacecraftScaleWeapon(vRecord)
	return isWhatClass(vRecord, "Spacecraft Scale Weapons");
end

function isWhatClass(vRecord, sCompare, sCompare2)
	local bIsClass = false;

	local nodeItem;
	if type(vRecord) == "string" then
		nodeItem = DB.findNode(vRecord);
	elseif type(vRecord) == "databasenode" then
		nodeItem = vRecord;
	end
	if not nodeItem then
		return false, "", "";
	end

	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	if (sTypeLower == sCompare:lower()) then
		bIsClass = true;
	end
	if (sCompare2) then
		if (sTypeLower == sCompare2:lower()) then
			bIsClass = true;
		end
	end

	return bIsClass, sTypeLower, sSubtypeLower;
end

function isItemClass(sClass)
	return StringManager.contains({"reference_magicitem", "reference_armor", "reference_weapons", "reference_equipment", "reference_ammunition"}, sClass);
end

function addItemToList2(sClass, nodeSource, nodeTarget, nodeTargetList)
	if isItemClass(sClass) then
		-- If this is a Heavy Weapon...
		local sType = DB.getValue(nodeSource, "type", "");
		local bHeavyWeapon = false;
		if sType == "Heavy Weaponry" then
			local nMass = DB.getValue(nodeSource, "mass", 0);
			if nMass >= 100 then

				local bOptionEHW = OptionsManager.isOption("EHW", "yes");
				bHeavyWeapon = true;

				if bOptionEHW == false then
					local msg = {font = "msgfont"};
					local sItemName = DB.getValue(nodeSource,"name","");

					local sFormat = Interface.getString("char_add_heavy_weaponry");
					msg.text = string.format(sFormat, sItemName);

					Comm.deliverChatMessage(msg);
					return false;
				end
			end
		end

		DB.copyNode(nodeSource, nodeTarget);
		DB.setValue(nodeTarget, "locked", "number", 1);
		DB.setValue(nodeTarget, "isidentified", "number", 1);

		return true;
	end

	return false;
end


function addAmmunitionDamageAction(vTarget, draginfo, sClass, sRecord)

	local nodeTargetRecord = vTarget;

	if not nodeTargetRecord then
		return;
	end

	if type(sRecord) == "databasenode" then
		nodeSource = sRecord;
	elseif type(sRecord) == "string" then
		nodeSource = DB.findNode(sRecord);
	end

	local ammoName = DB.getValue(nodeSource, 'name', '');
	local ammoTraits = DB.getValue(nodeSource, 'traits', '');
	local ammoRange = DB.getValue(nodeSource, 'range', '');
	local ammoDamage = StringManager.trim(DB.getValue(nodeSource, 'damage', ''));
	local ammoCost = DB.getValue(nodeSource, 'cost', '');
	local weaponDamage = StringManager.trim(DB.getValue(vTarget, 'damage', ''));
	local weaponMaxAmmo = DB.getValue(vTarget, 'maxammo', '')
	local weaponTraits = DB.getValue(vTarget, 'traits', '');
	local nodeActions = DB.createChild(vTarget, "damageactions");
	local sNewTraits = self.updateAmmoTraits(weaponTraits, ammoTraits, weaponDamage, ammoName);

	if nodeActions then
		local nodeAction = DB.createChild(nodeActions);
		if nodeAction then
			DB.setValue(nodeAction, "ammotype", "string", ammoName);
			DB.setValue(nodeAction, "ammo", "number", weaponMaxAmmo);
			DB.setValue(nodeAction, "maxammo", "number", weaponMaxAmmo);
			DB.setValue(nodeAction, "rateoffire", "string", "single");
			DB.setValue(nodeAction, "traits", "string", sNewTraits);
			DB.setValue(nodeAction, "shortcut", "windowreference", "reference_ammunition", DB.getPath(nodeSource));

			if ammoDamage:lower():match("[+-]%d+d") then
				local aAmmoDice,nAmmoMod = DiceManager.convertStringToDice(ammoDamage:lower());
				local aWeaponDice,nWeaponMod = DiceManager.convertStringToDice(weaponDamage:lower());
				local aFinalDice = {};
				local nFinalMod = 0;

				for _,v in ipairs(aAmmoDice) do
					table.insert(aFinalDice, v);
				end
				for _,v in ipairs(aWeaponDice) do
					table.insert(aFinalDice, v);
				end

				nFinalMod = nAmmoMod + nWeaponMod;

				local sFinalDamage = DiceManager.convertDiceToString(aFinalDice, nFinalMod);
				DB.setValue(nodeAction, "damage", "string", sFinalDamage);
			else
				DB.setValue(nodeAction, "damage", "string", ammoDamage);
			end
		end
	end
end

function updateAmmoTraits(sWeaponTraits, sAmmoTraits, sWeaponDamage, sAmmo)
	local nDamageDice = tonumber(sWeaponDamage:match('%d+')) or 0;
	local nMultiplier = 1;
	sAmmo = sAmmo:lower();

	if sAmmo == 'apds' then
		nMultiplier = 3;
	end
	if sAmmo == 'heap' then
		nMultiplier = 2;
	end
	if sAmmo == 'solid shot' then
		nMultiplier = 0.5;
	end

	local nNewAPTotal = (nDamageDice * nMultiplier)

	if sAmmo == 'solid shot' then
		nNewAPTotal = math.floor(nNewAPTotal+0.5);
	end

	-- Check for AP X (APDS/Armour Piercing)
	if sAmmoTraits:find('AP X') then
		if sWeaponTraits:find('AP %d+') then
			local nWeaponAP = tonumber(sWeaponTraits:match('AP (%d+)'));

			sWeaponTraits = sWeaponTraits:gsub('AP (%d+)','AP ' .. (nNewAPTotal + nWeaponAP));
			sAmmoTraits = sAmmoTraits:gsub('AP X%p?','');
		else
			sAmmoTraits = sAmmoTraits:gsub('AP X','AP ' .. nNewAPTotal);
		end
	end
	-- Check for AP Special
	if sAmmoTraits:find('AP Special') then
		if sWeaponTraits:find('AP %d+') then
			local nWeaponAP = tonumber(sWeaponTraits:match('AP (%d+)'));

			sWeaponTraits = sWeaponTraits:gsub('AP (%d+)','AP ' .. (nNewAPTotal + nWeaponAP));
			sAmmoTraits = sAmmoTraits:gsub('AP Special%p?','');
		else
			sAmmoTraits = sAmmoTraits:gsub('AP Special','AP ' .. nNewAPTotal);
		end
	end
	-- Check for AP x3/x2
	if sAmmoTraits:find('AP x%d') then

		local nNewMultiplier = sAmmoTraits:match('AP x(%d)');

		nNewAPTotal = (nDamageDice * nNewMultiplier);

		if sWeaponTraits:find('AP %d') then
			local nWeaponAP = tonumber(sWeaponTraits:match('AP (%d)'));

			sWeaponTraits = sWeaponTraits:gsub('AP (%d)','AP ' .. (nNewAPTotal + nWeaponAP));
			sAmmoTraits = sAmmoTraits:gsub('AP x%d%p?','');
		else
			sAmmoTraits = sAmmoTraits:gsub('AP x%d','AP ' .. nNewAPTotal);
		end
	end

	local sNewTraits = sWeaponTraits;
	if sNewTraits == "" then
		sNewTraits = sAmmoTraits;
	else
		if sAmmoTraits ~= "" then
			sNewTraits = sNewTraits .. ', ' .. sAmmoTraits;
		end
	end

	return sNewTraits;
end

function checkAmmunitionIsValid(vTarget, draginfo, sClass, sRecord)
	local nodeTargetRecord = vTarget;
	local bAllowedForThisWeapon = false;

	if not nodeTargetRecord then
		return;
	end

	if type(sRecord) == "databasenode" then
		nodeSource = sRecord;
	elseif type(sRecord) == "string" then
		nodeSource = DB.findNode(sRecord);
	end

	local ammoName = DB.getValue(nodeSource, 'name', '');
	local ammoPistol = DB.getValue(nodeSource, 'pistol', '-');
	local ammoRifle = DB.getValue(nodeSource, 'rifle', '-');
	local ammoShotgun = DB.getValue(nodeSource, 'shotgun', '-');
	local ammoHeavy = DB.getValue(nodeSource, 'heavy', '-');
	local weaponName = DB.getValue(vTarget, 'name', '');
	local weaponType = DB.getValue(vTarget, 'type', '');
	local weaponSubType = DB.getValue(vTarget, 'subtype', ''):lower();

	if ammoPistol == 'X' then
		if weaponSubType:find('pistol') then
			bAllowedForThisWeapon = true;
		end
	end
	if ammoRifle == 'X' then
		if weaponSubType:find('rifle') then
			bAllowedForThisWeapon = true;
		end
	end
	if ammoShotgun == 'X' then
		if weaponSubType:find('shotgun') then
			bAllowedForThisWeapon = true;
		end
	end
	if ammoHeavy == 'X' then
		if weaponSubType:find('heavy') then
			bAllowedForThisWeapon = true;
		end
	end

	if bAllowedForThisWeapon == false then
		-- Announce
		local msg = {font = "msgfont"};
		local sFormat = Interface.getString("char_actions_message_addammo");

		msg.text = string.format(sFormat, ammoName, weaponName);

		Comm.deliverChatMessage(msg);
	end

	return bAllowedForThisWeapon;

end

function updateToolTip(sTraits)
	local aWords = StringManager.split(sTraits,",");
	local sToolTip = "";
	local sType = "";
	local sTrait = "";

	local i = 1;
	while aWords[i] do

		sTrait = aWords[i]:gsub('%d+', '');
		sTrait = StringManager.trim(sTrait:lower());

		if DataCommon["weapontraits"][sTrait:lower()] then

			sType = DataCommon["weapontraits"][sTrait:lower()];

			if sToolTip == "" then
				sToolTip = sTrait:upper() ..": " .. sType;
			else
				sToolTip = sToolTip .. "\n\n" .. sTrait:upper() .. ": " .. sType;
			end
		end
		i = i + 1;
	end

	return sToolTip;
end
