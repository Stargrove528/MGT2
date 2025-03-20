--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

CT_COMBATANT_PATH = "combattracker.shiplist.*";
CT_SHIPLIST = "combattracker.shiplist";
CT_PHASENUM = "combattracker.phasenumber";
CT_SHIPROUNDNUM = "combattracker.shiproundnumber";

function onInit()
	ActorManager.registerActorRecordType("charspacecraftsheet");
	ActorManager.registerActorRecordType("spacecraft");
	local tData = {
		sTrackerPath = CT_SHIPLIST,
		sCombatantParentPath = CT_SHIPLIST,
		sCombatantPath = CT_COMBATANT_PATH,
		fSort = CombatManager.sortfuncStandard,
		fCleanup = SpacecraftCombatManager.deleteCleanup,
	};
	CombatManager.setTracker("ship", tData);
	CombatManager.addPlayerRecordType("charspacecraftsheet");

	CombatRecordManager.setRecordTypeCallback("battlespacecraft", SpacecraftCombatManager.onShipBattleAdd);
	CombatRecordManager.setRecordTypeCallback("charspacecraftsheet", SpacecraftCombatManager.onPCShipAdd);
	CombatRecordManager.setRecordTypeCallback("spacecraft", SpacecraftCombatManager.onNPCShipAdd);

	DB.addHandler("charspacecraftsheet.*", "onDelete", TokenManager.deleteOwner);
	DB.addHandler("charspacecraftsheet.*", "onObserverUpdate", TokenManager.updateOwner);
end
function onTabletopInit()
	Interface.addKeyedEventHandler("onHotkeyActivated", "combattrackernextship", SpacecraftCombatManager.onHotKeyNextShipActor);
	Interface.addKeyedEventHandler("onHotkeyActivated", "combattrackernextshipphase", SpacecraftCombatManager.onHotKeyNextShipPhase);
	Interface.addKeyedEventHandler("onHotkeyActivated", "combattrackernextshipround", SpacecraftCombatManager.onHotKeyNextShipRound);
end

function onHotKeyNextShipActor()
	if Session.IsHost then
		SpacecraftCombatManager.nextShip();
	end
	return true;
end
function onHotKeyNextShipPhase()
	if Session.IsHost then
		SpacecraftCombatManager.nextPhase(1);
	end
	return true;
end
function onHotKeyNextShipRound()
	if Session.IsHost then
		SpacecraftCombatManager.nextRound(1);
	end
	return true;
end

function onShipBattleAdd(tCustom)
	SpacecraftCombatManager.addShipBattle(tCustom);
	return true;
end
function onPCShipAdd(tCustom)
	SpacecraftCombatManager.addPCShip(tCustom);
	return true;
end
function onNPCShipAdd(tCustom)
	SpacecraftCombatManager.addNPCShip(tCustom);
	return true;
end

function deleteCleanup(v)
	-- Clear any effects first, so that saves aren't triggered when initiative advanced
	DB.deleteChildren(v, "effects");

	-- Move to the next actor, if this CT entry is active
	if CombatManager.isActive(v) then
		SpacecraftCombatManager.nextShip();
	end
end

--
-- TURN FUNCTIONS
--

-- Handle turn notification (including bell ring based on option)
function showPhaseMessage(nodeEntry, bActivate, bSkipBell)
	local rActor = ActorManager.resolveActor(nodeEntry);
	local sName = ActorManager.getDisplayName(rActor);
	local sClass, sRecord = DB.getValue(nodeEntry, "link", "", "");
	local sFaction = DB.getValue(nodeEntry, "friendfoe", "");
	local bHidden = CombatManager.isCTHidden(nodeEntry);

	local msg = {font = "narratorfont", icon = "turn_flag"};
	msg.text = string.format("[%s] %s", Interface.getString("combat_tag_turn"), sName);
	if OptionsManager.isOption("RSHE", "on") then
		local sEffects = EffectManager.getEffectsString(nodeEntry, true);
		if sEffects ~= "" then
			msg.text = msg.text .. " - [" .. sEffects .. "]";
		end
	end
	if bHidden then
		msg.secret = true;
		Comm.addChatMessage(msg);
	else
		Comm.deliverChatMessage(msg);
	end

	if bActivate and not bSkipBell and not bHidden and OptionsManager.isOption("RING", "on") and CombatManager.isPlayerCT(nodeEntry) then
		local nodePC = ActorManager.getCreatureNode(rActor);
		if nodePC then
			local sOwner = DB.getOwner(nodePC);
			if (sOwner or "") ~= "" then
				User.ringBell(sOwner);
			end
		end
	end
