-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Physical Characteristics
physicalcharacteristics = {
	"STR",
	"END",
	"DEX"
};

-- Non-physical Characteristics
nonphysicalcharacteristics = {
	"INT",
	"EDU",
	"SOC",
	"MOD",
	"PSI",
	"LUC",
	"MOR",
	"SAN",
	"TER",
	"WEA",
	"CHA",
	"RES"
};

-- All Characteristics
allcharacteristics = {
	"STR",
	"END",
	"DEX",
	"INT",
	"EDU",
	"SOC",
	"PSI",
	"LUC",
	"MOR",
	"SAN",
	"TER",
	"WEA",
	"CHA",
	"RES"
};

allcharacteristicstitles = {
	"Strength",
	"Endurance",
	"Dexterity",
	"Intellect",
	"Education",
	"Social",
	"PSI",
	"Luck",
	"Morale",
	"Sanity",
	"Territory",
	"Wealth",
	"Charisma",
	"Resolve"
};

creaturetype = {
	"Animal",
	"Humanoid",
	"Robot",
	"Android",
	"Other",
};

-- Damage types supported
dmgtypes = {
	"kinetic",
	"laser",
	"psionic",
	"radiation",
	"energy",
	"plasma",
	"stun",
	"fire",
	"corrosive",
	"ap",
	"sap",
	"super-ap",
	"poison",
	"acid",
	"sonic"
};

-- Damage types supported
shipdmgtypes = {
	"kinetic",
	"laser",
	"ion",
	"radiation",
	"energy",
	"plasma",
	"missile",
	"missiles",
	"fire",
	"corrosive",
	"fusion",
	"tachyon",
	"torpedo",
};

-- Conditions supported in effect conditionals and for token widgets
conditions = {
	"unconscious",
	"fatigued",
	"micro gravity",
	"minimum gravity",
	"very low gravity",
	"low gravity",
	"high gravity",
	"extreme gravity",
	"fire",
	"poisoned",
	"head major wound",
	"head severe wound",
	"arms major wound",
	"arms severe wound",
	"torso major wound",
	"torso severe wound",
	"legs major wound",
	"legs severe wound",
	"prone target",
	"target in cover",
}

-- spacecraftroleslist = {
-- 	"Administator",
-- 	"Astrogator",
-- 	"Captain",
-- 	"Engineer",
-- 	"Gunner",
-- 	"Maintenance",
-- 	"Marine",
-- 	"Medic",
-- 	"Officer",
-- 	"Pilot",
-- 	"Steward",
-- 	"Other"
-- };

-- spacecraftroles = {
-- 	"administator",
-- 	"astrogator",
-- 	"captain",
-- 	"engineer",
-- 	"gunner",
-- 	"maintenance",
-- 	"marine",
-- 	"medic",
-- 	"officer",
-- 	"pilot",
-- 	"steward",
-- 	"other"
-- };

aSpacecraftCriticals = {
	"",
	"Sensors",
	"Power Plant",
	"Fuel",
	"Weapon",
	"Armour",
	"Hull",
	"M-Drive",
	"Cargo",
	"J-Drive",
	"Crew",
	"Computer"
}

