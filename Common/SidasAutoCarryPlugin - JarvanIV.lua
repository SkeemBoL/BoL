--[[
	AutoCarry Plugin - Jarvan IV the Exemplar of Demacia 1.1 by Skeem

	Changelog :
   1.0 - Initial Release
   1.1 - Fixed ult Canceling
	   - Fixed Knocked Up Ratio
	   - Fixed Auto Pots
 ]] --

if myHero.charName ~= "JarvanIV" then return end

--[Function When Plugin Loads]--
function PluginOnLoad()
	mainLoad() -- Loads our Variable Function
	mainMenu() -- Loads our Menu function
end

--[OnTick]--
function PluginOnTick()
	if Recall then return end
	if IsSACReborn then
		AutoCarry.Crosshair:SetSkillCrosshairRange(850)
	else
		AutoCarry.SkillsCrosshair.range = 850
	end
	Checks()
	SmartKS()
	
	if Carry.AutoCarry then FullCombo() end
	if Carry.MixedMode and Target then 
		if Menu.qHarass and not IsMyManaLow() and GetDistance(Target) <= qRange then CastQ(Target) end
	end
	if Menu.eqRun then EQToMouse() end
	if Carry.LaneClear then JungleClear() end
	
	if Extras.ZWItems and IsMyHealthLow() and Target and (ZNAREADY or WGTREADY) then CastSpell((wgtSlot or znaSlot)) end
	if Extras.aHP and NeedHP() and not (UsingHPot or UsingFlask) and (HPREADY or FSKREADY) then CastSpell((hpSlot or fskSlot)) end
	if Extras.aMP and IsMyManaLow() and not (UsingMPot or UsingFlask) and(MPREADY or FSKREADY) then CastSpell((mpSlot or fskSlot)) end
	if Extras.AutoLevelSkills then autoLevelSetSequence(levelSequence) end
end

--[Drawing our Range/Killable Enemies]--
function PluginOnDraw()
	if not myHero.dead then
		if EREADY and Menu.eDraw then 
			DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0x191970)
		end
		if Menu.cDraw then
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
end

--[Casting our Q into Enemies]--
function CastQ(Target)
	if Menu.KnockUp then EnemysInFlag() end
    if QREADY then 
		AutoCarry.CastSkillshot(SkillQ, Target)
    end
end

--[Casting our E into Enemies]--
function CastE(Target)
    if EREADY then 
		AutoCarry.CastSkillshot(SkillE, Target)
    end
end


function EQToMouse()
	if EREADY and QREADY then
	MousePos = Vector(mousePos.x, mousePos.y, mousePos.z)
	CastSpell(_E, MousePos.x, MousePos.z)
	CastSpell(_Q, MousePos.x, MousePos.z)
	end
end

function EnemysInFlag()
	if Flag and Target then
		if GetDistance(Flag, Target) <= 180 then
			Target = Flag
		end
	end
end

--[Object Detection]--
function PluginOnCreateObj(obj)
	if obj.name:find("JarvanCataclysm_tar.troy") then
		UltToggled = true
	end
	if obj.name:find("TeleportHome.troy") then
		if GetDistance(obj, myHero) <= 70 then
			Recall = true
		end
	end
	if obj.name:find("JarvanDemacianStandard_mis.troy") then
		Flag = obj
	end
	if obj.name:find("Global_Item_HealthPotion.troy") then
		if GetDistance(obj, myHero) <= 70 then
			UsingHPot = true
			UsingFlask = true
		end
	end
	if obj.name:find("Global_Item_ManaPotion.troy") then
		if GetDistance(obj, myHero) <= 70 then
			UsingFlask = true
			UsingMPot = true
		end
	end
end

function PluginOnDeleteObj(obj)
	if obj.name:find("TeleportHome.troy") then
		Recall = false
	end
	if obj.name:find("JarvanDemacianStandard_mis.troy") then
		Flag = nil
	end
	if obj.name:find("JarvanCataclysm_tar.troy") then
		UltToggled = false
	end
	if obj.name:find("Global_Item_HealthPotion.troy") then
		UsingHPot = false
		UsingFlask = false
	end
	if obj.name:find("Global_Item_ManaPotion.troy") then
		UsingMPot = false
		UsingFlask = false
	end
end

--[Low Mana Function by Kain]--
function IsMyManaLow()
    if myHero.mana < (myHero.maxMana * ( Extras.MinMana / 100)) then
        return true
    else
        return false
    end
end

--[/Low Mana Function by Kain]--

--[Low Health Function Trololz]--
function IsMyHealthLow()
	if myHero.health < (myHero.maxHealth * ( Extras.ZWHealth / 100)) then
		return true
	else
		return false
	end
end
--[/Low Health Function Trololz]--

--[Health Pots Function]--
function NeedHP()
	if myHero.health < (myHero.maxHealth * ( Extras.HPHealth / 100)) then
		return true
	else
		return false
	end
end