end
function requestShipActivation(nodeEntry, bSkipBell)
	-- De-activate all other entries
	for _,v in pairs(CombatManager.getCombatantNodes("ship")) do
		DB.setValue(v, "active", "number", 0);
	end

	-- Set active flag
	DB.setValue(nodeEntry, "active", "number", 1);

	-- Turn notification
	showPhaseMessage(nodeEntry, true, bSkipBell);
end
function nextShip(bSkipBell, bNoRoundAdvance)
	if not Session.IsHost then
		return;
	end

	local nodeActive = CombatManager.getActiveCT("ship");
	local nIndexActive = 0;

	-- Check the skip hidden NPC option
	local bSkipHidden = OptionsManager.isOption("CTSH", "on");

	-- Determine the next actor
	local nodeNext = nil;
	local aEntries = CombatManager.getSortedCombatantList("ship");
	if #aEntries > 0 then
		if nodeActive then
			for i = 1,#aEntries do
				if aEntries[i] == nodeActive then
					nIndexActive = i;
					break;
				end
			end
		end
		if bSkipHidden then
			local nIndexNext = 0;
			for i = nIndexActive + 1, #aEntries do
				if DB.getValue(aEntries[i], "friendfoe", "") == "friend" then
					nIndexNext = i;
					break;
				else
					if not CombatManager.isCTHidden(aEntries[i]) then
						nIndexNext = i;
						break;
					end
				end
			end
			if nIndexNext > nIndexActive then
				nodeNext = aEntries[nIndexNext];
				for i = nIndexActive + 1, nIndexNext - 1 do
					showPhaseMessage(aEntries[i], false);
				end
			end
		else
			nodeNext = aEntries[nIndexActive + 1];
		end
	end

	-- If next actor available, advance effects, activate and start turn
	if nodeNext then
		-- Start turn for next actor
		requestShipActivation(nodeNext, bSkipBell);
	elseif not bNoRoundAdvance then
		if bSkipHidden then
			for i = nIndexActive + 1, #aEntries do
				showPhaseMessage(aEntries[i], false);
			end
		end
		nextPhase(1);
	end
end
function nextPhase(nRounds)
	if not Session.IsHost then
		return;
	end

	local nodeActive = CombatManager.getActiveCT("ship");
	local nRoundCurrent = DB.getValue(CT_SHIPROUNDNUM, 0);
	local nPhaseCurrent = DB.getValue(CT_PHASENUM, 0);

	-- If current actor, then advance based on that
	local nStartCounter = 1;
	local aEntries = CombatManager.getSortedCombatantList("ship");
	if nodeActive then
		DB.setValue(nodeActive, "active", "number", 0);

		local bFastTurn = false;
		for i = 1,#aEntries do
			if aEntries[i] == nodeActive then
				bFastTurn = true;
			end
		end

		nStartCounter = nStartCounter + 1;

		-- Announce round
		nPhaseCurrent = nPhaseCurrent + 1;
		if nPhaseCurrent > 2 then
			nPhaseCurrent = 0;
			nRoundCurrent = nRoundCurrent + 1;
		end

		local msg = {font = "narratorfont", icon = "turn_flag"};
		msg.text = Interface.getString("sct_spacecraft_phase" .. nPhaseCurrent) .. " " .. "[ROUND " .. nRoundCurrent .. "]";
		Comm.deliverChatMessage(msg);
	end
	for i = nStartCounter, nRounds do
		-- Announce round
		nPhaseCurrent = nPhaseCurrent + 1;
		if nPhaseCurrent == 2 then

		elseif nPhaseCurrent > 3 then
			nPhaseCurrent = 0;
			nRoundCurrent = nRoundCurrent + 1;
		end

		local msg = {font = "narratorfont", icon = "turn_flag"};
		msg.text = Interface.getString("sct_spacecraft_phase" .. nPhaseCurrent) .. " " .. "[ROUND " .. nRoundCurrent .. "]";
		Comm.deliverChatMessage(msg);
	end

	-- Update round counter
	DB.setValue(CT_PHASENUM, "number", nPhaseCurrent);
	DB.setValue(CT_SHIPROUNDNUM, "number", nRoundCurrent);

	-- Check option to see if we should advance to first actor or stop on round start
	if OptionsManager.isOption("RNDS", "off") then
		local bSkipBell = (nRounds > 1);
		if #aEntries > 0 then
			nextShip(bSkipBell, true);
		end
	end
