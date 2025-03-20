--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- NPC's Characteristics' DM's

function onSourceUpdate()
	local nValue = calculateSources();
	setValue(GameSystem.calculateCharacteristicDM(nValue))

	-- now to rebuild the UPP
	lcStrength = DEC_HEX(window["npc_strength"].getValue());
	lcDexterity = DEC_HEX(window["npc_dexterity"].getValue());
	lcEndurance = DEC_HEX(window["npc_endurance"].getValue());
	lcIntelligence = DEC_HEX(window["npc_intelligence"].getValue());
	lcEducation = DEC_HEX(window["npc_education"].getValue());
	lcSocial = DEC_HEX(window["npc_social"].getValue());

	lcUPP = lcStrength .. lcDexterity .. lcEndurance .. lcIntelligence .. lcEducation .. lcSocial;

	window["upp"].setValue(lcUPP);
end

function action(draginfo)
	local nTotal = getValue();
	local sAttribute = getName();

	sAttribute = string.sub(sAttribute:upper(),1,3);

	local rActor = ActorManager.resolveActor(window.getDatabaseNode());

	ActionsCharacteristics.performRoll(draginfo, rActor, 2, sAttribute, nTotal, 0);
end

function onDoubleClick(x, y)
	action();
	return true;
end

function onDragStart(button, x, y, draginfo)
	action(draginfo);
	return true;
end

function DEC_HEX(IN)
    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.mod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
	end
	-- if the value is empty, set it "0"
	if OUT == "" then
		OUT = "0";
	end
    return OUT
end