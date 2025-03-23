VehicleManager = VehicleManager or {};

function VehicleManager.onWeaponDrop(draginfo, nodeTarget)
  local sDragType = draginfo.getType();
  if sDragType ~= "shortcut" then
    return false;
  end

  local sClass, sRecord = draginfo.getShortcutData();
  if sClass ~= "item" then
    return false;
  end

  local nodeSource = DB.findNode(sRecord);
  if not nodeSource then
    return false;
  end

  local sType = DB.getValue(nodeSource, "type", ""):lower();
  local sSubType = DB.getValue(nodeSource, "subtype", ""):lower();

  if not (sType == "weapon" or sType == "weapons" or sType == "heavy weaponry") then
    return false;
  end

  local nodeWeapons = nodeTarget.createChild("weaponlist");
  if not nodeWeapons then
    return false;
  end

  local nodeNew = nodeWeapons.createChild();
  if nodeNew then
    DB.setValue(nodeNew, "name", "string", DB.getValue(nodeSource, "name", ""));
    DB.setValue(nodeNew, "range", "string", DB.getValue(nodeSource, "range", ""));
    DB.setValue(nodeNew, "damage", "string", DB.getValue(nodeSource, "damage", ""));
    DB.setValue(nodeNew, "traits", "string", DB.getValue(nodeSource, "traits", ""));
  end

  return true;
end
