--[[
    Util functions that wrap my interface and the Blizzard's WoW Classic lua API code for ease of use
]]

--[[
	- DONE - PaperDollFrame_SetPrimaryStats();
	- WONT DO - PaperDollFrame_SetResistances();
	- DONE - PaperDollFrame_SetArmor();
	- WONT DO? - PaperDollFrame_SetAttackBothHands();
	- DONE - PaperDollFrame_SetDamage();
	- DONE - PaperDollFrame_SetAttackPower();
	- WONT DO? - PaperDollFrame_SetRangedAttack();
	- DONE - PaperDollFrame_SetRangedDamage(); - the same as SetDamage but using UnitRangedDamage
	- DONE - PaperDollFrame_SetRangedAttackPower();
]]

local function DebugBreakPrint()
    print("ERROR");
end

local function CSC_GetAppropriateDamage(unit, category)
    --[[ TODO: Find a way to check if this is a ranged unit
    if IsRangedWeapon() then
		local attackTime, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
		return minDamage, maxDamage, nil, nil, 0, 0, percent;
	else
		return UnitDamage(unit);
    end
	]]
	if category == "Melee" then
		return UnitDamage(unit);
	elseif category == "Ranged" then
		local attackTime, minDamage, maxDamage, bonusPos, bonusNeg, percent = UnitRangedDamage(unit);
		return minDamage, maxDamage, nil, nil, 0, 0, percent;
	end
end

local function CSC_PaperDollFrame_SetLabelAndText(statFrame, label, text, isPercentage, numericValue)
	if ( statFrame.Label ) then
        statFrame.Label:SetText(format(STAT_FORMAT, label));
	end
	if ( isPercentage ) then
		text = format("%d%%", numericValue + 0.5);
	end
	statFrame.Value:SetText(text);
    statFrame.numericValue = numericValue;
end

local function CSC_PaperDollFormatStat(name, base, posBuff, negBuff)
	local effective = max(0,base + posBuff + negBuff);
	local text = HIGHLIGHT_FONT_COLOR_CODE..name.." "..effective;
	if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
		text = text..FONT_COLOR_CODE_CLOSE;
	else 
		if ( posBuff > 0 or negBuff < 0 ) then
			text = text.." ("..base..FONT_COLOR_CODE_CLOSE;
		end
		if ( posBuff > 0 ) then
			text = text..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..posBuff..FONT_COLOR_CODE_CLOSE;
		end
		if ( negBuff < 0 ) then
			text = text..RED_FONT_COLOR_CODE.." "..negBuff..FONT_COLOR_CODE_CLOSE;
		end
		if ( posBuff > 0 or negBuff < 0 ) then
			text = text..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE;
		end

		-- if there is a negative buff then show the main number in red, even if there are
		-- positive buffs. Otherwise show the number in green
		if ( negBuff < 0 ) then
			effective = RED_FONT_COLOR_CODE..effective..FONT_COLOR_CODE_CLOSE;
		end
	end
    
    return effective, text;
end

