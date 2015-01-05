--[[ Xerath - The Magus Ascendant by Skeem 1.2 

	Changelog:
	          1.2 - Reworked whole script 
	              - No Longer AutoCarry Plugin
	              - Supports Prodiction / Harass / Jungle Clear
	              - KS with R like a baus
	              - Toggle to use R in combo
	              - Needs improvement on auto W disable]]--
  
-- Name Check --  
if myHero.charName ~= "Xerath" then return end

if VIP_USER then 
	require "Prodiction" 
end

-- Loading Function --
function OnLoad()
	Variables()
	XerathMenu()
	PrintChat("<font color='#0000FF'> >> Xerath - The Magus Ascendant 1.2 Loaded!! <<</font>")
end

-- Tick Function --
function OnTick()
	Checks()
	wManagement()
	UseConsumables()
	DamageCalculation()

	-- Menu Vars --
	ComboKey =   XerathMenu.combo.comboKey
	FarmingKey = XerathMenu.farming.farmKey
	HarassKey =  XerathMenu.harass.harassKey
	JungleKey =  XerathMenu.jungle.jungleKey
	
	if ComboKey then FullCombo() end
	if HarassKey then HarassCombo() end
	if JungleKey then JungleClear() end
	if XerathMenu.ks.killSteal then KillSteal() end
	if XerathMenu.ks.autoIgnite then AutoIgnite() end
	if FarmingKey and not ComboKey then FarmMinions() end
end