aSpacecraftCriticalHitEffects = {
	["Sensors"] = { "All checks to use sensors suffer DM-2", "Sensors inoperative beyond Medium range", "Sensors inoperative beyond Short range", "Sensors inoperative beyond Close range", "Sensors inoperative beyond Adjacent range", "Sensors disabled" },
	["Power Plant"] = { "Thrust reduced by -1. Power reduced by 10%", "Thrust reduced by -1. Power reduced by 10%", "Thrust reduced by -1. Power reduced by 50%", "Thrust reduced to zero. Power reduced to 0", "Thrust reduced to zero, Hull Severity increased by +1. Power reduced to 0", "Thrust reduced to zero, Hull Severity increased by +1D. Power reduced to 0" },
	["Fuel"] = { "Leak - lose 1D tons of fuel per hour", "Leak - lose 1D tons of fuel per round", "Leak - lose 1D x 10% of fuel", "Fuel tank destroyed", "Fuel tank destroyed, Hull Severity increased by +1", "Fuel tank destroyed, Hull Severity increased by +1D" },
	["Weapon"] = { "Random weapon suffers Bane when used", "Random weapon disabled", "Random weapon destroyed", "Random weapon explodes, Hull Severity increased by +1", "Random weapon explodes, Hull Severity increased by +1", "Random weapon explodes, Hull Severity increased by +1" },
	["Armour"] = { "Armour reduced by -1", "Armour reduced by -D3", "Armour reduced by -1D", "Armour reduced by -1D", "Armour reduced by -2D, Hull Severity increased by +1", "Armour reduced by -2D, Hull Severity increased by +1" },
	["Hull"] = { "Spacecraft suffers 1D damage", "Spacecraft suffers 2D damage", "Spacecraft suffers 3D damage", "Spacecraft suffers 4D damage", "Spacecraft suffers 5D damage", "Spacecraft suffers 6D damage" },
	["M-Drive"] = { "All checks to control spacecraft suffer DM-1", "All checks to control spacecraft suffer DM-2, and Thrust reduced by -1", "All checks to control spacecraft suffer DM-3, and Thrust reduced by -1", "All checks to control spacecraft suffer DM-4, and Thrust reduced by -1", "Thrust reduced to zero", "Thrust reduced to zero, Hull Severity increased by +1" },
	["Cargo"] = { "10% of cargo destroyed", "1D x 10% of cargo destroyed", "2D x 10% of cargo destroyed", "All cargo destroyed", "All cargo destroyed, Hull Severity increased by +1", "All cargo destroyed, Hull Severity increased by +1" },
	["J-Drive"] = { "All checks to use jump drive suffer DM-2", "Jump drive disabled", "Jump drive destroyed", "Jump drive destroyed, Hull Severity increased by +1", "Jump drive destroyed, Hull Severity increased by +1", "Jump drive destroyed, Hull Severity increased by +1" },
	["Crew"] = { "Random occupant takes 1D damage", "Life support fails within 1D hours", "1D occupants take 2D damage", "Life support fails within 1D rounds", "All occupants take 3D damage", "Life support fails" },
	["Computer"] = { "All checks to use computers suffer DM-2", "Computer rating reduced by -1", "Computer rating reduced by -1", "Computer rating reduced by -1", "Computer disabled", "Computer destroyed" }
}

aCombatMishaps = {
	[2] = "Shoot or hit themself for normal weapon damage.",
	[3] = "The weapon is dropped somewhere inaccessible. It cannot be retrieved during this fight, and if the Travellers are forced to flee it will not be recoverable.",
	[4] = "The weapon is dropped somewhere inaccessible. It cannot be retrieved during this fight, and if the Travellers are forced to flee it will not be recoverable.",
	[5] = "The weapon is dropped but in sight. It can be recovered in a future round using a significant action.", 
	[6] = "The weapon is dropped but in sight. It can be recovered in a future round using a significant action.", 
	[7] = "A minor weapon malfunction or loss of proper grip has occurred. Any attack made this round is wasted but the weapon can be brought back into action by making an Easy (6+) skill check next round. This takes significant action and, if failed, the attempt must be repeated every round.",
	[8] = "A serious weapon malfunction has occurred, putting the weapon out of action until it can be fixed in a workshop.",
	[9] = "A serious weapon malfunction has occurred, putting the weapon out of action until it can be fixed in a workshop.",
	[10] = "The weapon is destroyed in ammunition explosion or other serious incident that causes critical structural damage to it.",
	[11] = "The weapon is destroyed in ammunition explosion or other serious incident that causes critical structural damage to it.",
	[12] = "The skill attempt fails but no Mishap has occurred beyond that",
}

aHitLocations = {
	[1] = "Head",
	[2] = "Arms",
	[3] = "Torso",
	[4] = "Torso",
	[5] = "Torso",
	[6] = "Legs",
}

