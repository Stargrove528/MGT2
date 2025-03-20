-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function convertDamageStringToDice(s)
	if not s then
		return {}, 0;
	end

	s = s:lower();
	if s:match("dd") then
		s = s:gsub("dd", "d6")
	end
	if not s:match("d6") and not s:match("d3") and not s:match("d66") then
		s = s:gsub("d", "d6")
	end
	return DiceManager.convertStringToDice(s);
end
