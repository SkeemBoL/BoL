--[[
	[Script] Aatrox - The Darkin Blade 1.1.1 by Skeem
	
		Features:
			- Prodiction for VIPs, NonVIP prediction
			- Full Combo:
				- Full E + Q + R Combo
				- Uses smart W with menu toggle
				- Items toggle in combo menu
				- Orbwalking Toggle in combo menu
			- Harass Settings:
				- Uses E+Q Combo to harass
				- Toggle to use Q in harass (Off by default)
				- Orbwalking toggle for harass in menu
			- Farming Settings:
				- Toggle to farm with E in menu (Off by default)
			- Jungle Clear Settings:
				- Toggle to use Q to clear jungle
				- Toggle to use E to clear jungle
				- Toggle to orbwalk the jungle minions
			- KillSteal Settings:
				- Smart KillSteal with Overkill Check:
					- Checks for enemy health < Q, E, QE
				- Toggle for Auto Ignite
			- Drawing Settings:
				- Toggle to draw if enemy is killable
				- Toggle to draw Q Range if available
				- Toggle to draw E Range if available (Off by default)
			- Misc Settings:
				- Q to Mouse for panicking moments
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
			1.0   - First Release!
			1.1   - Updated Everything!! no longer autocarry script
			1.1.1 - Added item usage
	
	]]--

-- Name Check --  
if myHero.charName ~= "Aatrox" then return end

if VIP_USER then 
	require "Prodiction" 
	require "Collision"
end

-- Loading Function --
function OnLoad()
	Variables()
	AatroxMenu()
	PrintChat("<font color='#0000FF'> >> Aatrox - The Darkin Blade 1.1.1 Loaded!! <<</font>")
end

-- OnTick function --
function OnTick()
	Checks()
	wCheck()
	UseConsumables()
	DamageCalculation()

	-- Menu Vars --
	ComboKey =   AatroxMenu.combo.comboKey
	FarmingKey = AatroxMenu.farming.farmKey
	HarassKey =  AatroxMenu.harass.harassKey
	JungleKey =  AatroxMenu.jungle.jungleKey
	
	if ComboKey then FullCombo() end
	if HarassKey then HarassCombo() end
	if JungleKey then JungleClear() end
	if AatroxMenu.ks.killSteal then KillSteal() end
	if AatroxMenu.ks.autoIgnite then AutoIgnite() end
	if FarmingKey and not (ComboKey or HarassKey) then FarmMinions() end
end

