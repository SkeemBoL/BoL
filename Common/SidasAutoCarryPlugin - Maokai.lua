--[[
	AutoCarry Plugin - Maokai the Twisted Treant 0.1 by Skeem
	With Code from Kain
	Copyright 2013
	Changelog :
   1.0 - Initial Release
 ]] --

if myHero.charName ~= "Maokai" then return end

--[Function When Plugin Loads]--
function PluginOnLoad()
	mainLoad() -- Loads our Variable Function
	mainMenu() -- Loads our Menu function
end

--[OnTick]--
function PluginOnTick()
	if Recall then return end
	if IsSACReborn then
		AutoCarry.Crosshair:SetSkillCrosshairRange(1300)
	else
		AutoCarry.SkillsCrosshair.range = 1300
	end
	Checks()
	SmartKS()
	
	if Carry.AutoCarry then FullCombo() end
	if Carry.MixedMode and Target then 
		if Menu.qHarass and not IsMyManaLow() and GetDistance(Target) <= qRange then CastQ(Target) end
		if Menu.eHarass and not IsMyManaLow() and GetDistance(Target) <= eRange then CastE(Target) end
	end
	
	if Extras.ZWItems and IsMyHealthLow() and Target and (ZNAREADY or WGTREADY) then CastSpell((wgtSlot or znaSlot)) end
	if Extras.aHP and NeedHP() and not (UsingHPot or UsingFlask) and (HPREADY or FSKREADY) then CastSpell((hpSlot or fskSlot)) end
	if Extras.aMP and IsMyManaLow() and not (UsingMPot or UsingFlask) and(MPREADY or FSKREADY) then CastSpell((mpSlot or fskSlot)) end
	if Extras.AutoLevelSkills then autoLevelSetSequence(levelSequence) end
	
end

--[Drawing our Range/Killable Enemies]--
function PluginOnDraw()
	if not myHero.dead then
		if WREADY and Menu.wDraw then 
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x191970)
		end
		if EREADY and Menu.eDraw then 
			DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0x707019)
		end
		if Target and Menu.DrawTarget then
				DrawText("Targetting: " .. Target.charName, 15, 100, 100, 0xFFFF0000)
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

--[Casting our Q/E into Enemies]--
function CastQ(Target)
    if QREADY then 
        if IsSACReborn then
            SkillQ:Cast(Target)
        else
			AutoCarry.CastSkillshot(SkillQ, Target)
        end
    end
end

function CastE(Target)
	if EREADY then
		if IsSACReborn then
			SkillE:Cast(Target)
		else
			AutoCarry.CastSkillshot(SkillE, Target)
		end
	end
end

--[Function That Counts Enemies in Range]--
function CountEnemies(point, range)
        local ChampCount = 0
        for j = 1, heroManager.iCount, 1 do
                local enemyhero = heroManager:getHero(j)
                if myHero.team ~= enemyhero.team and ValidTarget(enemyhero, rRange) then
                        if GetDistance(enemyhero, point) <= range then
                                ChampCount = ChampCount + 1
                        end
                end
        end            
        return ChampCount
end

--[Casting our Ultimate with MEC]--
function CastR(Target)
    if RREADY then
		local ultPos = GetAoESpellPosition(550, Target)
		if ultPos and GetDistance(ultPos) <= rRange then
			if CountEnemies(ultPos, 550) > 1 then
				CastSpell(_R, ultPos.x, ultPos.z)
			elseif IsSACReborn then
				SkillR:Cast(Target)
			else
				AutoCarry.CastSkillshot(SkillR, Target)
			end
		end
	end
end

--[Object Detection for W, Recalling, E, R]--
function PluginOnCreateObj(obj)
	if obj.name:find("TeleportHome.troy") then
		if GetDistance(obj, myHero) <= 70 then
			Recall = true
		end
	end
	if obj.name:find("Regenerationpotion_itm.troy") then
		if GetDistance(obj, myHero) <= 70 then
			UsingHPot = true
		end
	end
	if obj.name:find("ManaPotion_itm.troy") then
		if GetDistance(obj, myHero) <= 70 then
			UsingMPot = true
		end
	end
	if obj.name:find("potion_manaheal") then
		if GetDistance(obj, myHero) <= 70 then
			UsingFlask = true
		end
	end
end

