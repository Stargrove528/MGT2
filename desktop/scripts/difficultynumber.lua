local nodeSource = nil;
local bLocked = false;

OOB_MSGTYPE_APPLYTASKDIFFICULTY = "applytaskdifficultychange";

function onInit()
	DB.addHandler("desktoppanel.difficultynumber", "onAdd", onSourceUpdate);
    DB.addHandler("desktoppanel.difficultynumber", "onUpdate", onSourceUpdate);

    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYTASKDIFFICULTY, handleTaskDifficultyChange);

    if Session.IsHost then
        setValue(DB.getValue("desktoppanel.difficultynumber", 0));
        if DB.isPublic("desktoppanel") == false then
            DB.setPublic("desktoppanel", true)
        end
    end
end

function onClose()
	DB.removeHandler("desktoppanel.difficultynumber", "onAdd", onSourceUpdate);
	DB.removeHandler("desktoppanel.difficultynumber", "onUpdate", onSourceUpdate);
end

function onSourceUpdate()
	if bLocked then return; end
	bLocked = true;
    setValue(DB.getValue("desktoppanel.difficultynumber", 0));
	bLocked = false;
end

function onValueChanged()
	if bLocked then return; end
    bLocked = true;
    if Session.IsHost then
        DB.setValue("desktoppanel.difficultynumber", "number", getValue());
    else
        local msgOOB = {};

        msgOOB.type = OOB_MSGTYPE_APPLYTASKDIFFICULTY;
        msgOOB.nValue = getValue()

        Comm.deliverOOBMessage(msgOOB, "");
	end
	bLocked = false;
end

function handleTaskDifficultyChange(msgOOB)

    DB.setValue("desktoppanel.difficultynumber", "number", msgOOB.nValue);

    ChatManager.SystemMessage("Task Difficulty changed to " .. msgOOB.nValue);
end