-- PRIMARY STATS --
function CSC_PaperDollFrame_SetPrimaryStats(statFrames, unit)
	
	local statIndexTable = {
		"STRENGTH",
		"AGILITY",
		"STAMINA",
		"INTELLECT",
		--"SPIRIT", -- fix for Classic
	}

	-- Fix for classic (NUM_STATS instead of NUM_STATS-1)
	for i=1, NUM_STATS-1, 1 do
		local frameText;

		local stat;
		local effectiveStat;
		local posBuff;
		local negBuff;
		stat, effectiveStat, posBuff, negBuff = UnitStat(unit, i);
		
		-- Set the tooltip text
		local tooltipText = HIGHLIGHT_FONT_COLOR_CODE.._G["SPELL_STAT"..i.."_NAME"].." ";

		-- Get class specific tooltip for that stat
		local temp, classFileName = UnitClass(unit);
		local classStatText = _G[strupper(classFileName).."_"..statIndexTable[i].."_".."TOOLTIP"];
		-- If can't find one use the default
		if ( not classStatText ) then
			classStatText = _G["DEFAULT".."_"..statIndexTable[i].."_".."TOOLTIP"];
		end

		if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
			--text:SetText(effectiveStat);
			frameText = effectiveStat;
			statFrames[i].tooltip = tooltipText..effectiveStat..FONT_COLOR_CODE_CLOSE;
			statFrames[i].tooltip2 = classStatText;
		else 
			tooltipText = tooltipText..effectiveStat;
			if ( posBuff > 0 or negBuff < 0 ) then
				tooltipText = tooltipText.." ("..(stat - posBuff - negBuff)..FONT_COLOR_CODE_CLOSE;
			end
			if ( posBuff > 0 ) then
				tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..posBuff..FONT_COLOR_CODE_CLOSE;
			end
			if ( negBuff < 0 ) then
				tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..negBuff..FONT_COLOR_CODE_CLOSE;
			end
			if ( posBuff > 0 or negBuff < 0 ) then
				tooltipText = tooltipText..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE;
			end
			statFrames[i].tooltip = tooltipText;
			statFrames[i].tooltip2= classStatText;

			-- If there are any negative buffs then show the main number in red even if there are
			-- positive buffs. Otherwise show in green.
			if ( negBuff < 0 ) then
				frameText = RED_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE;
			else
				frameText = GREEN_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE;
			end
		end
		CSC_PaperDollFrame_SetLabelAndText(statFrames[i], _G["SPELL_STAT"..i.."_NAME"], frameText, false, effectiveStat);
		statFrames[i]:Show();
	end
end

-- DAMAGE --
function CSC_PaperDollFrame_SetDamage(statFrame, unit, category)

    statFrame:SetScript("OnEnter", CharacterDamageFrame_OnEnter)
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
    end)

    local speed, offhandSpeed = UnitAttackSpeed(unit);
    local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = CSC_GetAppropriateDamage(unit, category);
    
    local displayMin = max(floor(minDamage),1);
    local displayMax = max(ceil(maxDamage),1);
    
    minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
    maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;
    
    local baseDamage = (minDamage + maxDamage) * 0.5;
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
	local totalBonus = (fullDamage - baseDamage);
	local damagePerSecond = (max(fullDamage,1) / speed);
    local damageTooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1);
    
    local colorPos = "|cff20ff20";
    local colorNeg = "|cffff2020";
    
    -- epsilon check
	if ( totalBonus < 0.1 and totalBonus > -0.1 ) then
		totalBonus = 0.0;
    end
    
    local damageText;

    if ( totalBonus == 0 ) then
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText = displayMin.." - "..displayMax;
		else
			damageText = displayMin.."-"..displayMax;
		end
	else
		-- set bonus color and display
		local color;
		if ( totalBonus > 0 ) then
			color = colorPos;
		else
			color = colorNeg;
		end
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText = color..displayMin.." - "..displayMax.."|r";
		else
			damageText = color..displayMin.."-"..displayMax.."|r";
		end
		if ( physicalBonusPos > 0 ) then
			damageTooltip = damageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			damageTooltip = damageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percent > 1 ) then
			damageTooltip = damageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
		elseif ( percent < 1 ) then
			damageTooltip = damageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
		end
    end
    
    CSC_PaperDollFrame_SetLabelAndText(statFrame, DAMAGE, damageText, false, displayMax);

    statFrame.damage = damageTooltip;
	statFrame.attackSpeed = speed;
    statFrame.dps = damagePerSecond;
    statFrame.unit = unit; -- not in classic

    -- If there's an offhand speed then add the offhand info to the tooltip
	if ( offhandSpeed and category == "Melee") then
		minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
		maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
		local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
		local offhandDamagePerSecond = (max(offhandFullDamage,1) / offhandSpeed);
		local offhandDamageTooltip = max(floor(minOffHandDamage),1).." - "..max(ceil(maxOffHandDamage),1);
		if ( physicalBonusPos > 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percent > 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
		elseif ( percent < 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
		end
		statFrame.offhandDamage = offhandDamageTooltip;
		statFrame.offhandAttackSpeed = offhandSpeed;
		statFrame.offhandDps = offhandDamagePerSecond;
	else
		statFrame.offhandAttackSpeed = nil;
    end

    statFrame:Show();
end

function CSC_PaperDollFrame_SetMeleeAttackPower(statFrame, unit)
    
	local base, posBuff, negBuff = UnitAttackPower(unit);
    
    local valueText, tooltipText = CSC_PaperDollFormatStat(MELEE_ATTACK_POWER, base, posBuff, negBuff);
    local valueNum = max(0, base + posBuff + negBuff);
    CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_ATTACK_POWER, valueText, false, valueNum);
    statFrame.tooltip = tooltipText;
    statFrame.tooltip2 = format(MELEE_ATTACK_POWER_TOOLTIP, max((base+posBuff+negBuff), 0)/ATTACK_POWER_MAGIC_NUMBER);
	statFrame:Show();
end

function CSC_PaperDollFrame_SetRangedAttackPower(statFrame, unit)
    
	-- If no ranged attack then set to n/a
    if ( PaperDollFrame.noRanged ) then
        -- TODO: we need to set the label too
        statFrame.Value:SetText(NOT_APPLICABLE);
		statFrame.tooltip = nil;
		return;
	end
    if ( HasWandEquipped() ) then
        -- TODO: we need to set the label too
        statFrame.Value:SetText("--");
		statFrame.tooltip = nil;
		return;
	end

	local base, posBuff, negBuff = UnitRangedAttackPower(unit);
    local valueText, tooltipText = CSC_PaperDollFormatStat(RANGED_ATTACK_POWER, base, posBuff, negBuff);
    local valueNum = max(0, base + posBuff + negBuff);
    CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_ATTACK_POWER, valueText, false, valueNum);
	statFrame.tooltip = tooltipText;
    statFrame.tooltip2 = format(RANGED_ATTACK_POWER_TOOLTIP, base/ATTACK_POWER_MAGIC_NUMBER);
    statFrame:Show();
