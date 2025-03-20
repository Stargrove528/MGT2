-- PC Vehicle Manager
-- Handles PC Vehicle Records and Sidebar Button

local function createVehicleRecord()
    local nodeVehicle = DB.createChild("pcvehicle");
    if nodeVehicle then
        DB.setValue(nodeVehicle, "name", "string", "New Vehicle");
        return nodeVehicle;
    end
end

function onInit()
    LibraryData.registerRecordType({
        name = "pcvehicle",
        displayname = "PC Vehicle",
        recordtype = "pcvehicle",
        sidebar = "PC VEHICLE",
        onCreate = createVehicleRecord
    });
end
