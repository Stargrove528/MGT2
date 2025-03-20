--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerOption2("HDCV", true, "option_header_client", "option_label_HDCV", "option_entry_cycler",
		{ labels = "option_val_enddexstr|option_val_strdexend|option_val_strenddex|option_val_dexendstr|option_val_dexstrend", values = "END DEX STR|STR DEX END|STR END DEX|DEX END STR|DEX STR END", baselabel = "option_val_endstrdex", baseval = "END STR DEX", default = "END STR DEX" });
	OptionsManager.registerOption2("DDCV", true, "option_header_client", "option_label_DDCV", "option_entry_cycler",
		{ labels = "option_val_enddexstr|option_val_strdexend|option_val_strenddex|option_val_dexendstr|option_val_dexstrend", values = "END DEX STR|STR DEX END|STR END DEX|DEX END STR|DEX STR END", baselabel = "option_val_endstrdex", baseval = "END STR DEX", default = "END STR DEX" });
	OptionsManager.registerOption2("SAV", false, "option_header_combat", "option_label_ARMOUR", "option_entry_cycler",
		{ labels = "option_val_on|option_val_off", values = "yes|no", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("STUDYP", false, "option_header_houserule", "option_label_STUDYP", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("EHW", false, "option_header_houserule", "option_label_EHW", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("CHARPSI", false, "option_header_characteristics", "option_label_CHARPSI", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("SHPC", false, "option_header_combat", "option_label_SHPC", "option_entry_cycler",
		{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "detailed" });
	OptionsManager.registerOption2("SHNPC", false, "option_header_combat", "option_label_SHNPC", "option_entry_cycler",
		{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "status" });

	OptionsManager.registerOption2("CHARTER", false, "option_header_characteristics", "option_label_CHARTER", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("CHARRES", false, "option_header_characteristics", "option_label_CHARRES", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });

	OptionsManager.registerOption2("CHARMOR", false, "option_header_characteristics_companion", "option_label_CHARMOR", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("CHARLUC", false, "option_header_characteristics_companion", "option_label_CHARLUC", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("CHARSAN", false, "option_header_characteristics_companion", "option_label_CHARSAN", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("CHARWEA", false, "option_header_characteristics_companion", "option_label_CHARWLT", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("CHARCHA", false, "option_header_characteristics_companion", "option_label_CHARCHA", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });

	OptionsManager.registerOption2("COMPMISHAPS", false, "option_header_combat_companion", "option_label_COMPMISHAPS", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("COMPWE", false, "option_header_combat_companion", "option_label_COMPWOUNDEFFECTS", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("COMPHL", false, "option_header_combat_companion", "option_label_COMPHITLOCATIONS", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("COMPDWE", false, "option_header_combat_companion", "option_label_COMPDISABLINGWOUNDEFFECTS", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("COMPNR", false, "option_header_combat_companion", "option_label_COMPNATURALRESILIENCE", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("COMPKB", false, "option_header_combat_companion", "option_label_COMPKNOCKOUTBLOW", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });
	OptionsManager.registerOption2("COMPRFB", false, "option_header_combat_companion", "option_label_COMPRANDOMFIRSTBLOOD", "option_entry_cycler",
		{ labels = "option_val_on", values = "yes", baselabel = "option_val_off", baseval = "no", default = "no" });

	OptionsManager.registerOption2("BARC", false, "option_header_combat", "option_label_BARC", "option_entry_cycler",
		{ labels = "option_val_tiered", values = "tiered", baselabel = "option_val_standard", baseval = "", default = "" });

	OptionsManager.registerOption2("SPCRIT", false, "option_header_combat", "option_label_SPCRIT", "option_entry_cycler",
		{ labels = "option_val_on|option_val_off", values = "yes|no", baselabel = "option_val_on", baseval = "yes", default = "yes" });
	OptionsManager.registerOption2("SPACRIT", false, "option_header_combat", "option_label_SPACRIT", "option_entry_cycler",
		{ labels = "option_val_on|option_val_off", values = "yes|no", baselabel = "option_val_on", baseval = "yes", default = "yes" });

	OptionsManager.registerOption2("SHRR", false, "option_header_game", "option_label_SHRR", "option_entry_cycler",
		{ labels = "option_val_on|option_val_friendly", values = "on|pc", baselabel = "option_val_off", baseval = "off", default = "on" });

	--Disable/Enable the UWP Auto-Generation
	OptionsManager.registerOption2("UWPAG", false, "option_header_houserule", "option_label_UWPAG", "option_entry_cycler",
		{ labels = "option_val_on|option_val_off", values = "on|off", baselabel = "option_val_on", baseval = "on", default = "on" });
end
