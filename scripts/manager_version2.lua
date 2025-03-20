local rsname = "MGT2";
local rsmajorversion = 6;

function onInit()
	if Session.IsHost then
		VersionManager2.updateCampaign();
	end

	Module.addEventHandler("onModuleLoad", onModuleLoad);
end
function onModuleLoad(sModule)
	local _,_,aMajor = DB.getRulesetVersion(sModule);
	updateModule(sModule, aMajor[rsname]);
end

function updateCampaign()
	local _,_,aMajor,aMinor = DB.getRulesetVersion();
	local major = aMajor[rsname];
	if not major then
		return;
	end

	if major > 0 and major < rsmajorversion then
		ChatManager.SystemMessage("Migrating campaign database to latest data version.");
		DB.backup();

		if major < 6 then
			VersionManager2.convertCharspacecraft6();
		end
	end
end
function updateModule(sModule, nVersion)
	if not nVersion then
		nVersion = 0;
	end

	if nVersion < rsmajorversion then
		local nodeRoot = DB.getRoot(sModule);
		if nVersion < 6 then
			VersionManager2.convertCharspacecraft6(nodeRoot);
		end
	end
end

function convertCharspacecraft6(nodeRoot)
	if nodeRoot then
		for _,nodeCharspacecraft in ipairs(DB.getChildList(nodeRoot, "charspacecraftsheet")) do
			VersionManager2.migrateCharspacecraft6(nodeCharspacecraft, nodeRoot);
		end
	else
		for _,nodeCharspacecraft in ipairs(DB.getChildList("charspacecraftsheet")) do
			VersionManager2.migrateCharspacecraft6(nodeCharspacecraft);
		end
	end
end

function migrateCharspacecraft6(nodeCharspacecraft, nodeRoot)
	if DB.getType(nodeCharspacecraft, "notes") == "formattedtext" then
		return;
	end

	local sNotes = DB.getValue(nodeCharspacecraft, "notes", "");
	local sModifiedText = "<p>" .. sNotes .. "</p>";
	DB.deleteChild(nodeCharspacecraft, "notes");
	DB.setValue(nodeCharspacecraft, "notes", "formattedtext", sModifiedText);
end