--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Spacecraft

function onInit()
	constructDefaultDetails();
	update();
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());

	class.setReadOnly(bReadOnly);
    type.setReadOnly(bReadOnly);
	tl.setReadOnly(bReadOnly);
	-- hull_points.setReadOnly(bReadOnly);
    tons.setReadOnly(bReadOnly);
	-- crew.setReadOnly(bReadOnly);
	maintenance_cost.setReadOnly(bReadOnly);
	purchase_cost.setReadOnly(bReadOnly);
	crew.setReadOnly(bReadOnly);
	-- mdrive.setReadOnly(bReadOnly);
	-- jdrive.setReadOnly(bReadOnly);
	-- basic_ships_systems.setReadOnly(bReadOnly);
	-- sensors.setReadOnly(bReadOnly);
	-- weapons.setReadOnly(bReadOnly);
	fuel_consumption.setReadOnly(bReadOnly);

	local bShowFuel = true;
	local bShowClass = true;

	if bReadOnly then
		if (fuel_consumption.getValue() == '') then
			bShowFuel = false;
		end
		if (class.getValue() == '') then
			bShowClass = false;
		end
	end

	header_cei.setVisible(bShowFuel);
	fuel_consumption.setVisible(bShowFuel);
	fuel_consumption_label.setVisible(bShowFuel);
	fuel_divider.setVisible(bShowFuel);
	class.setVisible(bShowClass);
	class_label.setVisible(bShowClass);

	power_requirements.update(bReadOnly);
end

-- Create default spacecraft details
function constructDefaultDetails()
	local aDefaultDetails = DataCommon.spacecraftdefaultdetails;

	local nodeSpaceCraft = getDatabaseNode();
	local nodeDetails;

	if not nodeSpaceCraft.details then
		nodeDetails = DB.createChild(nodeSpaceCraft, 'details');
	else
		nodeDetails = DB.getChild(nodeSpaceCraft, 'details');
	end

	if DB.getChildCount(nodeDetails) == 0 then
		local i = 1;
		while aDefaultDetails[i] do
			nodeNewDetail = DB.createChild(nodeDetails)
			DB.setValue(nodeNewDetail,'name', 'string', aDefaultDetails[i]);
			i = i + 1;
		end
	end

end