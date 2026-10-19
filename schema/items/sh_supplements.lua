
ITEM.name = "Пищевая паста"
ITEM.model = Model("models/props_lab/jar01a.mdl")
ITEM.description = "Серое пастообразное вещество в белой пластиковой банке. На вкус как мел, но насыщает."

ITEM.functions.Eat = {
	OnRun = function(itemTable)
		local client = itemTable.player

		client:RestoreStamina(100)
		client:RestoreHunger(30)
		client:SetHealth(math.Clamp(client:Health() + 20, 0, client:GetMaxHealth()))
		client:EmitSound("npc/antlion_grub/squashed.wav", 75, 150, 0.25)
	end,
	OnCanRun = function(itemTable)
		return !itemTable.player:IsCombine()
	end
}
