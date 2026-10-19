local PLUGIN = PLUGIN
PLUGIN.name = "Body Segments"
PLUGIN.author = "Server"
PLUGIN.description = "Система сегментов тела с индивидуальным здоровьем."

-- ===================== НАСТРОЙКИ =====================
-- Максимальное HP каждого сегмента по умолчанию
-- и пороги статусов (в процентах от максимума).
-- status: "healthy" (цел), "wounded" (ранен), "broken" (сломан)

PLUGIN.segments = {
	head = {
		name = "Голова",
		maxHP = 100,
		thresholds = { wounded = 0.7, broken = 0.3 }
	},
	chest = {
		name = "Грудь",
		maxHP = 120,
		thresholds = { wounded = 0.7, broken = 0.3 }
	},
	abdomen = {
		name = "Живот",
		maxHP = 110,
		thresholds = { wounded = 0.7, broken = 0.3 }
	},
	l_arm = {
		name = "Левая рука",
		maxHP = 80,
		thresholds = { wounded = 0.6, broken = 0.25 }
	},
	r_arm = {
		name = "Правая рука",
		maxHP = 80,
		thresholds = { wounded = 0.6, broken = 0.25 }
	},
	l_leg = {
		name = "Левая нога",
		maxHP = 100,
		thresholds = { wounded = 0.6, broken = 0.25 }
	},
	r_leg = {
		name = "Правая нога",
		maxHP = 100,
		thresholds = { wounded = 0.6, broken = 0.25 }
	}
}

-- Ключ в SetData, под которым хранится состояние сегментов персонажа
PLUGIN.dataKey = "bodySegments"