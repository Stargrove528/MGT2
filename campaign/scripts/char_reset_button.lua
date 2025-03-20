--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onButtonPress()
    local sLongStatName = getName():sub(7):lower();
    local sShortStatName = sLongStatName:sub(1,3);
    local nBaseStat = DB.getValue(window.getDatabaseNode(),'attributes.' .. sLongStatName, -1);
    local nStatEquipment = DB.getValue(window.getDatabaseNode(),'attributes.' .. sShortStatName .. '_equipment', -1);
    local nStatModifier = DB.getValue(window.getDatabaseNode(),'attributes.' .. sShortStatName .. '_mod2', -1);
    window['woundtrack_' .. sShortStatName .. '_current'].setValue(nBaseStat + nStatEquipment + nStatModifier);
end