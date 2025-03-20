-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
    if draginfo.isType("shortcut") then

        local sFullClass = draginfo.getShortcutData();
        local node = draginfo.getDatabaseNode();
        local sClass = string.sub(sFullClass,1,17)
        local sTalent = string.sub(sFullClass,18)

        if StringManager.contains({"reference_psionic"}, sClass) then
           CharManager.addInfoDB(DB.getParent(getDatabaseNode()), node, sClass, sTalent);
            return true;
        end
    end
end