--[Smart KS Function]--
function SmartKS()
	 for i=1, heroManager.iCount do
	 local enemy = heroManager:GetHero(i)
		if ValidTarget(enemy) then
			dfgDmg, hxgDmg, bwcDmg, iDmg  = 0, 0, 0, 0
			qDmg = getDmg("Q",enemy,myHero)
            eDmg = getDmg("E",enemy,myHero)
			rDmg = getDmg("R",enemy,myHero)
			if DFGREADY then dfgDmg = (dfgSlot and getDmg("DFG",enemy,myHero) or 0)	end
            if HXGREADY then hxgDmg = (hxgSlot and getDmg("HXG",enemy,myHero) or 0) end
            if BWCREADY then bwcDmg = (bwcSlot and getDmg("BWC",enemy,myHero) or 0) end
            if IREADY then iDmg = (ignite and getDmg("IGNITE",enemy,myHero) or 0) end
            onspellDmg = (liandrysSlot and getDmg("LIANDRYS",enemy,myHero) or 0)+(blackfireSlot and getDmg("BLACKFIRE",enemy,myHero) or 0)
            itemsDmg = dfgDmg + hxgDmg + bwcDmg + iDmg + onspellDmg
			if Menu.sKS then
				if enemy.health <= (qDmg) and GetDistance(enemy) <= qRange and QREADY then
					if QREADY then CastQ(enemy) end
				
				elseif enemy.health <= (eDmg) and GetDistance(enemy) <= eRange and EREADY then
					if EREADY then CastE(enemy) end
				
				elseif enemy.health <= (qDmg + eDmg) and GetDistance(enemy) <= eRange and EREADY and QREADY then
					if EREADY then CastE(enemy) end
					if QREADY then CastQ(enemy) end
									
				elseif enemy.health <= (qDmg + itemsDmg) and GetDistance(enemy) <= qRange and QREADY then
					if DFGREADY then CastSpell(dfgSlot, enemy) end
					if HXGREADY then CastSpell(hxgSlot, enemy) end
					if BWCREADY then CastSpell(bwcSlot, enemy) end
					if BRKREADY then CastSpell(brkSlot, enemy) end
					if QREADY then CastQ(enemy) end
				
				elseif enemy.health <= (eDmg + itemsDmg) and GetDistance(enemy) <= eRange and EREADY then
					if DFGREADY then CastSpell(dfgSlot, enemy) end
					if HXGREADY then CastSpell(hxgSlot, enemy) end
					if BWCREADY then CastSpell(bwcSlot, enemy) end
					if BRKREADY then CastSpell(brkSlot, enemy) end
					if EREADY then CastE(enemy) end
				
				elseif enemy.health <= (qDmg + eDmg + itemsDmg) and GetDistance(enemy) <= eRange
					and EREADY and QREADY then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if EREADY then CastE(enemy) end
						if QREADY then CastQ(enemy) end
				
				elseif enemy.health <= (qDmg + eDmg + rDmg + itemsDmg) and GetDistance(enemy) <= qRange
					and QREADY and EREADY and WREADY and RREADY and enemy.health > (qDmg + eDmg) then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if EREADY and GetDistance(enemy) <= eRange then CastE(enemy) end
						if QREADY and GetDistance(enemy) <= qRange then CastQ(enemy) end
						if RREADY and GetDistance(enemy) <= rRange then CastSpell(_R, enemy) end						
				
				elseif enemy.health <= (rDmg + itemsDmg) and GetDistance(enemy) <= rRange
					and not QREADY and not EREADY and RREADY then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if RREADY then CastSpell(_R, enemy) end
				
				end
								
				if enemy.health <= iDmg and GetDistance(enemy) <= 600 then
					if IREADY then CastSpell(ignite, enemy) end
				end
			end
			KillText[i] = 1 
			if enemy.health <= (qDmg + eDmg + itemsDmg) and QREADY and EREADY then
			KillText[i] = 2
			end
			if enemy.health <= (qDmg + eDmg + rDmg + itemsDmg) and QREADY and EREADY and RREADY then
			KillText[i] = 3
			end
		end
	end
end

--[Full Combo with Items]--
function FullCombo()
	if Target then
		if AutoCarry.MainMenu.AutoCarry then
			if GetDistance(Target) <= eRange then CastE(Target) end
			if GetDistance(Target) <= qRange and not EREADY then CastQ(Target) end
			if GetDistance(Target) <= wRange then CastSpell(_W) end
			if Menu.rKill then
				if Target.health <= rDmg and GetDistance(Target) <= rRange and not UltToggled then CastSpell(_R, Target) end
			else
				if GetDistance(Target) <= rRange and not UltToggled then CastSpell(_R, Target) end
			end
		end
	end
end

function JungleClear()
	if IsSACReborn then
		JungleMob = AutoCarry.Jungle:GetAttackableMonster()
	else
		JungleMob = AutoCarry.GetMinionTarget()
	end
	if JungleMob and not IsMyManaLow() then
		if Extras.JungleQ and GetDistance(JungleMob) <= qRange then CastQ(JungleMob) end
		if Extras.JungleE and GetDistance(JungleMob) <= eRange then CastE(JungleMob) end
	end
end

