--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function action(draginfo)
	local tParty = PartyManager.getPartyActors();
	if #tParty == 0 then
		return true;
	end

	local sAbilityStat = DB.getValue("partysheet.checkselected", ""):lower();

	ModifierManager.lock();
	for _,v in pairs(tParty) do
		ActionsCharacteristics.performPartySheetRoll(nil, v, sAbilityStat);
	end
	ModifierManager.unlock(true);

	return true;
end

function onButtonPress()
	return action();
end