function PluginOnDeleteObj(obj)
	if obj.name:find("TeleportHome.troy") then
		Recall = false
	end
	if obj.name:find("Regenerationpotion_itm.troy") then
		UsingHPot = false
	end
	if obj.name:find("ManaPotion_itm.troy") then
		UsingMPot = false
	end
	if obj.name:find("potion_manaheal") then
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
			wDmg = getDmg("W",enemy,myHero)
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
				
				elseif enemy.health <= (wDmg) and GetDistance(enemy) <= wRange and WREADY then
					if WREADY then CastSpell(_W, enemy) end
					
				elseif enemy.health <= (qDmg + eDmg) and GetDistance(enemy) <= eRange and EREADY and QREADY then
					if QREADY then CastQ(enemy) end
					if EREADY then CastE(enemy) end
				
				elseif enemy.health <= (qDmg + wDmg) and GetDistance(enemy) <= wRange and WREADY and QREADY then
					if WREADY then CastSpell(_W, enemy) end
					if QREADY then CastQ(enemy) end
					
				elseif enemy.health <= (qDmg + wDmg + eDmg) and GetDistance(enemy) <= wRange and QREADY and WREADY and EREADY then
					if WREADY then CastSpell(_W, enemy) end
					if QREADY then CastQ(enemy) end
					if EREADY then CastE(enemy) end
				
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
						if EREADY and GetDistance(enemy) <= wRange then CastE(enemy) end
						if QREADY then CastQ(enemy) end
						
				elseif enemy.health <= (qDmg + wDmg + itemsDmg) and GetDistance(enemy) <= wRange 
					and WREADY and QREADY then
					if DFGREADY then CastSpell(dfgSlot, enemy) end
					if HXGREADY then CastSpell(hxgSlot, enemy) end
					if BWCREADY then CastSpell(bwcSlot, enemy) end
					if BRKREADY then CastSpell(brkSlot, enemy) end
					if WREADY then CastSpell(_W, enemy) end
					if QREADY then CastQ(enemy) end
					
				elseif enemy.health <= (qDmg + wDmg + eDmg + itemsDmg) and GetDistance(enemy) <= wRange 
					and QREADY and WREADY and EREADY then
					if DFGREADY then CastSpell(dfgSlot, enemy) end
					if HXGREADY then CastSpell(hxgSlot, enemy) end
					if BWCREADY then CastSpell(bwcSlot, enemy) end
					if BRKREADY then CastSpell(brkSlot, enemy) end
					if WREADY then CastSpell(_W, enemy) end
					if QREADY then CastQ(enemy) end
					if EREADY then CastE(enemy) end
				
				elseif enemy.health <= (qDmg + wDmg + eDmg + rDmg + itemsDmg) and GetDistance(enemy) <= qRange
					and QREADY and EREADY and WREADY and RREADY and enemy.health > (qDmg + eDmg) then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if WREADY and GetDistance(enemy) <= wRange then CastSpell(_W, enemy) end
						if RREADY and GetDistance(enemy) <= rRange then CastR(enemy) end
						if QREADY and GetDistance(enemy) <= qRange then CastQ(enemy) end
						if EREADY and GetDistance(enemy) <= eRange then CastE(enemy) end
						
				
				elseif enemy.health <= (rDmg + itemsDmg) and GetDistance(enemy) <= rRange
					and not QREADY and not EREADY and RREADY then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if RREADY then CastR(enemy) end
				
				end
				
				KillText[i] = 1 
				if enemy.health <= (qDmg + eDmg + wDmg + itemsDmg) and QREADY and WREADY and EREADY then
				KillText[i] = 2
				end
				if enemy.health <= (qDmg + eDmg + wDmg + rDmg + itemsDmg) and QREADY and WREADY and EREADY and RREADY then
				KillText[i] = 3
				end
				
				if enemy.health <= iDmg and GetDistance(enemy) <= 600 then
					if IREADY then CastSpell(ignite, enemy) end
				end
			end
		end
	end
end

--[Full Combo with Items]--
function FullCombo()
	if Target then
		if AutoCarry.MainMenu.AutoCarry then
			if EREADY and GetDistance(Target) <= eRange and Menu.useE then CastE(Target) end
			if WREADY and GetDistance(Target) <= wRange and Menu.useW then CastSpell(_W, Target) end
			if QREADY and GetDistance(Target) <= qRange and Menu.useQ then CastQ(Target) end
			if RREADY and GetDistance(Target) <= rRange and Menu.useR then CastR(Target) end
		end 
	end
