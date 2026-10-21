-- Minlevel and multiplier are MANDATORY
-- Maxlevel is OPTIONAL, but is considered infinite by default
-- Create a stage with minlevel 1 and no maxlevel to disable stages
-- Mubia Online: XP alta estilo MU. Calculado para ~3 horas del nivel 1 al 400 cazando
-- los monstruos de Strongarm (matar 1 bicho en nivel 1 ya sube al 2).
experienceStages = {
	{
		minlevel = 1,
		maxlevel = 9,
		multiplier = 60,
	},
	{
		minlevel = 10,
		maxlevel = 29,
		multiplier = 1300,
	},
	{
		minlevel = 30,
		maxlevel = 59,
		multiplier = 1600,
	},
	{
		minlevel = 60,
		maxlevel = 99,
		multiplier = 4500,
	},
	{
		minlevel = 100,
		maxlevel = 149,
		multiplier = 7000,
	},
	{
		minlevel = 150,
		maxlevel = 199,
		multiplier = 12500,
	},
	{
		minlevel = 200,
		maxlevel = 249,
		multiplier = 19000,
	},
	{
		minlevel = 250,
		maxlevel = 299,
		multiplier = 28000,
	},
	{
		minlevel = 300,
		maxlevel = 349,
		multiplier = 37500,
	},
	{
		minlevel = 350,
		multiplier = 50000,
	},
}

skillsStages = {
	{
		minlevel = 10,
		maxlevel = 60,
		multiplier = 15,
	},
	{
		minlevel = 61,
		maxlevel = 80,
		multiplier = 10,
	},
	{
		minlevel = 81,
		maxlevel = 110,
		multiplier = 6,
	},
	{
		minlevel = 111,
		maxlevel = 125,
		multiplier = 4,
	},
	{
		minlevel = 126,
		multiplier = 2,
	},
}

magicLevelStages = {
	{
		minlevel = 0,
		maxlevel = 60,
		multiplier = 10,
	},
	{
		minlevel = 61,
		maxlevel = 80,
		multiplier = 7,
	},
	{
		minlevel = 81,
		maxlevel = 100,
		multiplier = 5,
	},
	{
		minlevel = 101,
		maxlevel = 110,
		multiplier = 4,
	},
	{
		minlevel = 111,
		maxlevel = 125,
		multiplier = 3,
	},
	{
		minlevel = 126,
		multiplier = 2,
	},
}
