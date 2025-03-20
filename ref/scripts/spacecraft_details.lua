-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onListChanged()
	if Session.IsHost then
		local nodeShip = DB.getParent(getDatabaseNode());
		local sArmourDetail = SpacecraftManager.getArmour(nodeShip)
		if sArmourDetail then
			local nArmourValue = tonumber(sArmourDetail:match("(%d+)"));
			DB.setValue(nodeShip, "armour", "string", sArmourDetail);
			DB.setValue(nodeShip, "armour_rating", "number", nArmourValue);
		end
	end
end
