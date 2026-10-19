ITEM.name = "Грязная вода"
ITEM.description = "Мутная вода неизвестного происхождения. Утоляет жажду, но пить её небезопасно."
ITEM.model = "models/props_junk/garbage_plasticbottle003a.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Еда и вода"

ITEM.functions.Drink = {
	name = "Выпить",
	icon = "icon16/cup.png",
	OnRun = function(itemTable)
		local client = itemTable.player

		client:RestoreThirst(35)
		client:RiskDisease("parasites", 0.35) -- шанс 35% заразиться паразитами
		client:EmitSound("npc/barnacle/barnacle_gulp2.wav", 75, 90, 0.35)
	end,
	OnCanRun = function(itemTable)
		return !itemTable.player:IsCombine()
	end
}