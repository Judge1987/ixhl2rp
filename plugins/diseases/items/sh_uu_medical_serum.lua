ITEM.name = "Экспериментальная сыворотка UU-Medical"
ITEM.description = "Шприц с экспериментальным препаратом Альянса. На маркировке UU-Medical указано, что средство предназначено для подавления тяжёлых заболеваний. Эффективность не подтверждена."
ITEM.model = "models/health_capsule.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Медицина"
ITEM.useSound = "items/medshot4.wav"

ITEM.functions.Use = {
	name = "Ввести сыворотку",
	tip = "Экспериментальное лечение",
	icon = "icon16/heart.png",
	OnRun = function(item)
		local client = item.player

		if (!IsValid(client) or !client:GetCharacter()) then
			return false
		end

		if (!client:HasDisease("cancer")) then
			client:Notify("Сыворотка не находит подходящей цели для воздействия.")
			return false
		end

		if (client:CureDisease("cancer")) then
			client:EmitSound(item.useSound or "items/medshot4.wav")
			client:Notify("Вы вводите экспериментальную сыворотку UU-Medical. Слабость постепенно отступает.")
			return true
		end

		return false
	end,
}
