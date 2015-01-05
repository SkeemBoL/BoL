--[[

	Script - Talon - The Blade's Shadow

  	]] --		

--- Required Libraries for VIPs ---
if VIP_USER then
	require "Prodiction"
end 

-- / Hero Name Check / --
if myHero.charName ~= "Talon" then return end
-- / Hero Name Check / --

-- / Loading Function / --
function OnLoad()
	--->
		Variables()
		TalonMenu()
		PrintChat("<font color='#660066'> >> Talon - The Blade's Shadow Loaded!! <<</font>")
	---<
end
-- / Loading Function / --

-- / Tick Function / --
function OnTick()
	--->
		Checks()
		DamageCalculation()
		UseConsumables()
	---<
	-- Menu Variables --
	--->
		ComboKey =     TalonMenu.combo.comboKey
		HarassKey =    TalonMenu.harass.harassKey
		ClearKey =     TalonMenu.clear.clearKey
	---<
	-- Menu Variables --
	--->
		if ComboKey then
			FullCombo()
		end
		if HarassKey then
			HarassCombo()
		end
		if ClearKey then
			MixedClear()
		end	
		if TalonMenu.killsteal.smartKS then KillSteal() end
		if TalonMenu.misc.AutoLevelSkills then autoLevelSetSequence(levelSequence) end
	---<
end
-- / Tick Function / --

-- / Variables Function / --
function Variables()
	--- Skills Vars --
	--->
		SkillQ = {range = 125, name = "Noxian Diplomacy",  ready = false, color = ARGB(255,178, 0 , 0 ), toggle = false}
		SkillW = {range = 700, name = "Rake",              ready = false, color = ARGB(255, 32,178,170), speed = 900, delay = .7, width = 400}
		SkillE = {range = 700, name = "Cutthroat",		   ready = false, color = ARGB(255,128, 0 ,128)}
		SkillR = {range = 650, name = "Shadow Assault",	   ready = false								}
	---<
	--- Skills Vars ---
	--- Items Vars ---
	--->
		Items =
		{
					HealthPot      = {ready = false},
					ManaPot        = {ready = false},
					FlaskPot       = {ready = false}
		}
	---<
	--- Items Vars ---
	--- Orbwalking Vars ---
	--->
		lastAnimation = "Run"
		lastAttack = 0
		lastAttackCD = 0
		lastWindUpTime = 0
	---<
	--- Orbwalking Vars ---
	--- TickManager Vars ---
	--->
		TManager =
		{
			onTick	= TickManager(20),
			onDraw	= TickManager(80),
			onSpell	= TickManager(15)
		}
	---<
	--- TickManager Vars ---
	if VIP_USER then
		--- LFC Vars ---
		--->
			_G.oldDrawCircle = rawget(_G, 'DrawCircle')
			_G.DrawCircle = DrawCircle2
		---<
		--- LFC Vars ---
	end
	--- Drawing Vars ---
	--->
		TextList = {"Harass him", "Q = Kill", "W = Kill", "E = Kill!", "Q+W = Kill", "Q+E = Kill", "E+W = Kill", "Q+E+W = Kill", "Q+W+E+R: ", "Need CDs"}
		KillText = {}
		colorText = ARGB(255,255,204,0)
	---<
	--- Drawing Vars ---
	--- Misc Vars ---
	--->
		wPos = nil
		if VIP_USER then
			Prodict = ProdictManager.GetInstance()
			ProdictW = Prodict:AddProdictionObject(_W, SkillW.range, SkillW.speed, SkillW.delay, SkillW.width, myHero)
		end
		levelSequence = { 2,3,2,1,2,4,2,1,2,1,4,1,1,3,3,4,3,3 }
		UsingHPot, UsingMPot = false, false
		gameState = GetGame()
		if gameState.map.shortName == "twistedTreeline" then
			TTMAP = true
		else
			TTMAP = false
		end
	---<
	--- Misc Vars ---
	--- Tables ---
	--->
		allyHeroes = GetAllyHeroes()
		enemyHeroes = GetEnemyHeroes()
		enemyMinions = minionManager(MINION_ENEMY, SkillE.range, player, MINION_SORT_HEALTH_ASC)
		JungleMobs = {}
		JungleFocusMobs = {}
		priorityTable = {
	    	AP = {
	        	"Annie", "Ahri", "Akali", "Anivia", "Annie", "Brand", "Cassiopeia", "Diana", "Evelynn", "FiddleSticks", "Fizz", "Gragas", "Heimerdinger", "Karthus",
	        	"Kassadin", "Talon", "Kayle", "Kennen", "Leblanc", "Lissandra", "Lux", "Malzahar", "Mordekaiser", "Morgana", "Nidalee", "Orianna",
	        	"Ryze", "Sion", "Swain", "Syndra", "Teemo", "TwistedFate", "Veigar", "Viktor", "Vladimir", "Xerath", "Ziggs", "Zyra",
	        },
	    	Support = {
	        	"Alistar", "Blitzcrank", "Janna", "Karma", "Leona", "Lulu", "Nami", "Nunu", "Sona", "Soraka", "Taric", "Thresh", "Zilean",
	        },
	    	Tank = {
	        	"Amumu", "Chogath", "DrMundo", "Galio", "Hecarim", "Malphite", "Maokai", "Nasus", "Rammus", "Sejuani", "Nautilus", "Shen", "Singed", "Skarner", "Volibear",
	        	"Warwick", "Yorick", "Zac",
	        },
	    	AD_Carry = {
	        	"Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jayce", "Jinx", "KogMaw", "Lucian", "MasterYi", "MissFortune", "Pantheon", "Quinn", "Shaco", "Sivir",
	        	"Talon","Tryndamere", "Tristana", "Twitch", "Urgot", "Varus", "Vayne", "Yasuo","Zed", 
	        },
	    	Bruiser = {
	        	"Aatrox", "Darius", "Elise", "Fiora", "Gangplank", "Garen", "Irelia", "JarvanIV", "Jax", "Khazix", "LeeSin", "Nocturne", "Olaf", "Poppy",
	        	"Renekton", "Rengar", "Riven", "Rumble", "Shyvana", "Trundle", "Udyr", "Vi", "MonkeyKing", "XinZhao",
	        },
        }
		if TTMAP then --
			FocusJungleNames = {
				["TT_NWraith1.1.1"] = true,
				["TT_NGolem2.1.1"] = true,
				["TT_NWolf3.1.1"] = true,
				["TT_NWraith4.1.1"] = true,
				["TT_NGolem5.1.1"] = true,
				["TT_NWolf6.1.1"] = true,
				["TT_Spiderboss8.1.1"] = true,
			}		
			JungleMobNames = {
				["TT_NWraith21.1.2"] = true,
				["TT_NWraith21.1.3"] = true,
				["TT_NGolem22.1.2"] = true,
				["TT_NWolf23.1.2"] = true,
				["TT_NWolf23.1.3"] = true,
				["TT_NWraith24.1.2"] = true,
				["TT_NWraith24.1.3"] = true,
				["TT_NGolem25.1.1"] = true,
				["TT_NWolf26.1.2"] = true,
				["TT_NWolf26.1.3"] = true,
			}
		else 
			JungleMobNames = { 
				["Wolf8.1.2"] = true,
				["Wolf8.1.3"] = true,
				["YoungLizard7.1.2"] = true,
				["YoungLizard7.1.3"] = true,
				["LesserWraith9.1.3"] = true,
				["LesserWraith9.1.2"] = true,
				["LesserWraith9.1.4"] = true,
				["YoungLizard10.1.2"] = true,
				["YoungLizard10.1.3"] = true,
				["SmallGolem11.1.1"] = true,
				["Wolf2.1.2"] = true,
				["Wolf2.1.3"] = true,
				["YoungLizard1.1.2"] = true,
				["YoungLizard1.1.3"] = true,
				["LesserWraith3.1.3"] = true,
				["LesserWraith3.1.2"] = true,
				["LesserWraith3.1.4"] = true,
				["YoungLizard4.1.2"] = true,
				["YoungLizard4.1.3"] = true,
				["SmallGolem5.1.1"] = true,
			}
			FocusJungleNames = {
				["Dragon6.1.1"] = true,
				["Worm12.1.1"] = true,
				["GiantWolf8.1.1"] = true,
				["AncientGolem7.1.1"] = true,
				["Wraith9.1.1"] = true,
				["LizardElder10.1.1"] = true,
				["Golem11.1.2"] = true,
				["GiantWolf2.1.1"] = true,
				["AncientGolem1.1.1"] = true,
 				["Wraith3.1.1"] = true,
				["LizardElder4.1.1"] = true,
				["Golem5.1.2"] = true,
				["GreatWraith13.1.1"] = true,
				["GreatWraith14.1.1"] = true,
			}
		end
		for i = 0, objManager.maxObjects do
			local object = objManager:getObject(i)
			if object and object.valid and not object.dead then
				if FocusJungleNames[object.name] then
					table.insert(JungleFocusMobs, object)
				elseif JungleMobNames[object.name] then
					table.insert(JungleMobs, object)
				end
			end
		end
	---<
	--- Tables ---
