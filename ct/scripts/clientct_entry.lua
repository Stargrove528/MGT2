--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	onHealthChanged();
end

function onFactionChanged()
	super.onFactionChanged();
	updateHealthDisplay();
end

function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local sColor = ActorHealthManager.getHealthColor(rActor);

	strength.setColor(sColor);
	dexterity.setColor(sColor);
	endurance.setColor(sColor);
	status.setColor(sColor);
end

function updateHealthDisplay()
	local sOption;

	if friendfoe.getStringValue() == "friend" then
		sOption = "detailed";
	else
		sOption = "status";
	end

	if sOption == "detailed" then
		strength.setVisible(true);
		dexterity.setVisible(true);
		endurance.setVisible(true);

		status.setVisible(false);
	elseif sOption == "status" then
		strength.setVisible(false);
		dexterity.setVisible(false);
		endurance.setVisible(false);

		status.setVisible(true);
	end
end
