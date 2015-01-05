-- [[ Sida's AutoCarryPlugin - Lulu by Skeem]] --

if myHero.charName ~= "Lulu" then return end

function PluginOnLoad()
	AutoCarry.SkillsCrosshair.range = 945
	--> Main Load
	mainLoad()
	--> Main Menu
	mainMenu()
end

function PluginOnTick()
	Checks()
	if Target then
		if (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
			if QREADY and Menu.useQ then Cast(SkillQ, Target) end
			if WREADY and Menu.useW then CastSpell(_W, Target) end
			if EREADY and Menu.useE then CastSpell(_E, Target) end
		end 
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

--> Main Load
function mainLoad()
	qRange, wRange, eRange, rRange = 945, 650, 650, 900
	QREADY, WREADY, EREADY, RREADY = false, false, false, false
	SkillQ = {spellKey = _Q, range = qRange, speed = 1.53, delay = 250, width = 80}
	Cast = AutoCarry.CastSkillshot
	Menu = AutoCarry.PluginMenu
end

--> Main Menu
function mainMenu()
	Menu:addParam("sep1", "-- Full Combo Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("useQ", "Use Glitterlance (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useW", "Use Whimsy (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useE", "Use Help, Pix! (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sep3", "-- Draw Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("drawQ", "Draw - Glitterlance (Q)", SCRIPT_PARAM_ONOFF, false)
end

--> Checks
function Checks()
	Target = AutoCarry.GetAttackTarget()
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
end