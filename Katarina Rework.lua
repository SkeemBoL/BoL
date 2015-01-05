if myHero.charName ~= 'Katarina' then return end

--|> Cuz superx is the only lua bender
require 'SxOrbWalk'

class 'Katarina'

	function Katarina:__init()
		--|> Spell Information
		self.spells = {
			Q = Spells(_Q, 675, 'Bouncing Blades', 'targeted', ARGB(255,178, 0 , 0 )),
			W =	Spells(_W, 375, 'Sinister Steel',  'notarget', ARGB(255, 32,178,170)),
			E =	Spells(_E, 700, 'Shunpo',          'targeted', ARGB(255,128, 0 ,128)),
			R =	Spells(_R, 550, 'Death Lotus',     'notarget')
		}
		--|> Tracks When Throwing Q
		self.Q = {throwing = false, last = 0}
		self.targetsWithQ = {}

		--|> Tracks When Using R
		self.R = {using    = false, last = 0}

		--|> Tracks Ward Jumpings
		self.lastJump = 0

		--|> Starts Menu
		self:Menu()

		--|> Ignite Slot
		self.ignite = myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") and SUMMONER_1 or myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") and SUMMONER_2 or nil

		--|> EnemyText Table
		self.enemyText = {}
		--|> Items Table
		self:LoadItemsTable()

		--|> Wards Table
		self.wardsTable = {}
		for i = 0, objManager.maxObjects do
			local obj = objManager:getObject(i)
			if obj and obj.valid and (string.find(obj.name, "Ward") ~= nil or string.find(obj.name, "Wriggle") ~= nil or string.find(obj.name, "Trinket")) then
				table.insert(self.wardsTable, obj)
			end
		end

		--|> Minion Managers
		self.enemyMinions   = minionManager(MINION_ENEMY,   self.spells.E:Range(), myHero, MINION_SORT_MAXHEALTH_DEC)
		self.allyMinions    = minionManager(MINION_ALLY,    self.spells.E:Range(), myHero, MINION_SORT_MAXHEALTH_DEC)
		self.jungleMinions  = minionManager(MINION_JUNGLE,  self.spells.E:Range(), myHero, MINION_SORT_MAXHEALTH_DEC)
		self.otherMinions   = minionManager(MINION_OTHER,   self.spells.E:Range(), myHero, MINION_SORT_MAXHEALTH_DEC)

		--|> Callback Binds
		AddTickCallback(function() self:Tick() end)
		AddDrawCallback(function() self:Draw() end)
		AddProcessSpellCallback(function(unit, spell) self:Spells(unit, spell)	end)
		if VIP_USER then
			AddSendPacketCallback(function(packet) self:SendPacket(packet) end)
			AdvancedCallback:bind('GainBuff', function (unit, buff) self:GainBuff(unit, buff) end)
			AdvancedCallback:bind('LoseBuff', function (unit, buff) self:LoseBuff(unit, buff) end)
		end
		AddCreateObjCallback(function(obj) self:ObjCreate(obj) end)
		AddDeleteObjCallback(function(obj) self:ObjDelete(obj) end)

		--|> Prints Loaded
		print("<font color=\"#FF0000\">[Nintendo Katarina]:</font> <font color=\"#FFFFFF\">Loaded Version 3.01</font>")
	end

	function Katarina:Menu()
		---|> Initiates scriptConfig instance
		self.menu = scriptConfig('Nintendo Katarina', 'NintendoKatarina')
			--|> Skills Settings Menu
			self.menu:addSubMenu('-~=[Skill Settings]=~- ', 'skills')
				self.menu.skills:addSubMenu('Q - ['..self.spells.Q.name..']', 'Q')
					self.menu.skills.Q:addParam('autoQ',   'Auto Harass Enemies', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.Q:addParam('comboQ',  'Use in Combo',  SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.Q:addParam('harassQ', 'Use in Harass', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.Q:addParam('clearQ',  'Use in Clear ', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.Q:addParam('drawQ',   'Draw Range ',   SCRIPT_PARAM_ONOFF, true)
				self.menu.skills:addSubMenu('W - ['..self.spells.W.name..']', 'W')
					self.menu.skills.W:addParam('autoW',   'Auto Harass Enemies', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.W:addParam('comboW',  'Use in Combo',  SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.W:addParam('harassW', 'Use in Harass', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.W:addParam('clearW',  'Use in Clear ', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.W:addParam('drawW',   'Draw Range ',   SCRIPT_PARAM_ONOFF, true)
				self.menu.skills:addSubMenu('E - ['..self.spells.E.name..']', 'E')
					self.menu.skills.E:addParam('comboE',  'Use in Combo',  SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.E:addParam('harassE', 'Use in Harass', SCRIPT_PARAM_ONOFF, false)
					self.menu.skills.E:addParam('clearE',  'Use in Clear ', SCRIPT_PARAM_ONOFF, true)
					self.menu.skills.E:addParam('drawE',   'Draw Range ',   SCRIPT_PARAM_ONOFF, true)			
			
			--|> Combo Settings Menu
			self.menu:addSubMenu('-~=[Combo Settings]=~-', 'combo')
				self.menu.combo:addParam('procQ',    'Detonate Q Mark', SCRIPT_PARAM_ONOFF, true)
				self.menu.combo:addParam('useItems', 'Use Items',       SCRIPT_PARAM_ONOFF, true)
			
			--|> Harrass Settings Menu
			self.menu:addSubMenu('-~=[Harass Settings]=~-', 'harass')
				self.menu.harass:addParam('procQ', 'Detonate Q Mark', SCRIPT_PARAM_ONOFF, true)
			
			--|> Orbwalk Settings Menu
			self.menu:addSubMenu('-~=[Orbwalk Settings]=~-', 'orbwalk')
				SxOrb:LoadToMenu(self.menu.orbwalk, true)
				SxOrb:RegisterHotKey('fight',     self.menu, 'comboKey')
				SxOrb:RegisterHotKey('harass',    self.menu, 'harassKey')
				SxOrb:RegisterHotKey('laneclear', self.menu, 'clearKey')
				SxOrb:RegisterHotKey('lasthit',   self.menu, 'lasthitKey')

			--|> KillSteal Settings Menu
			self.menu:addSubMenu('-~=[KillSteal Settings]=~-', 'killsteal')
				self.menu.killsteal:addParam('killswitch', 'Use KillSteal', SCRIPT_PARAM_ONOFF, true)
				self.menu.killsteal:addParam('ignite',     'Auto Ignite',   SCRIPT_PARAM_ONOFF, true)
				self.menu.killsteal:addParam('wards',      'Use Wards',     SCRIPT_PARAM_ONOFF, true)

			--|> Farming Settings Menu
			self.menu:addSubMenu('-~=[Farming Settings]=~-', 'farming')
				self.menu.farming:addParam('farmQToggle', 'Q Farm Always',     SCRIPT_PARAM_ONKEYTOGGLE , false, GetKey('Z'))
				self.menu.farming:addParam('farmQLast',   'Q Farm in LastHit', SCRIPT_PARAM_ONOFF, true)
				self.menu.farming:addParam('farmWToggle', 'W Farm Always',     SCRIPT_PARAM_ONOFF, true)

			--|> Other Settings
			self.menu:addSubMenu('-~=[Other Settings]=~-', 'other')
				self.menu.other:addParam('maxjump', 'Always Ward Jump at Max Range', SCRIPT_PARAM_ONOFF, true)

			--|> Main Keys
			self.menu:addParam('comboKey',    'Full Combo Key', SCRIPT_PARAM_ONKEYDOWN, false, GetKey('X'))
			self.menu:addParam('harassKey',   'Harass Key',     SCRIPT_PARAM_ONKEYDOWN, false, GetKey('C'))
			self.menu:addParam('clearKey',    'Clear Key',      SCRIPT_PARAM_ONKEYDOWN, false, GetKey('V'))
			self.menu:addParam('lasthitKey',  'Last Hit Key',   SCRIPT_PARAM_ONKEYDOWN, false, GetKey('A'))
			self.menu:addParam('wardjumpKey', 'Ward Jump Key',  SCRIPT_PARAM_ONKEYDOWN, false, GetKey('G'))

			--|> Target Selector
			self.ts = TargetSelector(TARGET_LESS_CAST, self.spells.E.range, DAMAGE_MAGIC, true)
			self.ts.name = 'Katarina'
			self.menu:addTS(self.ts)

			--|> Loads Priority Table
			self:LoadPriorityTable()
			--|> Sets Prioties`
			self:SetTablePriorities()
	end

	function Katarina:Tick()
		local target = self:GetTarget()
		if target  and not self.using then
			if self.menu.comboKey then
				self:Combo(target)
			elseif self.menu.harassKey then
				self:Harass(target)
			end
			if self.menu.skills.Q.autoQ then
				self.spells.Q:Cast(target)
			end
			if self.menu.skills.W.autoW then
				self.spells.W:Cast(target)
			end
		end
		if self.menu.clearKey then
			self:Clear()
		end
		if self.menu.killsteal.killswitch then
			self:KillSteal()
		end
		if self.menu.killsteal.ignite and self.ignite ~= nil then
			self:AutoIgnite()
		end
		if self.menu.wardjumpKey then
    		local WardPos = (GetDistanceSqr(mousePos) <= 600 * 600 and mousePos) or (self.menu.other.maxjump and myHero + (Vector(mousePos) - myHero):normalized()*590)
			if WardPos then
				self:WardJump(WardPos.x, WardPos.z)
			end
		end
		if not self.menu.comboKey and not self.menu.harassKey then 
			self:Farm()
		end
		if self.Q.throwing then
			if (os.clock() - self.Q.last) > 0.5 then
				self.Q.throwing = false
			end
		end
	end

	function Katarina:Draw()
		if self.menu.skills.Q.drawQ and self.spells.Q:Ready() then
			self:DrawCircle(myHero.x, myHero.y, myHero.z, self.spells.Q:Range(), self.spells.Q:Color())
		end
		if self.menu.skills.W.drawW and self.spells.W:Ready() then
			self:DrawCircle(myHero.x, myHero.y, myHero.z, self.spells.W:Range(), self.spells.W:Color())
		end
		if self.menu.skills.E.drawE and self.spells.E:Ready() then
			self:DrawCircle(myHero.x, myHero.y, myHero.z, self.spells.E:Range(), self.spells.E:Color())
		end
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				local DmgTable = { Q = self.spells.Q:Damage(enemy), W = self.spells.W:Damage(enemy), E = self.spells.E:Damage(enemy)}
				local ExtraDmg = 0
				ExtraDmg = ExtraDmg + self:QBuffDmg(enemy)
				if self.ignite ~= nil and myHero:CanUseSpell(self.ignite) == READY then
					ExtraDmg = ExtraDmg + getDmg('IGNITE', enemy, myHero)
				end
				if DmgTable.W > enemy.health + ExtraDmg then
					self.enemyText[enemy.networkID] = 'W Kill'
				elseif DmgTable.Q > enemy.health + ExtraDmg then
					self.enemyText[enemy.networkID] = 'Q Kill'
				elseif DmgTable.E > enemy.health + ExtraDmg then
					self.enemyText[enemy.networkID] = 'E Kill'
				elseif DmgTable.Q + DmgTable.W > enemy.health + ExtraDmg then
					self.enemyText[enemy.networkID] = 'W + Q Kill'
				elseif DmgTable.E + DmgTable.W > enemy.health + ExtraDmg then
					self.enemyText[enemy.networkID] = 'E + W Kill'
				elseif DmgTable.Q + DmgTable.W + DmgTable.E > enemy.health + ExtraDmg then
					self.enemyText[enemy.networkID] = 'Q + W + E Kill'
				else
					self.enemyText[enemy.networkID] = 'Cant Kill Yet'
				end
				local pos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
				if self.enemyText[enemy.networkID] ~= nil then
					DrawText(self.enemyText[enemy.networkID], 12, pos.x, pos.y, ARGB(255,255,204,0))
				end
			end
		end
	end

	function Katarina:Combo(target)
		if self.menu.combo.useItems then
			self:UseItems(target)
		end
		if self.menu.skills.Q.comboQ then
			self.spells.Q:Cast(target)
		end
		if self.menu.skills.W.comboW then
			self.spells.W:Cast(target)
		end
		if not self.spells.Q:Ready() and self.menu.skills.E.comboE then
			if self.menu.combo.procQ then
				if not self.Q.throwing then
					self.spells.E:Cast(target)
				end
			else
				self.spells.E:Cast(target)
			end
		end
		if not self.spells.Q:Ready() and not self.spells.W:Ready() and not self.spells.E:Ready() then
			self.spells.R:Cast(target)
		end
	end

	function Katarina:Harass(target)
		if self.menu.skills.Q.harassQ then
			self.spells.Q:Cast(target)
		end
		if self.menu.skills.W.harassW then
			self.spells.W:Cast(target)
		end
		if not self.spells.Q:Ready() and self.menu.skills.harassE then
			if self.menu.harass.procQ then
				if not self.Q.throwing then
					self.spells.E:Cast(target)
				end
			else
				self.spells.Q:Cast(target)
			end
		end
	end

	function Katarina:Farm()
		self.enemyMinions:update()
		for i, minion in ipairs(self.enemyMinions.objects) do
			if self.menu.farming.farmWToggle then
				if ValidTarget(minion) and minion.health <= self.spells.W:Damage(minion) then
					self.spells.W:Cast(minion)
				end
			elseif self.menu.farming.farmQToggle or (self.menu.farming.farmQLast and self.menu.lasthitKey) then
				if ValidTarget(minion) and minion.health <= self.spells.Q:Damage(minion) then
					self.spells.Q:Cast(minion)
				end
			end
		end
	end

	function Katarina:Clear()
		local cleartarget = nil
		self.enemyMinions:update()
		self.otherMinions:update()
		self.jungleMinions:update()
		for i, minion in ipairs(self.enemyMinions.objects) do
			if ValidTarget(minion, 600) and (cleartarget == nil or not ValidTarget(cleartarget)) then
				cleartarget = minion
			end
		end
		for i, jungleminion in ipairs(self.jungleMinions.objects) do
			if ValidTarget(jungleminion, 600) and (cleartarget == nil or not ValidTarget(cleartarget)) then
				cleartarget = jungleminion
			end
		end
		for i, otherminion in ipairs(self.otherMinions.objects) do
			if ValidTarget(otherminion, 600) and (cleartarget == nil or not ValidTarget(cleartarget)) then
				cleartarget = otherminion
			end
		end
		if cleartarget ~= nil then
			if self.menu.skills.Q.clearQ then
				self.spells.Q:Cast(cleartarget)
			end
			if self.menu.skills.W.clearW then
				self.spells.W:Cast(cleartarget)
			end
			if self.menu.skills.E.clearE then
				self.spells.E:Cast(cleartarget)
			end
		end
	end

	function Katarina:KillSteal()
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, 700) then
				local DmgTable = { Q = self.spells.Q:Ready() and self.spells.Q:Damage(enemy) or 0, W = self.spells.W:Ready() and self.spells.W:Damage(enemy) or 0, E = self.spells.E:Ready() and self.spells.E:Damage(enemy) or 0}
				local ExtraDmg = 0
				if self.targetsWithQ[enemy.networkID] ~= nil then
					ExtraDmg = ExtraDmg + self:QBuffDmg(enemy)
				end
				if self.ignite ~= nil and myHero:CanUseSpell(self.ignite) == READY then
					ExtraDmg = ExtraDmg + getDmg('IGNITE', enemy, myHero)
				end
				if DmgTable.W > enemy.health + ExtraDmg then
					self.spells.W:Cast(enemy)
				elseif DmgTable.Q > enemy.health + ExtraDmg then
					self.spells.Q:Cast(enemy)
				elseif DmgTable.E > enemy.health + ExtraDmg then
					self.spells.E:Cast(enemy)
				elseif DmgTable.Q + DmgTable.W > enemy.health and GetDistance(enemy) <= self.spells.W:Range() + ExtraDmg then
					self.spells.W:Cast(enemy)
					self.spells.Q:Cast(enemy)
				elseif DmgTable.E + DmgTable.W > enemy.health + ExtraDmg then
					self.spells.E:Cast(enemy)
					self.spells.W:Cast(enemy)
				elseif DmgTable.Q + DmgTable.W + DmgTable.E > enemy.health + ExtraDmg then
					self.spells.E:Cast(enemy)
					self.spells.Q:Cast(enemy)
					self.spells.W:Cast(enemy)
				end
			elseif ValidTarget(enemy, self.spells.Q:Range() + 590) and (GetDistance(enemy) > self.spells.Q:Range()) then
				local ExtraDmg = 0
				if self.ignite ~= nil and myHero:CanUseSpell(self.ignite) == READY then
					ExtraDmg = ExtraDmg + getDmg('IGNITE', enemy, myHero)
				end
			 	if enemy.health <= (self.spells.Q:Damage(enemy) + ExtraDmg) then
					local WardPos = myHero + (Vector(enemy) - myHero):normalized()*590
					if WardPos then
						self:WardJump(WardPos.x, WardPos.z)
						self.spells.Q:Cast(enemy)
					end
				end
			end
		end
	end

	function Katarina:QBuffDmg(unit)
		local p = {dmg = {15,  30, 45,  60,   75},  apscaling = .15} -- QPassive Dmg
		local spellDmg  = p.dmg[myHero:GetSpellData(_Q).level] or 0
		local apscaling = p.apscaling or 0
		local totaldmg  = spellDmg + (apscaling * myHero.ap)
		return unit and myHero:CalcMagicDamage(unit, totaldmg)
	end

	function Katarina:DrawCircle(x, y, z, radius, color)
		local vPos1 = Vector(x, y, z)
		local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
		local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
		local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
		
		if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
			self:DrawCircleNextLvl(x, y, z, radius, 1, color, 300) 
		end
	end

	function Katarina:DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
		radius = radius or 300
		quality = math.max(8, self:Round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
		quality = 2 * math.pi / quality
		radius = radius * .92
		local points = {}
		
		for theta = 0, 2 * math.pi + quality, quality do
			local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
			points[#points + 1] = D3DXVECTOR2(c.x, c.y)
		end
		DrawLines2(points, width or 1, color or 4294967295)
	end

	function Katarina:Round(number)
		if number >= 0 then 
			return math.floor(number+.5) 
		else 
			return math.ceil(number-.5) 
		end
	end

	function Katarina:UseItems(target)
		for i, Item in pairs(self.items) do
			local Item = self.items[i]
			if GetInventoryItemIsCastable(Item.id) and GetDistanceSqr(target) <= Item.range*Item.range then
				CastItem(Item.id, target)
			end
		end
	end

	function Katarina:WardJump(x, y)
		if GetDistance(mousePos) then
			local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
			myHero:MoveTo(moveToPos.x, moveToPos.z)
		end	
		if self.spells.E:Ready() then
			local Jumped = false
			local WardDistance = 300
			for i, ally in ipairs(GetAllyHeroes()) do
				if ValidTarget(ally, self.spells.E:Range(), false) then
					if GetDistanceSqr(ally, mousePos) <= WardDistance*WardDistance then
						CastSpell(_E, ally)
						Jumped = true
						self.lastJump = GetTickCount() + 2000
					end
				end
			end
			self.allyMinions:update()
			for i, minion in pairs(self.allyMinions.objects) do
				if ValidTarget(minion, self.spells.E:Range(), false) then
					if GetDistanceSqr(minion, mousePos) <= WardDistance*WardDistance then
						CastSpell(_E, minion)
						Jumped = true
						self.lastJump = GetTickCount() + 2000
					end
				end
			end
			for i, Ward in pairs(self.wardsTable) do
				if GetDistanceSqr(mousePos) < 600 * 600 then
					if GetDistanceSqr(Ward, mousePos) < WardDistance*WardDistance then
					CastSpell(_E, Ward)
						Jumped = true
						self.lastJump = GetTickCount() + 2000
					end
				else
					if GetDistanceSqr(Ward) < self.spells.E:Range() * self.spells.E:Range() then
						CastSpell(_E, Ward)
					end
				end
			end

			if not Jumped and GetTickCount() >= self.lastJump then
				local Slot = nil
				if (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3340) or (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3350) or (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3361) or (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3362) then
					Slot = ITEM_7
				elseif GetInventorySlotItem(3154) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3154)) then
					Slot = GetInventorySlotItem(3154)
				elseif GetInventorySlotItem(3160) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(3160)) then
					Slot = GetInventorySlotItem(3160)
				elseif GetInventorySlotItem(2045) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(2045)) then
					Slot = GetInventorySlotItem(2045)
				elseif GetInventorySlotItem(2049) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(2049)) then
					Slot = GetInventorySlotItem(2049)
				elseif GetInventorySlotItem(2044) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(2044)) then
					Slot = GetInventorySlotItem(2044)
				elseif GetInventorySlotItem(2043) ~= nil and myHero:CanUseSpell(GetInventorySlotItem(2043)) then
					Slot = GetInventorySlotItem(2043)
				end			
				if Slot ~= nil then
					CastSpell(Slot, x, y)
					Jumped = true
					self.lastJump = GetTickCount() + 2000
				end
			end
		end
	end

	function Katarina:AutoIgnite()
		if myHero:CanUseSpell(self.ignite) == READY then
			for i, enemy in ipairs(GetEnemyHeroes()) do
				if ValidTarget(enemy, 600) and enemy.health <= getDmg('IGNITE', enemy, myHero) then
					CastSpell(self.ignite, enemy)
				end
			end
		end
	end

	function Katarina:SendPacket(packet)
		if packet.header == 0x00DE then -- castspell header
			packet.pos = 2
			if packet:DecodeF() == myHero.networkID then
				packet.pos = 26
				local spellid = packet:Decode1()
				if spellid == 3 then
					self.R.using = true
					self.R.last  = os.clock()
					print('started using R')
				end
			end
		end
	end

	function Katarina:ObjCreate(obj)
		if obj.valid and (string.find(obj.name, "Ward") ~= nil or string.find(obj.name, "Wriggle") ~= nil or string.find(obj.name, "Trinket")) then
			table.insert(self.wardsTable, obj)
		end
	end

	function Katarina:ObjDelete(obj)
		if obj then
			for i, ward in pairs(self.wardsTable) do
				if not ward.valid or obj.name == ward.name then
					table.remove(self.wardsTable, i)
				end
			end
		end
	end

	function Katarina:GainBuff(unit, buff)
		if buff.name == 'katarinaqmark' then
			self.targetsWithQ[unit.networkID] = true
			if self.Q.throwing then
				self.Q.throwing = false
			end
		end
	end

	function Katarina:LoseBuff(unit, buff)
		if buff.name == 'katarinaqmark' then
			self.targetsWithQ[unit.networkID] = nil
		end
		if unit.isMe and buff.name == "katarinarsound" then
			self.R.using = false
			self.R.last  = 0
			print('Ended Using R')
		end
	end

	function Katarina:Spells(unit, spell)
		if unit.isMe and spell.name == 'KatarinaQ' then
			self.Q.throwing = true
			self.Q.last     = os.clock()
		end
	end

	function Katarina:GetTarget()
		self.ts:update()
        if _G.MMA_Target and _G.MMA_Target.type == myHero.type then 
        	return _G.MMA_Target 
	    elseif _G.AutoCarry and  _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then 
	    	return _G.AutoCarry.Attack_Crosshair.target 
	    elseif self.ts.target and ValidTarget(self.ts.target) then
	    	return self.ts.target
	    end
	end

	function Katarina:LoadPriorityTable()
		--|> This bish is long for sake of cleaness is here
		self.priorityTable = {
			AP = {
				'Annie', 'Ahri', 'Akali', 'Anivia', 'Annie', 'Azir', 'Brand', 'Cassiopeia', 'Diana', 'Evelynn', 'FiddleSticks', 'Fizz', 'Gragas', 'Heimerdinger', 'Karthus',
				'Kassadin', 'Katarina', 'Kayle', 'Kennen', 'Leblanc', 'Lissandra', 'Lux', 'Malzahar', 'Mordekaiser', 'Morgana', 'Nidalee', 'Orianna',
				'Ryze', 'Sion', 'Swain', 'Syndra', 'Teemo', 'TwistedFate', 'Veigar', 'Viktor', 'Vladimir', 'Xerath', 'Ziggs', 'Zyra'
			},
			Support = {
				'Alistar', 'Blitzcrank', 'Braum', 'Janna', 'Karma', 'Leona', 'Lulu', 'Nami', 'Nunu', 'Sona', 'Soraka', 'Taric', 'Thresh', 'Zilean'
			},
			Tank = {
				'Amumu', 'Chogath', 'DrMundo', 'Galio', 'Hecarim', 'Malphite', 'Maokai', 'Nasus', 'Rammus', 'Sejuani', 'Nautilus', 'Shen', 'Singed', 'Skarner', 'Volibear',
				'Warwick', 'Yorick', 'Zac'
			},
			AD_Carry = {
				'Ashe', 'Caitlyn', 'Corki', 'Draven', 'Ezreal', 'Graves', 'Jayce', 'Jinx', 'Kalista', 'KogMaw', 'Lucian', 'MasterYi', 'MissFortune', 'Pantheon', 'Quinn', 'Shaco', 'Sivir',
				'Talon','Tryndamere', 'Tristana', 'Twitch', 'Urgot', 'Varus', 'Vayne', 'Yasuo','Zed'
			},
			Bruiser = {
				'Aatrox', 'Darius', 'Elise', 'Fiora', 'Gnar', 'Gangplank', 'Garen', 'Irelia', 'JarvanIV', 'Jax', 'Khazix', 'LeeSin', 'Nocturne', 'Olaf', 'Poppy',
				'Renekton', 'Rengar', 'Riven', 'RekSai', 'Rumble', 'Shyvana', 'Trundle', 'Udyr', 'Vi', 'MonkeyKing', 'XinZhao'
			}
		}
	end

	function Katarina:LoadItemsTable()
		self.items = {
			["BLACKFIRE"]	= { id = 3188, range = 750 },
			["BRK"]			= { id = 3153, range = 500 },
			["BWC"]			= { id = 3144, range = 450 },
			["DFG"]			= { id = 3128, range = 750 },
			["HXG"]			= { id = 3146, range = 700 },
			["ODYNVEIL"]	= { id = 3180, range = 525 },
			["DVN"]			= { id = 3131, range = 200 },
			["ENT"]			= { id = 3184, range = 350 },
			["HYDRA"]		= { id = 3074, range = 350 },
			["TIAMAT"]		= { id = 3077, range = 350 },
			["YGB"]			= { id = 3142, range = 350 }
		}
	end

	function Katarina:SetTablePriorities()
		local table = GetEnemyHeroes()
		if #table == 5 then
			for i, enemy in ipairs(table) do
				self:SetPriority(self.priorityTable.AD_Carry, enemy, 1)
				self:SetPriority(self.priorityTable.AP, enemy, 2)
				self:SetPriority(self.priorityTable.Support, enemy, 3)
				self:SetPriority(self.priorityTable.Bruiser, enemy, 4)
				self:SetPriority(self.priorityTable.Tank, enemy, 5)
			end
		elseif #table == 3 then
			for i, enemy in ipairs(table) do
				self:SetPriority(self.priorityTable.AD_Carry, enemy, 1)
				self:SetPriority(self.priorityTable.AP, enemy, 1)
				self:SetPriority(self.priorityTable.Support, enemy, 2)
				self:SetPriority(self.priorityTable.Bruiser, enemy, 2)
				self:SetPriority(self.priorityTable.Tank, enemy, 3)
			end
		else
			print('Too few champions to arrange priority!')
		end
	end

	function Katarina:SetPriority(table, hero, priority)
		for i = 1, #table do
			if hero.charName:find(table[i]) ~= nil then
				TS_SetHeroPriority(priority, hero.charName)
			end
		end
	end

--|> Spell Class cuz im lazy lul
class 'Spells'

	function Spells:__init(slot, range, name, type, color)
		self.slot   = slot
		self.range  = range
		self.name   = name
		self.type   = type
		self.string = self:SlotToString(slot)
		self.color  = color
	end

	function Spells:Cast(unit)
		if self:Ready() and GetDistance(unit) <= self.range then
			if self.type == 'targeted' then
				CastSpell(self.slot, unit)
			else
				CastSpell(self.slot)
			end
		end
	end

	function Spells:Color()
		return self.color
	end

	function Spells:Damage(target)
		return getDmg(self.string, target, myHero) or 0
	end

	function Spells:Data()
		return myHero:GetSpellData(self.slot)
	end

	function Spells:Range()
		return self.range
	end

	function Spells:Ready()
		return myHero:CanUseSpell(self.slot) == READY
	end

	function Spells:Slot()
		return self.slot
	end

	function Spells:SlotToString(slot)
		local strings = { [_Q] = 'Q', [_W] = 'W', [_E] = 'E', [_R] = 'R'}
		return strings[slot]
	end



--|> Self Initiation
Katarina = Katarina()

--|> Lewl Lewl Lewl Lewlite
LoadProtectedScript('VjUzEzdFTURpN0NFYN50TGhvRUxAbTNLRXlNeER2ZUVMRm1zSyB5TXlMMuXFU0DtM0lFeU19RXJlRRMHbTdHRXlNKi0XACgFLgdWKDF5THlGcmRFTEBuM0tFe01xSnJlRcpALTONBTlNf8cyZQVNQG0uykV4CXhGcuSETECtMstFpE35RO/lRUzdLbNLWnnNeUJyZUVIR20zSyQKPhw0BmVBSUBtMycqGCl5Qn9lRUwCDEAuc00JHCUdASBMRG4zS0UbOXlGcmVFTUBtM0tFeU15RnJlRUxAbTNLRXlNeUdyZUVNQG0zS0V5TXlGcmVFTEBtM0s=E58480610F088EB431C5643BA55EEA35')
SkeemInject("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", _ENV)