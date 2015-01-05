--[[ Kha'zix - The Voidreaver by Skeem 1.3
	
	Features:
			- Prodiction for VIPs, NonVIP prediction
			- Full Combo:
				- Full E + W + Q Combo
				- Toggle to use Muramana
				- Toggle for minimum E Range (Default is 400)
				- Items toggle in combo menu
				- Orbwalking Toggle in combo menu
			- Harass Settings:
				- Uses Q Combo to harass
				- Toggle to use W in harass (Off by default)
				- Orbwalking toggle for harass in menu
			- Farming Settings:
				- Toggle to farm with Q in menu
			- Jungle Clear Settings:
				- Toggle to use Q to clear jungle
				- Toggle to use W to clear jungle
				- Toggle to use E to clear jungle
				- Toggle to orbwalk the jungle minions
			- KillSteal Settings:
				- Smart KillSteal with Overkill Check:
					- Checks for enemy health < Q, W, E, Q+W, Q+E, W+E, Q+W+E
				- Toggle for Auto Ignite
			- Drawing Settings:
				- Toggle to draw if enemy is killable (Killable by x2Qs + combo or 1Q + Combo
				- Toggle to draw E Range if available
				- Toggle to draw W Range if available (Off by default)
			- Misc Settings:
				- Toggle for Auto Mana / Health Pots
		
		Credits & Mentions
			- Kain because I've used some of his code and learned a lot from his scripts
			- Sida / Manciuszz for orbwalking stuff and Bothappy for showing me it
			- Bothappy , so many things to thank you for where to begin haha !
				- updated Jungle Names from his autosmite
				- script reviewing making sure I had no mistakes
				- Testing, and taught me the best ways to do certain functions
			- Everyone at the KKK crew who tested this script and gave awesome suggestions!
			
		Changelog:
			1.0     - First Release!
			1.1     - Added ult usage:
			        - Always ult toggle (Always ults in combo)
			        - Smart Ult (Only ults if enemy can die from ult passive + skills)
			        - Fixed jumping at random minions..
			        - Fixed W for non VIPS
			1.2     - More effective W Fix for non vips
			1.2.1   - Fixed typo with W/E for nonvips
			1.2.2   - Fixed minion Targetting
			1.2.3   - Added a death check so it won't jump on dead targets
			1.2.4   - Added Tiamat/Hydra to Jungle Clear
			1.3     - Added vPrediction in misc menu
			        - Recoded Auto KS / Combo a little
			        - Added option to disable E in Combo
  ]]--
  
-- Name Check --  
if myHero.charName ~= "Khazix" then return end

if VIP_USER then 
	require "Prodiction" 
	require "Collision"
	if FileExist(LIB_PATH..'VPrediction.lua') then
		vPredictionExists = true
    	require "VPrediction"
	else -- safety check in case file was deleted.
		vPredictionExists = false
	end
end

-- Loading Function --
function OnLoad()
	Variables()
	KhazixMenu()
	PrintChat("<font color='#0000FF'> >> Kha'zix - The Voidreaver 1.2.3 Loaded!! <<</font>")
end

-- Tick Function --
function OnTick()
	Checks()
	EvolutionCheck()
	UseConsumables()
	DamageCalculation()

	-- Menu Vars --
	ComboKey =   KhazixMenu.combo.comboKey
	FarmingKey = KhazixMenu.farming.farmKey
	HarassKey =  KhazixMenu.harass.harassKey
	JungleKey =  KhazixMenu.jungle.jungleKey
	
	if ComboKey then FullCombo() end
	if HarassKey then HarassCombo() end
	if JungleKey then JungleClear() end
	if KhazixMenu.ks.killSteal then KillSteal() end
	if KhazixMenu.ks.autoIgnite then AutoIgnite() end
	if FarmingKey and not ComboKey then FarmMinions() end
end

function Variables()
	qRange, wRange, eRange, rRange = 325, 1000, 600
	qName, wName, eName, rName = "Taste Their Fear", "Void Spike", "Leap", "Void Assault"
	qReady, wReady, eReady, rReady = false, false, false, false
	evolvedE = false
	eSpeed, eDelay, eWidth = math.huge, .250, 100
	wSpeed, wDelay, wWidth = 828.5, 0.225, 100
	if VIP_USER then
		Prodict = ProdictManager.GetInstance()
		ProdictW = Prodict:AddProdictionObject(_W, wRange, wSpeed, wDelay, wWidth, myHero)
		ProdictE = Prodict:AddProdictionObject(_E, eRange, eSpeed, eDelay, eWidth, myHero)
		if vPredictionExists then
			vPred = VPrediction()
		end
	end
	hpReady, mpReady, fskReady, Recalling = false, false, false, false
	TextList = {"Harass him!!", "Q+W+E KILL!!", "x2Q+W+E KILL!", "ult+Q+W+E KILL!"}
	KillText = {}
	waittxt = {} -- prevents UI lags, all credits to Dekaron
	usingHPot, usingMPot, usingUlt, rManual = false, false, false, false
	for i=1, heroManager.iCount do waittxt[i] = i*3 end
	enemyMinions = minionManager(MINION_ENEMY, qRange, player, MINION_SORT_HEALTH_ASC)
	lastAnimation = nil
	lastAttack = 0
	lastAttackCD = 0
	lastWindUpTime = 0
	JungleMobs = {}
	JungleFocusMobs = {}

	-- Stolen from Apple who Stole it from Sida --
	JungleMobNames = { -- List stolen from SAC Revamped. Sorry, Sida!
        ["wolf8.1.1"] = true,
        ["wolf8.1.2"] = true,
        ["YoungLizard7.1.2"] = true,
        ["YoungLizard7.1.3"] = true,
        ["LesserWraith9.1.1"] = true,
        ["LesserWraith9.1.2"] = true,
        ["LesserWraith9.1.4"] = true,
        ["YoungLizard10.1.2"] = true,
        ["YoungLizard10.1.3"] = true,
        ["SmallGolem11.1.1"] = true,
        ["wolf2.1.1"] = true,
        ["wolf2.1.2"] = true,
        ["YoungLizard1.1.2"] = true,
        ["YoungLizard1.1.3"] = true,
        ["LesserWraith3.1.1"] = true,
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

	for i = 0, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object ~= nil then
			if FocusJungleNames[object.name] then
				table.insert(JungleFocusMobs, object)
			elseif JungleMobNames[object.name] then
				table.insert(JungleMobs, object)
			end
		end
	end
end

-- Our Menu --
function KhazixMenu()
	KhazixMenu = scriptConfig("Khazix - The Voidreaver", "Khazix")
	
	KhazixMenu:addSubMenu("["..myHero.charName.." - Combo Settings]", "combo")
		KhazixMenu.combo:addParam("comboKey", "Full Combo Key (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
		KhazixMenu.combo:addParam("comboERange", ""..eName.." Min Range", SCRIPT_PARAM_SLICE, 400, 0, eRange, -2)
		KhazixMenu.combo:addParam("comboItems", "Use Items with Burst", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.combo:addParam("comboAlwaysUlt", "Always Ult in Combo", SCRIPT_PARAM_ONOFF, false)
		KhazixMenu.combo:addParam("comboSmartUlt", "Use Ult on Killable enemies", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.combo:addParam("useE", "Use E in Combo", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.combo:addParam("comboOrbwalk", "OrbWalk on Combo", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.combo:permaShow("comboKey") 
	
	KhazixMenu:addSubMenu("["..myHero.charName.." - Harass Settings]", "harass")
		KhazixMenu.harass:addParam("harassKey", "Harass Hotkey (C)", SCRIPT_PARAM_ONKEYDOWN, false, 67)
		KhazixMenu.harass:addParam("harassW", "Use "..wName.." (W)", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.harass:addParam("harassOrbwalk", "OrbWalk on Harass", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.harass:permaShow("harassKey") 
		
	
	KhazixMenu:addSubMenu("["..myHero.charName.." - Farming Settings]", "farming")
		KhazixMenu.farming:addParam("farmKey", "Farming ON/Off (Z)", SCRIPT_PARAM_ONKEYTOGGLE, true, 90)
		KhazixMenu.farming:addParam("qFarm", "Farm with "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.farming:addParam("qFarmMana", "Min Mana % for Farming", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
		KhazixMenu.farming:permaShow("farmKey") 
		
	KhazixMenu:addSubMenu("["..myHero.charName.." - Clear Settings]", "jungle")
		KhazixMenu.jungle:addParam("jungleKey", "Jungle Clear Key (V)", SCRIPT_PARAM_ONKEYDOWN, false, 86)
		KhazixMenu.jungle:addParam("jungleQ", "Clear with "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.jungle:addParam("jungleW", "Clear with "..wName.." (W)", SCRIPT_PARAM_ONOFF, false)
		KhazixMenu.jungle:addParam("jungleE", "Clear with "..eName.." (E)", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.jungle:addParam("jungleOrbwalk", "Orbwalk the Jungle", SCRIPT_PARAM_ONOFF, true)
		
		
	KhazixMenu:addSubMenu("["..myHero.charName.." - KillSteal Settings]", "ks")
		KhazixMenu.ks:addParam("killSteal", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.ks:addParam("autoIgnite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.ks:permaShow("killSteal") 
			
	KhazixMenu:addSubMenu("["..myHero.charName.." - Drawing Settings]", "drawing")	
		KhazixMenu.drawing:addParam("mDraw", "Disable All Ranges Drawing", SCRIPT_PARAM_ONOFF, false)
		KhazixMenu.drawing:addParam("cDraw", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.drawing:addParam("wDraw", "Draw "..wName.." (W) Range", SCRIPT_PARAM_ONOFF, false)
		KhazixMenu.drawing:addParam("eDraw", "Draw "..eName.." (E) Range", SCRIPT_PARAM_ONOFF, true)
	
	KhazixMenu:addSubMenu("["..myHero.charName.." - Misc Settings]", "misc")
		KhazixMenu.misc:addParam("aMP", "Auto Mana Pots", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.misc:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
		KhazixMenu.misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
		KhazixMenu.misc:addParam("predType", "Prediction Type", SCRIPT_PARAM_LIST, 1, { "Prodiction", "VPrediction" })
		
	TargetSelector = TargetSelector(TARGET_LOW_HP, wRange,DAMAGE_PHYSICAL)
	TargetSelector.name = "Khazix"
	KhazixMenu:addTS(TargetSelector)
end

-- Our Full Combo --
function FullCombo()
	if KhazixMenu.combo.comboOrbwalk then
		if Target ~= nil then
			OrbWalking(Target)
		else
			moveToCursor()
		end
	end
	if ValidTarget(Target) then
		if KhazixMenu.combo.comboItems then UseItems(Target) end
		if KhazixMenu.combo.comboAlwaysUlt then
			if rReady and GetDistance(Target) <= eRange + 200 then 
				if eReady then CastSpell(_R) end
			end
		end
		if KhazixMenu.combo.comboSmartUlt then
			if Target.health <= ((qDmg*2) + pDmg + wDmg + eDmg + itemsDmg) and Target.health > (qDmg + wDmg + eDmg) then
				if rReady and GetDistance(Target) <= eRange + 200 then
					if eReady then CastSpell(_R) end
				end
			end
		end
		if not MuramanaIsActive() and GetDistance(Target) <= wRange then MuramanaOn() end
		CastQ(Target)
		CastW(Target)
		if KhazixMenu.combo.useE and GetDistance(Target) >= KhazixMenu.combo.comboERange then CastE(Target) end
	else
		if MuramanaIsActive() then MuramanaOff() end
	end
end

function HarassCombo()
	if KhazixMenu.harass.harassOrbwalk then
		if Target ~= nil then
			OrbWalking(Target)
		else
			moveToCursor()
		end
	end
	if Target ~= nil then
		CastQ(Target)
		CastW(Target)
	end
end

-- Farming Function --
function FarmMinions()
	if not myManaLow() then
		for _, minion in pairs(enemyMinions.objects) do
			local qMinionDmg = getDmg("Q", minion, myHero)
			if ValidTarget(minion) then
				if KhazixMenu.farming.qFarm and qReady and GetDistance(minion) <= qRange and minion.health <= qMinionDmg then
					CastSpell(_Q, minion)
				end
			end
		end
	end
end

-- Farming Mana Function --
function myManaLow()
	if myHero.mana < (myHero.maxMana * (KhazixMenu.farming.qFarmMana / 100)) then
		return true
	else
		return false
	end
end

-- Jungle Farming --
function JungleClear()
	JungleMob = GetJungleMob()
	if KhazixMenu.jungle.jungleOrbwalk then
		if JungleMob ~= nil then
			OrbWalking(JungleMob)
		else
			moveToCursor()
		end
	end
	if JungleMob ~= nil then
		if tmtReady and GetDistance(JungleMob) <= 185 then CastSpell(tmtSlot) end
		if hdrReady and GetDistance(JungleMob) <= 185 then CastSpell(hdrSlot) end
		if KhazixMenu.jungle.jungleQ and GetDistance(JungleMob) <= qRange then CastSpell(_Q, JungleMob) end
		if KhazixMenu.jungle.jungleW and GetDistance(JungleMob) <= wRange then CastSpell(_W, JungleMob.x, JungleMob.z) end
		if KhazixMenu.jungle.jungleE and GetDistance(JungleMob) <= eRange then CastSpell(_E, JungleMob.x, JungleMob.z) end
	end
end

-- Get Jungle Mob --
function GetJungleMob()
        for _, Mob in pairs(JungleFocusMobs) do
                if ValidTarget(Mob, qRange) then return Mob end
        end
        for _, Mob in pairs(JungleMobs) do
                if ValidTarget(Mob, qRange) then return Mob end
        end
end

-- Casting Q into Enemies ---
function CastQ(enemy)
	if not qReady or (GetDistance(enemy) > qRange) then
		return false
	end
	if ValidTarget(enemy) then 
		if VIP_USER then
			Packet("S_CAST", {spellId = _Q, targetNetworkId = enemy.networkID}):send()
		else
			CastSpell(_Q, enemy)
		end
	end
end

-- Casting W into Enemies --
function CastW(enemy)
	if not wReady or (GetDistance(enemy) > wRange) then
			return false
	end
	if ValidTarget(enemy) then
		if VIP_USER then
			if KhazixMenu.misc.predType == 1 then
				local wPos = ProdictW:GetPrediction(Target)
				local CollisionW = Collision(wRange, wSpeed, wDelay, wWidth)
				if wPos ~= nil then
					if not CollisionW:GetMinionCollision(wPos, myHero) then
						CastSpell(_W, wPos.x, wPos.z)
					end
				end
			else
				if vPredictionExists then
					local CastPosition, HitChance, Pos = vPred:GetLineCastPosition(enemy, wDelay, wWidth, wRange, wSpeed, myHero, true)
					if HitChance >= 2 then
						CastSpell(_W, CastPosition.x, CastPosition.z)
					end
				end
			end				
		else
			local wPred = TargetPrediction(wRange, wSpeed, wDelay, wWidth)
			local wPrediction = wPred:GetPrediction(enemy)
			if wPrediction and not willHitMinion(wPrediction, wWidth) then
				CastSpell(_W, wPrediction.x, wPrediction.z)
			end
		end
	end
end

function CastE(enemy)
	if not eReady or (GetDistance(enemy) > eRange) then
			return false
	end
	if ValidTarget(enemy) then
		if VIP_USER then
			if KhazixMenu.misc.predType == 1 then
				local ePos = ProdictE:GetPrediction(Target)
				if ePos ~= nil then
					CastSpell(_E, ePos.x, ePos.z)
				end
			else
				if vPredictionExists then
					local CastPosition,  HitChance,  Position = vPred:GetCircularCastPosition(enemy, eDelay, eWidth, eRange)
					if HitChance >= 2 then
						CastSpell(_E, CastPosition.x, CastPosition.z)
					end
				end
			end
		else
			CastSpell(_E, enemy.x, enemy.z)
		end
	end
end

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

-- KillSteal function --
function KillSteal()
	if ValidTarget(Target) then
		if Target.health <= qDmg then 
			CastQ(Target)
		elseif Target.health <= eDmg then
			CastE(Target)
		elseif wReady and Target.health <= wDmg and GetDistance(Target) <= wRange then
			CastW(Target)
		elseif qReady and eReady and Target.health <= (qDmg + eDmg) then
			CastE(Target)
			CastQ(Target)
		elseif qReady and wReady and Target.health <= (qDmg + wDmg) then
			CastW(Target)
			CastQ(Target)
		elseif eReady and wReady and Target.health <= (eDmg + wDmg) then
			CastW(Target)
			CastE(Target)
		elseif qReady and eReady and wReady and Target.health <= (qDmg + eDmg + wDmg) then
			CastW(Target)
			CastE(Target)
			CastQ(Target)
		end
	end
end

-- Auto Ignite --
function AutoIgnite()
	if Target ~= nil then
		if Target.health <= iDmg and GetDistance(Target) <= 600 then
			if iReady then CastSpell(ignite, Target) end
		end
	end
end

-- Using our consumables --
function UseConsumables()
	if not InFountain() and not Recalling and Target ~= nil then
		if KhazixMenu.misc.aHP and myHero.health < (myHero.maxHealth * (KhazixMenu.misc.HPHealth / 100))
			and not (usingHPot or usingFlask) and (hpReady or fskReady)	then
				CastSpell((hpSlot or fskSlot)) 
		end
		if KhazixMenu.misc.aMP and myHero.mana < (myHero.maxMana * (KhazixMenu.farming.qFarmMana / 100))
			and not (usingMPot or usingFlask) and (mpReady or fskReady) then
				CastSpell((mpSlot or fskSlot))
		end
	end
end		

-- Damage Calculations --
function DamageCalculation()
	for i=1, heroManager.iCount do
	local enemy = heroManager:GetHero(i)
		if ValidTarget(enemy) then
			dfgDmg, hxgDmg, bwcDmg, iDmg  = 0, 0, 0, 0
			qDmg, wDmg, eDmg = 0, 0, 0
			aDmg = getDmg("AD", enemy, myHero)
			pDmg = getDmg("P", enemy, myHero)
			if qReady then qDmg = getDmg("Q",enemy,myHero) + aDmg end
            if wReady then wDmg = getDmg("W",enemy,myHero) end
			if eReady then eDmg = getDmg("E",enemy,myHero) end
			if dfgReady then dfgDmg = (dfgSlot and getDmg("DFG",enemy,myHero) or 0)	end
            if hxgReady then hxgDmg = (hxgSlot and getDmg("HXG",enemy,myHero) or 0) end
            if bwcReady then bwcDmg = (bwcSlot and getDmg("BWC",enemy,myHero) or 0) end
            if iReady then iDmg = (ignite and getDmg("IGNITE",enemy,myHero) or 0) end
            onspellDmg = (liandrysSlot and getDmg("LIANDRYS",enemy,myHero) or 0)+(blackfireSlot and getDmg("BLACKFIRE",enemy,myHero) or 0)
            itemsDmg = dfgDmg + hxgDmg + bwcDmg + iDmg + onspellDmg
				KillText[i] = 1 
			if enemy.health <= (qDmg + eDmg + wDmg + itemsDmg) then
				KillText[i] = 2
			elseif enemy.health <= ((qDmg*2) + eDmg + wDmg + itemsDmg) then
				KillText[i] = 3
			elseif enemy.health <= ((qDmg*2) + pDmg + wDmg + eDmg + itemsDmg) then
				KillText[i] = 4
			end
		end
	end
end

-- Adjust Our Skills Range --
function EvolutionCheck()
	if myHero:GetSpellData(_Q).name == "khazixqlong" then
		qRange = 375
	end 
	if myHero:GetSpellData(_E).name == "khazixelong" then
		eRange = 900
		evolvedE = true
	end 
end 

-- Object Handling Functions --
function OnCreateObj(obj)
	if obj ~= nil then
		if obj.name:find("Global_Item_HealthPotion.troy") then
			if GetDistance(obj, myHero) <= 70 then
				usingHPot = true
				usingFlask = true
			end
		end
		if obj.name:find("Global_Item_ManaPotion.troy") then
			if GetDistance(obj, myHero) <= 70 then
				usingFlask = true
				usingMPot = true
			end
		end
		if obj.name:find("TeleportHome.troy") then
			if GetDistance(obj) <= 70 then
				Recalling = true
			end
		end
		if FocusJungleNames[obj.name] then
			table.insert(JungleFocusMobs, obj)
		elseif JungleMobNames[obj.name] then
            table.insert(JungleMobs, obj)
		end
	end
end

function OnDeleteObj(obj)
	if obj ~= nil then
			if obj.name:find("Global_Item_HealthPotion.troy") then
			if GetDistance(obj) <= 70 then
				usingHPot = false
				usingFlask = false
			end
		end
		if obj.name:find("Global_Item_ManaPotion.troy") then
			if GetDistance(obj) <= 70 then
				usingMPot = false
				usingFlask = false
			end
		end
		if obj.name:find("TeleportHome.troy") then
			if GetDistance(obj) <= 70 then
				Recalling = false
			end
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
end

-- Recalling Functions --
function OnRecall(hero, channelTimeInMs)
	if hero.networkID == player.networkID then
		Recalling = true
	end
end

function OnAbortRecall(hero)
	if hero.networkID == player.networkID then
		Recalling = false
	end
end

function OnFinishRecall(hero)
	if hero.networkID == player.networkID then
		Recalling = false
	end
end

-- Function OnDraw --
function OnDraw()
	--> Ranges
	if not KhazixMenu.drawing.mDraw and not myHero.dead then
		if wReady and KhazixMenu.drawing.wDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, wRange, 0x0000FF)
		end
		if eReady and KhazixMenu.drawing.eDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0x0000FF)
		end
	end
	if KhazixMenu.drawing.cDraw then
		for i=1, heroManager.iCount do
			local Unit = heroManager:GetHero(i)
			if ValidTarget(Unit) then
				if waittxt[i] == 1 and (KillText[i] ~= nil or 0 or 1) then
					PrintFloatText(Unit, 0, TextList[KillText[i]])
				end
			end
			if waittxt[i] == 1 then
				waittxt[i] = 30
			else
				waittxt[i] = waittxt[i]-1
			end
		end
	end
end

--Based on Manciuzz Orbwalker http://pastebin.com/jufCeE0e

function OrbWalking(Target)
	if TimeToAttack() and GetDistance(Target) <= myHero.range + GetDistance(myHero.minBBox) then
		myHero:Attack(Target)
    elseif heroCanMove() then
        moveToCursor()
    end
end

function TimeToAttack()
    return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end

function heroCanMove()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end

function moveToCursor()
	if GetDistance(mousePos) then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
		myHero:MoveTo(moveToPos.x, moveToPos.z)
    end        
end

function OnProcessSpell(object,spell)
	if object == myHero then
		if spell.name:lower():find("attack") then
			lastAttack = GetTickCount() - GetLatency()/2
			lastWindUpTime = spell.windUpTime*1000
			lastAttackCD = spell.animationTime*1000
        end
    end
end

function OnAnimation(unit,animationName)
    if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end

-- regular minion mec taken from Sida's Auto Carry --
function willHitMinion(predic, width)
        for _, minion in pairs(enemyMinions.objects) do
                if minion ~= nil and minion.valid and string.find(minion.name,"Minion_") == 1 and minion.team ~= player.team and minion.dead == false then
                        if predic ~= nil then
                                ex = player.x
                                ez = player.z
                                tx = predic.x
                                tz = predic.z
                                dx = ex - tx
                                dz = ez - tz
                                if dx ~= 0 then
                                        m = dz/dx
                                        c = ez - m*ex
                                end
                                mx = minion.x
                                mz = minion.z
                                distanc = (math.abs(mz - m*mx - c))/(math.sqrt(m*m+1))
                                if distanc < width and math.sqrt((tx - ex)*(tx - ex) + (tz - ez)*(tz - ez)) > math.sqrt((tx - mx)*(tx - mx) + (tz - mz)*(tz - mz)) then
                                        return true
                                end
                        end
                end
        end
        return false
end

-- Spells/Items Checks --
function Checks()
	-- Updates Targets --
	TargetSelector:update()
	tsTarget = TargetSelector.target
	if tsTarget and tsTarget.type == myHero.type and not tsTarget.dead then
		Target = tsTarget
	else
		Target = nil
	end
	
	-- Finds Ignite --
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	end
	
	-- Slots for Items / Pots / Wards --
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
	znaSlot, wgtSlot =                   GetInventorySlotItem(3157),
	                                     GetInventorySlotItem(3090)
	tmtSlot, hdrSlot = 					 GetInventorySlotItem(3077),
										 GetInventorySlotItem(3074)
	
	-- Spells --									 
	qReady = (myHero:CanUseSpell(_Q) == READY)
	wReady = (myHero:CanUseSpell(_W) == READY)
	eReady = (myHero:CanUseSpell(_E) == READY)
	rReady = (myHero:CanUseSpell(_R) == READY)
	iReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	
	-- Items --
	dfgReady = (dfgSlot ~= nil and myHero:CanUseSpell(dfgSlot) == READY)
	hxgReady = (hxgSlot ~= nil and myHero:CanUseSpell(hxgSlot) == READY)
	bwcReady = (bwcSlot ~= nil and myHero:CanUseSpell(bwcSlot) == READY)
	brkReady = (brkSlot ~= nil and myHero:CanUseSpell(brkSlot) == READY)
	znaReady = (znaSlot ~= nil and myHero:CanUseSpell(znaSlot) == READY)
	wgtReady = (wgtSlot ~= nil and myHero:CanUseSpell(wgtSlot) == READY)
	tmtReady = (tmtSlot ~= nil and myHero:CanUseSpell(tmtSlot) == READY)
	hdrReady = (hdrSlot ~= nil and myHero:CanUseSpell(hdrSlot) == READY)
	
	-- Pots --
	hpReady = (hpSlot ~= nil and myHero:CanUseSpell(hpSlot) == READY)
	mpReady =(mpSlot ~= nil and myHero:CanUseSpell(mpSlot) == READY)
	fskReady = (fskSlot ~= nil and myHero:CanUseSpell(fskSlot) == READY)
	
	-- Updates Minions --
	enemyMinions:update()
end