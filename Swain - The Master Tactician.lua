--[[
	[Script] Swain - The Master Tactician 1.3 by Skeem
	
		Features:
			- Prodiction for VIPs, NonVIP prediction
			- Full Combo:
				- Full W + E + Q + R Combo
				- Uses AoE Position for W
				- Items toggle in combo menu
				- Orbwalking Toggle in combo menu
			- Ult Settings:
				- Automatically uses ult with smart logic:
					- If your health is below the amount you set in menu
					  and your mana is above than you set in menu.
					  Checks if minions, jungle minions or enemies are around to heal to heal
					- Minimum mana toggle in menu (50% default)
					- Maximum health toggle in menu (70% default)
					- Auto Disable ult if enemies are not in range and health is > set value
			- W Prodiction Settings:
				- ChainCC Toggle to automatically use W after an enemy has been CCed
				- OnDash toggle to automatically use W when enemies use dashes
			- Harass Settings:
				- Uses E+Q Combo to harass
				- Orbwalking toggle for harass in menu
			- Farming Settings:
				- Toggle to farm with Q in menu
				- Toggle to farm with E in menu (Off by default)
				- Minimum mana to farm can be set in menu (50% default)
			- Jungle Clear Settings:
				- Toggle to use Q to clear jungle
				- Toggle to use W to clear jungle (Off by default)
				- Toggle to use E to clear jungle
				- Toggle to orbwalk the jungle minions
			- KillSteal Settings:
				- Smart KillSteal with Overkill Check:
					- Checks for enemy health < Q, E, W, QE, WQ, WE, WEQ
				- Toggle for Auto Ignite
			- Drawing Settings:
				- Toggle to draw if enemy is killable
				- Toggle to draw Q Range if available
				- Toggle to draw W Range if available (Off by default)
				- Toggle to draw E Range if available (Off by default)
			- Misc Settings:
				- Toggle for auto zhonyas/wooglets (needs more logic)
				- Toggle for Auto Mana / Health Pots
		
		Credits & Mentions
			- Kain because I've used some of his code and learned a lot from his scripts
			- Sida / Manciuszz for orbwalking stuff and Bothappy for showing me it
			- Bothappy , so many things to thank you for where to begin haha !
				- updated Jungle Names from his autosmite
				- script reviewing making sure I had no mistakes
				- Testing, and taught me the best ways to do certain functions
			- Zikkah for his very useful post on prodiction callbacks
			- Everyone at the KKK crew who tested this script and gave awesome suggestions!
			
		Changelog:
			1.0   - First Release!
			1.0.1 - Small Prodiction fix
			1.0.2 - Typo Fix, Prodiction Fix
			1.0.3 - Changed combo a little:
						- if enemy in eRange combo will be EQWR
						- if enemy outside of eRange and inside wRange it'll be WEQR
				  - Fixed auto ult disable
			1.1   - More auto ult fixes
			      - Removed wPos drawing
				  - Some prodiction tweaks
			1.1.1 - Fixed auto ult
			1.2   - Added AoE W
			      - Prodiction tweaks
			1.2.1 - Added own tweaks to prediction
			1.3   - Added vPrediction
			      - Some minor tweaks
	
	]]--

if myHero.charName ~= "Swain" then return end

-- Prodiction for VIPs --
if VIP_USER then 
	require "Prodiction"
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
	SwainMenu()
	PrintChat("<font color='#00FF00'> >> Swain - The Master Tactician 1.3 Loaded!! <<</font>")
end

-- Tick Function --
function OnTick()
	Checks()
	DamageCalculation()
	UltManagement()
	UseConsumables()
	
	-- Menu Vars --
	ComboKey =   SwainMenu.combo.comboKey
	FarmingKey = SwainMenu.farming.farmKey
	HarassKey =  SwainMenu.harass.harassKey
	JungleKey =  SwainMenu.jungle.jungleKey
	
	if ComboKey then FullCombo() end
	if HarassKey then HarassCombo() end
	if JungleKey then JungleClear() end
	if SwainMenu.ks.killSteal then KillSteal() end
	if SwainMenu.ks.autoIgnite then AutoIgnite() end
	if FarmingKey and not (ComboKey or HarassKey) then FarmMinions() end
end