end
function setRound(nRound)
	if not Session.IsHost then
		return;
	end

	-- Update round counter
	DB.setValue(CT_PHASENUM, "number", 0);
	DB.setValue(CT_SHIPROUNDNUM, "number", nRound);
end
function nextRound(nRounds)
	if not Session.IsHost then
		return;
	end

	local nodeActive = CombatManager.getActiveCT("ship");
	local nRoundCurrent = DB.getValue(CT_SHIPROUNDNUM, 0);
	local nPhaseCurrent = DB.getValue(CT_PHASENUM, 0);

	-- If current actor, then advance based on that
	local nStartCounter = 1;
	local aEntries = CombatManager.getSortedCombatantList("ship");
	if nodeActive then
		DB.setValue(nodeActive, "active", "number", 0);

		local bFastTurn = false;
		for i = 1,#aEntries do
			if aEntries[i] == nodeActive then
				bFastTurn = true;
			end
		end

		nStartCounter = nStartCounter + 1;

		-- Announce round
		nPhaseCurrent = 0;

		nRoundCurrent = nRoundCurrent + 1;

		local msg = {font = "narratorfont", icon = "turn_flag"};
		msg.text = Interface.getString("sct_spacecraft_phase0") .. " " .. "[ROUND " .. nRoundCurrent .. "]";
		Comm.deliverChatMessage(msg);
	end
	for i = nStartCounter, nRounds do
		-- Announce round
		nPhaseCurrent = 0;

		nRoundCurrent = nRoundCurrent + 1;

		local msg = {font = "narratorfont", icon = "turn_flag"};
		msg.text = Interface.getString("sct_spacecraft_phase0") .. " " .. "[ROUND " .. nRoundCurrent .. "]";
		Comm.deliverChatMessage(msg);
	end

	-- Update round counter
	DB.setValue(CT_PHASENUM, "number", nPhaseCurrent);
	DB.setValue(CT_SHIPROUNDNUM, "number", nRoundCurrent);

	-- Check option to see if we should advance to first actor or stop on round start
	if OptionsManager.isOption("RNDS", "off") then
		local bSkipBell = (nRounds > 1);
		if #aEntries > 0 then
			nextShip(bSkipBell, true);
		end
	end
end

--
-- ADD FUNCTIONS
--

function addShipBattle(tCustom)
	-- Setup
	if not tCustom.nodeRecord then
		return;
	end
	tCustom.sListPath = LibraryData.getCustomData("battlespacecraft", "spacecraftlist") or "spacecraftlist";

	-- Handle module load, since battle entries are "linked", not copied.
	tCustom.fLoadCallback = SpacecraftCombatManager.addShipBattle;
	if CombatRecordManager.handleBattleModuleLoad(tCustom) then
		return;
	end

	-- Clean up any placement tokens from an open battle window
	CombatRecordManager.clearBattlePlacementTokens(tCustom);

	-- Standard handling
	CombatRecordManager.addBattleHelper(tCustom);

	-- Open combat tracker
	Interface.openWindow("ct_ship_combat", "combattracker");