aWoundEffects = {
	["Head"] = { "DM-1 on all checks", "DM-2 on all checks" },
	["Arms"] = { "DM-1 on all checks involving the arms", "DM-1 on all checks involving the arms" },
	["Torso"] = { "DM-1 on all physical checks; speed reduced by 1m", "DM-2 on all physical checks. Traveller can only craw unless supported." },
	["Legs"] = { "Speed reduced by 2m. DM-1 on all movement-based checks", "Leg disabled; Traveller can only hobble slowly with support. No movement-based activity is possible." },
}

aDisablingWoundEffects = {
	[1] = "The Traveller is vaporised, shredded, spread all over the landscape or otherwise destroyed in graphic and gruesome fashion.",
	[2] = "The Traveller is either killed outright in a dramatic fashion such as having their head blown off, or lingers just long enough to make a final speech to their friends/enemies/passersby. They cannot be saved in either case.",
	[3] = "The Traveller is either killed outright in a dramatic fashion such as having their head blown off, or lingers just long enough to make a final speech to their friends/enemies/passersby. They cannot be saved in either case.",
	[4] = "The Traveller will die unless given prompt medical assistance. If they survive, they will lose the limb that was injured, or an eye, or suffer some similar major permanent injury as determined by the referee. This can of course be repaired with cybernetics, but the process will be slow and expensive.",
	[5] = "The Traveller will die unless given prompt medical assistance. If they survive, they will lose the limb that was injured, or an eye, or suffer some similar major permanent injury as determined by the referee. This can of course be repaired with cybernetics, but the process will be slow and expensive.",
	[6] = "The Traveller will die unless given prompt medical assistance, and suffer permanent effects if they survive at all. Lose 1D from any one of STR, DEX or END and D3 from the others.",
	[7] = "The Traveller will die unless given prompt medical assistance, and suffer permanent effects if they survive at all. Lose 1D from any one of STR, DEX or END and D3 from the others.",
	[8] = "The Traveller will survive if given even the most basic emergency assistance, and suffer no ill effects providing they receive proper medical treatment whilst recovering. If it is not, the Traveller will permanently lose D3 points from both STR and END.",
	[9] = "The Traveller will survive if given even the most basic emergency assistance, and suffer no ill effects providing they receive proper medical treatment whilst recovering. If it is not, the Traveller will permanently lose D3 points from both STR and END.",
	[10] = "The Traveller will survive despite their injuries, even without assistance, and will make a full recovery if medical attention is successfully provided.",
	[11] = "The Traveller will survive despite their injuries, even without assistance, and will make a full recovery if medical attention is successfully provided.",
	[12] = "The Traveller is terribly hurt but will somehow cling to life and begin to recover even if medical attention is not provided.",
}

starportquality = {
	["A"] = "Excellent",
	["B"] = "Good",
	["C"] = "Routine",
	["D"] = "Poor",
	["E"] = "Frontier"
}

size = {
	["1"] = "1,600km",
	["2"] = "3,200km, Triton, Luna, Europa",
	["3"] = "4,800km, Mercury, Ganymede",
	["4"] = "6,400km, Mars",
	["5"] = "8,000km",
	["6"] = "9,600km",
	["7"] = "11,200km",
	["8"] = "12,800km Earth",
	["9"] = "14,400km",
	["10"] = "16,000km",
	["A"] = "16,000km"
}

atmospheretype = {
	["0"] = "None",
	["1"] = "Trace",
	["2"] = "Very Thin, Tainted",
	["3"] = "Very Thin",
	["4"] = "Thin, Tainted",
	["5"] = "Thin",
	["6"] = "Standard",
	["7"] = "Standard, Tainted",
	["8"] = "Dense",
	["9"] = "Dense, Tainted",
	["10"] = "Exotic",
	["A"] = "Exotic",
	["11"] = "Corrosive",
	["B"] = "Corrosive",
	["12"] = "Insidious",
	["C"] = "Insidious",
	["13"] = "Dense, High",
	["D"] = "Dense, High",
	["14"] = "Thin, Low",
	["E"] = "Thin, Low",
	["15"] = "Unusual",
	["F"] = "Unusual"
}

