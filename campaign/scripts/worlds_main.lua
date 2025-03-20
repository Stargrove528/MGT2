--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- World Data

function onInit()
	update();
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());

	uwp.setReadOnly(bReadOnly);
	uwp.setVisible(bReadOnly == false);
	uwp_label.setVisible(bReadOnly == false);
	divider.setVisible(bReadOnly == false);

	hexlocation.setReadOnly(bReadOnly);
	starport_quality.setReadOnly(bReadOnly);
	size.setReadOnly(bReadOnly);
	atmosphere_type.setReadOnly(bReadOnly);
	hydrographics.setReadOnly(bReadOnly);
	population.setReadOnly(bReadOnly);
	government_type.setReadOnly(bReadOnly);
	law_level.setReadOnly(bReadOnly);
	tech_level.setReadOnly(bReadOnly);
	bases.setReadOnly(bReadOnly);
	trade_codes.setReadOnly(bReadOnly);
	travel_code.setReadOnly(bReadOnly);
	system.setReadOnly(bReadOnly);
	sector.setReadOnly(bReadOnly);
	subsector.setReadOnly(bReadOnly);
	allegiances.setReadOnly(bReadOnly);
	domain.setReadOnly(bReadOnly);


end