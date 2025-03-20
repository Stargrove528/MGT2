--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onFilter(w)
	if w.taskvis.getValue() ~= 0 then
		return true;
	end
	return false;
end

