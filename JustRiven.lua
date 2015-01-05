-- Script Name: Just Riven
-- Script Ver.: 1.7.7
-- Author     : Skeem

--[[ Changelog:
	1.0   - Initial Release
	1.1   - Smoothen up combo
	      - Fixed Error Spamming
	1.2   - Smoothen up Orbwalking
	      - Added some packet checks
	1.3   - Remade orbwalker completely packet based now
	      - Combo should be a lot faster
	      - Added Menu Options for max stacks to use in combo
	1.4   - Whole new combo system
		  - Added Selector make sure to have latest (http://iuser99.com/scripts/Selector.lua)
		  - Removed Max Stacks in combo from menu (let me know if you want this back, i don't think its need anymore)
	      - Added menu to cancel anims with laugh/movement
	      - Added tiamat cancel AA anim -> W cancel tiamat anim -> Q cancel w Anim
	      - Added option to disable orbwalk in combo
	      - Fixed 'chasing target' when using combo
	      - Changed R Menu (Now in Combo Options) & Fixed Path Lib error with R
	      - Added R Damage logic based on skills available and option to use in combo
	      - Fixed Auto Ignite & Nil error spamming when not having it
	1.4.5 - Fixed Ult Kill Usage
	      - Fixed W error spamming
	      - Tried to improve AA in between spells
	      - Fixed boolean error
	      - Fixed Qing backwards when trying to run
	1.5   - Update Riven's orbwalker a bit
	1.6   - Now Uses SxOrbwalker remade a lot of the script!
	1.7   - Updated the script! Combo should be as smooth as baby's butt now
	      - Added Semi Harrass
	      - Added Lane Clear
	      - Updated Orbwalker
	      - Updated Damage Calculations
	      - Fixed All Path Lib Errors
	1.7.3 - Updated Combo a little
	      - Updated Orbwalker No longer sticks to target if spells on cd
	      - You can now use your favorite orbwalker in lane clear,harass mode with this script
	1.7.5 - Fixed Nil Errors?
	      - Fixed Lane Clear/Wave Clear
	      - Still nothing on harass for now
	1.7.7 - Fixed Auto Ignite for new patch
	      - Fixed Tiamat canceling W animation
	      - Added Q if not in AA range (might add a passive limiter if it Qs too fast let me know)
	      - Fixed some AA Canceling issues
	      - New printchat (best part of update)
]]--

if myHero.charName ~= 'Riven' then return end

	Spells = {
		Q = {key = _Q, name = 'Broken Wings',   range = 300, ready = false, data = nil, color = 0x663300},
		W = {key = _W, name = 'Ki Burst',       range = 260, ready = false, data = nil, color = 0x333300},
		E = {key = _E, name = 'Valor',          range = 390, ready = false, data = nil, color = 0x666600},
		R = {key = _R, name = 'Blade of Exile', range = 900, ready = false, data = nil, color = 0x993300}
	}

	Ignite = (myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") and SUMMONER_2) or nil
	EnemyMinions  = minionManager(MINION_ENEMY,  400, player, MINION_SORT_HEALTH_ASC)
	JungleMinions = minionManager(MINION_JUNGLE, 400, player, MINION_SORT_MAXHEALTH_DEC)

	Items = {
		YGB	   = {id = 3142, range = 350, ready = false},
		BRK    = {id = 3153, range = 500, ready = false},
		HYDRA  = {id = 3074, range = 350, ready = false},
		TIAMAT = {id = 3077, range = 350, ready = false}
	}

	BuffInfo = {
		P = {stacks = 0},
		Q = {stage  = 0}
	}

	Orbwalking = {
		lastAA     = 0,
		windUp     = 3.75,
		animation  = 0.625,
	}

	TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 500, DAMAGE_PHYSICAL, true)
	TS.name = 'Riven'
	
	RivenMenu = scriptConfig('~[Just Riven]~', 'Riven')
		RivenMenu:addSubMenu('~[Skill Settings]~', 'skills')
			RivenMenu.skills:addParam('', '--[ W Options ]--', SCRIPT_PARAM_INFO, '')
			RivenMenu.skills:addParam('autoW', 'Auto W Close Enemies', SCRIPT_PARAM_ONOFF, false)
		
		RivenMenu:addSubMenu('~[Combo Settings]~', 'combo')
			RivenMenu.combo:addParam('ulti',     'Use R for Potential Kills', SCRIPT_PARAM_ONOFF, true)
			RivenMenu.combo:addParam('orb',      'Use Built In Orbwalker', SCRIPT_PARAM_ONOFF, true)
			RivenMenu.combo:addParam('anim',     'Cancel Animation With:',    SCRIPT_PARAM_LIST, 2, {"Laugh", "Movement"})

		RivenMenu:addSubMenu('~[Harass Settings]~', 'harass')
			RivenMenu.harass:addParam('q',     'Use Q Semi-Harass', SCRIPT_PARAM_ONOFF, true)
			RivenMenu.harass:addParam('mode',  'Harass Mode',    SCRIPT_PARAM_LIST, 2, {"Always", "OnKey", "Never"})			
			RivenMenu.harass:addParam('orb',   'Use Built In Orbwalker', SCRIPT_PARAM_ONOFF, true)

		RivenMenu:addSubMenu('~[Clear Settings]~', 'clear')
			RivenMenu.clear:addParam('q',     'Use Q Clear', SCRIPT_PARAM_ONOFF, true)
			RivenMenu.clear:addParam('w',     'Use W Clear', SCRIPT_PARAM_ONOFF, true)
			RivenMenu.clear:addParam('e',     'Use E Clear', SCRIPT_PARAM_ONOFF, true)
			RivenMenu.clear:addParam('orb',   'Use Built In Orbwalker', SCRIPT_PARAM_ONOFF, true)

		RivenMenu:addSubMenu('~[Kill Settings]~', 'kill')
			RivenMenu.kill:addParam('enabled', 'Enable KillSteal',    SCRIPT_PARAM_ONOFF, true)
			RivenMenu.kill:addParam('killQ',   'GapClose Q to KS',    SCRIPT_PARAM_ONOFF, true)
			RivenMenu.kill:addParam('killR',   'KillSteal with R',    SCRIPT_PARAM_LIST, 1, {"When Already Used", "Always", "Never"})
			RivenMenu.kill:addParam('killW',   'KillSteal with W',    SCRIPT_PARAM_ONOFF, true)
			RivenMenu.kill:addParam('Ignite',  'Auto Ignite Enemies', SCRIPT_PARAM_ONOFF, true)

		RivenMenu:addSubMenu('~[Draw Ranges]~', 'draw')
			RivenMenu.draw:addParam('target', 'Draw Circle on Target', SCRIPT_PARAM_ONOFF, true)
			for string, spell in pairs(Spells) do
				RivenMenu.draw:addParam(string, 'Draw '..spell.name..' ('..string..')', SCRIPT_PARAM_ONOFF, true)
			end		
		RivenMenu:addParam('comboKey',  'Combo Key  [X]',  SCRIPT_PARAM_ONKEYDOWN, false, GetKey('X'))
		RivenMenu:addParam('harassKey', 'Harass Key [C]',  SCRIPT_PARAM_ONKEYDOWN, false, GetKey('C'))
		RivenMenu:addParam('clearKey',  'Clear Key  [V]',  SCRIPT_PARAM_ONKEYDOWN, false, GetKey('V'))
		RivenMenu:addTS(TS)

PrintChat("<font color='#663300'>Just Riven 1.7.7 GGWP</font>")

function OnTick()
	Target = GetTarget()

	for _, spell in pairs(Spells) do
		spell.ready = myHero:CanUseSpell(spell.key) == READY
		spell.data  = myHero:GetSpellData(spell.key)
	end

	for _, item in pairs(Items) do
		item.ready = GetInventoryItemIsCastable(item.id)
	end

	if RivenMenu.comboKey then
		if RivenMenu.combo.orb then
			Orb(Target)
		end
		CastCombo(Target)
		if BuffInfo.P.stacks > 0 and ValidTarget(Target, AARange(Target)) then
			Attack(Target)
		end
	end
	if RivenMenu.clearKey then
		Clear()
	end
	if RivenMenu.skills.autoW and Spells.W.ready and Target then
		Cast(_W, Target, Spells.W.range)
	end
	if RivenMenu.kill.enabled then
		KillSteal()
	end
end 

function OnDraw()
	if myHero.dead then return end
	for string, spell in pairs(Spells) do
		if spell.ready and RivenMenu.draw[string] then
			DrawCircle(myHero.x, myHero.y, myHero.z, spell.range, spell.color)
		end
	end
	if RivenMenu.draw.target and ValidTarget(Target) then
		DrawCircle(Target.x, Target.y, Target.z, Target.range, 0xFF0000)
	end
end

function OnGainBuff(unit, buff)
	if unit.isMe then
		if buff.name == 'rivenpassiveaaboost' then
			BuffInfo.P.stacks = 1
		end
		if buff.name == 'riventricleavesoundone' then
			BuffInfo.Q.stage  = 1
		end
		if buff.name == 'riventricleavesoundtwo' then
			BuffInfo.Q.stage  = 2
		end
	end
end

function OnLoseBuff(unit, buff)
	if unit.isMe then
		if buff.name == 'rivenpassiveaaboost' then
			BuffInfo.P.stacks = 0
		end
		if buff.name == 'RivenTriCleave' then
			BuffInfo.Q.stage  = 0
		end
	end
end

function OnUpdateBuff(unit, buff)
	if unit.isMe then
		if buff.name == 'rivenpassiveaaboost' then
			BuffInfo.P.stacks = buff.stack
		end
	end
end

function OnSendPacket(packet)
	local p = Packet(packet)
	if p:get('name') == 'S_CAST' and p:get('sourceNetworkId') == myHero.networkID then
		DelayAction(function() 
			CancelAnimation()
		end, Latency())
		if p:get('spellId') == 0 then
			ResetAA()
		elseif p:get('spellId') == 1 then
			if ValidTarget(Target, Items.HYDRA.range) then
 				if Items.HYDRA.ready then
					DelayAction(function() CastItem(Items.HYDRA.id)  end, Latency())
				elseif Items.TIAMAT.ready then
					DelayAction(function() CastItem(Items.TIAMAT.id) end, Latency())
				end
			end
		elseif p:get('spellId') > 3 then
			DelayAction(function()
				ResetAA()
				if RivenMenu.comboKey or RivenMenu.harassKey and ValidTarget(Target, AARange(Target)) then
					Attack(Target)
				end
			end, Latency())
		end
	end
end

function OnRecvPacket(packet)
	if packet.header == 0xFE then
		packet.pos = 1
 		if packet:DecodeF() == myHero.networkID then
 			Orbwalking.lastAA = Clock() - Latency()
 			if ValidTarget(Target, Items.HYDRA.range) then
 				if Items.HYDRA.ready then
					DelayAction(function() CastItem(Items.HYDRA.id) ResetAA()  end, Latency())
				elseif Items.TIAMAT.ready then
					DelayAction(function() CastItem(Items.TIAMAT.id) ResetAA() end, Latency())
				end
			end
 		end
	elseif packet.header == 0x34 then
		packet.pos = 1
		if packet:DecodeF() == myHero.networkID then
			packet.pos = 9
			if packet:Decode1() == 0x11 then
				ResetAA()
			end
		end
	-- Thanks to Bilbao :3 --
	elseif packet.header == 0x65 then
  		packet.pos = 5
  		local dmgType  = packet:Decode1()
  		local targetId = packet:DecodeF()
  		local souceId  = packet:DecodeF()
  		if souceId == myHero.networkID and dmgType == (12 or 3) then
  			if ValidTarget(Target) and Spells.Q.ready then
  				if RivenMenu.comboKey or (RivenMenu.harass.q and RivenMenu.harassKey) then
  					Cast(_Q, Target, Spells.Q.range)
  				end
			end
  		end
 	end
end

function GetTarget()
	TS:update()
	if TS.target ~= nil and not TS.target.dead and TS.target.type  == myHero.type and TS.target.visible then
		return TS.target
	end
end


function CastCombo(target)
	if ValidTarget(target) then
		if Items.YGB.ready and InRange(target) then
			CastItem(Items.YGB.id)
		end
		if RivenMenu.combo.ulti and Ult(target) and Spells.R.ready and InRange(target) then
			CastSpell(_R)
		end
		if Spells.E.ready then
			Cast(_E, target, Spells.E.range)
		end
		if not InRange(target) and Spells.Q.ready and BuffInfo.P.stacks < 3 then
			Cast(_Q, target, Spells.Q.range)
		end
		if not Items.TIAMAT.ready or Items.HYDRA.ready and not Spells.Q.ready then 
			Cast(_W, target, Spells.W.range)
		end
	end
end

function Ult(target)
	local R1  = Spells.R.ready and myHero:CalcDamage(target, (myHero.totalDamage *.20)) or 0
	local Dmg = {P  = getDmg('P',  target, myHero) + R1,
				 A  = getDmg('AD', target, myHero) + R1,
				 Q  = Spells.Q.ready and getDmg('Q', target, myHero) + R1 or 0,
				 W  = Spells.W.ready and getDmg('W', target, myHero) + R1 or 0,
				 R2 = Spells.R.ready and getDmg('R', target, myHero) + R1 or 0}

	return ((Dmg.P*3) + (Dmg.A*3) + (Dmg.Q*3) + Dmg.W + Dmg.R2) > target.health
end

function UltOn()
	return Spells.R.data.level > 0 and Spells.R.ready and Spells.R.data.name ~= 'RivenFengShuiEngine'
end

function KillSteal()
	for _, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, Spells.R.range) then
			local RDmg = getDmg('R', enemy, myHero) or 0
			if Spells.R.ready and enemy.health <= RDmg then
				if RivenMenu.kill.killR == 1 then
					if UltOn() then
						Cast(_R, enemy, Spells.R.range)
					end
				elseif RivenMenu.kill.killR == 2 then
					if UltOn() then
						Cast(_R, enemy, Spells.R.range)						
					else
						CastSpell(_R)	
					end
				end
			end
			if Ignite ~= nil and RivenMenu.kill.Ignite and ValidTarget(enemy, 600) then
				IgniteCheck(enemy)
			end
		end
	end
end

function IgniteCheck(target)
	return  target.health < getDmg("IGNITE", target, myHero) and CastSpell(Ignite, target)
end

function Cast(spell, target, range, packet)
	return target and GetDistanceSqr(target.visionPos) < range * range and (not packet and CastSpell(spell, target.visionPos.x, target.visionPos.z) or Packet("S_CAST", { spellId = spell, toX = target.x, toY = target.z, fromX = target.x, fromY = target.z }):send())
end

function CancelAnimation()
	return RivenMenu.combo.anim == 1 and SendChat('/l') or Packet('S_MOVE', { x = mousePos.x, y = mousePos.z }):send()
end

function Clear()
	local QOn = Spells.Q.ready and RivenMenu.clear.q
	local WOn = Spells.W.ready and RivenMenu.clear.w
	local EOn = Spells.E.ready and RivenMenu.clear.e
	local Minion = MinionTarget()
	local Jungle = JungleTarget()
	local FocusTarget = Jungle ~= nil and Jungle or Minion ~= nil and Minion
		if RivenMenu.clear.orb then
			Orb(FocusTarget)
		end
	if FocusTarget then
		if QOn and GetDistance(FocusTarget) < Spells.Q.range then
			CastSpell(_Q, FocusTarget.x, FocusTarget.z)	
		elseif WOn and GetDistance(FocusTarget) < Spells.W.range then
			CastSpell(_W, FocusTarget.x, FocusTarget.z)
		elseif EOn and GetDistance(FocusTarget) < Spells.E.range then
			CastSpell(_E, FocusTarget.x, FocusTarget.z)
		end
	end
	if BuffInfo.P.stacks > 0 and InRange(FocusTarget) then
		Attack(FocusTarget)
	end
end

function MinionTarget()
	EnemyMinions:update()
	for _, minion in pairs(EnemyMinions.objects) do
		if minion and ValidTarget(minion, 400) then
			return minion
		end
	end
	return nil
end

function JungleTarget()
	JungleMinions:update()
	for _, jungleminion in pairs(JungleMinions.objects) do
		if jungleminion and ValidTarget(jungleminion, 400) then
			return jungleminion
		end
	end
	return nil
end

function Orb(target)
    if target and CanAttack() and ValidTarget(target, AARange(target)) then
      	Attack(target)
    elseif CanMove() then
    	local MovePos = Vector(myHero) + 400 * (Vector(mousePos) - Vector(myHero)):normalized()
    	Packet('S_MOVE', { x = MovePos.x, y = MovePos.z }):send()
    end
end

function CanAttack()
	return Clock() + Latency()  > Orbwalking.lastAA + AnimationTime()
end

function AARange(target)
	return target and myHero.range + myHero.boundingRadius + target.boundingRadius
end

function InRange(target)
	return target and GetDistanceSqr(target.visionPos, myHero.visionPos) < AARange(target) * AARange(target)
end

function Attack(target)
	if target then
		Orbwalking.lastAA = Clock() + Latency()
		myHero:Attack(target)
	end
end

function CanMove()
	return Clock() + Latency() > (Orbwalking.lastAA + WindUpTime())
end

function WindUpTime()
	return (1 / (myHero.attackSpeed * Orbwalking.windUp))
end

function AnimationTime()
	return (1 / (myHero.attackSpeed * Orbwalking.animation))
end

function Latency()
	return GetLatency() / 2000
end

function Clock()
	return os.clock()
end

function ResetAA()
	Orbwalking.lastAA = 0
end