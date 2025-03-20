--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local nResultWounds = 0

function onInit()
	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "attackscore"), "onUpdate", updateAttackVisibility);
	DB.addHandler(DB.getPath(node, "defensescore"), "onUpdate", updateAttackVisibility);
	DB.addHandler(DB.getPath(node, "attackdescription"), "onUpdate", updateAttackDescription);
	DB.addHandler(DB.getPath(node, "damage"), "onUpdate", updateDamageVisibility);
	DB.addHandler(DB.getPath(node, "hiticon"), "onUpdate", updateAttackResult);

	updateAttackDescription()
	updateAttackResult()
	updateAttackVisibility()
	updateDamageVisibility()
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "attackscore"), "onUpdate", updateAttackResult);
	DB.removeHandler(DB.getPath(node, "defensescore"), "onUpdate", updateAttackResult);
	DB.removeHandler(DB.getPath(node, "attackdescription"), "onUpdate", updateAttackDescription);
	DB.removeHandler(DB.getPath(node, "damage"), "onUpdate", updateDamageVisibility);
	DB.removeHandler(DB.getPath(node, "hiticon"), "onUpdate", updateAttackResult);
end

function getCombatantNode()
	return DB.getParent(windowlist.getDatabaseNode())
end


function isNotBlank(sContent)
	return not isBlank(sContent)
end

function isBlank(sContent)
	return not sContent or StringManager.trim(sContent) == ""
end

function append(sSource, sNewContent, sSeparator)
	if not sSource then
		return sNewContent or ""
	end
	if #sSource > 0 and isNotBlank(sNewContent) then
		sSource = sSource .. (sSeparator and sSeparator or ", ")
	end
	return sSource .. (sNewContent or "")
end

--
-- Attacker description
--

function updateAttackDescription()
	local sDesc = DB.getValue(getDatabaseNode(), "attackdescription");
	local bVisible = isNotBlank(sDesc)
	descriptionrow.setVisible(bVisible)
	attackdescription.setVisible(bVisible)
end

--
-- Attack results
--

function updateAttackResult()
	local rAttackResult = ActionShipAttack.attackResultFromPendingResult(getDatabaseNode());
	if rAttackResult.bCriticalFailure then
		setAttackNote(Interface.getString("attack_result_critical_failure"))
		setHit("roll_attack_miss")
	elseif rAttackResult.bMiss then
		setAttackNote(Interface.getString("attack_result_miss"))
		setHit("roll_attack_miss")
	elseif rAttackResult.bHit then
		setAttackNote(Interface.getString("attack_result_hit"))
		setHit("roll_attack_hit")
	end
end

function isAttackResultVisible()
	local nAttackResult = DB.getValue(getDatabaseNode(), "attackscore", 0)
	local bAttackResult;
	if nAttackResult > 0 then
		bAttackResult = true;
	else
		bAttackResult = false;
	end
	return bAttackResult
end

function updateAttackVisibility()
	local bVisible = isAttackResultVisible()
	attackrow.setVisible(bVisible)
	attackscore.setVisible(bVisible)
	attackscore_label.setVisible(bVisible)
	--defensescore.setVisible(bVisible)
	defensescore_label.setVisible(false)
	-- damagearc.setVisible(false)
	attacknote.setVisible(bVisible)
	apply.setVisible(bVisible)
end

--
-- Setup attack result
--

function setHit(sIcon)
	hiticon.setIcon(sIcon)
	hiticon.setVisible(isNotBlank(sIcon) and isAttackResultVisible())
end

function setAttackNote(sText)
	attacknote.setValue(sText)
	attacknote.setVisible(isNotBlank(sText) and isAttackResultVisible())
end

--
-- Damage results
--

function isDamageResultVisible()
	local nDamageResult = DB.getValue(getDatabaseNode(), "damage", 0)
	local bDamageResult;
	if nDamageResult > 0 then
		bDamageResult = true;
	else
		bDamageResult = false;
	end
	return bDamageResult
end

