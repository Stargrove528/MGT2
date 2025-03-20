function onInit()
  local name = "Core";
  local skilldata = {
    ["Admin"] = { spent=-3, attribute="", attributeDM=0},
    ["Advocate"] = { spent=-3, attribute="", attributeDM=0},
    ["Animals"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Athletics"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Art"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Astrogation"] = { spent=-3, attribute="", attributeDM=0},
    ["Battle Dress"] = { spent=-3, attribute="", attributeDM=0},
    ["Broker"] = { spent=-3, attribute="", attributeDM=0},
    ["Carouse"] = { spent=-3, attribute="", attributeDM=0},
    ["Comms"] = { spent=-3, attribute="", attributeDM=0},
    ["Computers"] = { spent=-3, attribute="", attributeDM=0},
    ["Deception"] = { spent=-3, attribute="", attributeDM=0},
    ["Diplomat"] = { spent=-3, attribute="", attributeDM=0},
    ["Drive"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Engineer"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Explosives"] = { spent=-3, attribute="", attributeDM=0},
    ["Flyer"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Explosives"] = { spent=-3, attribute="", attributeDM=0},
    ["Gambler"] = { spent=-3, attribute="", attributeDM=0},
    ["Gun Combat"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Gunner"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Heavy Weapons"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Investigate"] = { spent=-3, attribute="", attributeDM=0},
    ["Jack of all Trades"] = { spent=-3, attribute="", attributeDM=0},
    ["Language"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Leadership"] = { spent=-3, attribute="", attributeDM=0},
    ["Life Sciences"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Mechanic"] = { spent=-3, attribute="", attributeDM=0},
    ["Medic"] = { spent=-3, attribute="", attributeDM=0},
    ["Melee"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Navigation"] = { spent=-3, attribute="", attributeDM=0},
    ["Persuade"] = { spent=-3, attribute="", attributeDM=0},
    ["Pilot"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Physical Sciences"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Recon"] = { spent=-3, attribute="", attributeDM=0},
    ["Remote Operations"] = { spent=-3, attribute="", attributeDM=0},
    ["Seafarer"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Sensors"] = { spent=-3, attribute="", attributeDM=0},
    ["Social Sciences"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Space Sciences"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Stealth"] = { spent=-3, attribute="", attributeDM=0},
    ["Steward"] = { spent=-3, attribute="", attributeDM=0},
    ["Streetwise"] = { spent=-3, attribute="", attributeDM=0},
    ["Survival"] = { spent=-3, attribute="", attributeDM=0},
    ["Tactics"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Trade"] = { sublabeling=true, spent=-3, attribute="", attributeDM=0},
    ["Vacc Suit"] = { spent=-3, attribute="", attributeDM=0},
    ["Zero-G"] = { spent=-3, attribute="", attributeDM=0},
    ["Unskilled"] = { spent=-3, attribute="", attributeDM=0},
  }

	function getSkills()
		return skilldata;
	end

	function getName()
		return name;
	end

	function setSkills(value)
		skilldata = value;
	end

	function setName(value)
		name = value;
	end
end