end

function addPCShip(tCustom)
	-- Parameter validation
	if not tCustom.nodeRecord then
		return;
	end

	-- Standard handling
	tCustom.sTrackerKey = "ship";
	CombatRecordManager.handleStandardCombatAdd(tCustom);
	if not tCustom.nodeCT then
		return;
	end
	
	CombatRecordManager.handleStandardCombatAddPCFields(tCustom);

	tCustom.sFinalName = DB.getValue(tCustom.nodeRecord, "name", "");
	CombatRecordManager.handleStandardCombatAddToken(tCustom);

	CombatRecordManager.handleStandardCombatAddPlacement(tCustom);
end
function addNPCShip(tCustom)
	-- Parameter validation
	if not tCustom.nodeRecord then
		return;
	end

	-- Standard handling
	tCustom.sTrackerKey = "ship";
	CombatRecordManager.handleStandardCombatAdd(tCustom);
	if not tCustom.nodeCT then
		return;
	end

	CombatRecordManager.handleStandardCombatAddFields(tCustom);
	CombatRecordManager.handleStandardCombatAddSpaceReach(tCustom);

	DB.setValue(tCustom.nodeCT, "hptotal", "number", DB.getValue(tCustom.nodeRecord, "hull_points", 0));

	CombatRecordManager.handleStandardCombatAddPlacement(tCustom);

	return nodeEntry;
end

--
-- RESET FUNCTIONS
--

function resetInit()
	-- De-activate all entries
	for _,v in pairs(CombatManager.getCombatantNodes("ship")) do
		DB.setValue(v, "active", "number", 0);
		DB.setValue(v, "initresult", "number", 0);
	end

	-- Reset the round counter
	DB.setValue(CT_PHASENUM, "number", 0);
	DB.setValue(CT_SHIPROUNDNUM, "number", 1);
end
function rollInit(sType)
	for _,vChild in ipairs(DB.getChildList(SpacecraftCombatManager.CT_SHIPLIST)) do
		local bRoll = true;
		if sType then
			local sClass,_ = DB.getValue(vChild, "link", "", "");
			if sType == "npc" and sClass == "charsheet" then
				bRoll = false;
			elseif sType == "pc" and sClass ~= "charsheet" then
				bRoll = false;
			end
		end

		if bRoll then
			DB.setValue(vChild, "initresult", "number", -10000);
			DB.setValue(vChild, "initresult_saved", "number", -10000);
			DB.setValue(vChild, "init_mod", "number", 0);
		end
	end

	for _,vChild in ipairs(DB.getChildList(SpacecraftCombatManager.CT_SHIPLIST)) do
		local bRoll = true;
		if sType then
			local sClass,_ = DB.getValue(vChild, "link", "", "");
			if sType == "npc" and sClass == "charsheet" then
				bRoll = false;
			elseif sType == "pc" and sClass ~= "charsheet" then
				bRoll = false;
			end
		end

		if bRoll then
			rollEntryInit(vChild);
		end
	end
