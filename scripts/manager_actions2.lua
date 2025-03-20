--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function encodeDesktopMods(rRoll, bDamageRoll)
	local nMod = 0;

	if ModifierStack.getModifierKey("PLUS1") then
		nMod = nMod + 1;
	end
	if ModifierStack.getModifierKey("MINUS1") then
		nMod = nMod - 1;
	end
	if ModifierStack.getModifierKey("PLUS2") then
		nMod = nMod + 2;
	end
	if ModifierStack.getModifierKey("MINUS2") then
		nMod = nMod - 2;
	end
	if ModifierStack.getModifierKey("PLUS3") then
		nMod = nMod + 3;
	end
	if ModifierStack.getModifierKey("MINUS3") then
		nMod = nMod - 3;
	end

	if nMod == 0 then
		return;
	end

	rRoll.nMod = rRoll.nMod + nMod;
	if rRoll.sDesc then
		rRoll.sDesc = rRoll.sDesc .. string.format(" [%+d]", nMod);
	end

	return nMod;
end

function endcodeDesktopAttributes(rRoll, sSourceNode)
	local nValue = 0
	local sStatChosen = ''

	if ModifierStack.getModifierKey("STR") then
		sStatChosen = 'STR'
	end
	if ModifierStack.getModifierKey("DEX") then
		sStatChosen = 'DEX'
	end
	if ModifierStack.getModifierKey("END") then
		sStatChosen = 'END'
	end
	if ModifierStack.getModifierKey("INT") then
		sStatChosen = 'INT'
	end
	if ModifierStack.getModifierKey("EDU") then
		sStatChosen = 'EDU'
	end
	if ModifierStack.getModifierKey("SOC") then
		sStatChosen = 'SOC'
	end
	if ModifierStack.getModifierKey("PSI") then
		sStatChosen = 'PSI'
	end

	-- Check we're not overriding the same stat
	if (rRoll.sSkillStat) then
		if (rRoll.sSkillStat:upper() == sStatChosen:upper()) then
			sStatChosen = ""
		end
	end

	-- now if wee've chosen a stat, let's get the DM for it
	if sStatChosen ~= "" then
		nValue = DB.getValue(sSourceNode .. '.attributes.' .. sStatChosen:lower() .. '_mod', 0);
	end

	return nValue, sStatChosen
end

function encodeAdvantage(rRoll)
	local bBoon, bBane = false;

	local bButtonBoon = ModifierStack.getModifierKey("BOON");
	local bButtonBane = ModifierStack.getModifierKey("BANE");
	if bButtonBoon then
		bBoon = true;
	end
	if bButtonBane then
		bBane = true;
	end

	if bBoon then
		rRoll.sDesc = rRoll.sDesc .. " [BOON]";
	end
	if bBane then
		rRoll.sDesc = rRoll.sDesc .. " [BANE]";
	end

	if (bBane and not bBoon) or (bBoon and not bBane) then
		table.insert(rRoll.aDice, "d6");
	end
end

function decodeAdvantage(rRoll)
	local bADV = string.match(rRoll.sDesc, "%[BOON%]");
	local bDIS = string.match(rRoll.sDesc, "%[BANE%]");
	if (bADV and not bDIS) or (bDIS and not bADV) then
		if #(rRoll.aDice) > 0 then
			local nDroppedDieResult, nDroppedDie = rRoll.aDice[1].result, 1

			for i=2, 3, 1
			do
				if bADV and rRoll.aDice[i].result < nDroppedDieResult or bDIS and rRoll.aDice[i].result > nDroppedDieResult then
					nDroppedDieResult = rRoll.aDice[i].result
					nDroppedDie = i
				end
			end

			table.remove(rRoll.aDice, nDroppedDie);
			if rRoll.aDice.expr then
				rRoll.aDice.expr = nil;
			end
			rRoll.sDesc = rRoll.sDesc .. " [DROPPED " .. nDroppedDieResult .. "]";
		end
	end
end