hydrographics = {
	["0"] = "0%-5% Desert world",
	["1"] = "6%-15% Dry world",
	["2"] = "16%-25% A few small seas",
	["3"] = "26%-35% Small seas and oceans",
	["4"] = "36%-45% Wet world",
	["5"] = "46%-55% Large oceans",
	["6"] = "56%-65%",
	["7"] = "66%-75% Earth-like world",
	["8"] = "76%-85% Water world",
	["9"] = "86%-95% Only a few small islands and archipelagos",
	["10"] = "96-100% Almost entirely water",
	["A"] = "96-100% Almost entirely water"
}

population = {
	["0"] = "None",
	["1"] = "Few",
	["2"] = "Hundreds",
	["3"] = "Thousands",
	["4"] = "Tens of Thousands",
	["5"] = "Hundreds of thousands",
	["6"] = "Millions",
	["7"] = "Tens of millions",
	["8"] = "Hundreds of millions",
	["9"] = "Billions",
	["10"] = "Tens of billions",
	["A"] = "Tens of billions",
	["11"] = "Hundreds of billions",
	["B"] = "Hundreds of billions",
	["12"] = "Trillions",
	["C"] = "Trillions"
}

governmenttype = {
	["0"] = "None",
	["1"] = "Company/corporation",
	["2"] = "Participating democracy",
	["3"] = "Self-perpetuating oligarchy",
	["4"] = "Representative democracy",
	["5"] = "Feudal technocracy",
	["6"] = "Captive government",
	["7"] = "Balkanisation",
	["8"] = "Civil service bureaucracy",
	["9"] = "Impersonal Bureaucracy",
	["10"] = "Charismatic dictator",
	["A"] = "Charismatic dictator",
	["11"] = "Non-charismatic leader",
	["B"] = "Non-charismatic leader",
	["12"] = "Charismatic oligarchy",
	["C"] = "Charismatic oligarchy",
	["13"] = "Religious dictatorship",
	["D"] = "Religious dictatorship"
}

lawlevel = {
	["0"] = "No restrictions - heavy armour and a handy weapon recommended...",
	["1"] = "No Poison gas, explosives, undetectable weapons, WMD or Battle Dress",
	["2"] = "No Portable energy and laser weapons or Combat armour",
	["3"] = "No Military weapons or Flak armour",
	["4"] = "No Light assault weapons and submachine guns or Cloth armour",
	["5"] = "No Personal concealable weapons or Mesh armour",
	["6"] = "No firearms except shotguns & stunners; carrying weapons discouraged",
	["7"] = "No Shotguns",
	["8"] = "No bladed weapons, stunners or visible armour",
	["9"] = "No weapons, No armour",
	["A"] = "No weapons, No armour",
	["10"] = "No weapons, No armour",
	["B"] = "No weapons, No armour",
	["11"] = "No weapons, No armour",
	["C"] = "No weapons, No armour",
	["12"] = "No weapons, No armour",
	["D"] = "No weapons, No armour",
	["13"] = "No weapons, No armour"
}

tradecodes = {
	["ag"] = "Agricultural",
	["as"] = "Asteroid",
	["ba"] = "Barren",
	["de"] = "Desert",
	["fl"] = "Fluid Oceans",
	["ga"] = "Garden",
	["hi"] = "High Population",
	["ht"] = "High Tech",
	["ic"] = "Ice-Capped",
	["in"] = "Industrial",
	["lo"] = "Low Population",
	["lt"] = "Low Tech",
	["na"] = "Non-Agricultural",
	["ni"] = "Non-Industrial",
	["po"] = "Poor",
	["ri"] = "Rich",
	["va"] = "Vacuum",
	["wa"] = "Water World"
}

basecodes = {
	["a"] = "Naval Base and Scout Base",
	["b"] = "Naval Base and Way Station",
	["c"] = "Vargr Corsair Base",
	["d"] = "Naval Depot (Depot)",
	["e"] = "Hiver Assembly Center",
	["f"] = "Military and Naval Base",
	["g"] = "Vargr Naval Base",
	["h"] = "Vargr Naval Base and Corsair Base",
	["j"] = "Naval Base",
	["k"] = "K'kree Naval Base",
	["l"] = "Hiver Naval Base",
	["m"] = "Miliary Base",
	["n"] = "Naval Base",
	["o"] = "K'kree Naval Outpost",
	["p"] = "Droyne Naval Base",
	["q"] = "Droyne Military Garrison",
	["r"] = "Aslan Clan Base",
	["s"] = "Scout Base",
	["t"] = "Aslan Tiaukhu Base",
	["u"] = "Aslan Tiaukhu and Clan Base",
	["v"] = "Scout/Exploration Base",
	["w"] = "Way Station",
	["x"] = "Zhodani Relay Station",
	["y"] = "Zhodani Depot",
	["z"] = "Zhodani Naval and Military Base",
}

