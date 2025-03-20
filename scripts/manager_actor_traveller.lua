--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActorManager.registerActorRecordType("charspacecraftsheet");
	ActorManager.registerActorRecordType("spacecraft");
	ActorManager.registerActorRecordType("vehicle");


	ActorManagerTraveller.initActorHealth();
end

function initActorHealth()
	ColorManager.getTieredHealthColor = ActorManagerTraveller.getTieredHealthColor;
	ActorHealthManager.getWoundPercent = ActorManagerTraveller.getWoundPercent;
end

function getTieredHealthColor(nPercentWounded)
	local sColor;
	if nPercentWounded >= 1 then
		sColor = ColorManager.getUIColor("health_dyingordead");
	elseif nPercentWounded <= 0 then
		sColor = ColorManager.getUIColor("health_unwounded");
	elseif nPercentWounded <= 0.33 then
		sColor = ColorManager.getUIColor("health_wounds_light");
	elseif nPercentWounded <= 0.66 then
		sColor = ColorManager.getUIColor("health_wounds_moderate");
	else
		sColor = ColorManager.getUIColor("health_wounds_heavy");
	end
	return sColor;
end
function getWoundPercent(v)
	local rActor = ActorManager.resolveActor(v);

	local nTotalHP, nCurrentHealth, nDeathDice, nPercentWounded;

	local nodeCT = ActorManager.getCTNode(rActor);
	local sNPCType = DB.getValue(nodeCT, "type", "humannoid"):lower()
	if sNPCType ~= "animal" and sNPCType ~= "robot" then
		nTotalAttributes = DB.getValue(nodeCT, "attributes.dexterity", 0) +
				DB.getValue(nodeCT, "attributes.endurance", 0) +
				DB.getValue(nodeCT, "attributes.strength", 0);
		nCurrentHealth = DB.getValue(nodeCT, "woundtrack.dex", 0) +
				DB.getValue(nodeCT, "woundtrack.end", 0) +
				DB.getValue(nodeCT, "woundtrack.str", 0);
	else
		nCurrentHealth = DB.getValue(nodeCT, "woundtrack.hits", 0);
		nTotalAttributes = DB.getValue(nodeCT, "hits", 0);
	end

	local sStatus;
	if nCurrentHealth <= 0 then
		nPercentWounded = 1;
		sStatus = ActorHealthManager.STATUS_DEAD;
	else
		nPercentWounded = 1 - (nCurrentHealth / nTotalAttributes)
		local nHealthLeft = (nCurrentHealth / nTotalAttributes) * 100

		if nPercentWounded >= 1 then
			sStatus = ActorHealthManager.STATUS_DEAD;
		elseif nPercentWounded >= .90 and sNPCType == "animal" then
			sStatus = ActorHealthManager.STATUS_UNCONSCIOUS;
		else
			if nPercentWounded >= 0.66 then
				sStatus = ActorHealthManager.STATUS_HEAVY;
			elseif nPercentWounded >= 0.33 then
				sStatus = ActorHealthManager.STATUS_MODERATE;
			elseif nPercentWounded > 0 then
				sStatus = ActorHealthManager.STATUS_LIGHT;
			else
				sStatus = ActorHealthManager.STATUS_HEALTHY;
			end
		end
	end

	return nPercentWounded, sStatus;
end

function getShipWoundColor(nodeCT)
	local nPercentWounded, sStatus = ActorManagerTraveller.getShipWoundPercent(nodeCT);
	local sColor;
	if sStatus == ActorHealthManager.STATUS_DISABLED then
		sColor = ColorManager.getUIColor("health_simple_bloodied");
	else
		sColor = ColorManager.getHealthColor(nPercentWounded, true);
	end
	return sColor, nPercentWounded, sStatus;
end
function getShipWoundPercent(nodeCT)
	local nHP = math.max(DB.getValue(nodeCT, "hptotal", 0), 0);
	local nWounds = math.max(DB.getValue(nodeCT, "hpdamage", 0), 0);
	local nPercentWounded = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end

	local sStatus = "";
	if nPercentWounded > 1 then
		sStatus = ActorHealthManager.STATUS_DESTROYED;
	elseif nPercentWounded == 1 then
		sStatus = ActorHealthManager.STATUS_DISABLED;
	elseif nPercentWounded > 0 then
		if nPercentWounded >= .8 then
			sStatus = "Critical Damage";
		elseif nPercentWounded >= .6 then
			sStatus = "Major Damage";
		elseif nPercentWounded >= .25 then
			sStatus = "Minor Damage";
		elseif nPercentWounded >= .05 then
			sStatus = "Superficial";
		else
			sStatus = "No Damage";
		end
	end
	return nPercentWounded, sStatus;
end
