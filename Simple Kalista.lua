if myHero.charName ~= 'Kalista' then return end

require 'Prodiction'
local PassiveTargets = {}

function OnLoad()
	TargetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1150, DAMAGE_MAGIC)
	TargetSelector.name = 'Kalista'
	Menu = scriptConfig('Simple Kalista', 'Kalista')
		Menu:addSubMenu('combo', 'combo')
			Menu.combo:addParam('key', 'Combo Key', SCRIPT_PARAM_ONKEYDOWN, false, 88)
		Menu:addSubMenu('harass', 'harass')
			Menu.harass:addParam('key', 'Harass Key', SCRIPT_PARAM_ONKEYDOWN, false, 67)
			Menu.harass:addParam('minMana', 'Q Min Mana %', SCRIPT_PARAM_SLICE, 55, 0, 100, -1)
		Menu:addSubMenu('ks', 'ks')
			Menu.ks:addParam('qks', 'KS with Q', SCRIPT_PARAM_ONOFF, true)
			Menu.ks:addParam('eks', 'KS with E', SCRIPT_PARAM_ONOFF, true)
	Menu:addTS(TargetSelector)
	PrintChat('Simple Kalista Loaded')

end

function OnTick()
	TargetSelector:update()
	local Target = ValidTarget(TargetSelector.target) and TargetSelector.target
	if Target then
		if Menu.combo.key then
			CastQ(Target)
		end
		if Menu.harass.key and (myHero.mana >= (myHero.maxMana * (Menu.harass.minMana / 100))) then
			CastQ(Target)
		end
	end
	if Menu.ks.qks then
		for _, enemy in ipairs(GetEnemyHeroes()) do
			if enemy.health < QDmg(enemy) then
				CastQ(unit)
			end
		end
	end
	for _, enemy in ipairs(GetEnemyHeroes()) do
		for i, passive in pairs(PassiveTargets) do
			if passive.target == enemy then
				if Menu.ks.eks then
					if enemy.health < EDmg(enemy, passive.stacks) and GetDistance(enemy) < 1000 then
						CastSpell(_E)
					end
				end
				if Menu.combo.key and GetDistance(enemy) > 500 and GetDistance(enemy) < 1000 and passive.stacks > 3 then
					CastSpell(_E)
				end 
			end
		end
	end
end

function OnGainBuff(unit, buff)
	if buff.source == myHero and buff.name == 'kalistaexpungemarker' then
		local insert = {target = unit, stacks = 1}
		table.insert(PassiveTargets, insert)
		--print(unit.charName..' now has 1 stack')
	end
end

function OnUpdateBuff(unit, buff)
	if buff.source == myHero and buff.name == 'kalistaexpungemarker' then
		for i, passive in pairs(PassiveTargets) do
			if passive.target == unit then
				local stacks = passive.stacks
				passive.stacks = stacks + 1
				--print(unit.charName..' now has '..passive.stacks..' stacks')
			end
		end
	end
end

function OnLoseBuff(unit, buff)
	if buff.name == 'kalistaexpungemarker' then
		for i, passive in pairs(PassiveTargets) do
			if passive.target == unit then
				table.remove(PassiveTargets, i)
				--print(unit.charName..' now has 0 stacks')
			end
		end
	end
end

function CastQ(unit)
	if ValidTarget(unit, 1150) then
		local pos, info = Prodiction.GetPrediction(unit, 1150, 1200, .46, 30)
		if info.collision() == false and pos then
			CastSpell(_Q, pos.x, pos.z)
		end
	end
end

function QDmg(unit)
	local pierce    = {10, 70, 130, 190, 250}
	local spellDmg  = pierce[myHero:GetSpellData(_Q).level] or 0
	local totaldmg  = spellDmg + myHero.totalDamage
	return unit and myHero:CalcDamage(unit, totaldmg) or 0
end

function EDmg(unit, stacks)
	local first = {
		dmg = {20, 30, 40, 50, 60},
		scaling = .60
	}
	local adds = {
		dmg = {5, 9, 14, 20, 27},
		scaling = {.15, .18, .21, .24, .27}
	}
	if unit and stacks > 0 then
		local mainDmg  = first.dmg[myHero:GetSpellData(_E).level] + (first.scaling * myHero.totalDamage)
		local extraDmg = (stacks > 1 and (adds.dmg[myHero:GetSpellData(_E).level] + (adds.scaling[myHero:GetSpellData(_E).level] * myHero.totalDamage)) * (stacks - 1)) or 0
		return myHero:CalcDamage(unit, (mainDmg + extraDmg))
	end
end