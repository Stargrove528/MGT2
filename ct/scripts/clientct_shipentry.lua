--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onFactionChanged();
	self.onHealthChanged();
end

function onActiveChanged()
	self.updateDisplay();
	self.updateHealthDisplay();
end
function onFactionChanged()
	self.updateDisplay();
	self.updateHealthDisplay();
end
function onIDChanged()
	local nodeRecord = getDatabaseNode();
	local sClass = DB.getValue(nodeRecord, "link", "spacecraft", "");
	if sClass == "spacecraft" then
		local bID = LibraryData.getIDState("spacecraft", nodeRecord, true);
		name.setVisible(bID);
		nonid_name.setVisible(not bID);
	else
		name.setVisible(true);
		nonid_name.setVisible(false);
	end
end
function onHealthChanged()
	local sColor = ActorManagerTraveller.getShipWoundColor(getDatabaseNode());

	hpdamage.setColor(sColor);
	status.setColor(sColor);
end

function updateDisplay()
	local sFaction = friendfoe.getStringValue();

	local sOptCTSI = OptionsManager.getOption("CTSI");
	local bShowInit = ((sOptCTSI == "friend") and (sFaction == "friend")) or (sOptCTSI == "on");
	initresult.setVisible(bShowInit);

	if active.getValue() == 1 then
		name.setFont("sheetlabel");
		nonid_name.setFont("sheetlabel");

		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);

		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active");
		else
			setFrame("ctentrybox_active");
		end

		windowlist.scrollToWindow(self);
	else
		name.setFont("sheettext");
		nonid_name.setFont("sheettext");

		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);

		if sFaction == "friend" then
			setFrame("ctentrybox_friend");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe");
		else
			setFrame("ctentrybox");
		end
	end
end
function updateHealthDisplay()
	local sOption;
	if friendfoe.getStringValue() == "friend" then
		sOption = OptionsManager.getOption("SHPC");
	else
		sOption = OptionsManager.getOption("SHNPC");
	end

	if sOption == "detailed" then
		hpdamage.setVisible(true);
		hptotal.setVisible(true);

		status.setVisible(false);
	elseif sOption == "status" then
		hpdamage.setVisible(false);
		hptotal.setVisible(false);

		status.setVisible(true);
	else
		hpdamage.setVisible(false);
		hptotal.setVisible(false);

		status.setVisible(false);
	end
end