-- Our Variables --
function Variables()
	qRange, eRange, rRange = 650, 1000, 300
	qName, wName, eName, rName = "Dark Flight", "Blood Thirst", "Blades of Torment", "Massacre"
	qReady, wReady, eReady, rReady = false, false, false, false
	if VIP_USER then
		qSpeed, qDelay, qWidth = 1800, .270, 280
		eSpeed, eDelay, eWidth = 1200, .270, 80
		qPos, ePos = nil, nil
		Prodict = ProdictManager.GetInstance()
		ProdictQ = Prodict:AddProdictionObject(_Q, qRange, qSpeed, qDelay, qWidth, myHero)
		ProdictE = Prodict:AddProdictionObject(_E, eRange, eSpeed, eDelay, eWidth, myHero)
	end
	hpReady, fskReady, Recalling = false, false, false
	TextList = {"Harass him!!", "Q+W+E KILL!!"}
	KillText = {}
	waittxt = {} -- prevents UI lags, all credits to Dekaron
	usingHPot, usingUlt, rManual = false, false, false
	for i=1, heroManager.iCount do waittxt[i] = i*3 end
	enemyMinions = minionManager(MINION_ENEMY, eRange, player, MINION_SORT_HEALTH_ASC)
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
function AatroxMenu()
	AatroxMenu = scriptConfig("Aatrox - The Darkin Blade", "Aatrox")
	
	AatroxMenu:addSubMenu("["..myHero.charName.." - Combo Settings]", "combo")
		AatroxMenu.combo:addParam("comboKey", "Full Combo Key (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
		AatroxMenu.combo:addParam("comboItems", "Use Items with Burst", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.combo:addParam("comboW", "Use "..wName.." (W)", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.combo:addParam("comboWHealth", "Minimum Health Heal W", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
		AatroxMenu.combo:addParam("comboR", "Use "..rName.." (R)", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.combo:addParam("comboRHealth", "Minimum Enemy Health to R", SCRIPT_PARAM_SLICE, 60, 0, 100, -1)
		AatroxMenu.combo:addParam("comboOrbwalk", "OrbWalk on Combo", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.combo:permaShow("comboKey") 
	
	AatroxMenu:addSubMenu("["..myHero.charName.." - Harass Settings]", "harass")
		AatroxMenu.harass:addParam("harassKey", "Harass Hotkey (C)", SCRIPT_PARAM_ONKEYDOWN, false, 67)
		AatroxMenu.harass:addParam("harassQ", "Use "..qName.." (Q)", SCRIPT_PARAM_ONOFF, false)
		AatroxMenu.harass:addParam("harassOrbwalk", "OrbWalk on Harass", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.harass:permaShow("harassKey") 
		
	
	AatroxMenu:addSubMenu("["..myHero.charName.." - Farming Settings]", "farming")
		AatroxMenu.farming:addParam("farmKey", "Farming ON/Off (Z)", SCRIPT_PARAM_ONKEYTOGGLE, false, 90)
		AatroxMenu.farming:addParam("eFarm", "Farm with "..eName.." (E)", SCRIPT_PARAM_ONOFF, false)
		AatroxMenu.farming:permaShow("farmKey") 
		
	AatroxMenu:addSubMenu("["..myHero.charName.." - Clear Settings]", "jungle")
		AatroxMenu.jungle:addParam("jungleKey", "Jungle Clear Key (V)", SCRIPT_PARAM_ONKEYDOWN, false, 86)
		AatroxMenu.jungle:addParam("jungleQ", "Clear with "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.jungle:addParam("jungleE", "Clear with "..eName.." (E)", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.jungle:addParam("jungleOrbwalk", "Orbwalk the Jungle", SCRIPT_PARAM_ONOFF, true)
		
		
	AatroxMenu:addSubMenu("["..myHero.charName.." - KillSteal Settings]", "ks")
		AatroxMenu.ks:addParam("killSteal", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.ks:addParam("autoIgnite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.ks:permaShow("killSteal") 
			
	AatroxMenu:addSubMenu("["..myHero.charName.." - Drawing Settings]", "drawing")	
		AatroxMenu.drawing:addParam("mDraw", "Disable All Ranges Drawing", SCRIPT_PARAM_ONOFF, false)
		AatroxMenu.drawing:addParam("cDraw", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.drawing:addParam("qDraw", "Draw "..qName.." (Q) Range", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.drawing:addParam("eDraw", "Draw "..eName.." (E) Range", SCRIPT_PARAM_ONOFF, false)
	
	AatroxMenu:addSubMenu("["..myHero.charName.." - Misc Settings]", "misc")
		AatroxMenu.misc:addParam("qRun", "Q To Mouse (G)", SCRIPT_PARAM_ONKEYDOWN, false, 71)
		AatroxMenu.misc:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
		AatroxMenu.misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
		AatroxMenu.misc:permaShow("qRun")
		
	TargetSelector = TargetSelector(TARGET_LOW_HP, eRange,DAMAGE_MAGIC)
	TargetSelector.name = "Aatrox"
	AatroxMenu:addTS(TargetSelector)
end

-- Our Full Combo Function --
function FullCombo()
	if AatroxMenu.combo.comboOrbwalk then
		if Target ~= nil then
			OrbWalking(Target)
		else
			moveToCursor()
		end
	end
	if Target ~= nil then
		if AatroxMenu.combo.comboItems then
			UseItems(Target)
		end
		if AatroxMenu.combo.comboW then
			if not wActive() and wReady and myHero.health > (myHero.maxHealth * ( AatroxMenu.combo.comboWHealth / 100)) then
				CastSpell(_W)
			end
			if wActive() and wReady and myHero.health < (myHero.maxHealth * ( AatroxMenu.combo.comboWHealth / 100)) then
				CastSpell(_W)
			end
		end
		if AatroxMenu.combo.comboR then
			if rReady and GetDistance(Target) <= rRange and Target.health  < (myHero.maxHealth * ( AatroxMenu.combo.comboRHealth / 100)) then
				CastSpell(_R)
			end
		end
		if eReady and GetDistance(Target) <= eRange then CastE(Target) end
		if qReady and GetDistance(Target) <= qRange then CastQ(Target) end
	end
end

-- Harrass Combo Function --
function HarassCombo()
	if AatroxMenu.harass.harassOrbwalk then
		if Target ~= nil then
			OrbWalking(Target)
		else
			moveToCursor()
		end
	end
	if Target ~= nil then
		if eReady and GetDistance(Target) <= eRange then CastE(Target) end
		if AatroxMenu.harass.harassQ and qReady and GetDistance(Target) <= qRange then CastQ(Target) end
	end
end

-- Farming Function --
function FarmMinions()
	for _, minion in pairs(enemyMinions.objects) do
		local eMinionDmg = getDmg("E", minion, myHero)
		if ValidTarget(minion) then
			if AatroxMenu.farming.eFarm and eReady and GetDistance(minion) <= eRange and minion.health <= eMinionDmg then
					CastSpell(_E, minion.x, minion.z)
			end
		end
	end
end

-- Jungle Farming --
function JungleClear()
	JungleMob = GetJungleMob()
	if AatroxMenu.jungle.jungleOrbwalk then
		if JungleMob ~= nil then
			OrbWalking(JungleMob)
		else
			moveToCursor()
		end
	end
	if JungleMob ~= nil then
		if AatroxMenu.jungle.jungleQ and GetDistance(JungleMob) <= qRange then CastSpell(_Q, JungleMob.x, JungleMob.z) end
		if AatroxMenu.jungle.jungleE and GetDistance(JungleMob) <= eRange then CastSpell(_E, JungleMob.x, JungleMob.z) end
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

-- Casting W into Enemies --
function CastQ(enemy)
	if not enemy then 
		enemy = Target 
	end
	if Target ~= nil then
		if VIP_USER then
			if qPos ~= nil then
				CastSpell(_Q, qPos.x, qPos.z)
			end
		else
			CastSpell(_Q, enemy.x, enemy.z)
		end
	end
end

function CastE(enemy)
	if not enemy then
		enemy = Target
	end
	if Target ~= nil then
		if VIP_USER then
			if ePos ~= nil then
				CastSpell(_E, ePos.x, ePos.z)
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
	if Target ~= nil then
		if hxgReady and GetDistance(enemy) <= 600 then CastSpell(hxgSlot, enemy) end
		if bwcReady and GetDistance(enemy) <= 450 then CastSpell(bwcSlot, enemy) end
		if brkReady and GetDistance(enemy) <= 450 then CastSpell(brkSlot, enemy) end
		if tmtReady and GetDistance(enemy) <= 185 then CastSpell(tmtSlot) end
		if hdrReady and GetDistance(enemy) <= 185 then CastSpell(hdrSlot) end
	end
end

-- KillSteal function --
function KillSteal()
	if Target ~= nil then
		if qReady and Target.health <= qDmg and GetDistance(Target) <= qRange then 
			CastQ(Target)
		elseif eReady and Target.health <= eDmg and GetDistance(Target) <= eRange then
			CastE(Target)
		elseif qReady and eReady and Target.health <= (qDmg + eDmg) and GetDistance(Target) <= eRange then
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
		if AatroxMenu.misc.aHP and myHero.health < (myHero.maxHealth * (AatroxMenu.misc.HPHealth / 100))
			and not (usingHPot or usingFlask) and (hpReady or fskReady)	then
				CastSpell((hpSlot or fskSlot)) 
		end
	end
end		

-- Damage Calculations --
function DamageCalculation()
	for i=1, heroManager.iCount do
	local enemy = heroManager:GetHero(i)
		if ValidTarget(enemy) then
			dfgDmg, hxgDmg, bwcDmg, iDmg  = 0, 0, 0, 0
			qDmg, eDmg = 0, 0
			if qReady then qDmg = getDmg("Q",enemy,myHero) end
			if eReady then eDmg = getDmg("E",enemy,myHero) end
			if dfgReady then dfgDmg = (dfgSlot and getDmg("DFG",enemy,myHero) or 0)	end
            if hxgReady then hxgDmg = (hxgSlot and getDmg("HXG",enemy,myHero) or 0) end
            if bwcReady then bwcDmg = (bwcSlot and getDmg("BWC",enemy,myHero) or 0) end
            if iReady then iDmg = (ignite and getDmg("IGNITE",enemy,myHero) or 0) end
            onspellDmg = (liandrysSlot and getDmg("LIANDRYS",enemy,myHero) or 0)+(blackfireSlot and getDmg("BLACKFIRE",enemy,myHero) or 0)
            itemsDmg = dfgDmg + hxgDmg + bwcDmg + iDmg + onspellDmg
			
				KillText[i] = 1 
			if enemy.health <= (qDmg + eDmg + itemsDmg) then
				KillText[i] = 2
			end
		end
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

-- W Functions --
function wActive()
	if myHero:GetSpellData(_W).name == "aatroxw2" then
		return true
	else
		return fase
	end
end

function wCheck()
	if wActive() and wReady and myHero.health < (myHero.maxHealth * ( AatroxMenu.combo.comboWHealth / 100)) then
		CastSpell(_W)
	end
end

-- Function OnDraw --
function OnDraw()
	--> Ranges
	if not AatroxMenu.drawing.mDraw and not myHero.dead then
		if qReady and AatroxMenu.drawing.qDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x0000FF)
		end
		if eReady and AatroxMenu.drawing.eDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0x0000FF)
		end
	end
	if AatroxMenu.drawing.cDraw then
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
	if myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") then
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") then
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
			qPos = ProdictQ:GetPrediction(Target)
			ePos = ProdictE:GetPrediction(Target)
		end
	end
end
