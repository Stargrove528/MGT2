--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function action(draginfo)
	local tParty = PartyManager.getPartyActors();
	if #tParty == 0 then
		return true;
	end
	
	local sSkill = DB.getValue("partysheet.skillselected", "");
	local sSkillCharacteristic = DB.getValue("partysheet.skillcharacteristicselected", "");

	ModifierManager.lock();
	for _,v in pairs(tParty) do
		ActionSkill.performPartySheetRoll(nil, v, sSkill, sSkillCharacteristic);
	end
	ModifierManager.unlock(true);
	return true;
end

function onButtonPress()
	return action();
end