end

-- SECONDARY STATS --
function CSC_PaperDollFrame_SetCritChance(statFrame, unit, category)
    -- TODO: Maybe implement it differently (have to test when the game launches)
    -- Warning: For some reason these return the same value on retail.... will have to check on Classic
    local critChance;

    if category == "Melee" then
        critChance = GetCritChance();
    elseif category == "Ranged" then
        critChance = GetRangedCritChance();
    elseif category == "Spell" then
        critChance = GetSpellCritChance();
    end

    CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_CRITICAL_STRIKE, critChance, true, critChance);
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_CRITICAL_STRIKE).." "..format("%.2F%%", critChance)..FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = "";
    statFrame:Show();
end

function CSC_PaperDollFrame_SetHitChance(statFrame, unit)
	local hitChance = Round(GetHitModifier());
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Hit", hitChance, true, hitChance);
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE.."Chance to hit enemies at your level"..FONT_COLOR_CODE_CLOSE;
	statFrame:Show();
end

function CSC_PaperDollFrame_SetAttackSpeed(statFrame, unit)
	local speed, offhandSpeed = UnitAttackSpeed(unit);

	local displaySpeed = format("%.2F", speed);
	if ( offhandSpeed ) then
		offhandSpeed = format("%.2F", offhandSpeed);
	end
	if ( offhandSpeed ) then
		displaySpeed =  BreakUpLargeNumbers(displaySpeed).." / ".. offhandSpeed;
	else
		displaySpeed =  BreakUpLargeNumbers(displaySpeed);
	end
	CSC_PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, displaySpeed, false, speed);
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED).." "..displaySpeed..FONT_COLOR_CODE_CLOSE;
	statFrame:Show();
end

