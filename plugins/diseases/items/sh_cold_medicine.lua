ITEM.name = "Жаропонижающее"
ITEM.description = "Таблетки от простуды. Облегчают симптомы ОРЗ."
ITEM.model = "models/biirrii/pack_8/props/medicine_1.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Медицина"

ITEM.functions.Take = {
	name = "Принять",
	icon = "icon16/pill.png",
	OnRun = function(itemTable)
		local client = itemTable.player

		if (!client:HasDisease("cold")) then
			client:Notify("Вы не чувствуете необходимости принимать это.")
			return false -- предмет не расходуется
		end

		client:CureDisease("cold")
		client:EmitSound("npc/barnacle/barnacle_gulp1.wav", 75, 100, 0.35)
		client:Notify("Вам становится легче.")
	end
}