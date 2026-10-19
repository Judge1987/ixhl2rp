
FACTION.name = "Citizen"
FACTION.description = "A regular human citizen enslaved by the Universal Union."
FACTION.color = Color(150, 125, 100, 255)
FACTION.models = {
"models/sd/citizens/citizen_female_01_hair1.mdl",
"models/sd/citizens/citizen_female_01_hair2.mdl",
"models/sd/citizens/citizen_female_01_hair3.mdl",
"models/sd/citizens/citizen_female_02_hair1.mdl",
"models/sd/citizens/citizen_female_02_hair2.mdl",
"models/sd/citizens/citizen_female_02_hair3.mdl",
"models/sd/citizens/citizen_female_03_hair1.mdl",
"models/sd/citizens/citizen_female_03_hair2.mdl",
"models/sd/citizens/citizen_female_04_hair1.mdl",
"models/sd/citizens/citizen_female_04_hair2.mdl",
"models/sd/citizens/citizen_female_04_hair2.mdl",
"models/sd/citizens/citizen_female_04_hair3.mdl",
"models/sd/citizens/citizen_female_05_hair1.mdl",
"models/sd/citizens/citizen_female_05_hair2.mdl",
"models/sd/citizens/citizen_female_05_hair3.mdl",
"models/sd/citizens/citizen_male_01_hair1.mdl",
"models/sd/citizens/citizen_male_01_hair2.mdl",
"models/sd/citizens/citizen_male_01_hair3.mdl",
"models/sd/citizens/citizen_male_02_hair1.mdl",
"models/sd/citizens/citizen_male_02_hair2.mdl",
"models/sd/citizens/citizen_male_02_hair3.mdl",
"models/sd/citizens/citizen_male_03_hair1.mdl",
"models/sd/citizens/citizen_male_03_hair2.mdl",
"models/sd/citizens/citizen_male_03_hair3.mdl",
"models/sd/citizens/citizen_male_04_hair1.mdl",
"models/sd/citizens/citizen_male_04_hair2.mdl",
"models/sd/citizens/citizen_male_04_hair3.mdl",
"models/sd/citizens/citizen_male_04_hair4.mdl",
"models/sd/citizens/citizen_male_05_hair1.mdl",
"models/sd/citizens/citizen_male_05_hair2.mdl",
"models/sd/citizens/citizen_male_05_hair3.mdl",
"models/sd/citizens/citizen_male_05_hair4.mdl",
"models/sd/citizens/citizen_male_06_hair1.mdl",
"models/sd/citizens/citizen_male_06_hair2.mdl",
"models/sd/citizens/citizen_male_06_hair3.mdl",
"models/sd/citizens/citizen_male_07_hair1.mdl",
"models/sd/citizens/citizen_male_07_hair2.mdl",
"models/sd/citizens/citizen_male_07_hair3.mdl",
"models/sd/citizens/citizen_male_07_hair4.mdl",
"models/sd/citizens/citizen_male_08_hair1.mdl",
"models/sd/citizens/citizen_male_08_hair2.mdl",
"models/sd/citizens/citizen_male_08_hair3.mdl",
"models/sd/citizens/citizen_male_09_hair1.mdl",
"models/sd/citizens/citizen_male_09_hair2.mdl",
"models/sd/citizens/citizen_male_09_hair3.mdl",
"models/sd/citizens/citizen_male_10_hair1.mdl",
"models/sd/citizens/citizen_male_10_hair2.mdl",
"models/sd/citizens/citizen_male_10_hair3.mdl"
}
FACTION.isDefault = true

function FACTION:OnCharacterCreated(client, character)
	local id = Schema:ZeroNumber(math.random(1, 99999), 5)
	local inventory = character:GetInventory()

	character:SetData("cid", id)

	inventory:Add("suitcase", 1)
	inventory:Add("ration", 1)
	inventory:Add("cid", 1, {
		name = character:GetName(),
		id = id
	})
end

FACTION_CITIZEN = FACTION.index
