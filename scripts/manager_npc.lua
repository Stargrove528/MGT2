--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function checkHasSkill(nodeNPC, sRequiredSkill)
    local nSkillLevel = -3;

    -- Get the list we are going to check
    local sSkillsList = DB.getValue(nodeNPC,'skills', '');
    if not sSkillsList then
        return nil;
    end

    local aSkills = {};

    for sSkill in string.gmatch(sSkillsList:lower(), "[^,]+") do
		local sSkill = StringManager.trim(sSkill);
		table.insert(aSkills, sSkill);
	end

    -- Let's look for the skill we require
    local nodeSkill = nil;
    for _, vSkill in pairs(aSkills) do
        sEachSkill = StringManager.trim(vSkill:gsub('%d+',""));

        if (sEachSkill == sRequiredSkill:lower()) then
            nSkillLevel = vSkill:match('%d+');
            break;
        end
    end

    return nSkillLevel;
end

