local name = "psitalents";
local psitalents = {
  ["Awareness"] = { spent=-3, attributeDM=0},
  ["Clairvoyance"] = { spent=-3, attributeDM=0},
  ["Telekinesis"] = { spent=-3, attributeDM=0},
  ["Telepathy"] = { spent=-3, attributeDM=0},
  ["Teleportation"] = { spent=-3, attributeDM=0}
}

function getPsiTalents()
  return psitalents;
end

function getName()
  return name;
end

function setPsiTalents(value)
  skills = value;
end

function setName(value)
  name = value;
end