-- DEFENSES --
function CSC_PaperDollFrame_SetArmor(statFrame, unit)

	local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor(unit);
	negBuff = 0; -- Remove for Classic

	if (unit ~= "player") then
		--[[ In 1.12.0, UnitArmor didn't report positive / negative buffs for units that weren't the active player.
			 This hack replicates that behavior for the UI. ]]
		base = effectiveArmor;
		armor = effectiveArmor;
		posBuff = 0;
		negBuff = 0;
	end

	local playerLevel = UnitLevel(unit);
	local armorReduction = effectiveArmor/((85 * playerLevel) + 400);
	armorReduction = 100 * (armorReduction/(armorReduction + 1));

	local valueText, tooltipText = CSC_PaperDollFormatStat(ARMOR, base, posBuff, negBuff);
	local valueNum = max(0, base + posBuff + negBuff);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_ARMOR, valueText, false, valueNum);
	statFrame.tooltip = tooltipText;
    statFrame.tooltip2 = format(ARMOR_TOOLTIP, playerLevel, armorReduction);
	statFrame:Show();
end

function CSC_PaperDollFrame_SetDefense(statFrame, unit)
	--local base, modifier = UnitDefense(unit); -- Classic
	local base, modifier = 0, 0;
	local DEFENSE_COLON = "Defense"; -- Remove for classic

	local posBuff = 0;
	local negBuff = 0;
	if ( modifier > 0 ) then
		posBuff = modifier;
	elseif ( modifier < 0 ) then
		negBuff = modifier;
	end
	local valueText, tooltipText = CSC_PaperDollFormatStat(DEFENSE_COLON, base, posBuff, negBuff);
	local valueNum = max(0, base + posBuff + negBuff);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, "Defense", valueText, false, valueNum);
	statFrame.tooltip = tooltipText;
	statFrame:Show();
end

function CSC_PaperDollFrame_SetDodge(statFrame, unit)
	local chance = GetDodgeChance();
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_DODGE, chance, true, chance);
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE));
	statFrame:Show();
end

function CSC_PaperDollFrame_SetParry(statFrame, unit)
	local chance = GetParryChance();
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_PARRY, chance, true, chance);
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY));
	statFrame:Show();
end

local function CSC_PaperDollFrame_GetArmorReduction(armor, attackerLevel)
	return C_PaperDollInfo.GetArmorEffectiveness(armor, attackerLevel) * 100;
end

local function CSC_PaperDollFrame_GetArmorReductionAgainstTarget(armor)
	local armorEffectiveness = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(armor);
	if ( armorEffectiveness ) then
		return armorEffectiveness * 100;
	end
end

function CSC_PaperDollFrame_SetBlock(statFrame, unit)
	local chance = GetBlockChance();
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_BLOCK, chance, true, chance);
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE;

	local shieldBlockArmor = GetShieldBlock();
	local blockArmorReduction = CSC_PaperDollFrame_GetArmorReduction(shieldBlockArmor, UnitEffectiveLevel(unit));
	local blockArmorReductionAgainstTarget = CSC_PaperDollFrame_GetArmorReductionAgainstTarget(shieldBlockArmor);

	statFrame.tooltip2 = CR_BLOCK_TOOLTIP:format(blockArmorReduction);
	if (blockArmorReductionAgainstTarget) then
		statFrame.tooltip3 = format(STAT_BLOCK_TARGET_TOOLTIP, blockArmorReductionAgainstTarget);
	else
		statFrame.tooltip3 = nil;
	end
	statFrame:Show();
end

function CSC_PaperDollFrame_SetStagger(statFrame, unit)
	local stagger, staggerAgainstTarget = C_PaperDollInfo.GetStaggerPercentage(unit);
	CSC_PaperDollFrame_SetLabelAndText(statFrame, STAT_STAGGER, stagger, true, stagger);

	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAGGER).." "..string.format("%.2F%%",stagger)..FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = format(STAT_STAGGER_TOOLTIP, stagger);
	if (staggerAgainstTarget) then
		statFrame.tooltip3 = format(STAT_STAGGER_TARGET_TOOLTIP, staggerAgainstTarget);
	else
		statFrame.tooltip3 = nil;
	end

	statFrame:Show();
end