end


--[Variables Load]--
function mainLoad()
	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
	Carry = AutoCarry.MainMenu
	qRange,wRange,eRange,rRange = 600, 650, 1100, 625
	QREADY, WREADY, EREADY, RREADY = false, false, false, false
	Menu = AutoCarry.PluginMenu
	rActive, Recall = false, false
	UsingHPot, UsingMPot, UsingFlask = false, false, false
	TextList = {"Harass him!!", "E+W+Q KILL!!", "FULL COMBO KILL!"}
	KillText = {}
	waittxt = {} -- prevents UI lags, all credits to Dekaron
	for i=1, heroManager.iCount do waittxt[i] = i*3 end -- All credits to Dekaron
	levelSequence = { 3, 1, 2, 1, 1, 4, 1, 3, 1, 3, 4, 3, 3, 2, 2, 4, 2, 2, }
	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(false, _Q, qRange, "Arcane Smash", AutoCarry.SPELL_LINEAR, 0, false, false, 1.1, 250, 110, false)
		SkillE = AutoCarry.Skills:NewSkill(false, _E, eRange, "Sapling Toss", AutoCarry.SPELL_CIRCLE, 0, false, false, 1.75, 400, 450, false)
		SkillR = AutoCarry.Skills:NewSkill(false, _R, rRange, "Vengeful Maelstrom", AutoCarry.SPELL_CIRCLE, 0, false, false, .2, 350, 550, false)
	else
		SkillQ = {spellKey = _Q, range = qRange, speed = 1.1, delay = 250, width = 110, configName = "Arcane Smash", displayName = "Q (Arcane Smash)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
		SkillE = {spellKey = _E, range = eRange, speed = 1.75, delay = 300, width = 450, configName = "Sapling Toss", displayName = "E (Sapling Toss)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
		SkillR = {spellKey = _R, range = rRange, speed = .2, delay = 350, width = 550, configName = "Vengeful Maelstrom", displayName = "R (Vengeful Maelstrom)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
	end
end

--[Main Menu & Extras Menu]--
function mainMenu()
	Menu:addParam("sep1", "-- Full Combo Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("useQ", "Use Arcane Smash (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useW", "Use Twisted Advance (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useE", "Use Sapling Toss (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useR", "Use Vengeful Maelstrom (R)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sep2", "-- Mixed Mode Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("qHarass", "Use Arcane Smash (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("eHarass", "Use Sapling Toss (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sep3", "-- KS Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("sKS", "Use Smart Combo KS", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sep5", "-- Draw Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("eDraw", "Draw Sapling Toss (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("wDraw", "Draw Twisted Advance (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("DrawTarget", "Draw Target", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("cDraw", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
	Extras = scriptConfig("Sida's Auto Carry Plugin: "..myHero.charName..": Extras", myHero.charName)
	Extras:addParam("sep6", "-- Misc --", SCRIPT_PARAM_INFO, "")
	Extras:addParam("MinMana", "Minimum Mana for Q/E Harass %", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
	Extras:addParam("ZWItems", "Auto Zhonyas/Wooglets", SCRIPT_PARAM_ONOFF, true)
	Extras:addParam("ZWHealth", "Min Health % for Zhonyas/Wooglets", SCRIPT_PARAM_SLICE, 15, 0, 100, -1)
	Extras:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
	Extras:addParam("aMP", "Auto Auto Mana Pots", SCRIPT_PARAM_ONOFF, true)
	Extras:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
	Extras:addParam("AutoLevelSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_ONOFF, true)
end

--[Certain Checks]--
function Checks()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then ignite = SUMMONER_2 end
	if IsSACReborn then Target = AutoCarry.Crosshair:GetTarget(true) else Target = AutoCarry.GetAttackTarget(true) end
	dfgSlot, hxgSlot, bwcSlot = GetInventorySlotItem(3128), GetInventorySlotItem(3146), GetInventorySlotItem(3144)
	brkSlot = GetInventorySlotItem(3092),GetInventorySlotItem(3143),GetInventorySlotItem(3153)
	znaSlot, wgtSlot = GetInventorySlotItem(3157),GetInventorySlotItem(3090)
	hpSlot, mpSlot, fskSlot = GetInventorySlotItem(2003),GetInventorySlotItem(2004),GetInventorySlotItem(2041)
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY and not HaveTibbers)
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