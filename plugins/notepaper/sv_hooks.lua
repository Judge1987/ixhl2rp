local PLUGIN = PLUGIN

-- исписанный лист может подобрать только автор; чистый — кто угодно.
-- хук вызывается с экземпляром ITEM в качестве self, поэтому проверка живая:
-- если лист подпишут уже лёжа на полу, его никто, кроме автора, не возьмёт.
function PLUGIN:OnCanPickUp(client, itemEnt)
	local item = itemEnt and itemEnt.ixItem

	if (!item or item.base != "base_notepaper") then
		return
	end

	local owner = tonumber(item:GetData("owner", 0))

	if (owner == 0) then
		return true
	end

	local character = client:GetCharacter()

	return character and tonumber(character:GetID()) == owner
end
