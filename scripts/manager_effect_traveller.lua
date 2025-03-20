--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function parseEffectComp(s)
	local sType = nil;
	local aDice = {};
	local nMod = 0;
	local aRemainder = {};
	local nRemainderIndex = 1;

	local aWords, aWordStats = StringManager.parseWords(s, "%.%[%]%(%):");

	if #aWords > 0 then
		if #aWords > 1 then
			sDamageDice = aWords[2]:match("%((%w+)%)")

			if StringManager.isDiceString(sDamageDice) then
				sType = aWords[1]:lower();
				-- we could check this to match a damage type
			end
		end

		if sType then
			nRemainderIndex = 2;

			local sValueCheck = aWords[1]:sub(#sType + 2);
			if sValueCheck ~= "" then
				table.insert(aWords, 2, sValueCheck);
				table.insert(aWordStats, 2, { startpos = aWordStats[1].startpos + #sType + 1, endpos = aWordStats[1].endpos });
				aWords[1] = aWords[1]:sub(1, #sType + 1);
				aWordStats[1].endpos = #sType + 1;
			end

			if #aWords > 1 then
				if StringManager.isDiceString(sDamageDice) then
					aDice, nMod = StringManager.convertStringToDice(sDamageDice:lower());
					nRemainderIndex = 3;
				end
			end
		end

		if nRemainderIndex <= #aWords then
			while nRemainderIndex <= #aWords and aWords[nRemainderIndex]:match("^%[[%+%-]?%w+%]$") do
				table.insert(aRemainder, aWords[nRemainderIndex]);
				nRemainderIndex = nRemainderIndex + 1;
			end
		end

		if nRemainderIndex <= #aWords then
			local sRemainder = s:sub(aWordStats[nRemainderIndex].startpos);
			local nStartRemainderPhrase = 1;
			local i = 1;
			while i < #sRemainder do
				local sCheck = sRemainder:sub(i, i);
				if sCheck == "," then
					local sRemainderPhrase = sRemainder:sub(nStartRemainderPhrase, i - 1);
					if sRemainderPhrase and sRemainderPhrase ~= "" then
						sRemainderPhrase = StringManager.trim(sRemainderPhrase);
						table.insert(aRemainder, sRemainderPhrase);
					end
					nStartRemainderPhrase = i + 1;
				elseif sCheck == "(" then
					while i < #sRemainder do
						if sRemainder:sub(i, i) == ")" then
							break;
						end
						i = i + 1;
					end
				elseif sCheck == "[" then
					while i < #sRemainder do
						if sRemainder:sub(i, i) == "]" then
							break;
						end
						i = i + 1;
					end
				end
				i = i + 1;
			end
			local sRemainderPhrase = sRemainder:sub(nStartRemainderPhrase, #sRemainder);
			if sRemainderPhrase and sRemainderPhrase ~= "" then
				sRemainderPhrase = StringManager.trim(sRemainderPhrase);
				table.insert(aRemainder, sRemainderPhrase);
			end
		end
	end

	return  {
		type = sType or "",
		mod = nMod,
		dice = aDice,
		remainder = aRemainder,
		original = StringManager.trim(s)
	};
end

function hasEffectCondition(rActor, sEffect, rTarget)
	return hasEffect(rActor, sEffect, rTarget, false, true);
end

function hasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
	if not sEffect or not rActor then
		return false;
	end
	local sLowerEffect = sEffect:lower();

	-- Iterate through each effect
	local aMatch = {};
	for _,v in ipairs(DB.getChildList(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
		if nActive ~= 0 then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp,sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = parseEffectComp(sEffectComp);
				local sDamageStriped = (rEffectComp.original:lower());

				sDamageStriped = StringManager.trim(sDamageStriped:gsub('%b()', ''));

				if rEffectComp.original:lower() == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if EffectManager.isEffectTarget(v, rTarget) then
							nMatch = kEffectComp;
						end
					elseif not bTargetedOnly then
						nMatch = kEffectComp;
					end
				elseif sDamageStriped == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if EffectManager.isEffectTarget(v, rTarget) then
							nMatch = kEffectComp;
						end
					elseif not bTargetedOnly then
						nMatch = kEffectComp;
					end
				end
			end

			-- If matched, then remove one-off effects
			if nMatch > 0 then
				if nActive == 2 then
					DB.setValue(v, "isactive", "number", 1);
				else
					table.insert(aMatch, v);
					local sApply = DB.getValue(v, "apply", "");
					if sApply == "action" then
						EffectManager.notifyExpire(v, 0);
					elseif sApply == "roll" then
						EffectManager.notifyExpire(v, 0, true);
					elseif sApply == "single" then
						EffectManager.notifyExpire(v, nMatch, true);
					end
				end
			end
		end
	end

	if #aMatch > 0 then
		return true;
	end
	return false;
end

function getDamageDetails(rActor, sEffect)
	if not sEffect or not rActor then
		return false;
	end
	local sLowerEffect = sEffect:lower();
	local aDetails = nil;

	-- Iterate through each effect
	for _,v in ipairs(DB.getChildList(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
		if nActive ~= 0 then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp,sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = parseEffectComp(sEffectComp);
				local sDamageStriped = (rEffectComp.original:lower());
				sDamageStriped = StringManager.trim(sDamageStriped:gsub('%b()', ''));

				if sDamageStriped == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if EffectManager.isEffectTarget(v, rTarget) then
							aDetails = rEffectComp;
							aDetails.sDamage = sDamageStriped;
						end
					elseif not bTargetedOnly then
						aDetails = rEffectComp;
						aDetails.sDamage = sDamageStriped;
					end
				end
			end
		end
	end
	if aDetails then
		return aDetails;
	end
	return nil;
end
