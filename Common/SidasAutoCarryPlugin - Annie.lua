--[[
	AutoCarry Plugin - Annie Hastur, the Dark Child 1.4.2 by Skeem
	With Code from Kain
	Copyright 2013
	Changelog :
   1.0    - Initial Release
   1.1    - Recoded Should Work Better
	      - Fixed Auto Ignite
	      - Fixed bug with ultimate
	      - Fixed MEC no library required now
	      - Added Draw Text now draws if target can die from combo
	      - Added Auto Health Pots / Auto Mana Pots
	      - Added Auto Zhonyas (Needs Work maybe set at 15% default)
	      - Added Auto Spell Levels
   1.2    - Added prodiction to W, R
	      - W uses MEC
   1.2.2  - Fixed bug with qFarm not deactivating
		  - Fixed W & R.
		  - Fixed Force Tibbers
		  - Fixed Script not showing for some users
	1.3   - Fixed W Usage (added new cone function)
	      - Fixed recalling bug
		  - Fixed Auto Pots
	1.3.1 - Changed castR to vadash's
	1.4   - Changed W Range
	      - Fixed some issues with R
	      - Added better support for revamped
	1.4.1 - Added fix for casting W before R when stun is up
	1.4.2 - Fixed spamming E while Recalling & Tweaked DFG Usage
  	]] --


--[ Plugin Loads] --
function PluginOnLoad()
	
	loadMain() -- Loads Global Variables
	menuMain() -- Loads AllClass Menu
end
--[/Loads]

--[Plugin OnTick]--
function PluginOnTick()
		if Recalling then return end -- If we're recalling then won't run any combos
		Checks()
		SmartKS()
		UseConsumables()
		
		if Menu.dAttack and Carry.AutoCarry then AutoCarry.CanAttack = false else AutoCarry.CanAttack = true end
		if not IsMyManaLow() and Menu.sFarm and Menu.qFarm and not HaveStun and not Carry.AutoCarry then qFarm()
			elseif not IsMyManaLow() and not Menu.sFarm and Menu.qFarm and not Carry.AutoCarry then qFarm() end
		if Menu.cStun and EREADY and not HaveStun then CastSpell(_E) end
		if Carry.AutoCarry then bCombo() end
		if Menu.sKS then SmartKS() end
		if Target and Carry.MixedMode then
			if Menu.qHarass and QREADY and GetDistance(Target) <= qRange then CastSpell(_Q, Target) end
			if Menu.wHarass and WREADY and GetDistance(Target) <= wRange then CastW(Target) end
		end
		if Extras.AutoLevelSkills then autoLevelSetSequence(levelSequence) end
end
--[/OnTick]--

function qFarm()
	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		local qDmg = getDmg("Q",minion,myHero)
		   if ValidTarget(minion) and QREADY and GetDistance(minion) <= qRange then
            if qDmg >= minion.health then CastSpell(_Q, minion) end
        end
   end
end

--[Burst Combo Function]--
function bCombo()
	if Target then
		if DFGREADY and GetDistance(Target) <= qRange then CastSpell(dfgSlot, Target) end
		if HXGREADY then CastSpell(hxgSlot, Target) end
		if BWCREADY then CastSpell(bwcSlot, Target) end
		if BRKREADY then CastSpell(brkSlot, Target) end
		if RREADY and GetDistance(Target) <= rRange and HaveStun then CastR(Target) end
		if EREADY and GetDistance(Target) <= wRange then CastSpell(_E) end
		if QREADY and GetDistance(Target) <= qRange then CastSpell(_Q, Target) end
		if WREADY and GetDistance(Target) <= wRange then CastW(Target) end
	end
end
--[/Burst Combo Function]--

--[Skills that use MEC]--
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

function CastR(Target)
    if RREADY then
        local ultPos = GetAoESpellPosition(450, Target, 250)
        if ultPos and GetDistance(ultPos) <= rRange then
            if CountEnemies(ultPos, 450) >= 1 then
                CastSpell(_R, ultPos.x, ultPos.z)
            end
        else
            if IsSACReborn and TS_GetPriority(Target) <= 2 then
                SkillR:Cast(Target)
            else
            	CastSpell(_R, Target.x, Target.z)
            end
        end
    end 
end 
--[Skills that use MEC]--