--[Variables Load]--
function mainLoad()
	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
	if IsSACReborn then AutoCarry.Skills:DisableAll() end
	Carry = AutoCarry.MainMenu
	qRange,wRange,eRange,rRange = 800, 300, 850, 650
	qDelay, eDelay = 200, 200
	Flag, UltToggled = nil, false
	qName, wName, eName = "Dragon Strike", "Golden Aegis", "Demacian Standard"
	qSpeed, eSpeed = .2, 1.4
	qWidth, eWidth = 70, 450
	QREADY, WREADY, EREADY, RREADY = false, false, false, false
	HK1, HK2, HK3 = string.byte("Z"), string.byte("K"), string.byte("G")
	Menu = AutoCarry.PluginMenu
	UsingHPot, UsingMPot, UsingFlask = false, false, false
	Recall = false, false, false
	TextList = {"Harass him!!", "Q+E KILL!!", "FULL COMBO KILL!"}
	KillText = {}
	waittxt = {} -- prevents UI lags, all credits to Dekaron
	for i=1, heroManager.iCount do waittxt[i] = i*3 end -- All credits to Dekaron
	levelSequence = { nil, 0, 1, 2, 1, 4, 1, 3, 1, 3, 4, 3, 3, 2, 2, 4, 2, 2, }
	-- This was Copy + Paste from Kain :P
	SkillQ = {spellKey = _Q, range = qRange, speed = qSpeed, delay = qDelay, width = qWidth, configName = qName, displayName = "Q "..qName.."", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
	SkillE = {spellKey = _E, range = rRange, speed = eSpeed, delay = eDelay, width = eWidth, configName = eName, displayName = "E "..eName.."", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
end

--[Main Menu & Extras Menu]--
function mainMenu()
	Menu:addParam("sep1", "-- Full Combo Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("useQ", "Use "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useW", "Use "..wName.." (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useE", "Use "..eName.." (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("KnockUp", "Always Try to Knock UP", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("rKill","Only Use R if enemy can die", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("eqRun", "E + Q To Mouse", SCRIPT_PARAM_ONKEYDOWN, false, HK3)
	Menu:addParam("sep2", "-- Mixed Mode Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("qHarass", "Use "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sep3", "-- KS Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("sKS", "Use Smart Combo KS", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sep5", "-- Draw Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("eDraw", "Draw "..eName.." (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("cDraw", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
	Extras = scriptConfig("Sida's Auto Carry Plugin: "..myHero.charName..": Extras", myHero.charName)
	Extras:addParam("sep6", "-- Misc --", SCRIPT_PARAM_INFO, "")
	Extras:addParam("JungleQ", "Jungle with "..qName.." (Q)", SCRIPT_PARAM_ONOFF, true)
	Extras:addParam("JungleE", "Jungle with "..eName.." (E)", SCRIPT_PARAM_ONOFF, true)
	Extras:addParam("MinMana", "Minimum Mana for Jungle/Harass %", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
	Extras:addParam("ZWItems", "Auto Zhonyas/Wooglets", SCRIPT_PARAM_ONOFF, true)
	Extras:addParam("ZWHealth", "Min Health % for Zhonyas/Wooglets", SCRIPT_PARAM_SLICE, 15, 0, 100, -1)
	Extras:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
	Extras:addParam("aMP", "Auto Auto Mana Pots", SCRIPT_PARAM_ONOFF, true)
	Extras:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
	Extras:addParam("AutoLevelSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_ONOFF, true)
end

--[Certain Checks]--
function Checks()
	if myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") then ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") then ignite = SUMMONER_2 end
	if IsSACReborn then Target = AutoCarry.Crosshair:GetTarget() else Target = AutoCarry.GetAttackTarget() end
	dfgSlot, hxgSlot, bwcSlot = GetInventorySlotItem(3128), GetInventorySlotItem(3146), GetInventorySlotItem(3144)
	brkSlot = GetInventorySlotItem(3092),GetInventorySlotItem(3143),GetInventorySlotItem(3153)
	znaSlot, wgtSlot = GetInventorySlotItem(3157),GetInventorySlotItem(3090)
	hpSlot, mpSlot, fskSlot = GetInventorySlotItem(2003),GetInventorySlotItem(2004),GetInventorySlotItem(2041)
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	DFGREADY = (dfgSlot ~= nil and myHero:CanUseSpell(dfgSlot) == READY)
	HXGREADY = (hxgSlot ~= nil and myHero:CanUseSpell(hxgSlot) == READY)
	BWCREADY = (bwcSlot ~= nil and myHero:CanUseSpell(bwcSlot) == READY)
	BRKREADY = (brkSlot ~= nil and myHero:CanUseSpell(brkSlot) == READY)
	ZNAREADY = (znaSlot ~= nil and myHero:CanUseSpell(znaSlot) == READY)
	WGTREADY = (wgtSlot ~= nil and myHero:CanUseSpell(wgtSlot) == READY)
	IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	HPREADY = (hpSlot ~= nil and myHero:CanUseSpell(hpSlot) == READY)
	MPREADY =(mpSlot ~= nil and myHero:CanUseSpell(mpSlot) == READY)
	FSKREADY = (fskSlot ~= nil and myHero:CanUseSpell(fskSlot) == READY)
end
