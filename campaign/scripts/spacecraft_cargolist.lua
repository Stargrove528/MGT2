--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local sortLocked = false;

function setSortLock(isLocked)
	sortLocked = isLocked;
end

function onInit()
	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "*.tons"), "onUpdate", onCargoChanged);
	DB.addHandler(DB.getPath(node), "onChildDeleted", onCargoChanged);
end
function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "*.tons"), "onUpdate", onCargoChanged);
	DB.removeHandler(DB.getPath(node), "onChildDeleted", onCargoChanged);
end

function StateChanged()
	for _,w in ipairs(getWindows()) do
		w.onIDChanged();
	end
	applySort();
end

function onListChanged()
	updateContainers();
end

function onSortCompare(w1, w2)
	if sortLocked then
		return false;
	end
	return ItemManager.onInventorySortCompare(w1, w2);
end

function updateContainers()
	onInventorySortUpdate(self);
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass,sRecord = draginfo.getShortcutData();
		if sClass == 'tradegoods' then
			nodeTradeGoods = DB.findNode(sRecord);
			local sName = DB.getValue(nodeTradeGoods, 'name', '');
			local nodeCargo = getDatabaseNode();
			local nodeCargoItem = DB.createChild(nodeCargo);

			DB.setValue(nodeCargoItem,'name', 'string', sName);
		end
	end
end

function onInventorySortUpdate(cList)
	for _,w in ipairs(cList.getWindows()) do
		if not w.hidden_locationpath then
			w.createControl("hsc", "hidden_locationpath");
		end
		local aSortPath, bContained = ItemManager.getInventorySortPath(cList, w);
		w.hidden_locationpath.setValue(table.concat(aSortPath, "\a"));
		if w.name then
			if bContained then
				w.name.setAnchor("left", nil, "left", "absolute", 5 + (10 * (#aSortPath - 1)));
			else
				w.name.setAnchor("left", nil, "left", "absolute", 5);
			end
		end
	end

	cList.applySort();
end

function onCargoChanged()
	local nodeShip = window.getDatabaseNode();

	if string.find(DB.getPath(nodeShip):lower(), 'partysheet') then
		local _, sRecord = DB.getValue(window.getDatabaseNode(), "link", "", "");
		nodePCShip = DB.findNode(sRecord);
		if SpacecraftManager.updatePSCargoTotals then
			SpacecraftManager.updatePSCargoTotals(nodeShip, nodePCShip);
		end
		return;
	end

	if SpacecraftManager.updateCargoTotals then
		SpacecraftManager.updateCargoTotals(nodeShip);
	end
end
