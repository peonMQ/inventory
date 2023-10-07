---@class Filter
---@field name string
---@field value string

local invslotfilters = {
  any="Any Slot",
  ammo="Ammo",
  arms="Arms",
  back="Back",
  charm="Charm",
  chest="Chest",
  leftear="Ears",
  face="Face",
  feet="Feet",
  leftfinger="Fingers",
  hands="Hands",
  head="Head",
  legs="Legs",
  mainhand="Mainhand",
  neck="Neck",
  offhand="Offhand",
  powersource="Powersource",
  ranged="Ranged",
  shoulder="Shoulder",
  waist="Waist",
  leftwrist="Wrists",
}


local itemtypefilters = {
  any="Any Type",
  Armor="Armor",
  weapon="Weapon",
  Augmentation="Augmentation",
  container="Container",
  Food="Food",
  Drink="Drink",
  Combinable="Combinable",
}

local classfilters = {
  any="Any Class",
  Bard="Bard",
  Beastlord="Beastlord",
  Berserker="Berserker",
  Cleric="Cleric",
  Druid="Druid",
  Enchanter="Enchanter",
  Magician="Magician",
  Monk="Monk",
  Necromancer="Necromancer",
  Paladin="Paladin",
  Ranger="Ranger",
  Rogue="Rogue",
  ["Shadow Knight"]="Shadow Knight",
  Shaman="Shaman",
  Warrior="Warrior",
  Wizard="Wizard",
}

local locationfilters = {
  any="Any Location",
  inventory="On person",
  equiped="Equiped",
  bank="In Bank",
}

local function mapToKeyValuePair(filterTable)
  local kvps = {}
  for key,value in pairs(filterTable) do
    local kvp = {key=key, value=value}
    table.insert(kvps, kvp)
  end

  table.sort(kvps, function(a,b)
        if a.key == "any" then
          return true
        elseif b.key == "any" then
          return false
        end

        return a.value < b.value
      end
    )
  return kvps
end

return {
  SlotFilter = mapToKeyValuePair(invslotfilters),
  TypeFilter = mapToKeyValuePair(itemtypefilters),
  ClassFilter = mapToKeyValuePair(classfilters),
  LocationFilter = mapToKeyValuePair(locationfilters)
}