function updateDamageVisibility()
	local bVisible = isDamageResultVisible()
	damagerow.setVisible(bVisible)
	damage.setVisible(bVisible)
	damage_label.setVisible(bVisible)
	-- damagearc.setVisible(true)
	apply.setVisible(bVisible)
end

--
-- Actions
--

function applyDamage()
	local nDamage = damage.getValue();
	local sArc = 'front' --damagearc.getValue();
	local nShieldDamage = DB.getValue(getCombatantNode(), "shielddamage", 0);
	local nHPDamage = DB.getValue(getCombatantNode(), "hpdamage", 0);

	local nHPTotal = DB.getValue(getCombatantNode(), "hptotal", 0);
	local aRanCrit = {};

	-- need to work out Armour value and Shields (High Guard only for those)
	-- local nShipArmour =
	local nNode = getCombatantNode();
	local nArmourValue = DB.getValue(nNode, 'armour_rating', 0);
	local nPendingNode = getDatabaseNode();
	local sTraits = DB.getValue(nPendingNode, 'traits', '');
	local sDamageType = DB.getValue(nPendingNode, 'damagetype', '');
	local sAttackDescription = DB.getValue(nPendingNode, 'attackdescription', '');

	-- Certain weapon damage ignores armour
	if sTraits:lower():match('%f[%a]ion%f[%A]') or sDamageType:lower():match('%f[%a]ion%f[%A]') then
		local sMsg = Interface.getString("sct_message_ion_damage");
		ChatManager.Message(sMsg);
		nArmourValue = 0;
	end

	local nFinalDamage = nDamage - nArmourValue;
	local nOriginalHullPoints = DB.getValue(nNode, 'hptotal', -1);
	local nHull10Percent = math.floor(nOriginalHullPoints/10 + 0.5);
	local aHullDamagePortions = {};

	-- Build an array of 10% points
	for i = 1, 10 do
		table.insert(aHullDamagePortions, nHull10Percent * i);
	end

	local nLastBand = 0;
	local nNewBand = 0;
	local nCriticalsToRoll = 1;

	-- Now work out which band they were on
	for i = 1, 10 do
		if nHPDamage < aHullDamagePortions[i] then
			nLastBand = i;
		end
		if aHullDamagePortions[i] > nHPDamage then
			break;
		end
	end

	-- Now work out which band they are going to be in
	for i = 1, 10 do
		if (nHPDamage + nFinalDamage) < aHullDamagePortions[i] then
			nNewBand = i;
		end
		if aHullDamagePortions[i] > (nHPDamage + nFinalDamage) then
			break;
		end
	end

	local bSustainedDamage = false;

	if nLastBand < nNewBand then
		bSustainedDamage = true;
		nCriticalsToRoll = nNewBand - nLastBand;
	end

	if nFinalDamage > 0 then
		if ((nFinalDamage) + nHPDamage) > nHPTotal then
			DB.setValue(getCombatantNode(), "hpdamage", "number", nHPTotal);
		else
			DB.setValue(getCombatantNode(), "hpdamage", "number", (nFinalDamage) + nHPDamage);

			local sMsg = string.format(Interface.getString("sct_pendingattack_message_pen"), nFinalDamage);
			ChatManager.Message(sMsg);
		end

		if sAttackDescription:upper():match('%[CRITICAL%]') then
			if OptionsManager.isOption("SPCRIT", "yes") then
				-- Apply critical
				SpacecraftCriticalsManager.rollForCritcal(nNode);
			end
		else
			if OptionsManager.isOption("SPACRIT", "yes") then
				-- Need to 'A ship will suffer a severity 1 critical hit everytime it loses 10% (rounded up) of its starting hull.'
				if bSustainedDamage then --nFinalDamage >= nHull10Percent and nOriginalHullPoints > 0 then
					for i = 1, nCriticalsToRoll do
						SpacecraftCriticalsManager.rollForCritcal(nNode, true);
					end
				end
			end
		end

	else
		local sMsg = string.format(Interface.getString("sct_pendingattack_message_nodam"));
		ChatManager.Message(sMsg);
	end

	removeEntry()
end

function removeEntry()
	DB.deleteNode(getDatabaseNode());
end