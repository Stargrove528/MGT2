--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("dice", modRoll);
	ActionsManager.registerResultHandler("dice", onRoll);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end

function modRoll(rSource, rTarget, rRoll)
	ActionsManager2.encodeDesktopMods(rRoll);

	if #(rRoll.aDice) == 2 and rRoll.aDice[1].type == "d6" and rRoll.aDice[2].type == "d6" then
		ActionsManager2.encodeAdvantage(rRoll);
	end
end

function onRoll(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end
