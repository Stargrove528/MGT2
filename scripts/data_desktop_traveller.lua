--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ColorManager.setSidebarCategoryIconColor("FFFFFE");
	ColorManager.setSidebarCategoryTextColor("FFFFFE");
	ColorManager.setSidebarRecordIconColor("FFFFFE");
	ColorManager.setSidebarRecordTextColor("FFFFFE");
	ColorManager.setButtonContentColor("FFFFFF");
	ColorManager.setWindowMenuIconColor("323234");

	WindowTabManager.registerTab("partysheet_host", { sName = "partyship", sTabRes = "tab_ships", sClass = "ps_partyship" });
	WindowTabManager.registerTab("partysheet_client", { sName = "partyship", sTabRes = "tab_ships", sClass = "ps_partyship" });

	DecalManager.setDefault("images/decals/mgt2_decal.png@MGT2 Assets");

	StoryManager.addBlockFrame("trav1");
	StoryManager.addBlockFrame("trav2");
	StoryManager.addBlockFrame("trav3");
	StoryManager.addBlockFrame("trav4");
	StoryManager.addBlockFrame("trav5");
	StoryManager.addBlockFrame("trav6");
	StoryManager.addBlockFrame("trav7");
	StoryManager.addBlockFrame("trav8");
	StoryManager.addBlockFrame("trav9");
	StoryManager.addBlockFrame("trav10");
	StoryManager.addBlockFrame("trav11");
	StoryManager.addBlockFrame("trav12");
	StoryManager.addBlockFrame("trav13");
	StoryManager.addBlockFrame("trav14");
	StoryManager.addBlockFrame("trav15");
	StoryManager.addBlockFrame("trav16");
	StoryManager.addBlockFrame("trav17");
	StoryManager.addBlockFrame("trav18");
	StoryManager.addBlockFrame("trav19");
	StoryManager.addBlockFrame("trav20");
	StoryManager.addBlockFrame("trav21");
	StoryManager.addBlockFrame("trav22");
	StoryManager.addBlockFrame("trav23");
	StoryManager.addBlockFrame("trav24");
	StoryManager.addBlockFrame("trav25");
	StoryManager.addBlockFrame("trav26");
	StoryManager.addBlockFrame("trav27");
	StoryManager.addBlockFrame("trav28");

	ModifierManager.addModWindowPresets(_tModifierWindowPresets);
	ModifierManager.addKeyExclusionSets(_tModifierExclusionSets);

	for k,v in pairs(_tDataModuleSet) do
		for _,v2 in ipairs(v) do
			Desktop.addDataModuleSet(k, v2);
		end
	end

	local tButton;
    if Session.IsHost then
	    tButton = { 
	    	sIcon = "sidebar_icon_link_shipct", 
	    	tooltipres = "sidebar_tooltip_shipct", 
	    	class = "ct_ship_combat", 
	    	path = "combattracker" 
	    	};
	    DesktopManager.registerSidebarToolButton(tButton, "partysheet_host");

	    tButton = { 
	    	sIcon = "sidebar_icon_link_taskchains", 
	    	tooltipres = "sidebar_tooltip_taskchains", 
	    	class = "taskchains_host", 
	    	path = "taskchains" 
	    	};
		DesktopManager.registerSidebarToolButton(tButton, "partysheet_host");
		DB.setPublic(DB.createNode("taskchains"), true);
    else
	    tButton = { 
	    	sIcon = "sidebar_icon_link_shipct", 
	    	tooltipres = "sidebar_tooltip_shipct", 
	    	class = "shipcombattracker_client", 
	    	path = "combattracker" 
	    };
	    DesktopManager.registerSidebarToolButton(tButton, "partysheet_client");

	    tButton = { 
	    	sIcon = "sidebar_icon_link_taskchains", 
	    	tooltipres = "sidebar_tooltip_taskchains", 
	    	class = "taskchains_client", 
	    	path = "taskchains" 
	    	};
		DesktopManager.registerSidebarToolButton(tButton, "partysheet_client");
    end
end

-- Shown in Modifiers window
-- NOTE: Set strings for "modifier_category_*" and "modifier_label_*"
_tModifierWindowPresets =
{
	{
		sCategory = "bonus",
		tPresets =
		{
			"BON_AIMING_1",
			"BON_LASER_SIGHT",
			"BON_AIMING_2",
			"BON_SHORT_RANGE",
			"BON_AIMING_3",
		},
	},
	{
		sCategory = "shipbonus",
		tPresets =
		{
			"BON_FIRECONTROL1",
			"BON_FIRECONTROL2",
			"BON_FIRECONTROL3",
			"BON_FIRECONTROL4",
			"BON_FIRECONTROL5",
		},
	},
	{
		sCategory = "penalty",
		tPresets = {
			"PEN_FAST_MOVING_1",
			"PEN_COVER",
			"PEN_FAST_MOVING_2",
			"PEN_PRONE",
			"PEN_FAST_MOVING_3",
			"PEN_LONG_RANGE",
			"PEN_FAST_MOVING_4",
			"PEN_EXTREME_RANGE",
		}
	},
};
_tModifierExclusionSets =
{
	--{ "DEF_COVER", "DEF_SCOVER" },
};

_tDataModuleSet =
{
	["client"] =
	{
		{
			name = "MGT2 - Players Reference",
			modules =
			{
				{ name = "MGT2 Players Reference", storeid = "MGP40000TRVMG2E", displayname = "MGT2 Player's Reference" },
			},
		},
		{
			name = "MGT2 - All Rules",
			modules =
			{
				{ name = "MGT2 Core Rulebook", storeid = "MGP40000TRVMG2E", displayname = "MGT2 Core Rulebook" },
				{ name = "MGT2 Players Reference", storeid = "MGP40000TRVMG2E", displayname = "MGT2 Player's Reference" },
			},
		},
	},
	["host"] =
	{
		{
			name = "MGT2 - Core Rules",
			modules =
			{
				{ name = "MGT2 Core Rulebook", storeid = "MGP40000TRVMG2E", displayname = "MGT2 Core Rulebook" }
			},
		},
		{
			name = "MGT2 - All Rules",
			modules =
			{
				{ name = "MGT2 Core Rulebook", storeid = "MGP40000TRVMG2E", displayname = "MGT2 Core Rulebook" },
				{ name = "MGT2 Players Reference", storeid = "MGP40000TRVMG2E", displayname = "MGT2 Player's Reference" },
			},
		},
	},
};
