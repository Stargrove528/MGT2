--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	if draginfo.isType("skill") then
		local sDesc = draginfo.getDescription():lower();
		local sRequiredSkill = skillrequired.getValue():lower();
		local sTaskDifficulty = taskdifficulty.getValue():lower();
		local nTaskDifficulty = tonumber(string.match(sTaskDifficulty, "%d+"));
		local sBaseSkill = StringManager.trim(sDesc:gsub("(%b())",''):lower())
		sBaseSkill = StringManager.trim(sBaseSkill:gsub("%[.-%]",""));

		if string.find(sDesc, sRequiredSkill, nil, true) or string.find(sRequiredSkill, sBaseSkill) or (sBaseSkill == "unskilled skill") or (sBaseSkill == "jack of all trades") then
			local nodeWin = getDatabaseNode();
			if nodeWin then
				local w = Interface.findWindow("difficultynumber", "");
				w.difficultynumber.setValue(nTaskDifficulty);
				return TaskChainManager.onDrop("tc", DB.getPath(nodeWin), draginfo);
			end
		end
	end
end