end
function rollEntryInit(nodeEntry)
	if not nodeEntry then
		return;
	end

	-- Start with the base initiative bonus
	local nInit = DB.getValue(nodeEntry, "init", 0);
	local nInitMod = 0;

	-- Get any effect modifiers
	local rActor = ActorManager.resolveActor(nodeEntry);

	-- For PCs, we always roll unique initiative
	local sClass, sRecord = DB.getValue(nodeEntry, "link", "", "");
	if sClass == "charsheet" then

		local _,sCharLink = DB.getValue(nodeEntry, "link", "");
		local nInitBonus = DB.getValue(DB.findNode(sCharLink), "initiative", 0);

		local nDexDM = DB.getValue(nodeEntry, "attributes.dex_mod", 0);
		local nIntDM = DB.getValue(nodeEntry, "attributes.int_mod", 0);

		local nInitMod = nDexDM;
		if nIntDM > nInitMod then
			nInitMod = nIntDM;
		end
		local nInitResult = rollRandomInit(nInitMod, nInitBonus);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		DB.setValue(nodeEntry, "initresult_saved", "number", nInitResult);
		DB.setValue(nodeEntry, "init_mod", "number", 0);
		return;
	end

	-- For NPCs, if NPC init option is not group, then roll unique initiative
	local sOptINIT = OptionsManager.getOption("INIT");
	if sOptINIT ~= "group" then

		local sType = DB.getValue(nodeEntry, "type", "unknown");
		nInitMod = getInitMod(nodeEntry, sType);

		local nInitResult = rollRandomInit(nInitMod);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		DB.setValue(nodeEntry, "initresult_saved", "number", nInitResult);
		DB.setValue(nodeEntry, "init_mod", "number", 0);
		return;
	end

	-- For NPCs with group option enabled

	-- Get the entry's database node name and creature name
	local sStripName = CombatManager.stripCreatureNumber(DB.getValue(nodeEntry, "name", ""));
	if sStripName == "" then

		local sType = DB.getValue(nodeEntry, "type", "unknown");

		nInitMod = getInitMod(nodeEntry, sType);

		local nInitResult = rollRandomInit(nInitMod);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		DB.setValue(nodeEntry, "initresult_saved", "number", nInitResult);
		DB.setValue(nodeEntry, "init_mod", "number", 0);
		return;
	end

	-- Iterate through list looking for other creature's with same name
	local nLastInit = nil;
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		if DB.getName(v) ~= DB.getName(nodeEntry) then
			local sTemp = CombatManager.stripCreatureNumber(DB.getValue(v, "name", ""));
			if sTemp == sStripName then
				local nChildInit = DB.getValue(v, "initresult", 0);
				if nChildInit ~= -10000 then
					nLastInit = nChildInit;
				end
			end
		end
	end

	-- If we found similar creatures, then match the initiative of the last one found
	if nLastInit then
		DB.setValue(nodeEntry, "initresult", "number", nLastInit);
		DB.setValue(nodeEntry, "initsaved", "number", nLastInit);
		DB.setValue(nodeEntry, "init_mod", "number", 0);
	else
		local sType = DB.getValue(nodeEntry, "type", "unknown");

		nInitMod = getInitMod(nodeEntry, sType);

		local nInitResult = rollRandomInit(nInitMod);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		DB.setValue(nodeEntry, "initresult_saved", "number", nInitResult);
		DB.setValue(nodeEntry, "init_mod", "number", 0);
	end
end
function getInitMod(nodeEntry, sType)
	local nInitMod = 0;
	local nThrustMod = 0;

	-- ships thrust is a mod for init
	for _,vItem in ipairs(DB.getChildList(nodeEntry, "details")) do
		local sDetail = DB.getValue(vItem, "name", ""):lower();
		if sDetail == "m-drive" then

			local sMDriveDetail = DB.getValue(vItem, "detail", "");
			local _,sThrust = sMDriveDetail:lower():match("(thrust)%s(%d+)")

			nThrustMod = tonumber(sThrust);
		end
	end

	nInitMod = nInitMod + nThrustMod;

	return nInitMod;
end
function rollRandomInit(nInitDM, nInitBonus)
	if not nInitBonus then
		nInitBonus = 0;
	end

	local nInitResult = 0;

	for i=1,2 do
		nInitResult = nInitResult + math.random(6);
	end

	nInitResult = nInitResult + nInitBonus;

	return nInitResult;
end

--
-- MISC
--

function handleDrop(draginfo, sTargetPath)
	if ((sTargetPath or "") == "") or not draginfo then
		return false;
	end
	if StringManager.contains(GameSystem.spacecrafttargetactions, draginfo.getType()) then
		ActionsManager.actionDrop(draginfo, ActorManager.resolveActor(sTargetPath));
		return true;
	end
	return false;
end
