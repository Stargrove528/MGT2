--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function getItemRecordDisplayClass(vNode)
	local sRecordDisplayClass = "item";
	if vNode then
		local sBasePath, sSecondPath = UtilityManager.getDataBaseNodePathSplit(vNode);

		if sBasePath == "reference" then
			if sSecondPath == "equipmentdata" then
				local sTypeLower = StringManager.trim(DB.getValue(DB.getPath(vNode, "type"), ""):lower());
				if sTypeLower == "weapons" or sTypeLower == "weapon" or sTypeLower == "heavy weaponry" or sTypeLower == "spacecraft scale weapons" then
					sRecordDisplayClass = "reference_weapons";
				elseif sTypeLower == "armor" or sTypeLower == "armour" then
					sRecordDisplayClass = "reference_armor";
				else
					sRecordDisplayClass = "reference_equipment";
				end
			end
		end
	end
	return sRecordDisplayClass;
end

function isItemIdentifiable(vNode)
	local sBasePath = UtilityManager.getDataBaseNodePathSplit(vNode)
	return (sBasePath ~= "reference");
end

aRecordOverrides = {
	["item"] = {
		fIsIdentifiable = isItemIdentifiable,
		aDataMap = { "item", "reference.equipmentdata" },
		aGMListButtons = { "button_item_armour", "button_item_weapons" };
		aPlayerListButtons = { "button_item_armour", "button_item_weapons" };
		fRecordDisplayClass = getItemRecordDisplayClass,
		aRecordDisplayClasses = { "item", "reference_armor", "reference_weapons", "reference_equipment", "reference_ammunition", "reference_heavyweaponry", "reference_spacecraftscaleweapons" },
		aCustomFilters = {
			["Type"] = { sField = "type" },
		},
	},
	["npc"] = {
		aDataMap = { "npc", "reference.npcdata" },
		aCustomFilters = {
			["Type"] = { sField = "type" }
		}
	},
	["vehicle"] = {
		aDataMap = { "vehicle", "reference.vehicle" },
		sRecordDisplayClass = "reference_vehicle",
	},

	-- New record types
	["homeworld"] = {
		bExport = true,
		aDataMap = { "homeworld", "reference.homeworld" },
		sRecordDisplayClass = "reference_homeworld",
	},
	["worlds"] = {
		aDataMap = { "worlds", "reference.worlds" },
		sRecordDisplayClass = "worlds",
		aCustomFilters = {
			["Sector"] = { sField = "sector" },
			["SubSector"] = { sField = "subsector" }
		},
		tOptions = {
			bExport = true,
		},
	},
	["career"] = {
		aDataMap = { "career", "reference.career" },
		sRecordDisplayClass = "reference_career",
		tOptions = {
			bExport = true,
		},
	},
	["race"] = {
		aDataMap = { "race", "reference.race" },
		sRecordDisplayClass = "reference_race",
		tOptions = {
			bExport = true,
		},
	},
	["skill"] = {
		aDataMap = { "skill", "reference.skilldata" },
		sRecordDisplayClass = "reference_skill",
		tOptions = {
			bExport = true,
		},
	},
	["psionic"] = {
		fIsIdentifiable = isItemIdentifiable,
		aDataMap = { "psionic", "reference.psionicdata" },
		sListDisplayClass = "masterindexitem_id",
		fRecordDisplayClass = getPsionicRecordDisplayClass,
		aRecordDisplayClasses = { "reference_psionic" },
		aCustomFilters = {
			["Talent"] = { sField = "talent" },
		},
		tOptions = {
			bExport = true,
			bID = true,
		},
	},
	["spacecraft"] = {
		aDataMap = { "spacecraft", "reference.spacecraft" },
		sRecordDisplayClass = "spacecraft",
		aCustomFilters = {
			["Type"] = { sField = "type" },
		},
		tOptions = {
			bExport = true,
			bPicture = true,
			bToken = true,
		},
	},
	["charspacecraftsheet"] = {
		sSidebarCategory = "player",
		sEditMode = "play",
		aDataMap = {"charspacecraftsheet"},
		fToggleIndex = toggleCharRecordIndex,
		tOptions = {
			bExport = true,
			bPicture = true,
			bToken = true,
		},
	},
	["pcvehicle"] = {
		sSidebarCategory = "player",
		sEditMode = "play",
		aDataMap = {"pcvehicle"},
		fToggleIndex = toggleCharRecordIndex,
		tOptions = {
			bExport = true,
			bPicture = true,
			bToken = true,
		},
	},
	["tradegoods"] = {
		aDataMap = { "tradegoods", "reference.tradegoods" },
		sRecordDisplayClass = "tradegoods",
		tOptions = {
			bExport = true,
		},
	},
	["battle"] = {
		aGMListButtons = { "button_battlespacecraft", "button_battlerandom", "button_battle_quickmap"  },
	},
	["battlespacecraft"] = {
		aDataMap = { "battlespacecraft", "reference.battlespacecraft" },
		tOptions = {
			bExport = true,
			bHidden = true,
		},
	},
	["taskchains"] = {
		aDataMap = { "taskchain", "reference.taskchains" },
		sRecordDisplayClass = "reference_taskchain",
		tOptions = {
			bExport = true,
		},
	},
};

aListViews = {
	["item"] = {
		["weapon"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=200 },
				{ sName = "tl", sType = "number", sHeadingRes = "item_grouped_label_tl", nWidth=50, bCentered=true },
				{ sName = "damage", sType = "string", sHeadingRes = "item_grouped_label_damage", nWidth=150, bCentered=true },
				{ sName = "skill", sType = "string", sHeadingRes = "item_grouped_label_skill", nWidth=100, bCentered=true },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", nWidth=100, bCentered=true },
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Weapons" }
			},
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = {},
		},
		["armour"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=200 },
				{ sName = "tl", sType = "number", sHeadingRes = "item_grouped_label_tl", nWidth=50, bCentered=true },				
				{ sName = "mass", sType = "number", sHeadingRes = "item_grouped_label_weight", nWidth=50, bCentered=true },				
				{ sName = "skill", sType = "string", sHeadingRes = "item_grouped_label_skill", nWidth=100, bCentered=true },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", nWidth=100, bCentered=true },
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Armour" }
			},
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = {},
		},
	},
	["vehicle"] = {
		["bytype"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "vehicle_grouped_label_name", nWidth=200 },
				{ sName = "tl", sType = "number", sHeadingRes = "vehicle_grouped_label_tl", sTooltipRes="vehicle_grouped_tooltip_tl", bCentered=true },
				{ sName = "skill", sType = "string", sHeadingRes = "vehicle_grouped_label_skill", sTooltipRes="vehicle_grouped_tooltip_skill", nWidth=100, bCentered=true },
				{ sName = "cost", sType = "string", sHeadingRes = "vehicle_grouped_label_cost", nWidth=80, bCentered=true },
			},
			aFilters = {},
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = {},
		},
	},
};

function onInit()
	LibraryData.overrideRecordTypes(aRecordOverrides);
	LibraryData.setRecordViews(aListViews);


	-- NPC type data
	npctypedata = {
		Interface.getString("npc_type_patron"),
		Interface.getString("npc_type_npc"),
		Interface.getString("npc_type_creature"),
		Interface.getString("npc_type_drone")
	};
end
