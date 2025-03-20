--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	super.onInit();

	self.updateToggles();
	self.onTypeChanged();
	self.onHealthChanged();
end

function updateToggles()
	if self.isPC() then
		button_section_defense.setVisible(false);
		spacer_button_section_defense.setVisible(true);
		button_section_active.setVisible(false);
		spacer_button_section_active.setVisible(true);
	end
end

function onTypeChanged()
	local bShowSimpleHits = (type.getValue() == "Animal" or type.getValue() == "Robot");

	strength.setVisible(not bShowSimpleHits);
	dexterity.setVisible(not bShowSimpleHits);
	endurance.setVisible(not bShowSimpleHits);
	hits.setVisible(bShowSimpleHits);
	hits_label.setVisible(bShowSimpleHits);
end
function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local _,sStatus,sColor = ActorHealthManager.getHealthInfo(rActor);

	endurance.setColor(sColor);
	dexterity.setColor(sColor);
	strength.setColor(sColor);
	status.setValue(sStatus);
	hits.setColor(sColor)

	if not self.isPC() then
		idelete.setVisible(ActorHealthManager.isDyingOrDeadStatus(sStatus));
	end
end

function linkPCFields()
	super.linkPCFields();

	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		originalstrength.setLink(DB.createChild(nodeChar, "attributes.strength", "number"));
		originaldexterity.setLink(DB.createChild(nodeChar, "attributes.dexterity", "number"));
		originalendurance.setLink(DB.createChild(nodeChar, "attributes.endurance", "number"));

		dex_mod.setLink(DB.createChild(nodeChar, "attributes.dex_mod", "number"));
		int_mod.setLink(DB.createChild(nodeChar, "attributes.int_mod", "number"));

		strength.setLink(DB.createChild(nodeChar, "woundtrack.str", "number"));
		dexterity.setLink(DB.createChild(nodeChar, "woundtrack.dex", "number"));
		endurance.setLink(DB.createChild(nodeChar, "woundtrack.end", "number"));

		hits.setLink(DB.createChild(nodeChar, "woundtrack.hits", "number"), true);

		armour.setLink(DB.createChild(nodeChar, "armour", "string"), true);
		armour_protection.setLink(DB.createChild(nodeChar, "armour_protection", "string"), true);
	end
end
