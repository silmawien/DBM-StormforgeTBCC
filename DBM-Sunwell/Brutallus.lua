local mod	= DBM:NewMod("Brutallus", "DBM-Sunwell")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20210623162544")
mod:SetCreatureID(24882)
mod:SetEncounterID(WOW_PROJECT_ID ~= (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5) and 725 or 2489)
mod:DisableESCombatDetection()--ES fires for the RP event that has nothing to do with engaging boss
mod:SetModelID(22711)
mod:SetUsedIcons(1, 2, 3, 4, 5, 6, 7, 8)
mod:SetHotfixNoticeRev(20200726000000)--2020, 7, 26
mod:SetMinSyncRevision(20200726000000)--2020, 7, 26

mod:RegisterCombat("yell", L.Pull)
mod.disableHealthCombat = true

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 45150",
	"SPELL_AURA_APPLIED 31944 20478 46394 45185 45150",
	"SPELL_AURA_APPLIED_DOSE 45150",
	"SPELL_AURA_REMOVED 31944 20478 46394",
	"SPELL_MISSED 46394"
)

local warnMeteor		= mod:NewSpellAnnounce(45150, 3)
local warnBurn			= mod:NewTargetAnnounce(46394, 3, nil, false, 2)
local warnStomp			= mod:NewTargetAnnounce(45185, 3, nil, "Tank", 2)
local warningFlameTargets	= mod:NewTargetNoFilterAnnounce(31944, 4)

local specWarnMeteor	= mod:NewSpecialWarningStack(45150, nil, 4, nil, nil, 1, 6)
local specWarnBurn		= mod:NewSpecialWarningYou(46394, nil, nil, nil, 1, 2)
local specWarnArmageddon= mod:NewSpecialWarningYou(20478, nil, nil, nil, 1, 2)
local specWarnFlameWreath	= mod:NewSpecialWarningMove(31944, nil, nil, nil, 3, 2)

local timerMeteorCD		= mod:NewCDTimer(12, 45150, nil, nil, nil, 3)
local timerStompCD		= mod:NewCDTimer(31, 45185, nil, nil, nil, 2)
local timerBurn			= mod:NewTargetTimer(60, 46394, nil, "false", 2, 3)
local timerBurnCD		= mod:NewCDTimer(20, 46394, nil, nil, nil, 3)
local timerArmageddon	= mod:NewCDTimer(40, 20478, nil, nil, nil, 2)
local timerFlame			= mod:NewBuffActiveTimer(20.2, 31944, nil, nil, nil, 3, nil, DBM_CORE_L.DEADLY_ICON)

-- timertype = "target", timer, spellId, timerText, optionDefault, optionName (2?), colorType (3)

local yellArmageddon	= mod:NewYell(20478)
local yellBurn			= mod:NewYell(46394)
local yellDoomfire      = mod:NewYell(31944)

local berserkTimer		= mod:NewBerserkTimer(360)

mod:AddSetIconOption("BurnIcon", 46394, true, false, {1, 2, 3})
mod:AddSetIconOption("WreathIcons", 31944, true, false, {7, 8})

mod:AddRangeFrameOption(46394, 4)

mod.vb.burnIcon = 3

local WreathTargets = {}
mod.vb.flameWreathIcon = 8

local debuffName = DBM:GetSpellInfo(46394)

local DebuffFilter
do
	DebuffFilter = function(uId)
		return DBM:UnitDebuff(uId, debuffName)
	end
end

local function warnFlameWreathTargets(self)
	if #WreathTargets > 1 then
		warningFlameTargets:Show(table.concat(WreathTargets, "<, >"))
		timerFlame:Start()
	end
	self.vb.flameWreathIcon = 8
	table.wipe(WreathTargets)
end

function mod:OnCombatStart(delay)
	self.vb.burnIcon = 3
	self.vb.flameWreathIcon = 8
	timerBurnCD:Start(-delay)
	timerStompCD:Start(-delay)
	timerArmageddon:Start(-delay)
	berserkTimer:Start(-delay)
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 46394 then
		warnBurn:Show(args.destName)
		timerBurn:Start(args.destName)
		if self:AntiSpam(19, 1) then
			timerBurnCD:Start()
		end
		if self.Options.BurnIcon then
			self:SetIcon(args.destName, self.vb.burnIcon)
		end
		if self.vb.burnIcon == 1 then
			self.vb.burnIcon = 3
		else
			self.vb.burnIcon = self.vb.burnIcon - 1
		end
		if args:IsPlayer() then
			specWarnBurn:Show()
			specWarnBurn:Play("targetyou")
			yellBurn:Yell()
		end
		if self.Options.RangeFrame then
			if DBM:UnitDebuff("player", args.spellName) then--You have debuff, show everyone
				DBM.RangeCheck:Show(4, nil)
			else--You do not have debuff, only show players who do
				DBM.RangeCheck:Show(4, DebuffFilter)
			end
		end
	elseif args.spellId == 45185 then
		warnStomp:Show(args.destName)
		timerStompCD:Start()
	elseif args.spellId == 45150 and args:IsPlayer() then
		local amount = args.amount or 1
		if amount >= 4 then
			specWarnMeteor:Show(amount)
			specWarnMeteor:Play("stackhigh")
		end
	elseif args.spellId == 20478 then
		if args:IsPlayer() then
			yellArmageddon:Yell()
		end
		timerArmageddon:Start()
	elseif args.spellId == 31944 then
		WreathTargets[#WreathTargets + 1] = args.destName
		if args:IsPlayer() then
			yellDoomfire:Yell()
			specWarnFlameWreath:Show()
			specWarnFlameWreath:Play("keepmove")
		end
		if self.Options.WreathIcons then
			self:SetIcon(args.destName, self.vb.flameWreathIcon, 20)
		end
		self.vb.flameWreathIcon = self.vb.flameWreathIcon - 1
		self:Unschedule(warnFlameWreathTargets)
		self:Schedule(0.3, warnFlameWreathTargets, self)
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 46394 then
		if self.Options.BurnIcon then
			self:SetIcon(args.destName, 0)
		end
	elseif args.spellId == 20478 then
		self:SetIcon(args.destName, 0)
	elseif args.spellId == 31944 and self.Options.WreathIcons then
		self:SetIcon(args.destName, 0)
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 45150 then
		warnMeteor:Show()
		timerMeteorCD:Start()
	end
end

function mod:SPELL_MISSED(_, _, _, _, _, _, _, _, spellId)
	if spellId == 46394 then
		warnBurn:Show("MISSED")
		if self:AntiSpam(19, 1) then
			timerBurnCD:Start()
		end
	end
end