-- Our Variables --
function Variables()
	qRange, wRange, eRange, rRange = 625, 900, 625, 700
	qName, wName, eName, rName = "Decrepify", "Nevermove", "Torment", "Ravenous Flock"
	qReady, wReady, eReady, rReady = false, false, false, false
	wSpeed, wDelay, wWidth = 2000, .700, 250
	if VIP_USER then
		Prodict = ProdictManager.GetInstance()
		ProdictW = Prodict:AddProdictionObject(_W, wRange, wSpeed, wDelay, wWidth, myHero)
		if vPredictionExists then
			vPred = VPrediction()
		end
	end
	hpReady, mpReady, fskReady, Recalling = false, false, false, false
	TextList = {"Harass him!!", "Q+W+E KILL!!", "FULL COMBO KILL!"}
	KillText = {}
	waittxt = {} -- prevents UI lags, all credits to Dekaron
	usingHPot, usingMPot, usingUlt, rManual = false, false, false, false
	for i=1, heroManager.iCount do waittxt[i] = i*3 end
	enemyMinions = minionManager(MINION_ENEMY, eRange, player, MINION_SORT_HEALTH_ASC)
	lastAnimation = nil
	lastAttack = 0
	lastAttackCD = 0
	lastWindUpTime = 0
	JungleMobs = {}
	JungleFocusMobs = {}
	debugMode = false

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
function SwainMenu()
	SwainMenu = scriptConfig("Swain - The Master Tactician", "Swain")
	
	SwainMenu:addSubMenu("["..myHero.charName.." - Combo Settings]", "combo")
		SwainMenu.combo:addParam("comboKey", "Full Combo Key (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
		SwainMenu.combo:addParam("comboW", "Use "..wName.." (W)", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.combo:addParam("comboItems", "Use Items with Burst", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.combo:addParam("comboOrbwalk", "OrbWalk on Combo", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.combo:permaShow("comboKey") 
	
	SwainMenu:addSubMenu("["..myHero.charName.." - Ult Settings]", "ult")
		SwainMenu.ult:addParam("AutoDisableUlt", "Auto Disable Ult", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.ult:addParam("HealWithUlt", "Auto Heal With Ult", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.ult:addParam("MinUltHealth", "Min Health % to Heal", SCRIPT_PARAM_SLICE, 70, 0, 100, -1)
		SwainMenu.ult:addParam("MinUltMana", "Min Mana % to Heal", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
		
	--[[if VIP_USER then
	SwainMenu:addSubMenu("["..myHero.charName.." - W Prodiction]", "wprodict")
		SwainMenu.wprodict:addParam("chainCC", "Auto Chain CC", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.wprodict:addParam("onDash", "Use W OnDash", SCRIPT_PARAM_ONOFF, true)
	end]]--		
	
	SwainMenu:addSubMenu("["..myHero.charName.." - Harass Settings]", "harass")
		SwainMenu.harass:addParam("harassKey", "Harass Hotkey (C)", SCRIPT_PARAM_ONKEYDOWN, false, 67)
		SwainMenu.harass:addParam("harassOrbwalk", "OrbWalk on Harass", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.harass:permaShow("harassKey") 
		
	
	SwainMenu:addSubMenu("["..myHero.charName.." - Farming Settings]", "farming")
		SwainMenu.farming:addParam("farmKey", "Farming ON/Off (Z)", SCRIPT_PARAM_ONKEYTOGGLE, false, 90)
		SwainMenu.farming:addParam("qFarm", "Farm with "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.farming:addParam("eFarm", "Farm with "..eName.." (E)", SCRIPT_PARAM_ONOFF, false)
		SwainMenu.farming:addParam("qFarmMana", "Min Mana % for Farming", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
		SwainMenu.farming:permaShow("farmKey") 
		
	SwainMenu:addSubMenu("["..myHero.charName.." - Clear Settings]", "jungle")
		SwainMenu.jungle:addParam("jungleKey", "Jungle Clear Key (V)", SCRIPT_PARAM_ONKEYDOWN, false, 86)
		SwainMenu.jungle:addParam("jungleQ", "Clear with "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.jungle:addParam("jungleW", "Clear with "..wName.." (W)", SCRIPT_PARAM_ONOFF, false)
		SwainMenu.jungle:addParam("jungleE", "Clear with "..eName.." (E)", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.jungle:addParam("jungleOrbwalk", "Orbwalk the Jungle", SCRIPT_PARAM_ONOFF, true)
		
		
	SwainMenu:addSubMenu("["..myHero.charName.." - KillSteal Settings]", "ks")
		SwainMenu.ks:addParam("killSteal", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.ks:addParam("autoIgnite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.ks:permaShow("killSteal") 
			
	SwainMenu:addSubMenu("["..myHero.charName.." - Drawing Settings]", "drawing")	
		SwainMenu.drawing:addParam("mDraw", "Disable All Ranges Drawing", SCRIPT_PARAM_ONOFF, false)
		SwainMenu.drawing:addParam("cDraw", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.drawing:addParam("qDraw", "Draw "..qName.." (Q) Range", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.drawing:addParam("wDraw", "Draw "..wName.." (W) Range", SCRIPT_PARAM_ONOFF, false)
		SwainMenu.drawing:addParam("eDraw", "Draw "..eName.." (E) Range", SCRIPT_PARAM_ONOFF, false)
	
	SwainMenu:addSubMenu("["..myHero.charName.." - Misc Settings]", "misc")
		SwainMenu.misc:addParam("ZWItems", "Auto Zhonyas/Wooglets", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.misc:addParam("ZWHealth", "Min Health % for Zhonyas/Wooglets", SCRIPT_PARAM_SLICE, 15, 0, 100, -1)
		SwainMenu.misc:addParam("aMP", "Auto Mana Pots", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.misc:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
		SwainMenu.misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
		SwainMenu.misc:addParam("predType", "Prediction Type", SCRIPT_PARAM_LIST, 1, { "Prodiction", "VPrediction" })

	TargetSelector = TargetSelector(TARGET_LOW_HP, wRange,DAMAGE_MAGIC)
	TargetSelector.name = "Swain"
	SwainMenu:addTS(TargetSelector)
end

-- Our Full Combo --
function FullCombo()
	if SwainMenu.combo.comboOrbwalk then
		if Target ~= nil then
			OrbWalking(Target)
		else
			moveToCursor()
		end
	end
	if ValidTarget(Target) then
		CastQ(Target)
		CastE(Target)
		CastW(Target)
		if rReady and GetDistance(Target) <= rRange and not usingUlt then
			CastSpell(_R)
			rManual = false
			if debugMode then PrintChat ("Debug 269") end
		end
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
			if SwainMenu.misc.predType == 1 then
				local wAoEPos = GetAoESpellPosition(250, enemy, 250)
				if wAoEPos and GetDistance(wAoEPos) <= wRange then
					if CountEnemies(wAoEPos, 250) > 1 then
						CastSpell(_W, wAoEPos.x, wAoEPos.z)
						if debugMode then PrintChat("AoE W") end
					elseif CountEnemies(wAoEPos, 250) < 2 then
						if wPos ~= nil then
							CastSpell(_W, wPos.x, wPos.z)
							if debugMode then PrintChat("W Normal ELSE") end
						end
					end
				else 
					if wPos then
						CastSpell(_W, wPos.x, wPos.z)
						if debugMode then PrintChat("W Normal VIP") end
					end
				end
			else
				if vPredictionExists then
					local CastPosition,  HitChance,  Position = vPred:GetCircularCastPosition(enemy, wDelay, wWidth, wRange)
					if HitChance >= 2 then
						CastSpell(_W, CastPosition.x, CastPosition.z)
						if debugMode then PrintChat("W vPred") end
					end
				end
			end
		else
			CastSpell(_W, enemy.x, enemy.z)
			if debugMode then PrintChat("W Free") end
		end
	end
end

-- Casting E into Enemies ---
function CastE(enemy)
	if not eReady or (GetDistance(enemy) > eRange) then
		return false
	end
	if ValidTarget(enemy) then 
		if VIP_USER then
			Packet("S_CAST", {spellId = _E, targetNetworkId = enemy.networkID}):send()
		else
			CastSpell(_E, enemy)
		end
	end
end


-- Harass Combo --
function HarassCombo()
	if SwainMenu.harass.harassOrbwalk then
		if ValidTarget(Target) then
			OrbWalking(Target)
		else
			moveToCursor()
		end
	end
	if ValidTarget(Target) then
		CastE(Target)
		CastQ(Target)
	end
end

-- Farming Function --
function FarmMinions()
	if not myManaLow() then
		for _, minion in pairs(enemyMinions.objects) do
			local qMinionDmg = getDmg("Q", minion, myHero)
			local eMinionDmg = getDmg("E", minion, myHero)
			if ValidTarget(minion) then
				if SwainMenu.farming.qFarm and qReady and minion.health <= qMinionDmg then
					CastSpell(_Q, minion)
				end
				if SwainMenu.farming.eFarm and eReady and minion.health <= eMinionDmg then
					CastSpell(_E, minion)
				end
			end
		end
	end
end

-- Farming Mana Function --
function myManaLow()
	if myHero.mana < (myHero.maxMana * (SwainMenu.farming.qFarmMana / 100)) then
		return true
	else
		return false
	end
end

-- Jungle Farming --
function JungleClear()
	JungleMob = GetJungleMob()
	local AARange = myHero.range
	if SwainMenu.jungle.jungleOrbwalk then
		if JungleMob ~= nil then
			OrbWalking(JungleMob)
		else
			moveToCursor()
		end
	end
	if JungleMob ~= nil then
		if SwainMenu.jungle.jungleQ and GetDistance(JungleMob) <= qRange then CastSpell(_Q, JungleMob) end
		if SwainMenu.jungle.jungleW and GetDistance(JungleMob) <= wRange then CastSpell(_W, JungleMob.x, JungleMob.z) end
		if SwainMenu.jungle.jungleE and GetDistance(JungleMob) <= eRange then CastSpell(_E, JungleMob) end
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

-- KillSteal function --
function KillSteal()
	if Target ~= nil then
		if qReady and Target.health <= qDmg and GetDistance(Target) <= qRange then 
			CastSpell(_Q, Target)
		elseif eReady and Target.health <= eDmg and GetDistance(Target) <= eRange then
			CastSpell(_E, Target)
		elseif wReady and Target.health <= wDmg and GetDistance(Target) <= wRange then
			CastW(Target)
		elseif qReady and eReady and Target.health <= (qDmg + eDmg) and GetDistance(Target) <= eRange then
			CastSpell(_E, Target)
			CastSpell(_Q, Target)
		elseif qReady and wReady and Target.health <= (qDmg + wDmg) and GetDistance(Target) <= qRange then
			CastW(Target)
			CastSpell(_Q, Target)
		elseif eReady and wReady and Target.health <= (eDmg + wDmg) and GetDistance(Target) <= eRange then
			CastW(Target)
			CastSpell(_E, Target)
		elseif qReady and eReady and wReady and Target.health <= (qDmg + eDmg + wDmg) and GetDistance(Target) <= wRange then
			CastW(Target)
			CastSpell(_E, Target)
			CastSpell(_Q, Target)
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

-- Functions to Handle our Ult --
function UltManagement()
	if not rReady then return end
	if SwainMenu.ult.HealWithUlt then
		Minions = GetRMinions()
		JungleMinions = GetJungleMob()
		if not usingUlt then
			if myHero.mana > (myHero.maxMana * (SwainMenu.ult.MinUltMana / 100))
				and
			   myHero.health < (myHero.maxHealth * (SwainMenu.ult.MinUltHealth / 100))
			    and (Minions ~= nil or JungleMinions ~= nil or Target ~= nil) then
					CastSpell(_R)
					rManual = false
					if debugMode then PrintChat("Debug 408") end
			end
		elseif usingUlt and not rManual then
			if myHero.mana < (myHero.maxMana * (SwainMenu.ult.MinUltMana / 100)) then
				if not SwainMenu.combo.comboKey then
					CastSpell(_R)
					rManual = false
					if debugMode then PrintChat("Debug 415") end
				end
			end
			if myHero.health >= (myHero.maxHealth * (SwainMenu.ult.MinUltHealth / 100)) then
				if not SwainMenu.combo.comboKey then 
					CastSpell(_R)
					rManual = false
					if debugMode then PrintChat("Debug 422") end
				end
			end
			if myHero.mana < (myHero.maxMana * (SwainMenu.ult.MinUltMana / 100)) then
				if Target ~= nil and Target.health >= (qDmg + wDmg + eDmg + (rDmg*4)) then
					CastSpell(_R)
					rManual = false
					if debugMode then PrintChat("Debug 429") end
				end
			end
		end
	end
	if usingUlt and not rManual and SwainMenu.ult.AutoDisableUlt then
		if not SwainMenu.ult.HealWithUlt then
			if not Target then 
				CastSpell(_R)
				rManual = false
				if debugMode then PrintChat("Debug 439") end
			end
		end
	end
end

-- Count Enemies --
function CountEnemies(point, range)
	local ChampCount = 0
    for j = 1, heroManager.iCount, 1 do
        local enemyhero = heroManager:getHero(j)
        if myHero.team ~= enemyhero.team and ValidTarget(enemyhero, rRange+150) then
            if GetDistance(enemyhero, point) <= range then
                ChampCount = ChampCount + 1
            end
        end
    end            
    return ChampCount
end

-- Minions for Ult --
function GetRMinions()
        for _, rMinion in pairs(enemyMinions.objects) do
                if ValidTarget(rMinion, rRange) then return rMinion end
        end
end

-- Manual Ult Detection --
function OnWndMsg(msg,key)
	if not rManual then
		if key == 82 then 
			rManual = true
		end
	end
end

-- Using our consumables --
function UseConsumables()
	if not InFountain() and not Recalling and Target ~= nil then
		if SwainMenu.misc.ZWItems and myHero.health < (myHero.maxHealth * (SwainMenu.misc.ZWHealth / 100))
			and GetDistance(Target) <= 500 and (znaReady or wgtReady) then
				CastSpell((wgtSlot or znaSlot)) 
		end
		if SwainMenu.misc.aHP and myHero.health < (myHero.maxHealth * (SwainMenu.misc.HPHealth / 100))
			and not (usingHPot or usingFlask) and (hpReady or fskReady)	then
				CastSpell((hpSlot or fskSlot)) 
		end
		if SwainMenu.misc.aMP and myHero.mana < (myHero.maxMana * (SwainMenu.farming.qFarmMana / 100))
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
			qDmg, wDmg, eDmg, rDmg = 0, 0, 0, 0
			if qReady then qDmg = getDmg("Q",enemy,myHero) end
            if wReady then wDmg = getDmg("W",enemy,myHero) end
			if eReady then eDmg = getDmg("E",enemy,myHero) end
            if rReady then rDmg = getDmg("R",enemy,myHero)*7 end
			if dfgReady then dfgDmg = (dfgSlot and getDmg("DFG",enemy,myHero) or 0)	end
            if hxgReady then hxgDmg = (hxgSlot and getDmg("HXG",enemy,myHero) or 0) end
            if bwcReady then bwcDmg = (bwcSlot and getDmg("BWC",enemy,myHero) or 0) end
            if iReady then iDmg = (ignite and getDmg("IGNITE",enemy,myHero) or 0) end
            onspellDmg = (liandrysSlot and getDmg("LIANDRYS",enemy,myHero) or 0)+(blackfireSlot and getDmg("BLACKFIRE",enemy,myHero) or 0)
            itemsDmg = dfgDmg + hxgDmg + bwcDmg + iDmg + onspellDmg
				KillText[i] = 1 
			if enemy.health <= (qDmg + eDmg + wDmg + itemsDmg) then
				KillText[i] = 2
			end
			if enemy.health <= (qDmg + eDmg + wDmg + rDmg + itemsDmg) and enemy.health >= (qDmg + eDmg + wDmg + itemsDmg) then
				KillText[i] = 3
			end
		end
	end
end

-- Prodiction Features --
function ChainCC(unit, pos, spell)
	if GetDistance(pos) < spell.range and myHero:CanUseSpell(spell.Name) == READY then
            CastSpell(spell.Name, pos.x, pos.z)
	end
end

function DashCC(unit, pos, spell)
	if GetDistance(pos) < spell.range and myHero:CanUseSpell(spell.Name) == READY then
        CastSpell(spell.Name, pos.x, pos.z)
	end
end

-- Object Handling Functions --
function OnCreateObj(obj)
	if obj ~= nil then
		if obj.name:find("swain_demonForm") then
			if GetDistance(obj) <= 70 then
				usingUlt = true
			end
		end
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
		if obj.name:find("swain_demonForm") then
			if GetDistance(obj) <= 70 then
				usingUlt = false
			end
		end
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
	if not SwainMenu.drawing.mDraw and not myHero.dead then
		if qReady and SwainMenu.drawing.qDraw then 
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x00B200)
		end
		if wReady and SwainMenu.drawing.wDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, wRange, 0x59B200)
		end
		if eReady and SwainMenu.drawing.eDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0x00B259)
		end
	end
	if SwainMenu.drawing.cDraw then
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
	if object == myHero and spell.name == "SwainMetamorphism" then
		if  usingUlt then
			usingUlt = false
		else
			usingUlt = true
		end
	end
end

function OnAnimation(unit,animationName)
    if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end

-- Spells/Items Checks --
function Checks()
	-- Updates Targets --
	TargetSelector:update()
	Target = TargetSelector.target
	
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
	
	-- Pots --
	hpReady = (hpSlot ~= nil and myHero:CanUseSpell(hpSlot) == READY)
	mpReady =(mpSlot ~= nil and myHero:CanUseSpell(mpSlot) == READY)
	fskReady = (fskSlot ~= nil and myHero:CanUseSpell(fskSlot) == READY)
	
	-- Updates Minions --
	enemyMinions:update()
	if VIP_USER then
		if ValidTarget(Target) then
			wPos = ProdictW:GetPrediction(Target)
		end
	end
end

-------------- END OF SWAIN THE MASTER TACTICIAN --------------------

--[[ 
        AoE_Skillshot_Position 2.0 by monogato
        
        GetAoESpellPosition(radius, main_target, [delay]) returns best position in order to catch as many enemies as possible with your AoE skillshot, making sure you get the main target.
        Note: You can optionally add delay in ms for prediction (VIP if avaliable, normal else).
]]

function GetCenter(points)
        local sum_x = 0
        local sum_z = 0
        
        for i = 1, #points do
                sum_x = sum_x + points[i].x
                sum_z = sum_z + points[i].z
        end
        
        local center = {x = sum_x / #points, y = 0, z = sum_z / #points}
        
        return center
end

function ContainsThemAll(circle, points)
        local radius_sqr = circle.radius*circle.radius
        local contains_them_all = true
        local i = 1
        
        while contains_them_all and i <= #points do
                contains_them_all = GetDistanceSqr(points[i], circle.center) <= radius_sqr
                i = i + 1
        end
        
        return contains_them_all
end

-- The first element (which is gonna be main_target) is untouchable.
function FarthestFromPositionIndex(points, position)
        local index = 2
        local actual_dist_sqr
        local max_dist_sqr = GetDistanceSqr(points[index], position)
        
        for i = 3, #points do
                actual_dist_sqr = GetDistanceSqr(points[i], position)
                if actual_dist_sqr > max_dist_sqr then
                        index = i
                        max_dist_sqr = actual_dist_sqr
                end
        end
        
        return index
end

function RemoveWorst(targets, position)
        local worst_target = FarthestFromPositionIndex(targets, position)
        
        table.remove(targets, worst_target)
        
        return targets
end

function GetInitialTargets(radius, main_target)
        local targets = {main_target}
        local diameter_sqr = 4 * radius * radius
        
        for i=1, heroManager.iCount do
                target = heroManager:GetHero(i)
                if target.networkID ~= main_target.networkID and ValidTarget(target) and GetDistanceSqr(main_target, target) < diameter_sqr then table.insert(targets, target) end
        end
        
        return targets
end

function GetPredictedInitialTargets(radius, main_target, delay)
        if VIP_USER and not vip_target_predictor then vip_target_predictor = TargetPredictionVIP(nil, nil, delay/1000) end
        local predicted_main_target = VIP_USER and vip_target_predictor:GetPrediction(main_target) or GetPredictionPos(main_target, delay)
        local predicted_targets = {predicted_main_target}
        local diameter_sqr = 4 * radius * radius
        
        for i=1, heroManager.iCount do
                target = heroManager:GetHero(i)
                if ValidTarget(target) then
                        predicted_target = VIP_USER and vip_target_predictor:GetPrediction(target) or GetPredictionPos(target, delay)
                        if target.networkID ~= main_target.networkID and GetDistanceSqr(predicted_main_target, predicted_target) < diameter_sqr then table.insert(predicted_targets, predicted_target) end
                end
        end
        
        return predicted_targets
end

-- I don't need range since main_target is gonna be close enough. You can add it if you do.
function GetAoESpellPosition(radius, main_target, delay)
        local targets = delay and GetPredictedInitialTargets(radius, main_target, delay) or GetInitialTargets(radius, main_target)
        local position = GetCenter(targets)
        local best_pos_found = true
        local circle = Circle(position, radius)
        circle.center = position
        
        if #targets > 2 then best_pos_found = ContainsThemAll(circle, targets) end
        
        while not best_pos_found do
                targets = RemoveWorst(targets, position)
                position = GetCenter(targets)
                circle.center = position
                best_pos_found = ContainsThemAll(circle, targets)
        end
        
        return position, #targets
end