travelcodes = {
	["-"] = "Green Zone (no danger)",
	["g"] = "Green Zone (no danger)",
	["a"] = "Amber Zone (caution advised)",
	["b"] = "Blue Zone (caution advised)",
	["r"] = "Red Zone (severe danger)",
	["w"] = "Black Zone (Wilds)"
}

weapontraits = {
	["ap"] = "This weapon has the ability to punch through armour through the use of specially shaped ammunition or high technology. It will ignore an amount of Armour equal to the AP score listed. Spacecraft Scale targets (see page 157) ignore the AP trait unless the weapon making the attack is also Spacecraft Scale.",
	["artillery"] = "Artillery weapons shoot projectiles along a ballistic trajectory, allowing them to ‘lob’ shots at targets that are	out of sight. When firing at a target that can be seen, these	Artillery weapons follow the usual rules for ranged attacks.",
	["auto"] = "These weapons fire multiple rounds with every pull of the trigger, filling the air with a hail of fire. A weapon with the Auto trait can make attacks in three fire modes: single, burst, and full auto.",
	["blast"] = "This weapon has an explosive component or is otherwise able to affect targets spread across a wide area. Upon a successful attack, damage is rolled against every target within the weapon’s Blast score in metres. Dodge Reactions may not be made against a Blast weapon, but targets may dive for cover. Cover may be taken advantage of if it lies between a target and the centre of the weapon’s Blast.",
	["bulky"] = "A Bulky weapon has a powerful recoil or is simply extremely heavy - this makes it difficult to use effectively in combat by someone of a weak physical stature. A Traveller using a Bulky weapon must have STR 9 or higher to use it without penalty. Otherwise, all attack rolls will have a negative DM equal to the difference between their STR DM and +1.",
	["dangerous"] = "This weapon can be as lethal to the Traveller using it as his intended target. If an attack roll is made by this weapon with an Effect of -5 or worse, it explodes. Its damage is inflicted upon the Traveller firing it, and the weapon is rendered inoperable.",
	["fire"] = "This weapon sets a target on fire, causing damage every round after the initial attack. A target can only be set on fire by one Fire weapon at a time - use the highest damage Fire weapon. Left to its own devices, a fire will extinguish itself on a 2D roll of 8+, rolled for at the start of every round. However, the referee may rule it continues to burn so long as flammable material is present. A Traveller may use a Significant Action to extinguish requiring an Average (8+) DEX check. The Traveller gains DM+2 if they are using firefighting equipment.",
	["one use"] = "This weapon is designed to be used just once, completely expending its energy or ammunition in one go and then being rendered useless.",
	["radiation"] = "When a Radiation weapon is fired, anyone close to the firer, target and the line of fire in-between the two will receive 2D x 20 rads, multiplied by 5 for Spacecraft scale weapons. This effect extends from the firer, target and line of fire a distance in metres equal to the number of dice the weapon rolls for damage. If the fusion weapon is Destructive, this distance becomes ten times the number of dice rolled for damage.",
	["scope"] = "The weapon has been fitted with vision-enhancing sights, allowing it to put shots on target from far greater ranges. A weapon with the Scope trait ignores the rule that limits all attacks made at a range greater than 100 metres are automatically Extreme Range, so long as the Traveller aims before shooting.",
	["silent"] = "Most projectile weapons require a noisy discharge of chemical, heat or kinetic energy in order to attack, but this weapon channels or removes the excess sound energy also created. Any attempts to detect the sound of this weapon firing suffer DM-6.",
	["smart"] = "This weapon has intelligent or semi-intelligent rounds that are able to guide themselves onto a target. They gain a DM to their attack rolls equal to the difference between their TL and that of the target, to a minimum of DM+1 and a maximum of DM+6.",
	["smasher"] = "This weapon is particularly heavy and carries a great deal of momentum when it is swung. A Traveller attacked by a Smasher weapon may not attempt to parry it.",
	["stun"] = "These weapons are designed to deal non-lethal damage, incapacitating a living target rather than killing it. Damage is only deducted from END, taking into account any armour. If the target’s END is reduced to 0, the target will be incapacitated and unable to perform any actions for a number of rounds by which the damage exceeded his END. Damage received from Stun weapons is completely healed by one hour of rest.",
	["very bulky"] = "Some weapons are designed only for the strongest combatants. A Traveller using a Very Bulky weapon must have STR 12 or higher to use it without penalty. Otherwise, all attack rolls will have a negative DM equal to the difference between their STR DM and +2. Zero-G: This weapon has little or no recoil, allowing it to be used in low or zero gravity situations without requiring an Athletics (dexterity) check.",
	["very dangerous"] = "Only a madman uses a weapon with the reputation of this one. If an attack roll is made by this weapon with an Effect of -3 or worse, it explodes. Its damage is inflicted upon the Traveller firing it, and the weapon is rendered inoperable.",
	["zero-g"] = "This weapon has little or no recoil, allowing it to be used in low or zero gravity situations without	requiring an Athletics (dexterity) check."
}