--[Casts our W Skill]--
function CastW(enemy)
	if not enemy and ValidTarget(Target) then
		enemy = Target
	end
    if WREADY then 
		if IsSACReborn then
			SkillW:Cast(enemy)
		else
			AutoCarry.CastSkillshot(SkillW, Target)
		end
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
			rDmg = getDmg("R",enemy,myHero)
			if DFGREADY then dfgDmg = (dfgSlot and getDmg("DFG",enemy,myHero) or 0)	end
            if HXGREADY then hxgDmg = (hxgSlot and getDmg("HXG",enemy,myHero) or 0) end
            if BWCREADY then bwcDmg = (bwcSlot and getDmg("BWC",enemy,myHero) or 0) end
            if IREADY then iDmg = (ignite and getDmg("IGNITE",enemy,myHero) or 0) end
            onspellDmg = (liandrysSlot and getDmg("LIANDRYS",enemy,myHero) or 0)+(blackfireSlot and getDmg("BLACKFIRE",enemy,myHero) or 0)
            itemsDmg = dfgDmg + hxgDmg + bwcDmg + iDmg + onspellDmg
			if Menu.sKS then
				if enemy.health <= (qDmg) and GetDistance(enemy) <= qRange and QREADY then
					if QREADY then CastSpell(_Q, enemy) end
				
				elseif enemy.health <= (wDmg) and GetDistance(enemy) <= wRange and WREADY then
					if WREADY then CastW(enemy) end
				
				elseif enemy.health <= (qDmg + wDmg) and GetDistance(enemy) <= wRange and WREADY and QREADY then
					if QREADY then CastSpell(_Q, enemy) end
					if WREADY then CastW(enemy) end
				
				elseif enemy.health <= (qDmg + itemsDmg) and GetDistance(enemy) <= qRange and QREADY then
					if DFGREADY then CastSpell(dfgSlot, enemy) end
					if HXGREADY then CastSpell(hxgSlot, enemy) end
					if BWCREADY then CastSpell(bwcSlot, enemy) end
					if BRKREADY then CastSpell(brkSlot, enemy) end
					if QREADY then CastSpell(_Q, enemy) end
				
				elseif enemy.health <= (wDmg + itemsDmg) and GetDistance(enemy) <= wRange and WREADY then
					if DFGREADY then CastSpell(dfgSlot, enemy) end
					if HXGREADY then CastSpell(hxgSlot, enemy) end
					if BWCREADY then CastSpell(bwcSlot, enemy) end
					if BRKREADY then CastSpell(brkSlot, enemy) end
					if WREADY then CastW(enemy) end
				
				elseif enemy.health <= (qDmg + wDmg + itemsDmg) and GetDistance(enemy) <= wRange
					and WREADY and QREADY then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if WREADY and GetDistance(enemy) <= wRange then CastW(enemy) end
						if QREADY then CastSpell(_Q, enemy) end
				
				elseif enemy.health <= (qDmg + wDmg + rDmg + itemsDmg) and GetDistance(enemy) <= qRange
					and QREADY and EREADY and WREADY and RREADY and enemy.health > (qDmg + wDmg) then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if RREADY and GetDistance(enemy) <= rRange then CastR(enemy) end
						if QREADY and GetDistance(enemy) <= qRange then CastSpell(_Q, enemy) end
						if WREADY and GetDistance(enemy) <= wRange then CastW(enemy) end
						
				
				elseif enemy.health <= (rDmg + itemsDmg) and GetDistance(enemy) <= rRange
					and not QREADY and not EREADY and RREADY then
						if DFGREADY then CastSpell(dfgSlot, enemy) end
						if HXGREADY then CastSpell(hxgSlot, enemy) end
						if BWCREADY then CastSpell(bwcSlot, enemy) end
						if BRKREADY then CastSpell(brkSlot, enemy) end
						if RREADY then CastR(enemy) end
				
				end
			end
			KillText[i] = 1 
			if enemy.health <= (qDmg + wDmg + itemsDmg) and QREADY and WREADY then
				KillText[i] = 2
			end
			if enemy.health <= (qDmg + wDmg + rDmg + itemsDmg) and QREADY and WREADY and RREADY then
				KillText[i] = 3
			end
			if enemy.health <= iDmg and GetDistance(enemy) <= 600 then
				if IREADY then CastSpell(ignite, enemy) end
			end
		end
	end
end
--[/Smart KS Function]--

function UseConsumables()
	if not InFountain() and not Recalling and Target ~= nil then
		if Extras.aHP and myHero.health < (myHero.maxHealth * (Extras.HPHealth / 100))
			and not (usingHPot or usingFlask) and (hpReady or fskReady)	then
				CastSpell((hpSlot or fskSlot)) 
		end
		if Extras.aMP and myHero.mana < (myHero.maxMana * (Extras.MinMana / 100))
			and not (usingMPot or usingFlask) and (mpReady or fskReady) then
				CastSpell((mpSlot or fskSlot))
		end
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
--[Object Detection]--
function PluginOnCreateObj(obj)
	if obj and GetDistance(obj) <= 50 then
		if obj.name == "StunReady.troy" then HaveStun = true end
        if obj.name == "BearFire_foot.troy" then HaveTibbers = true end
		if obj.name == "TeleportHome.troy" then Recall = true end
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
end
 