end
-- / Variables Function / --

-- / Menu Function / --
function TalonMenu()
	--- Main Menu ---
	--->
		TalonMenu = scriptConfig("Talon - The Blade's Shadow", "Talon")
		---> Combo Menu
		TalonMenu:addSubMenu("["..myHero.charName.." - Combo Settings]", "combo")
			TalonMenu.combo:addParam("comboKey", "Full Combo Key (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
			TalonMenu.combo:addParam("comboERange", ""..SkillE.name.." Min Range", SCRIPT_PARAM_SLICE, 400, 0, SkillE.range, -2)
			TalonMenu.combo:addParam("comboItems", "Use Items with Burst", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.combo:addParam("ult2Kill", "Ult to Kill Only", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.combo:addParam("comboOrbwalk", "Orbwalk in Combo", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.combo:permaShow("comboKey")
		---<
		---> Harass Menu
		TalonMenu:addSubMenu("["..myHero.charName.." - Harass Settings]", "harass")
			TalonMenu.harass:addParam("hMode", "Harass Mode",SCRIPT_PARAM_SLICE, 1, 1, 2, 0)
			TalonMenu.harass:addParam("harassKey", "Harass Hotkey (C)", SCRIPT_PARAM_ONKEYDOWN, false, 67)
			TalonMenu.harass:addParam("harassERange", ""..SkillE.name.." Min Range", SCRIPT_PARAM_SLICE, 400, 0, SkillE.range, -2)
			TalonMenu.harass:addParam("harassOrbwalk", "Orbwalk in Harass", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.harass:addParam("info1","Harass Mode 1 = W", SCRIPT_PARAM_INFO, "")
			TalonMenu.harass:addParam("info2","Harass Mode 2 = W + E + Q", SCRIPT_PARAM_INFO, "")
			TalonMenu.harass:permaShow("harassKey")
		---<
		---> Clear Menu		
		TalonMenu:addSubMenu("["..myHero.charName.." - Clear Settings]", "clear")
			TalonMenu.clear:addParam("clearKey", "Jungle/Lane Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, 86)
			TalonMenu.clear:addParam("JungleFarm", "Use Skills to Farm Jungle", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.clear:addParam("ClearLane", "Use Skills to Clear Lane", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.clear:addParam("clearQ", "Clear with "..SkillQ.name.." (Q)", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.clear:addParam("clearW", "Clear with "..SkillW.name.." (W)", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.clear:addParam("clearE", "Clear with "..SkillE.name.." (E)", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.clear:addParam("clearOrbM", "OrbWalk Minions", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.clear:addParam("clearOrbJ", "OrbWalk Jungle", SCRIPT_PARAM_ONOFF, true)
		---<
		---> KillSteal Menu
		TalonMenu:addSubMenu("["..myHero.charName.." - KillSteal Settings]", "killsteal")
			TalonMenu.killsteal:addParam("smartKS", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.killsteal:addParam("ultKS", "Use "..SkillR.name.." (R) to KS", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.killsteal:addParam("itemsKS", "Use Items to KS", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.killsteal:addParam("Ignite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.killsteal:permaShow("smartKS")
		---<
		---> Drawing Menu			
		TalonMenu:addSubMenu("["..myHero.charName.." - Drawing Settings]", "drawing")
			if VIP_USER then
				TalonMenu.drawing:addSubMenu("["..myHero.charName.." - LFC Settings]", "lfc")
					TalonMenu.drawing.lfc:addParam("LagFree", "Activate Lag Free Circles", SCRIPT_PARAM_ONOFF, false)
					TalonMenu.drawing.lfc:addParam("CL", "Length before Snapping", SCRIPT_PARAM_SLICE, 300, 75, 2000, 0)
					TalonMenu.drawing.lfc:addParam("CLinfo", "Higher length = Lower FPS Drops", SCRIPT_PARAM_INFO, "")
			end
			TalonMenu.drawing:addParam("disableAll", "Disable All Ranges Drawing", SCRIPT_PARAM_ONOFF, false)
			TalonMenu.drawing:addParam("drawText", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.drawing:addParam("drawTargetText", "Draw Who I'm Targetting", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.drawing:addParam("drawQ", "Draw "..SkillQ.name.."(Q) Range", SCRIPT_PARAM_ONOFF, false)
			TalonMenu.drawing:addParam("drawW", "Draw "..SkillW.name.."(W) Range", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.drawing:addParam("drawE", "Draw "..SkillE.name.."(E) Range", SCRIPT_PARAM_ONOFF, false)
		---<
		---> Misc Menu	
		TalonMenu:addSubMenu("["..myHero.charName.." - Misc Settings]", "misc")
			TalonMenu.misc:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
			TalonMenu.misc:addParam("aMP", "Auto Mana Pots", SCRIPT_PARAM_ONOFF, true)
			TalonMenu.misc:addParam("MPMana", "Min % for Mana Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
			TalonMenu.misc:addParam("uTM", "Use Tick Manager/FPS Improver",SCRIPT_PARAM_ONOFF, false)
			TalonMenu.misc:addParam("AutoLevelSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_ONOFF, false)
		---<
		---> Target Selector		
			TargetSelector = TargetSelector(TARGET_LESS_CAST, SkillE.range, DAMAGE_PHYSICAL)
			TargetSelector.name = "Talon"
			TalonMenu:addTS(TargetSelector)
		---<
		---> Arrange Priorities
			if heroManager.iCount < 10 then -- borrowed from Sidas Auto Carry, modified to 3v3
       			PrintChat(" >> Too few champions to arrange priority")
			elseif heroManager.iCount == 6 and TTMAP then
				ArrangeTTPrioritys()
    		else
        		ArrangePrioritys()
    		end
    	---<
	---<
	--- Main Menu ---
end
-- / Menu Function / --

-- / Full Combo Function / --
function FullCombo()
	--- Combo While Not Channeling --
	--->
		if Target then
			if TalonMenu.combo.comboOrbwalk then
				OrbWalking(Target)
			end
			if TalonMenu.combo.comboItems then
				UseItems(Target)
			end
				CastW(Target)
				if GetDistance(Target) >= TalonMenu.combo.comboERange and not SkillW.ready then
					DelayAction(function()CastE(Target) end, 0.5)
				end
				CastQ(Target)
			if TalonMenu.combo.ult2Kill then
				if Target.health < rDmg then
					CastR(Target)
				end
			else
				CastR(Target)
			end
		else
			if TalonMenu.combo.comboOrbwalk then
				moveToCursor()
			end
		end
	---<
	--- Combo While Not Channeling --
end
-- / Full Combo Function / --

-- / Harass Combo Function / --
function HarassCombo()
	--- Smart Harass --
	--->
		if Target then
			if TalonMenu.harass.harassOrbwalk then
				OrbWalking(Target)
			end
			--- Harass Mode 1 W ---
			if TalonMenu.harass.hMode == 1 then
				CastW(Target)
			--- Harass Mode 1 ---
			--- Harass Mode 2 W+E+Q ---
			else
				CastW(Target)
				if GetDistance(Target) >= TalonMenu.harass.harassERange and not SkillW.ready then
					DelayAction(function()CastE(Target) end, 0.5)
				end
				CastQ(Target)
			end
			--- Harass Mode 2 ---
		else
			if TalonMenu.harass.harassOrbwalk then
				moveToCursor()
			end
		end
	---<
	--- Smart Harass ---
end
-- / Harass Combo Function / --

-- / Clear Function / --
function MixedClear()
	--- Jungle Clear ---
	--->
		if TalonMenu.clear.JungleFarm then
			local JungleMob = GetJungleMob()
			if JungleMob ~= nil then
				if TalonMenu.clear.clearOrbJ then
					OrbWalking(JungleMob)
				end
				if TalonMenu.clear.clearQ and SkillQ.ready and GetDistance(JungleMob) <= SkillQ.range then
					CastSpell(_Q)
				end
				if TalonMenu.clear.clearW and SkillW.ready and GetDistance(JungleMob) <= SkillW.range then
					CastSpell(_W, JungleMob.x, JungleMob.z)
				end
				if TalonMenu.clear.clearE and SkillE.ready and GetDistance(JungleMob) <= SkillE.range then
					CastSpell(_E, JungleMob) 
				end
			else
				if TalonMenu.clear.clearOrbJ then
					moveToCursor()
				end
			end
		end
	---<
	--- Jungle Clear ---
	--- Lane Clear ---
	--->
		if TalonMenu.clear.ClearLane then
			for _, minion in pairs(enemyMinions.objects) do
				if  ValidTarget(minion) then
					if TalonMenu.clear.clearOrbM then
						OrbWalking(minion)
					end
					if TalonMenu.clear.clearQ and SkillQ.ready and GetDistance(minion) <= SkillQ.range then
						CastSpell(_Q)
					end
					if TalonMenu.clear.clearW and SkillW.ready and GetDistance(minion) <= SkillW.range then
						CastSpell(_W, minion.x, minion.z)
					end
					if TalonMenu.clear.clearE and SkillE.ready and GetDistance(minion) <= SkillE.range then 
						CastSpell(_E, minion)
					end
				else
					if TalonMenu.clear.clearOrbM then
						moveToCursor()
					end
				end
			end
		end
	---<
	--- Lane Clear ---
end
-- / Clear Function / --

-- / OnGainBuff Function / --
function OnGainBuff(unit, buff)
	--->
		if unit == myHero then
			if buff.name == "talonnoxiandiplomacybuff" then
				SkillQ.toggle = true
			end
		end
	---<
end
-- / OnGainBuff Function / --

-- / OnLoseBuff Function / --
function OnLoseBuff(unit, buff)
	--->
		if unit == myHero then
			if buff.name == "talonnoxiandiplomacybuff" then
				SkillQ.toggle = false
			end
		end
	---<
end
-- / OnLoseBuff Function / --

-- / Casting Q Function / --
function CastQ(enemy)
	--- Dynamic Q Cast ---
	--->
		if not (SkillQ.ready or SkillQ.toggle) or (GetDistance(enemy) > SkillQ.range) then
			return false
		end
		if ValidTarget(enemy) then 
			if not SkillQ.toggle then
				if TimeToAttack() then
					if VIP_USER then
						Packet('S_MOVE', {type = 3, x = enemy.x, y = enemy.z, sourceNetworkId = myHero.networkID, targetNetworkId = enemy.networkID}):send()
						return true
					else
						myHero:Attack(enemy)
						return true
					end
				else
					CastSpell(_Q)
					return true
				end
			else
				if VIP_USER then
					Packet('S_MOVE', {type = 3, x = enemy.x, y = enemy.z, sourceNetworkId = myHero.networkID, targetNetworkId = enemy.networkID}):send()
					return true
				else
					myHero:Attack(enemy)
					return true
				end
			end			
		end
		return false
	---<
	--- Dynamic Q Cast ---
end
-- / Casting Q Function / --

-- / Casting E Function / --
function CastE(enemy)
	--- Dynamic E Cast ---
	--->
		if not SkillE.ready or (GetDistance(enemy) > SkillE.range) then
			return false
		end
		if ValidTarget(enemy) then 
			if VIP_USER then
				Packet("S_CAST", {spellId = _E, targetNetworkId = enemy.networkID}):send()
				return true
			else
				CastSpell(_E, enemy)
					return true
			end
		end
		return false
	---<
	--- Dynamic E Cast ---
end
-- / Casting E Function / --

-- / Casting W Function / --
function CastW(enemy)
	--- Dynamic W Cast ---
	--->
		if not SkillW.ready or (GetDistance(enemy) > SkillW.range) then
			return false
		end
		if ValidTarget(enemy) then
			if VIP_USER then
				local wPos = ProdictW:GetPrediction(enemy)
				if wPos then
					CastSpell(_W, wPos.x, wPos.z)
					return true
				end
			else
				local wPred = TargetPrediction(SkillW.range, SkillW.speed, SkillW.delay, SkillW.width)
            	local wPrediction = wPred:GetPrediction(enemy)
            	if wPrediction then
					CastSpell(_W, wPrediction.x, wPrediction.z)
					return true
				end
			end
		end
		return false
	---<
	--- Dynamic W Cast ---
end
-- / Casting W Function / --

-- / Casting R Function / --
function CastR(enemy)
	--- Dynamic R Cast ---
	--->
		if not SkillR.ready or (GetDistance(enemy) > SkillR.range) then
			return false
		end
		if ValidTarget(enemy) then
			CastSpell(_R) 
		end
	---<
	--- Dymanic R Cast --
end
-- / Casting R Function / --

-- / Use Items Function / --
function UseItems(enemy)
	--- Use Items (Will Improve Soon) ---
	--->
		function UseItems(enemy)
			if not enemy then
				enemy = Target
			end
			if ValidTarget(enemy) then
				if hxgReady and GetDistance(enemy) <= 600 then CastSpell(hxgSlot, enemy) end
				if bwcReady and GetDistance(enemy) <= 450 then CastSpell(bwcSlot, enemy) end
				if brkReady and GetDistance(enemy) <= 450 then CastSpell(brkSlot, enemy) end
				if tmtReady and GetDistance(enemy) <= 185 then CastSpell(tmtSlot) end
				if hdrReady and GetDistance(enemy) <= 185 then CastSpell(hdrSlot) end
			end
		end
	---<
	--- Use Items ---
end
-- / Use Items Function / --

function UseConsumables()
	--- Check if Potions Needed --
	--->
		if TalonMenu.misc.aHP and isLow('Health') and not (UsingHPot or UsingFlask) and (Items.HealthPot.ready or Items.FlaskPot.ready) then
			CastSpell((hpSlot or fskSlot))
		end
	---<
	--- Check if Potions Needed --
end	

-- / Auto Ignite Function / --
function AutoIgnite(enemy)
	--- Simple Auto Ignite ---
	--->
		if enemy.health <= iDmg and GetDistance(enemy) <= 600 then
			if iReady then CastSpell(ignite, enemy) end
		end
	---<
	--- Simple Auto Ignite ---
end
-- / Auto Ignite Function / --

-- / Damage Calculation Function / --
function DamageCalculation()
	--- Calculate our Damage On Enemies ---
	--->
 		for i=1, heroManager.iCount do
		local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				aDmg = getDmg("AD", enemy, myHero)
				dfgDmg, hxgDmg, bwcDmg, iDmg, bftDmg = 0, 0, 0, 0, 0
				qDmg = (SkillQ.ready and getDmg("Q",enemy,myHero) or 0) + aDmg
    	        wDmg = (SkillW.ready and getDmg("W",enemy,myHero) or 0)
				eDmg = (SkillE.ready and getDmg("E",enemy,myHero) or 0)
            	rDmg = (SkillR.ready and getDmg("R",enemy,myHero,3) or 0)
        	    hxgDmg = (hxgReady and getDmg("HXG", enemy, myHero) or 0)
            	bwcDmg = (bwcReady and getDmg("BWC", enemy, myHero) or 0)
            	bftdmg = (bftReady and getDmg("BLACKFIRE", enemy, myHero) or 0)
            	iDmg = (ignite and getDmg("IGNITE",enemy,myHero) or 0)
            	onspellDmg = (liandrysSlot and getDmg("LIANDRYS",enemy,myHero) or 0)+(blackfireSlot and getDmg("BLACKFIRE",enemy,myHero) or 0)
            	itemsDmg = dfgDmg + bftDmg + hxgDmg + bwcDmg + iDmg + onspellDmg

            	if enemy.health > (qDmg + eDmg + wDmg + rDmg + itemsDmg) then
    				KillText[i] = 1
				elseif enemy.health <= qDmg then
					if SkillQ.ready then
						KillText[i] = 2
					else
						KillText[i] = 10
					end
				elseif enemy.health <= wDmg then
					if SkillW.ready then
						KillText[i] = 3
					else
						KillText[i] = 10
					end
				elseif enemy.health <= eDmg then
					if SkillE.ready then
						KillText[i] = 4
					else
						KillText[i] = 10
					end
				elseif enemy.health <= (qDmg + wDmg) and SkillQ.ready and SkillW.ready then
					if SkillQ.ready and SkillW.ready then
						KillText[i] = 5
					else
						KillText[i] = 10
					end
				elseif enemy.health <= (qDmg + eDmg) and SkillQ.ready and SkillE.ready then
					if SkillQ.ready and SkillE.ready then
						KillText[i] = 6
					else
						KillText[i] = 10
					end
				elseif enemy.health <= (wDmg + eDmg) and SkillW.ready and SkillE.ready then
					if SkillW.ready and SkillE.ready then
						KillText[i] = 7
					else
						KillText[i] = 10
					end
				elseif enemy.health <= (qDmg + wDmg + eDmg) and SkillQ.ready and SkillW.ready and SkillE.ready then
					if SkillQ.ready and SkillW.ready and SkillE.ready then
						KillText[i] = 8
					else
						KillText[i] = 10
					end
				elseif enemy.health <= (qDmg + wDmg + eDmg + rDmg + itemsDmg) then
					if SkillQ.ready and SkillW.ready and SkillE.ready then
						KillText[i] = 9
					else
						KillText[i] = 10
					end
				end
    ---<
    --- Calculate our Damage On Enemies ---
    --- Setting KillText Color & Text ---
    --->
			end
		end
	---<
	--- Setting KillText Color & Text ---
end
-- / Damage Calculation Function / --

-- / KillSteal Function / --
function KillSteal()
	--- KillSteal No Wards ---
	--->
		if Target then
			local distance = GetDistance(Target)
			local health = Target.health
			if health <= qDmg and SkillQ.ready and (distance < SkillQ.range) then
				CastQ(Target)
			elseif health <= wDmg and SkillW.ready and (distance < SkillW.range) then
				CastW(Target)
			elseif health <= eDmg and SkillE.ready and (distance < SkillE.range) then
				CastE(Target)
			elseif health <= (wDmg + eDmg) and SkillW.ready and SkillE.ready and (distance < SkillW.range) then
				CastW(Target)
			elseif health <= (qDmg + wDmg + eDmg) and SkillQ.ready and SkillW.ready and SkillE.ready and (distance < SkillE.range) then
				CastE(Target)
			elseif TalonMenu.killsteal.ultKS then
				if health <= (qDmg + wDmg + eDmg + rDmg) and SkillQ.ready and SkillW.ready and SkillE.ready and SkillR.ready and (distance < SkillE.range) then
					CastE(Target)
					CastQ(Target)
					CastW(Target)
					CastR(Target)
				end
				if health <= rDmg and distance < (SkillR.range - 100) then
					CastR(Target)
				end
			elseif TalonMenu.killsteal.itemsKS then
				if health <= (qDmg + wDmg + eDmg + rDmg + itemsDmg) then
					if SkillQ.ready and SkillW.ready and SkillE.ready and SkillR.ready then
						UseItems(Target)
					end
				elseif health <= (qDmg + wDmg + eDmg + itemsDmg) and health > (qDmg + wDmg + eDmg) then
					if SkillQ.ready and SkillW.ready and SkillE.ready then
						UseItems(Target)
					end
				end
			end
		end
	---<
	--- KillSteal No Wards ---
end
-- / KillSteal Function / --

-- / Misc Functions / --
--- On Animation (Setting our last Animation) ---
--->
	function OnAnimation(unit, animationName)
    	if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
	end
---<
--- Checking if Hero in Danger ---
--->
	function isInDanger(hero)
        nEnemiesClose, nEnemiesFar = 0, 0
        hpPercent = hero.health / hero.maxHealth
        for _, enemy in pairs(enemyHeroes) do
                if not enemy.dead and hero:GetDistance(enemy) <= 200 then
                        nEnemiesClose = nEnemiesClose + 1
                        if hpPercent < 0.5 and hpPercent < enemy.health / enemy.maxHealth then return true end
                elseif not enemy.dead and hero:GetDistance(enemy) <= 1000 then
                        nEnemiesFar = nEnemiesFar + 1
                end
        end
       
        if nEnemiesClose > 1 then return true end
        if nEnemiesClose == 1 and nEnemiesFar > 1 then return true end
        return false
	end
---<
--- Checking if Hero in Danger ---
--- Get Jungle Mob Function by Apple ---
--->
	function GetJungleMob()
		for _, Mob in pairs(JungleFocusMobs) do
			if ValidTarget(Mob, q1Range) then return Mob end
		end
		for _, Mob in pairs(JungleMobs) do
			if ValidTarget(Mob, q1Range) then return Mob end
		end
	end
---<
--- Get Jungle Mob Function by Apple ---
--- Arrange Priorities 5v5 ---
--->
	function ArrangePrioritys()
    	for i, enemy in pairs(enemyHeroes) do
        	SetPriority(priorityTable.AD_Carry, enemy, 1)
        	SetPriority(priorityTable.AP, enemy, 2)
        	SetPriority(priorityTable.Support, enemy, 3)
        	SetPriority(priorityTable.Bruiser, enemy, 4)
        	SetPriority(priorityTable.Tank, enemy, 5)
    	end
	end
---<
--- Arrange Priorities 5v5 ---
--- Arrange Priorities 3v3 ---
--->
	function ArrangeTTPrioritys()
		for i, enemy in pairs(enemyHeroes) do
			SetPriority(priorityTable.AD_Carry, enemy, 1)
        	SetPriority(priorityTable.AP, enemy, 1)
        	SetPriority(priorityTable.Support, enemy, 2)
        	SetPriority(priorityTable.Bruiser, enemy, 2)
        	SetPriority(priorityTable.Tank, enemy, 3)
		end
	end
---<
--- Arrange Priorities 3v3 ---
--- Set Priorities ---
--->
	function SetPriority(table, hero, priority)
    	for i=1, #table, 1 do
        	if hero.charName:find(table[i]) ~= nil then
            	TS_SetHeroPriority(priority, hero.charName)
        	end
    	end
	end
---<
--- Set Priorities ---
-- / Misc Functions / --
-- / On Create Obj Function / --
function OnCreateObj(obj)
	--- All of Our Objects (CREATE) --
	-->
		if obj ~= nil then
			if obj.name:find("Global_Item_HealthPotion.troy") then
				if GetDistance(obj, myHero) <= 70 then
					UsingHPot = true
				end
			end
			if FocusJungleNames[obj.name] then
				table.insert(JungleFocusMobs, obj)
			elseif JungleMobNames[obj.name] then
        		table.insert(JungleMobs, obj)
			end
		end
	---<
	--- All of Our Objects (CREATE) --
end
-- / On Create Obj Function / --

-- / On Delete Obj Function / --
function OnDeleteObj(obj)
	--- All of Our Objects (CLEAR) --
	--->
		if obj ~= nil then
			if obj.name:find("Global_Item_HealthPotion.troy") then
				UsingHPot = false
			end
			for i, Mob in pairs(JungleMobs) do
				if obj.name == Mob.name then
					table.remove(JungleMobs, i)
				end
			end
			for i, Mob in pairs(JungleFocusMobs) do
				if obj.name == Mob.name then
					table.remove(JungleFocusMobs, i)
				end
			end
		end
	--- All of Our Objects (CLEAR) --
	---<
end
--- All The Objects in The World Literally ---
-- / On Delete Obj Function / --

-- / Plugin On Draw / --
function OnDraw()
	--- Tick Manager Check ---
	--->
		if not TManager.onDraw:isReady() and TalonMenu.misc.uTM then return end
	---<
	--->
	--- Drawing Our Ranges ---
	--->
		if not myHero.dead then
			if not TalonMenu.drawing.disableAll then
				if SkillQ.ready and TalonMenu.drawing.drawQ then 
					DrawCircle(myHero.x, myHero.y, myHero.z, SkillQ.range, SkillQ.color)
				end
				if SkillW.ready and TalonMenu.drawing.drawW then
					DrawCircle(myHero.x, myHero.y, myHero.z, SkillW.range, SkillW.color)
				end
				if SkillE.ready and TalonMenu.drawing.drawE then
					DrawCircle(myHero.x, myHero.y, myHero.z, SkillE.range, SkillE.color)
				end
			end
		end
	---<
	--- Drawing Our Ranges ---
	--- Draw Enemy Damage Text ---
	--->
		if TalonMenu.drawing.drawText then
			for i = 1, heroManager.iCount do
        		local enemy = heroManager:GetHero(i)
        		if ValidTarget(enemy) then
        			local barPos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z)) --(Credit to Zikkah)
					local PosX = barPos.x - 35
					local PosY = barPos.y - 10
					DrawText(TextList[KillText[i]], 16, PosX, PosY, colorText)
				end
			end
		end
	---<
	--- Draw Enemy Damage Text ---
	--- Draw Enemy Target ---
	--->
		if Target then
			if TalonMenu.drawing.drawTargetText then
				DrawText("Targeting: " .. Target.charName, 12, 100, 100, colorText)
			end
		end
	---<
	--- Draw Enemy Target ---
end
-- / Plugin On Draw / --

-- / OrbWalking Functions / --
--- Orbwalking Target ---
--->
	function OrbWalking(Target)
		if TimeToAttack() and GetDistance(Target) <= myHero.range + GetDistance(myHero.minBBox) then
			myHero:Attack(Target)
    	elseif heroCanMove() then
        	moveToCursor()
    	end
	end
---<
--- Orbwalking Target ---
--- Check When Its Time To Attack ---
--->
	function TimeToAttack()
    	return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
	end
---<
--- Check When Its Time To Attack ---
--- Prevent AA Canceling ---
--->
	function heroCanMove()
		return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
	end
---<
--- Prevent AA Canceling ---
--- Move to Mouse ---
--->
	function moveToCursor()
		if GetDistance(mousePos) then
			local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
			myHero:MoveTo(moveToPos.x, moveToPos.z)
    	end        
	end
---<
--- Move to Mouse ---
--- On Process Spell ---
--->
	function OnProcessSpell(object,spell)
		--- Tick Manager Check ---
		--->
			if not TManager.onSpell:isReady() and TalonMenu.misc.uTM then return end
		---<
		--->
			if object == myHero then
				if spell.name:lower():find("attack") then
					lastAttack = GetTickCount() - GetLatency()/2
					lastWindUpTime = spell.windUpTime*1000
					lastAttackCD = spell.animationTime*1000
				end
			end
		---<
	end
---<
--- On Process Spell ---
-- / OrbWalking Functions / --

-- / FPS Manager Functions / --
class 'TickManager'
--- TM Init Function ---
--->
	function TickManager:__init(ticksPerSecond)
		self.TPS = ticksPerSecond
		self.lastClock = 0
		self.currentClock = 0
	end
---<
--- TM Init Function ---
--- TM Type Function ---
--->
	function TickManager:__type()
		return "TickManager"
	end
---<
--- TM Init Function ---
--- Set TPS Function ---
--->
	function TickManager:setTPS(ticksPerSecond)
		self.TPS = ticksPerSecond
	end
---<
--- Set TPS Function ---
--- Get TPS Function ---
--->
	function TickManager:getTPS(ticksPerSecond)
		return self.TPS
	end
---<
--- Get TPS Function ---
--- TM Ready Function ---
--->
	function TickManager:isReady()
		self.currentClock = os.clock()
		if self.currentClock < self.lastClock + (1 / self.TPS) then return false end
		self.lastClock = self.currentClock
		return true
	end
---<
--- TM Ready Function ---
-- / FPS Manager Functions / --
if VIP_USER then
	-- / Lag Free Circles Functions / --
	--- Draw Cicle Next Level Function ---
	--->
		function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
			radius = radius or 300
			quality = math.max(8, round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
			quality = 2 * math.pi / quality
			radius = radius * .92
			local points = {}
			
			for theta = 0, 2 * math.pi + quality, quality do
				local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
				points[#points + 1] = D3DXVECTOR2(c.x, c.y)
			end
			
			DrawLines2(points, width or 1, color or 4294967295)
		end
	---<
	--- Draw Cicle Next Level Function ---
	--- Round Function ---
	--->
		function round(num) 
			if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
		end
	---<
	--- Round Function ---
	--- Draw Cicle 2 Function ---
	--->
		function DrawCircle2(x, y, z, radius, color)
			local vPos1 = Vector(x, y, z)
			local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
			local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
			local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
			
			if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
				DrawCircleNextLvl(x, y, z, radius, 1, color, TalonMenu.drawing.lfc.CL) 
			end
		end
	---<
	--- Draw Cicle 2 Function ---
	-- / Lag Free Circles Functions / --
end

-- / Checks Function / --
function Checks()
	--- Tick Manager Check ---
	--->
		if not TManager.onTick:isReady() and TalonMenu.misc.uTM then return end
	---<
	--- Tick Manager Check ---
	if VIP_USER then
		--- LFC Checks ---
		--->
			if not TalonMenu.drawing.lfc.LagFree then 
				_G.DrawCircle = _G.oldDrawCircle 
			else
				_G.DrawCircle = DrawCircle2
			end
		---<
		--- LFC Checks ---
	end
	--- Updates & Checks if Target is Valid ---
	--->
		TargetSelector:update()
		tsTarget = TargetSelector.target
		if tsTarget and tsTarget.type == "obj_AI_Hero" then
			Target = tsTarget
		else
			Target = nil
		end
	---<
	--- Updates & Checks if Target is Valid ---	
	--- Checks and finds Ignite ---
	--->
		if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
			ignite = SUMMONER_1
		elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
			ignite = SUMMONER_2
		end
	---<
	--- Checks and finds Ignite ---
	--- Slots for Items ---
	--->
		rstSlot, ssSlot, swSlot, vwSlot =    GetInventorySlotItem(2045),
										     GetInventorySlotItem(2049),
										     GetInventorySlotItem(2044),
										     GetInventorySlotItem(2043)
		dfgSlot, hxgSlot, bwcSlot, brkSlot = GetInventorySlotItem(3128),
											 GetInventorySlotItem(3146),
											 GetInventorySlotItem(3144),
											 GetInventorySlotItem(3153)
		hpSlot, mpSlot, fskSlot =            GetInventorySlotItem(2003),
											 GetInventorySlotItem(2004),
								             GetInventorySlotItem(2041)
		znaSlot, wgtSlot, bftSlot =          GetInventorySlotItem(3157),
	    	                                 GetInventorySlotItem(3090),
											 GetInventorySlotItem(3188)
	---<
	--- Slots for Items ---
	--- Checks if Spells are Ready ---
	--->
		SkillQ.ready = (myHero:CanUseSpell(_Q) == READY)
		SkillW.ready = (myHero:CanUseSpell(_W) == READY)
		SkillE.ready = (myHero:CanUseSpell(_E) == READY)
		SkillR.ready = (myHero:CanUseSpell(_R) == READY)
		iReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	---<
	--- Checks if Active Items are Ready ---
	--->
		dfgReady = (dfgSlot ~= nil and myHero:CanUseSpell(dfgSlot) == READY)
		hxgReady = (hxgSlot ~= nil and myHero:CanUseSpell(hxgSlot) == READY)
		bwcReady = (bwcSlot ~= nil and myHero:CanUseSpell(bwcSlot) == READY)
		brkReady = (brkSlot ~= nil and myHero:CanUseSpell(brkSlot) == READY)
		znaReady = (znaSlot ~= nil and myHero:CanUseSpell(znaSlot) == READY)
		wgtReady = (wgtSlot ~= nil and myHero:CanUseSpell(wgtSlot) == READY)
		bftReady = (bftSlot ~= nil and myHero:CanUseSpell(bftSlot) == READY)
	---<
	--- Checks if Items are Ready ---
	--- Checks if Health Pots / Mana Pots are Ready ---
	--->
		Items.HealthPot.ready = (hpSlot ~= nil and myHero:CanUseSpell(hpSlot) == READY)
		Items.ManaPot.ready = (mpSlot ~= nil and myHero:CanUseSpell(mpSlot) == READY)
		Items.FlaskPot.ready = (fskSlot ~= nil and myHero:CanUseSpell(fskSlot) == READY)
	---<
	--- Checks if Health Pots / Mana Pots are Ready ---	
	--- Updates Minions ---
	--->
		enemyMinions:update()
	---<
	--- Updates Minions ---
end
-- / Checks Function / --

-- / isLow Function / --
function isLow(Name)
	--- Check Potions HP ---
	--->
		if Name == 'Health' then
			if (myHero.health / myHero.maxHealth) <= (TalonMenu.misc.HPHealth / 100) then
				return true
			else
				return false
			end
		end
	---<
	--- Check Potions HP ---
end
-- / isLow Function / --