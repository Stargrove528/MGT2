--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	addUnskilled();
end

function addUnskilled()
	if not isEmpty() then
		return;
	end
	-- Add the UnSkilled skill --

	-- Get the list we are going to add to
	local nodeList = DB.createChild(DB.getParent(getDatabaseNode()), "skilllist");
	if not nodeList then
		return nil;
	end

	local nodeSkill = DB.createChild(nodeList);
	DB.setValue(nodeSkill, "name", "string", "Unskilled Skill");
	DB.setValue(nodeSkill, "level", "number", -3);
	DB.setValue(nodeSkill, "bAllowDelete", "number", 0);
	DB.setValue(nodeSkill, "noedit", "number", 1);
	DB.setValue(nodeSkill, "text", "formattedtext", "<p>The Unskilled skill covers all the skills you don't have.</p>");

	return;
end

function onDrop(x, y, draginfo)
    if draginfo.isType("shortcut") then
        local sClass = draginfo.getShortcutData();
        local node = draginfo.getDatabaseNode();
        if StringManager.contains({"reference_skill"}, sClass) then
            CharManager.addInfoDB(DB.getParent(getDatabaseNode()), node, sClass);
            return true;
        end
    end
end

function onUpdate()
	local wStudyWindow = window.studyperiodwindow.window;
	local sSTUDYP = OptionsManager.getOption("STUDYP");

	wStudyWindow.char_studyperiod_content.studyperiodtitle.setVisible(false);
end
