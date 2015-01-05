--[[ Renekton by Skeem 0.1]]--

if myHero.charName ~= "Renekton" then return end

function PluginOnLoad()
	--> Main Load
	mainLoad()
	--> Main Menu
	mainMenu()
end

function PluginOnTick()
	Checks()
	if Target then
		if AutoCarry.MainMenu.AutoCarry then
			if QREADY and GetDistance(Target) <= qRange and Menu.useQ then CastSpell(_Q) end
			if WREADY and GetDistance(Target) <= aRange and Menu.useW then CastSpell(_W) end
			if EREADY and GetDistance(Target) <= eRange and Menu.useE then CastSpell(_E, Target.x, Target.z) end
		end 
	end
	if Menu.AutoUltimate then
		AutoUltimate()
	end
end

function PluginOnDraw()
	--> Ranges
	if not myHero.dead then
		if QREADY and Menu.drawQ then 
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x00FFFF)
		end
	end
end

function AutoUltimate()
local MinimumEnemies = Menu.MinimumEnemies
local EnemiesRange = Menu.MinimumRange
local MyHealthPercent = ((myHero.health/myHero.maxHealth)*100)
local MinimumHealth = Menu.MinimumHealth
	if (CountEnemyHeroInRange(EnemiesRange) >= MinimumEnemies) and (MyHealthPercent <= MinimumHealth) and rReady then
		CastSpell(_R)
	end
	if (CountEnemyHeroInRange(EnemiesRange) >= 1) and not myHero.canMove and (MyHealthPercent <= MinimumHealth) and rReady then
		CastSpell(_R)
	end	
end

--> Main Load
function mainLoad()
	qRange, eRange, aRange = 225, 450, 125
	QREADY, WREADY, EREADY, RREADY = false, false, false, false
	Menu = AutoCarry.PluginMenu
end

--> Main Menu
function mainMenu()
	Menu:addParam("sep1", "-- Full Combo Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("useQ", "Use Cull the Meek (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useW", "Use Ruthless Predator (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useE", "Use Slice & Die (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sep2", " -- Ultimate Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("AutoUltimate", "Auto Dominus (R)", SCRIPT_PARAM_ONKEYTOGGLE, true, 84) -- T
	Menu:addParam("MinimumHealth", "Minimum Health% for R", SCRIPT_PARAM_SLICE, 45, 1, 100, 0)
	Menu:addParam("MinimumEnemies", "Minimum Enemies for R", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
	Menu:addParam("MinimumRange", "Minimum Range for R", SCRIPT_PARAM_SLICE, 650, 200, 1000, -1)
	Menu:addParam("sep3", "-- Draw Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("drawQ", "Draw - Cull the Meek", SCRIPT_PARAM_ONOFF, false)
end

--> Checks
function Checks()
	Target = AutoCarry.GetAttackTarget()
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
end