-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ItemManager.setEncumbranceFields("charsheet", { "carried", "count", "mass", "type" });
	CharEncumbranceManager.addCustomCalc(CharEncumbranceManagerTraveller.calcEncumbrance);
end
function onTabletopInit()
	DB.addHandler("charsheet.*.attributes.strength", "onUpdate", CharEncumbranceManagerTraveller.onEncAttributeChange);
	DB.addHandler("charsheet.*.attributes.endurance", "onUpdate", CharEncumbranceManagerTraveller.onEncAttributeChange);
	DB.addHandler("charsheet.*.woundtrack.str_equipment", "onUpdate", CharEncumbranceManagerTraveller.onEncEquipmentChange);
	DB.addHandler("charsheet.*.woundtrack.end_equipment", "onUpdate", CharEncumbranceManagerTraveller.onEncEquipmentChange);
end
function onClose()
	DB.removeHandler("charsheet.*.attributes.strength", "onUpdate", CharEncumbranceManagerTraveller.onEncAttributeChange);
	DB.removeHandler("charsheet.*.attributes.endurance", "onUpdate", CharEncumbranceManagerTraveller.onEncAttributeChange);
	DB.removeHandler("charsheet.*.woundtrack.str_equipment", "onUpdate", CharEncumbranceManagerTraveller.onEncEquipmentChange);
	DB.removeHandler("charsheet.*.woundtrack.end_equipment", "onUpdate", CharEncumbranceManagerTraveller.onEncEquipmentChange);
end

function calcEncumbrance(nodeChar)
	local nEncumbrance = CharEncumbranceManagerTraveller.calcInventoryEncumbrance(nodeChar);
	nEncumbrance = nEncumbrance + CharEncumbranceManager.calcDefaultCurrencyEncumbrance(nodeChar);
	CharEncumbranceManager.setDefaultEncumbranceValue(nodeChar, nEncumbrance);

	CharEncumbranceManagerTraveller.updateEncumbranceState(nodeChar);
end
function calcInventoryEncumbrance(nodeChar)
 	local nInvTotal = 0;
    local nCount, nWeight;

	local nCount, nWeight;
	for _,vNode in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		local nCarried = DB.getValue(vNode, "carried", 0);
		if nCarried ~= 0 then
			nCount = DB.getValue(vNode, "count", 0);
            nWeight = DB.getValue(vNode, "mass", 0);

            if nCarried == 2 then				
        		local sType = StringManager.trim(DB.getValue(vNode, "type", "")):lower();
                if sType == "armour" then
                    local sSubType = StringManager.trim(DB.getValue(vNode, "subtype", "")):lower();
                    if (sSubType == "battle dress") or (sSubType == "powered armour") then
                        nWeight = 0;
                    else
                        nWeight = nWeight * 0.25;
                    end
                end
            end

			nInvTotal = nInvTotal + (nCount * nWeight);
		end
	end

	return nInvTotal;
end

function onEncAttributeChange(nodeField)
	local nodeChar = DB.getChild(nodeField, "...");
	CharEncumbranceManagerTraveller.calcEncumbranceLimit(nodeChar);
end
function onEncEquipmentChange(nodeField)
	local nodeChar = DB.getChild(nodeField, "...");
	CharEncumbranceManagerTraveller.calcEncumbranceLimit(nodeChar);
end

-- Traveller characters sometimes have to carry everything they need to survive. 
-- A character can carry a number of kilograms equal to their Strength + Endurance scores 
--   before they have to worry about their load. 
-- They are lightly encumbered if they carry up to twice this value and 
--   heavily encumbered if they carry up to three times their Strength + Endurance. 
-- A character can lift more with an Athletics (strength) check – add the Effect to his 
--   effective Strength to work out his new maximum lift – but cannot do more than 
--   stagger around with his new load at 1.5 metres per round. He may lift it for a 
--   number of rounds equal to the Effect of an Athletics (endurance) check.
function calcEncumbranceLimit(nodeChar)
	local nEncLimit = DB.getValue(nodeChar, "attributes.strength", 0) + 
			DB.getValue(nodeChar, "attributes.endurance", 0) + 
			DB.getValue(nodeChar, "woundtrack.str_equipment", 0) + 
			DB.getValue(nodeChar, "woundtrack.end_equipment", 0);

	DB.setValue(nodeChar, "encumbrance.base", "number", nEncLimit);
	DB.setValue(nodeChar, "encumbrance.light", "number", nEncLimit * 2);
	DB.setValue(nodeChar, "encumbrance.max", "number", nEncLimit * 3);

	CharEncumbranceManagerTraveller.updateEncumbranceState(nodeChar);
end

function updateEncumbranceState(nodeChar)
    local nEncLoad = DB.getValue(nodeChar, "encumbrance.load", 0);
	local nEncLimit = DB.getValue(nodeChar, "encumbrance.base", 0);

    local nEncMod;
    local sEncStatus;
    if nEncLoad > (nEncLimit * 2) then
    	nEncMod = -3;
        sEncStatus = "Heavily encumbered"
    elseif nEncLoad > nEncLimit then
    	nEncMod = -1;
        sEncStatus = "Lightly encumbered"
    else
    	nEncMod = 0;
        sEncStatus = "Not encumbered";
    end

	DB.setValue(nodeChar, "encumbrance.mod", "number", nEncMod);
    DB.setValue(nodeChar, "encumbrance.status", "string", sEncStatus);
end