function Variables()
	qRange, wRange, eRange, rRange, dangerRange = 1100, 1600, 650, 1100, 550
	qName, wName, eName, rName = "Arcanopulse", "Locus of Power", "Mage Chains", "Arcane Barrage"
	qReady, wReady, eReady, rReady = false, false, false, false
	HasBolt, BoltTime, rUsed = false, 0, 0
	wActive, wManual, Recall = false, false, false
	if VIP_USER then
		qSpeed, qDelay, qWidth = math.huge, .600, 100
		rSpeed, rDelay, rWidth = 2000, 0.250, 450
		qPos, rPos = nil, nil
		Prodict = ProdictManager.GetInstance()
		ProdictQ = Prodict:AddProdictionObject(_Q, qRange, qSpeed, qDelay, qWidth, myHero)
		ProdictR = Prodict:AddProdictionObject(_R, rRange, rSpeed, rDelay, rWidth, myHero)
	end
	hpReady, mpReady, fskReady = false, false, false
	TextList = {"Harass him!!", "Q+E KILL!!", "FULL COMBO KILL!"}
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
function XerathMenu()
	XerathMenu = scriptConfig("Xerath - The Magus Ascendant", "Xerath")
	
	XerathMenu:addSubMenu("["..myHero.charName.." - Combo Settings]", "combo")
		XerathMenu.combo:addParam("comboKey", "Full Combo Key (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
		XerathMenu.combo:addParam("comboItems", "Use Items with Burst", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.combo:addParam("comboUlt", "Use "..rName.." (R) in Combo", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.combo:addParam("comboOrbwalk", "OrbWalk on Combo", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.combo:permaShow("comboKey") 
	
	XerathMenu:addSubMenu("["..myHero.charName.." - Harass Settings]", "harass")
		XerathMenu.harass:addParam("harassKey", "Harass Hotkey (C)", SCRIPT_PARAM_ONKEYDOWN, false, 67)
		XerathMenu.harass:addParam("harassOrbwalk", "OrbWalk on Harass", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.harass:permaShow("harassKey") 
		
	
	XerathMenu:addSubMenu("["..myHero.charName.." - Farming Settings]", "farming")
		XerathMenu.farming:addParam("farmKey", "Farming ON/Off (Z)", SCRIPT_PARAM_ONKEYTOGGLE, false, 90)
		XerathMenu.farming:addParam("qFarm", "Farm with "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.farming:addParam("qFarmMana", "Min Mana % for Farming", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
		XerathMenu.farming:permaShow("farmKey") 
		
	XerathMenu:addSubMenu("["..myHero.charName.." - Clear Settings]", "jungle")
		XerathMenu.jungle:addParam("jungleKey", "Jungle Clear Key (V)", SCRIPT_PARAM_ONKEYDOWN, false, 86)
		XerathMenu.jungle:addParam("jungleQ", "Clear with "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.jungle:addParam("jungleE", "Clear with "..eName.." (E)", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.jungle:addParam("jungleOrbwalk", "Orbwalk the Jungle", SCRIPT_PARAM_ONOFF, true)
		
		
	XerathMenu:addSubMenu("["..myHero.charName.." - KillSteal Settings]", "ks")
		XerathMenu.ks:addParam("killSteal", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.ks:addParam("autoIgnite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.ks:permaShow("killSteal") 
			
	XerathMenu:addSubMenu("["..myHero.charName.." - Drawing Settings]", "drawing")	
		XerathMenu.drawing:addParam("mDraw", "Disable All Ranges Drawing", SCRIPT_PARAM_ONOFF, false)
		XerathMenu.drawing:addParam("cDraw", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.drawing:addParam("qDraw", "Draw "..qName.." (Q) Range", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.drawing:addParam("eDraw", "Draw "..eName.." (E) Range", SCRIPT_PARAM_ONOFF, false)
	
	XerathMenu:addSubMenu("["..myHero.charName.." - Misc Settings]", "misc")
		XerathMenu.misc:addParam("aMP", "Auto Mana Pots", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.misc:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
		XerathMenu.misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
		
	TargetSelector = TargetSelector(TARGET_LESS_CAST, wRange, DAMAGE_MAGIC)
	TargetSelector.name = "Xerath"
	XerathMenu:addTS(TargetSelector)
end

-- Our Full Combo --
function FullCombo()
	if XerathMenu.combo.comboOrbwalk then
		if Target ~= nil then
			OrbWalking(Target)
		else
			moveToCursor()
		end
	end
	if ValidTarget(Target) then
		if GetDistance(Target) > eRange and not wActive then
			if wReady and GetDistance(Target) <= 950 and (qReady or eReady or rReady) then CastSpell(_W) end
		end
		if GetDistance(Target) <= eRange then
			if eReady and GetDistance(Target) <= eRange then CastE(Target) end
			if qReady and GetDistance(Target) <= qRange and HasBolt then CastQ(Target) end
		end
		if wActive and GetDistance(Target) > eRange then
			if QREADY and GetDistance(Target) <= qRange and Menu.useQ then CastQ(Target) end
		end
		if GetDistance(Target) <= qRange and qReady and not eReady then CastQ(Target) end
		if XerathMenu.combo.comboUlt then
			if GetDistance(Target) <= rRange and (HasBolt or not eReady) then CastR(Target) end
		end
	end
end

function HarassCombo()
	if XerathMenu.harass.harassOrbwalk then
		if Target ~= nil then
			OrbWalking(Target)
		else
			moveToCursor()
		end
	end
	if Target ~= nil then
		if qReady and GetDistance(Target) <= qRange then CastQ(Target) end
	end
end

-- Farming Function --
function FarmMinions()
	if not myManaLow() then
		for _, minion in pairs(enemyMinions.objects) do
			local qMinionDmg = getDmg("Q", minion, myHero)
			if ValidTarget(minion) then
				if XerathMenu.farming.qFarm and qReady and GetDistance(minion) <= qRange and minion.health <= qMinionDmg then
					CastSpell(_Q, minion.x, minion.z)
				end
			end
		end
	end
end

-- Farming Mana Function --
function myManaLow()
	if myHero.mana < (myHero.maxMana * (XerathMenu.farming.qFarmMana / 100)) then
		return true
	else
		return false
	end
end

-- Jungle Farming --
function JungleClear()
	JungleMob = GetJungleMob()
	if XerathMenu.jungle.jungleOrbwalk then
		if JungleMob ~= nil then
			OrbWalking(JungleMob)
		else
			moveToCursor()
		end
	end
	if JungleMob ~= nil then
		if XerathMenu.jungle.jungleQ and GetDistance(JungleMob) <= qRange then CastSpell(_Q, JungleMob.x, JungleMob.z) end
		if XerathMenu.jungle.jungleE and GetDistance(JungleMob) <= eRange then CastSpell(_E, JungleMob) end
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

function wManagement()
	if wActive then
		if InDanger() then CastSpell(_W) end
		qRange, eRange, rRange = 1750, 950, 1600
		if not wManual then
			if not Target then CastSpell(_W) end
			if not (QREADY or EREADY or RREADY) and rUsed >= 3
				 then CastSpell(_W)
			 end
		end
	else
		qRange,eRange,rRange = 1100, 650, 1100
	end
end

-- Casting Q into Enemies --
function CastQ(enemy)
	if not enemy then 
		enemy = Target 
	end
	if ValidTarget(enemy) then
		if VIP_USER then
			if qPos ~= nil then
				CastSpell(_Q, qPos.x, qPos.z)
			end
		else
			CastSpell(_Q, enemy.x, enemy.z)
		end
	end
end

-- Casting E into enemies --
function CastE(enemy)
	if not enemy then
		enemy = Target
	end
	if ValidTarget(enemy) then
		if VIP_USER then
			Packet("S_CAST", {spellId = _E, targetNetworkId = enemy.networkID}):send()
		else
			CastSpell(_E, enemy)
		end
	end
end

function CastR(enemy)
	if not enemy then
		enemy = Target
	end
	if ValidTarget(enemy) then
		if rReady and rUsed < 3 then
			if VIP_USER then
				if rPos ~= nil then
					CastSpell(_R, rPos.x, rPos.z)
				end
			else
				CastSpell(_R, enemy.x, enemy.z)
			end
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
		if eReady and GetDistance(Target) <= eRange and Target.health <= eDmg then
			CastE(Target)
		elseif qReady and GetDistance(Target) <= qRange and Target.health <= qDmg then
			CastQ(Target)
		elseif qReady and eReady and Target.health <= (qDmg + eDmg) then
			if wReady and not wActive then
				if GetDistance(Target) > eRange and GetDistance(Target) < 950 then
					CastSpell(_W)
					CastE(Target)
				end
			else
				if GetDistance(Target) <= eRange then CastE(Target) end
			end
		elseif rReady and Target.health <= rDmg and GetDistance(Target) <= rRange then
			CastR(Target)
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
		if XerathMenu.misc.aHP and myHero.health < (myHero.maxHealth * (XerathMenu.misc.HPHealth / 100))
			and not (usingHPot or usingFlask) and (hpReady or fskReady)	then
				CastSpell((hpSlot or fskSlot)) 
		end
		if XerathMenu.misc.aMP and myHero.mana < (myHero.maxMana * (XerathMenu.farming.qFarmMana / 100))
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
			aDmg = getDmg("AD", enemy, myHero)
			pDmg = getDmg("P", enemy, myHero)
			qDmg = (qReady and getDmg("Q",enemy,myHero)) or 0
            eDmg = (eReady and getDmg("E",enemy,myHero)) or 0
            if rUsed == 0 then
				rDmg = (rReady and (getDmg("R",enemy,myHero)*3)) or 0
			elseif rUsed == 1 then
				rDmg = (rReady and (getDmg("R",enemy,myHero)*2)) or 0
			elseif rUsed == 2 then
				rDmg = (rReady and getDmg("R",enemy,myHero)) or 0
			end
			if dfgReady then dfgDmg = (dfgSlot and getDmg("DFG",enemy,myHero) or 0)	end
            if hxgReady then hxgDmg = (hxgSlot and getDmg("HXG",enemy,myHero) or 0) end
            if bwcReady then bwcDmg = (bwcSlot and getDmg("BWC",enemy,myHero) or 0) end
            if iReady then iDmg = (ignite and getDmg("IGNITE",enemy,myHero) or 0) end
            onspellDmg = (liandrysSlot and getDmg("LIANDRYS",enemy,myHero) or 0)+(blackfireSlot and getDmg("BLACKFIRE",enemy,myHero) or 0)
            itemsDmg = dfgDmg + hxgDmg + bwcDmg + iDmg + onspellDmg
				KillText[i] = 1 
			if enemy.health <= (qDmg + eDmg + itemsDmg) then
				KillText[i] = 2
			elseif enemy.health <= (qDmg + eDmg + rDmg + itemsDmg) then
				KillText[i] = 3
			end
		end
	end
end

function InDanger()
	if (CountEnemyHeroInRange(DangerRange) == 1) and myHero.health > (myHero.maxHealth * (XerathMenu.misc.HPHealth / 100)) then
		return false
	elseif (CountEnemyHeroInRange(DangerRange) == 1) and myHero.health < (myHero.maxHealth * (XerathMenu.misc.HPHealth / 100)) then
		return true
	elseif (CountEnemyHeroInRange(DangerRange) > 1) then
		return true
	else
		return false
	end
end

-- Object Handling Functions --
function OnCreateObj(obj)
	if obj ~= nil then
		if obj.name:find("Xerath_LocusOfPower_beam.troy") or obj.name:find("Xerath_LocusOfPower_buf.troy") then
			if GetDistance(obj, myHero) <= 70 then
				wActive = true
			end
		end
		if obj.name:find("Xerath_Bolt_hit_tar.troy") and Target and GetDistance(Target, obj) <= 70 then
			HasBolt = true
			BoltTime = GetTickCount()
		end
		if obj.name:find("Xerath_E_cas_green.troy") then
			if GetDistance(obj, myHero) <= 70 then
				rUsed = rUsed + 1
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
		if obj.name:find("Xerath_LocusOfPower_beam.troy") then
			wActive = false
		end
		if obj.name:find("Xerath_Bolt_hit_tar.troy") then
			HasBolt = false
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

function PluginOnWndMsg(msg,key)
	if key == 87 then wManual = true end
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
	if not XerathMenu.drawing.mDraw and not myHero.dead then
		if qReady and XerathMenu.drawing.qDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x0000FF)
		end
		if eReady and XerathMenu.drawing.rDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, rRange, 0x0000FF)
		end
	end
	if XerathMenu.drawing.cDraw then
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
	
	-- Manual Reset for Bolt --
	if GetTickCount() - BoltTime > 3000 then HasBolt = false end
	if rUsed >= 3 then rUsed = 0 end

	-- Updates Minions --
	enemyMinions:update()
	if VIP_USER then
		if ValidTarget(Target) then
			qPos = ProdictQ:GetPrediction(Target)
			rPos = ProdictR:GetPrediction(Target)
		end
	end
end