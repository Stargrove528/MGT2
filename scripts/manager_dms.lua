--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- This file holds the common functions for calculating DM's for non chars/npc attributes

function onSourceUpdate()
	local nValue = calculateSources();
	setValue(GameSystem.calculateCharacteristicDM(nValue))

    ActionsManager.registerResultHandler("crewmorale", onCrewMorale);
end

function action(draginfo)
	local nTotal = getValue();
	local sAttribute = getName();
	local rActor = ActorManager.resolveActor(window.getDatabaseNode());

    performRoll(draginfo, rActor);
end

function onDoubleClick(x, y)
	action();
	return true;
end

function onDragStart(button, x, y, draginfo)
	action(draginfo);
	return true;
end

function onCrewMorale(rSource, rTarget, rRoll)
    ActionsManager2.decodeAdvantage(rRoll);

    local nTotal = ActionsManager.total(rRoll);

    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

    Comm.deliverChatMessage(rMessage);
end

function performRoll(draginfo, rActor)
	local rRoll = getRoll(rActor);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor)
	local rRoll = {};

	rRoll.sType = "crewmorale";
	rRoll.aDice = DiceRollManager.getActorDice({ "d6", "d6" }, rActor);
	rRoll.nMod = 0;
	rRoll.sDesc = "[CREW MORALE]";

    ActionsManager2.encodeDesktopMods(rRoll);

    -- Boon/Bane
    ActionsManager2.encodeAdvantage(rRoll);

	return rRoll;
end
