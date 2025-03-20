--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATK = "applyatk";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATK, handleApplyAttack);

	ActionsManager.registerTargetingHandler("attack", onTargeting);
	ActionsManager.registerModHandler("attack", modAttack);
	ActionsManager.registerResultHandler("attack", onAttack);
end

function handleApplyAttack(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	local rRoll = UtilityManager.decodeRollFromOOB(msgOOB);
	ActionAttack.applyAttack(rSource, rTarget, rRoll);
end
function notifyApplyAttack(rSource, rTarget, rRoll)
	if not rTarget then
		return;
	end

	rRoll.sResults = table.concat(rRoll.aMessages, " ");
	
	local msgOOB = UtilityManager.encodeRollToOOB(rRoll);
	msgOOB.type = ActionAttack.OOB_MSGTYPE_APPLYATK;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	Comm.deliverOOBMessage(msgOOB, "");
end

function onTargeting(rSource, aTargeting, rRolls)
	local bRemoveOnMiss = false;
	local sOptRMMT = OptionsManager.getOption("RMMT");
	if sOptRMMT == "on" then
		bRemoveOnMiss = true;
	elseif sOptRMMT == "multi" then
		local aTargets = {};
		for _,vTargetGroup in ipairs(aTargeting) do
			for _,vTarget in ipairs(vTargetGroup) do
				table.insert(aTargets, vTarget);
			end
		end
		bRemoveOnMiss = (#aTargets > 1);
	end

	if bRemoveOnMiss then
		for _,vRoll in ipairs(rRolls) do
			vRoll.bRemoveOnMiss = true;
		end
	end

	return aTargeting;
end

function modAttack(rSource, rTarget, rRoll)
	clearCritState(rSource);

	local aAddDesc = {};
	local nAddMod = 0;
	local nSizeModifier = 0;
	local bCover, bRange, bCrossFire, bFireIntoMelee, bHigherGround, bObscured, bPinned, nProne, bSuppresiveFire = false;
	local bFlank, bHelpless, bSneak;
	local sSizeModifier = '';
	local aAttackFilter = {};

	if rSource then
		local sSourceNode = ActorManager.getCreatureNodeName(rSource);

		-- Determine attack type
		local sAttackType = string.match(rRoll.sDesc, "%[ATTACK.*%((%w+)%)%]");
		if not sAttackType then
			sAttackType = "M";
		end

		-- Check for Size modifiers
		local nodeTargetCT = ActorManager.getCTNode(rTarget);
		local sTargetTraits = DB.getValue(nodeTargetCT, "traits", "none"):lower();
		local aTargetTraits = StringManager.split(sTargetTraits, ",", true);

		for i = 1, #aTargetTraits do

			sTargetTrait = aTargetTraits[i]:lower();

			if string.find(sTargetTrait, "large%s*(.%d*)") then
				nSizeModifier = tonumber(string.match(sTargetTrait, "([%+%-]?%d+)/?"));
				sSizeModifier = sTargetTrait;
				break;
			end
			if string.find(sTargetTrait, "small%s*(.%d*)") then
				nSizeModifier = tonumber(string.match(sTargetTrait, "([%+%-]?%d+)/?"));
				sSizeModifier = sTargetTrait;
				break;
			end
		end

		-- Check modifiers
		-- BONUSES
		bAim1 = ModifierStack.getModifierKey("BON_AIMING_1");
		bAim2 = ModifierStack.getModifierKey("BON_AIMING_2");
		bAim3 = ModifierStack.getModifierKey("BON_AIMING_3");
		bLaserSight = ModifierStack.getModifierKey("BON_LASER_SIGHT");
		bShortRange = ModifierStack.getModifierKey("BON_SHORT_RANGE");

		if bAim1 then
			table.insert(aAddDesc, "\n [AIM +1]");
			nAddMod = nAddMod + 1;
		end
		if bAim2 then
			table.insert(aAddDesc, "\n [AIM +2]");
			nAddMod = nAddMod + 2;
		end
		if bAim3 then
			table.insert(aAddDesc, "\n [AIM +3]");
			nAddMod = nAddMod + 3;
		end
		if bLaserSight then
			table.insert(aAddDesc, "\n [LASER SIGHT +1]");
			nAddMod = nAddMod + 1;
		end
		if bShortRange then
			table.insert(aAddDesc, "\n [SHORT RANGE +1]");
			nAddMod = nAddMod + 1;
		end

		-- PENALTIES
		bCover = ModifierStack.getModifierKey("PEN_COVER");
		bRange1 = ModifierStack.getModifierKey("PEN_LONG_RANGE");
		bRange2 = ModifierStack.getModifierKey("PEN_EXTREME_RANGE");
		bProne = ModifierStack.getModifierKey("PEN_PRONE");
		bMovement1 = ModifierStack.getModifierKey("PEN_FAST_MOVING_1");
		bMovement2 = ModifierStack.getModifierKey("PEN_FAST_MOVING_2");
		bMovement3 = ModifierStack.getModifierKey("PEN_FAST_MOVING_3");
		bMovement4 = ModifierStack.getModifierKey("PEN_FAST_MOVING_4");

		if bCover then
			table.insert(aAddDesc, "\n [COVER -2]");
			nAddMod = nAddMod -2;
		end
		if bRange1 then
			table.insert(aAddDesc, "\n [LONG RANGE -2]");
			nAddMod = nAddMod -2;
		end
		if bRange2 then
			table.insert(aAddDesc, "\n [EXTREME RANGE -4]");
			nAddMod = nAddMod -4;
		end
		if bProne then
			table.insert(aAddDesc, "\n [PRONE TARGET -1]");
			nAddMod = nAddMod -1;
		end
		if bMovement1 then
			table.insert(aAddDesc, "\n [FAST MOVING -1]");
			nAddMod = nAddMod -1;
		end
		if bMovement2 then
			table.insert(aAddDesc, "\n [FAST MOVING -2]");
			nAddMod = nAddMod -2;
		end
		if bMovement3 then
			table.insert(aAddDesc, "\n [FAST MOVING -3]");
			nAddMod = nAddMod -3;
		end
		if bMovement4 then
			table.insert(aAddDesc, "\n [FAST MOVING -4]");
			nAddMod = nAddMod -4;
		end

		-- Get weapon traits
		local sTraits = rRoll.sWeaponTraits
		local aSourceTraits = StringManager.split(sTraits, ",", true);
		for i = 1, #aSourceTraits do
			sSourceTrait = aSourceTraits[i]:lower();

			if string.find(sSourceTrait, "very bulky") then
				local nStrength = DB.getValue(DB.findNode(sSourceNode), "attributes.strength", 0);
				local nVBulkyDM = 2;
				local nStrengthDM = GameSystem.calculateCharacteristicDM(nStrength);
				if nStrengthDM < nVBulkyDM then
					table.insert(aAddDesc, "[VERY BULKY " .. (nStrengthDM - nVBulkyDM) .."]");
					nAddMod = nAddMod + (nStrengthDM - nVBulkyDM)
				end
				break;
			end

			if string.find(sSourceTrait, "bulky") then
				local nStrength = DB.getValue(DB.findNode(sSourceNode), "attributes.strength", 0);
				local nBulkyDM = 1;
				local nStrengthDM = GameSystem.calculateCharacteristicDM(nStrength);
				if nStrengthDM < nBulkyDM then
					table.insert(aAddDesc, "[BULKY " .. (nStrengthDM - nBulkyDM) .."]");
					nAddMod = nAddMod + (nStrengthDM - nBulkyDM)
				end
				break;
			end
		end

		-- Get attack effect modifiers
		local bEffects = false;
		local nEffectsMod = 0;

		if EffectManagerTraveller.hasEffectCondition(rSource, "Fatigued") then
			bEffects = true;
			-- this is now Bane
			table.insert(aAddDesc,"[BANE]");
			table.insert(rRoll.aDice, "d6");
		end

		if EffectManagerTraveller.hasEffectCondition(rSource, "Head major wound") then
			bEffects = true;
			table.insert(aAddDesc,"[Head Major Wound, -1 DM]");
			nEffectsMod = nEffectsMod -1;
		end

		if EffectManagerTraveller.hasEffectCondition(rSource, "Arms severe wound") then
			bEffects = true;
			table.insert(aAddDesc,"[Arms Severe Wound, -1 DM]");
			nEffectsMod = nEffectsMod -1;
		elseif EffectManagerTraveller.hasEffectCondition(rSource, "Arms major wound") then
			bEffects = true;
			table.insert(aAddDesc,"[Arms Major Wound, -1 DM]");
			nEffectsMod = nEffectsMod -1;
		end

		-- Any attack uses STR or DEX, both are Physical
		if EffectManagerTraveller.hasEffectCondition(rSource, "Torso severe wound") then
			bEffects = true;
			table.insert(aAddDesc,"[Torso Severe Wound, -2 DM]");
			nEffectsMod = nEffectsMod -2;
		elseif EffectManagerTraveller.hasEffectCondition(rSource, "Torso major wound") then
			bEffects = true;
			table.insert(aAddDesc,"[Torso Major Wound, -2 DM]");
			nEffectsMod = nEffectsMod -1;
		end

		-- Is the Target Prone or In Cover?
		if EffectManagerTraveller.hasEffectCondition(rTarget, "Prone target") then
			bEffects = true;
			table.insert(aAddDesc,"[Prone target, -1 DM]");
			nEffectsMod = nEffectsMod -1;
		end
		if EffectManagerTraveller.hasEffectCondition(rTarget, "Target in cover") then
			bEffects = true;
			table.insert(aAddDesc,"[Target in cover, -2 DM]");
			nEffectsMod = nEffectsMod -2;
		end

		if sAttackType == "P" then
			rRoll.bIgnoreArmour = true;
		end

		local nOverrideValue, sOverrideStat = ActionsManager2.endcodeDesktopAttributes(rRoll, sSourceNode)

		-- Determine ability used with this skill
		if sOverrideStat ~= "" then
			rRoll.sDesc = rRoll.sDesc .. " [OVERRIDE - " .. sOverrideStat
			if nOverrideValue < 0 then
				if rRoll.nMod - nOverrideValue < 0 then
					rRoll.sDesc = rRoll.sDesc .. " = 2D" .. rRoll.nMod - nOverrideValue .. "]";
				elseif rRoll.nMod - nOverrideValue == 0 then
					rRoll.sDesc = rRoll.sDesc .. " = 2D]";
				else
					rRoll.sDesc = rRoll.sDesc .. " = 2D+" .. rRoll.nMod - nOverrideValue .. "]";
				end

			else
				rRoll.sDesc = rRoll.sDesc .. "= 2D+" .. rRoll.nMod + nOverrideValue .. "]";
			end

			-- Seems like a hack but it'll do for now
			rRoll.nMod = rRoll.nMod - (rRoll.nStatMod or 0) + nOverrideValue
		end

		if bEffects then
			rRoll.nMod = rRoll.nMod + nEffectsMod
			table.insert(aAddDesc, EffectManager.buildEffectOutput(nEffectsMod));
		end

		local nSkillDifferenceDM = CharManager.getArmourWornModifier(sSourceNode)

		if nSkillDifferenceDM < 0 then
			rRoll.sDesc = rRoll.sDesc .. "[Armour " .. nSkillDifferenceDM .. "]";
			rRoll.nMod = rRoll.nMod + nSkillDifferenceDM;
		end

		if nSizeModifier ~= 0 then
			table.insert(aAddDesc, string.format("[%s]", StringManager.capitalize(sSizeModifier)));
			nAddMod = nAddMod + nSizeModifier;
		end

		-- Build attack filter
		if sAttackType == "M" then
			table.insert(aAttackFilter, "melee");
		elseif sAttackType == "R" then
			table.insert(aAttackFilter, "ranged");
		end

	end

	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end

	ActionsManager2.encodeDesktopMods(rRoll);

	rRoll.nMod = rRoll.nMod + nAddMod;

	rRoll.bTestTrue = true;
	rRoll.bTestFalse = false;
end

function onAttack(rSource, rTarget, rRoll)
	ActionAttack.decodeAttackRoll(rRoll);
	
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");

	local bIsSourcePC = (rSource and rSource.sType == "pc");

	rRoll.nTotal = ActionsManager.total(rRoll);
	rRoll.aMessages = {};

	if rRoll.sDamage and rRoll.sDamage:upper():match("DD") then
		rRoll.bDestructive = true;
	else
		rRoll.bDestructive = false;
	end

	rMessage.effectresulttext = '';

	if rRoll.nTotal >= 8 then
		rRoll.sResult = "hit";
		rMessage.effectresulttext = "[HIT]";
	else
		rRoll.sResult = "miss";
		rMessage.effectresulttext = "[MISS]";
	end

	local nEffect = rRoll.nTotal - 8;
	local nBurstDamage = 0;
	local sTraits = rRoll.sWeaponTraits or "";
	local srateoffire = rRoll.sWeaponrateoffire;
	local sAutoTrait = sTraits:match("%auto %d+");

	if (sAutoTrait or "") ~= "" then
		if srateoffire == "burst" then
			nBurstDamage = string.match(sAutoTrait, "%d+")
			rMessage.text = rMessage.text .. " [Burst + " .. nBurstDamage .." DMG]";
		end
	end

	-- Was this rolled with an effect of 6+
	if rRoll.nTotal >= 14 then
		table.insert(rRoll.aMessages, "[MIN DAMAGE 1]");
	end

	if not rTarget then
		rMessage.text = rMessage.text .. " " .. table.concat(rRoll.aMessages, " ");
	end

	Comm.deliverChatMessage(rMessage);

	if nEffect >= 0 then
		if nEffect == 0 then
			rMessage.effectresulttext = rMessage.effectresulttext .. " [Marginal Success]";
		elseif (nEffect >= 1) and (nEffect <= 5) then
			if rRoll.bDestructive then
				rMessage.effectresulttext = rMessage.effectresulttext .. " [Average Success]";
			else
				rMessage.effectresulttext = rMessage.effectresulttext .. " [Average Success +" .. nEffect .. " DMG]";
			end
		elseif nEffect >= 6 then
			if rRoll.bDestructive then
				rMessage.effectresulttext = rMessage.effectresulttext .. " [Exceptional Success]";
			else
				rMessage.effectresulttext = rMessage.effectresulttext .. " [Exceptional Success +" .. nEffect .. " DMG]";
			end
		end
		if not rRoll.bDestructive then
			setCritState(rSource, nEffect + nBurstDamage);
		end
		if OptionsManager.isOption("COMPHL", "yes") then
			if rTarget and rTarget.sType == "charsheet" then
				ActionHitLocation.rollForHitLocation(ActorManager.getCTNodeName(rTarget));
			end
		end
	else
		if nEffect < 0 then
			if OptionsManager.isOption("COMPMISHAPS", "yes") then
				if rRoll.aDice[1].value == 1 and rRoll.aDice[2].value == 1 then
					rMessage.effectresulttext = rMessage.effectresulttext .. " [Combat Mishap]";
					ActionCombatMishaps.rollForMishap(ActorManager.getCTNodeName(rSource), rRoll.nMod);
				end
			end
		end
	end

	local bShowResultsToPlayer;
	local sOptSHRR = OptionsManager.getOption("SHRR");
	if sOptSHRR == "off" then
		bShowResultsToPlayer = false;
	elseif sOptSHRR == "pc" then
		bShowResultsToPlayer = (not rSource or ActorManager.isFaction(rSource, "friend")) or (not rTarget or ActorManager.isFaction(rTarget, "friend"));
	else
		bShowResultsToPlayer = true;
	end

	if bShowResultsToPlayer then
		local msg = {
			font = "narratorfont",
			text = rMessage.effectresulttext,
		};
		Comm.deliverChatMessage(msg);
	end

	-- Get weapon traits
	local aSourceTraits = StringManager.split(sTraits, ",", true);
	for i = 1, #aSourceTraits do
		sSourceTrait = aSourceTraits[i]:lower();
		if sSourceTrait:match("dangerous") then
			if nEffect <= -5 then
				local msg = {
					font = "narratorfont",
					text = "Dangerous weapon EXPLODES!",
					};
				Comm.deliverChatMessage(msg);
			end
			break;
		end
	end

	if rTarget then
		notifyApplyAttack(rSource, rTarget, rRoll);
	end

	-- REMOVE TARGET ON MISS OPTION
	if rTarget and rRoll.bRemoveOnMiss and (rRoll.sResult == "miss") then
		TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
	end
end

function decodeAttackRoll(rRoll)
	-- Rebuild detail fields if dragging from chat window
	if not rRoll.nOrder then
		rRoll.nOrder = tonumber(rRoll.sDesc:match("%[ATTACK.-#(%d+)")) or nil;
	end
	if not rRoll.sRange then
		rRoll.sRange = rRoll.sDesc:match("%[ATTACK.-%((%w+)%)%]");
	end
	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[ATTACK.-%]([^%[]+)"));
	end
end

function applyAttack(rSource, rTarget, rRoll)
	local msgShort = { font = "msgfont" };
	local msgLong = { font = "msgfont" };
	
	msgShort.text = "Attack";
	msgLong.text = "Attack";
	if rRoll.nOrder then
		msgShort.text = string.format("%s #%d", msgShort.text, rRoll.nOrder);
		msgLong.text = string.format("%s #%d", msgLong.text, rRoll.nOrder);
	end
	if (rRoll.sRange or "") ~= "" then
		msgShort.text = string.format("%s (%s)", msgShort.text, rRoll.sRange);
		msgLong.text = string.format("%s (%s)", msgLong.text, rRoll.sRange);
	end
	if (rRoll.sLabel or "") ~= "" then
		msgShort.text = string.format("%s (%s)", msgShort.text, rRoll.sLabel or "");
		msgLong.text = string.format("%s (%s)", msgLong.text, rRoll.sLabel or "");
	end
	msgLong.text = string.format("%s [%d]", msgLong.text, rRoll.nTotal or 0);

	-- Targeting information
	msgShort.text = string.format("%s ->", msgShort.text);
	msgLong.text = string.format("%s ->", msgLong.text);
	if rTarget then
		local sTargetName = ActorManager.getDisplayName(rTarget);
		msgShort.text = string.format("%s [at %s]", msgShort.text, sTargetName);
		msgLong.text = string.format("%s [at %s]", msgLong.text, sTargetName);
	end

	-- Extra roll information
	msgShort.icon = "roll_attack";
	if (rRoll.sResults or "") ~= "" then
		msgLong.text = string.format("%s %s", msgLong.text, rRoll.sResults);
		if rRoll.sResults:match("HIT%]") then
			msgLong.icon = "roll_attack_hit";
		elseif rRoll.sResults:match("MISS%]") then
			msgLong.icon = "roll_attack_miss";
		else
			msgLong.icon = "roll_attack";
		end
	else
		msgLong.icon = "roll_attack";
	end

	ActionsManager.outputResult(rRoll.bTower, rSource, rTarget, msgLong, msgShort);
end

aCritState = {};
aEffectMod = {};

function setCritState(rSource, nEffectModifier)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	if nEffectModifier >= 0 then
		aCritState[sSourceCT] = true;
	end
	aEffectMod[sSourceCT] = nEffectModifier;
end

function clearCritState(rSource)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT ~= "" then
		aCritState[sSourceCT] = nil;
		aEffectMod[sSourceCT] = 0;
	end
end

function isCrit(rSource, bClearState)
	--return true;
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return false;
	end
	local bState = aCritState[sSourceCT];
	local nEffectModifier = aEffectMod[sSourceCT];
	if bState and bClearState then
		aCritState[sSourceCT] = nil;
		aEffectMod[sSourceCT] = 0;
	end
	return bState, nEffectModifier;
end