function PluginOnDeleteObj(obj)
	if obj and GetDistance(obj) <= 50 then
		if obj.name == "StunReady.troy" then HaveStun = false end
        if obj.name == "BearFire_foot.troy" then HaveTibbers = false end
		if obj.name == "TeleportHome.troy" then Recall = false end
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
end
--[/Object Detection]--

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

function PluginOnDraw()
	--> Ranges
	if not myHero.dead then
		if QREADY and Menu.qDraw then 
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x191970)
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

function loadMain()
		if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
		if IsSACReborn then AutoCarry.Skills:DisableAll() end
		Menu = AutoCarry.PluginMenu
		Carry = AutoCarry.MainMenu
        if IsSACReborn then
		AutoCarry.Crosshair:SetSkillCrosshairRange(630)
		else
		AutoCarry.SkillsCrosshair.range = 630
		end
		HaveStun, HaveTibbers, Recall = false, false, false
		hpReady, mpReady, fskReady = false, false, false
		HK1, HK2, HK3 = string.byte("Z"), string.byte("K"), string.byte("T")
        qRange, wRange, eRange, rRange = 625, 600, 600, 630
		TextList = {"Harass him!!", "Q+W KILL!!", "FULL COMBO KILL!"}
		KillText = {}
		waittxt = {} -- prevents UI lags, all credits to Dekaron
		for i=1, heroManager.iCount do waittxt[i] = i*3 end -- All credits to Dekaron
		levelSequence = { nil, 0, 1, 3, 1, 4, 1, 2, 1, 2, 4, 2, 2, 3, 3, 4, 3, 3, }
		if IsSACReborn then
			SkillW = AutoCarry.Skills:NewSkill(false, _W, wRange, "Incinerate", AutoCarry.SPELL_CONE, 0, false, false, 1.5, 650, 45, false)
			SkillR = AutoCarry.Skills:NewSkill(false, _R, rRange, "Infernal Guardian", AutoCarry.SPELL_CIRCLE, 0, false, false, 1.5, 250, 450, false)
		else
			SkillW = {spellKey = _W, range = wRange, speed = 1.5, delay = 250, width = 100, configName = "Incinerate", displayName = "W Incinerate", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
			SkillR = {spellKey = _R, range = rRange, speed = 1.5, delay = 250, width = 450, configName = "Incinerate", displayName = "W Incinerate", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
		end
end

 
function menuMain()
        Menu:addParam("sep", "-- Farm Options --", SCRIPT_PARAM_INFO, "")
       	Menu:addParam("qFarm", "Disintegrate(Q) - Farm ", SCRIPT_PARAM_ONKEYTOGGLE, false, HK1)
		Menu:addParam("sFarm", "Don't Q Farm if Stun Ready", SCRIPT_PARAM_ONKEYTOGGLE, false, HK2)
		Menu:addParam("sep1", "-- Combo Options --", SCRIPT_PARAM_INFO, "")
		Menu:addParam("dAttack", "Disable Auto Attacks", SCRIPT_PARAM_ONKEYTOGGLE, false, HK3)
		Menu:addParam("cStun", "Charge Stun with E", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("fTibbers", "Force Tibbers without Stun", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("sep2", "-- Mixed Mode Options --", SCRIPT_PARAM_INFO, "")
		Menu:addParam("qHarass", "Use Disintegrate(Q)", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("wHarass", "Use Incinerate(W)", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("sep3", "-- KS Options --", SCRIPT_PARAM_INFO, "")
		Menu:addParam("sKS", "Use Smart Combo KS", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("sep5", "-- Draw Options --", SCRIPT_PARAM_INFO, "")
		Menu:addParam("qDraw", "Draw Disintegrate (Q)", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("DrawTarget", "Draw Target", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("cDraw", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
		
		Extras = scriptConfig("Sida's Auto Carry Plugin: "..myHero.charName..": Extras", myHero.charName)
		Extras:addParam("sep6", "-- Misc --", SCRIPT_PARAM_INFO, "")
		Extras:addParam("MinMana", "Minimum Mana for Q Farm %", SCRIPT_PARAM_SLICE, 40, 0, 100, 2)
		Extras:addParam("ZWItems", "Auto Zhonyas/Wooglets", SCRIPT_PARAM_ONOFF, true)
		Extras:addParam("ZWHealth", "Min Health % for Zhonyas/Wooglets", SCRIPT_PARAM_SLICE, 15, 0, 100, 2)
		Extras:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
		Extras:addParam("aMP", "Auto Auto Mana Pots", SCRIPT_PARAM_ONOFF, true)
		Extras:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, 2)
		Extras:addParam("AutoLevelSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_ONOFF, true)
end

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
	hpReady = (hpSlot ~= nil and myHero:CanUseSpell(hpSlot) == READY)
	mpReady =(mpSlot ~= nil and myHero:CanUseSpell(mpSlot) == READY)
	fskReady = (fskSlot ~= nil and myHero:CanUseSpell(fskSlot) == READY)
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