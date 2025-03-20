--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	if Session.IsHost then
		Token.addEventHandler("onContainerChanged", onContainerChanged);
	end
end

function onContainerChanged(tokenCT, nodeOldContainer, nOldId)
	local nodePS = VehicleManager.getNodeFromTokenRef(nodeOldContainer, nOldId);
	if nodePS then
		local nodeNewContainer = tokenCT.getContainerNode();
		if nodeNewContainer then
			DB.setValue(nodePS, "tokenrefnode", "string", DB.getPath(nodeNewContainer));
			DB.setValue(nodePS, "tokenrefid", "string", tokenCT.getId());
		else
			DB.setValue(nodePS, "tokenrefnode", "string", "");
			DB.setValue(nodePS, "tokenrefid", "string", "");
		end
	end
end
