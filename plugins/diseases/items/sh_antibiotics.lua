ITEM.name = "Антибиотик"
ITEM.description = "Антибактериальный препарат. Помогает при бактериальных инфекциях лёгких, но бесполезен при простуде."
ITEM.model = "models/hlvr/props/bottles/medicine_bottle_2.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Медицина"

ITEM.functions.Take = {
	name = "Принять",
	icon = "icon16/pill.png",
	OnRun = function(itemTable)
		local client = itemTable.player

		if (!client:HasDisease("pneumonia")) then
			client:Notify("Вы не чувствуете необходимости принимать это.")
			return false -- предмет не расходуется
		end

		client:CureDisease("pneumonia")
		client:EmitSound("npc/barnacle/barnacle_gulp1.wav", 75, 100, 0.35)
		client:Notify("Дышать становится заметно легче.")
	end
}