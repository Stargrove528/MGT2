-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- NPC's Characteristics 

function onLoseFocus()

	local sAttributes = getValue();
	
	-- So let's get each value
	sStrength = string.sub(sAttributes, 1,1);
	sDexterity = string.sub(sAttributes, 2,2);
	sEndurance = string.sub(sAttributes, 3,3);
	sIntelligence = string.sub(sAttributes, 4,4);
	sEducation = string.sub(sAttributes, 5,5);
	sSocial = string.sub(sAttributes, 6,6);

	local nStrength, nDexterity, nEndurance, nIntelligence, nEducation, nSocial;
	
	nStrength = tonumber(sStrength,16);
	nDexterity = tonumber(sDexterity,16);
	nEndurance = tonumber(sEndurance,16);
	nIntelligence = tonumber(sIntelligence,16);
	nEducation = tonumber(sEducation,16);
	nSocial = tonumber(sSocial,16);
	
	window["npc_strength"].setValue(nStrength);
	window["npc_dexterity"].setValue(nDexterity);
	window["npc_endurance"].setValue(nEndurance);
	window["npc_intelligence"].setValue(nIntelligence);
	window["npc_education"].setValue(nEducation);
	window["npc_social"].setValue(nSocial);
end