spacecraftdefaultdetails = {
	"Hull",
	"Armour",
	"M-Drive",
	"J-Drive",
	"Power Plant",
	"Fuel Tanks",
	"Bridge",
	"Computer",
	"Sensors",
	"Weapons",
	"Systems",
	"Staterooms",
	"Software",
	"Common Areas",
	"Cargo"
}

radiationstatusesimmediate = {
	[1] = "None",
	[2] = "1D damage, Nausea (-1 to all checks until medical treatment received)",
	[3] = "2D damage",
	[4] = "4D damage, hair loss",
	[5] = "6D damage, sterile",
	[6] = "8D damage, internal bleeding",
}

radiationstatusescumulative = {
	[1] = "None",
	[2] = "None",
	[3] = "-1 END permanently",
	[4] = "-2 END permanently",
	[5] = "-3 END permanently",
	[6] = "-4 END permanently",
}

function onInit()
	optional_characterisics_stol = {
		["psi"] = Interface.getString("PSI"),
		["luc"] = Interface.getString("luck"),
		["mor"] = Interface.getString("morale"),
		["san"] = Interface.getString("sanity"),
		["ter"] = Interface.getString("territory"),
		["wea"] = Interface.getString("wealth"),
		["cha"] = Interface.getString("charm"),
		["res"] = Interface.getString("resolve")
	};

	-- Party sheet drop down list data
	pscharacteristicsdata = {
		Interface.getString("strength"),
		Interface.getString("endurance"),
		Interface.getString("dexterity"),
		Interface.getString("intellect"),
		Interface.getString("education"),
		Interface.getString("social"),
		Interface.getString("PSI"),
		Interface.getString("luck"),
		Interface.getString("morale"),
		Interface.getString("sanity"),
		Interface.getString("territory"),
		Interface.getString("wealth"),
		Interface.getString("charisma"),
		Interface.getString("resolve")
	};

	-- Default Characteristics
	psdefaultcharacteristicsdata = {
		Interface.getString("strength"),
		Interface.getString("endurance"),
		Interface.getString("dexterity"),
		Interface.getString("intelligence"),
		Interface.getString("education"),
		Interface.getString("social"),
	};

	-- Optional Characteristics
	psoptionalcharacteristicsdata = {
		[Interface.getString("PSI")] = "psi",
		[Interface.getString("luck")] = "luc",
		[Interface.getString("morale")] = "mor",
		[Interface.getString("sanity")] = "san",
		[Interface.getString("territory")] = "ter",
		[Interface.getString("wealth")] = "wea",
		[Interface.getString("charm")] = "cha",
		[Interface.getString("resolve")] = "res"
	};
end