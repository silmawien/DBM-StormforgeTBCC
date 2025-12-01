local mod	= DBM:NewMod("Muru", "DBM-Sunwell")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20210623162544")
mod:SetCreatureID(25741)--25741 Muru, 25840 Entropius
mod:SetEncounterID(WOW_PROJECT_ID ~= (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5) and 728 or 2492)
mod:SetModelID(23404)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 42783 45996",
	"SPELL_CAST_SUCCESS 37063 41126 46177",
	"SPELL_SUMMON 46268 46282",
	"UNIT_DIED"
)

local warnHuman			= mod:NewAnnounce("WarnHuman", 4, 27778)
local warnVoid			= mod:NewAnnounce("WarnVoid", 4, 46087)
local warnDarkness		= mod:NewSpellAnnounce(45996, 2)
local warnPhase2		= mod:NewPhaseAnnounce(2)
local warnFiend			= mod:NewAnnounce("WarnFiend", 2, 46268)
local warnBlackHole		= mod:NewSpellAnnounce(46282, 3)

local warnWrathTargets  = mod:NewTargetNoFilterAnnounce(42783, 3)
local specWarnWrath		= mod:NewSpecialWarningMove(42783, nil, nil, nil, 3, 2)
local yellWrath	        = mod:NewYell(42783)

local timerFlameBurst   = mod:NewTimer(120, "Flame Burst", 41126, nil, nil, 3, nil, nil, 1, 3)

local specWarnVoidZone  = mod:NewSpecialWarningYou(37063, nil, nil, nil, 1, 2)
local yellVoidZone		= mod:NewYell(37063)

local timerHuman		= mod:NewTimer(60, "TimerHuman", 27778, nil, nil, 6)
local timerVoid			= mod:NewTimer(30, "TimerVoid", 46087, nil, nil, 6)
local timerNextDarkness	= mod:NewNextTimer(45, 45996, nil, nil, nil, 2)
local timerBlackHoleCD	= mod:NewCDTimer(15, 46282)
local timerPhase		= mod:NewTimer(10, "TimerPhase", 46087, nil, nil, 6)

local berserkTimer		= mod:NewBerserkTimer(600)

mod:AddSetIconOption("WrathIcons", 42783, true, false, {3, 2, 1})

mod.vb.humanCount = 1
mod.vb.voidCount = 1

local WrathTargets = {}
mod.vb.wrathIcon = 3

local function warnWrathTargets(self)
	if #WrathTargets > 2 then
		warnWrathTargets:Show(table.concat(WrathTargets, "<, >"))
	end
	self.vb.wrathIcon = 3
	table.wipe(WrathTargets)
end

local function HumanSpawn(self)
	warnHuman:Show(self.vb.humanCount)
	self.vb.humanCount = self.vb.humanCount + 1
	timerHuman:Start(nil, self.vb.humanCount)
	self:Schedule(60, HumanSpawn, self)
end

local function VoidSpawn(self)
	warnVoid:Show(self.vb.voidCount)
	self.vb.voidCount = self.vb.voidCount + 1
	timerVoid:Start(nil, self.vb.voidCount)
	self:Schedule(30, VoidSpawn, self)
end

local function phase2(self)
	self:SetStage(2)
	warnPhase2:Show()
	timerBlackHoleCD:Start(17)
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self.vb.humanCount = 1
	self.vb.voidCount = 1
	timerHuman:Start(5-delay, 1)
	timerVoid:Start(36.5-delay, 1)
	timerNextDarkness:Start(-delay)
	self:Schedule(5, HumanSpawn, self)
	self:Schedule(36.5, VoidSpawn, self)
	berserkTimer:Start(-delay)
	timerFlameBurst:Start(106-delay)
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 45996 and args:GetDestCreatureID() == 25741 then
		warnDarkness:Show()
		timerNextDarkness:Start()
	elseif args.spellId == 42783 then
		WrathTargets[#WrathTargets + 1] = args.destName
		if args:IsPlayer() then
			yellWrath:Yell()
			specWarnWrath:Show()
			specWarnWrath:Play("keepmove")
		end
		if self.Options.WrathIcons then
			self:SetIcon(args.destName, self.vb.wrathIcon, 7)
		end
		self.vb.wrathIcon = self.vb.wrathIcon - 1
		self:Unschedule(warnWrathTargets)
		self:Schedule(0.3, warnWrathTargets, self)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 46177 then
		timerNextDarkness:Stop()
		timerHuman:Stop()
		timerVoid:Stop()
		timerFlameBurst:Stop()
		timerPhase:Start()
	 	self:Unschedule(HumanSpawn)
		self:Unschedule(VoidSpawn)
		self:Schedule(10, phase2, self)
	elseif args.spellId == 41126 then
		-- Flame Burst
        timerFlameBurst:Start(120)
	elseif args.spellId == 37063 then
		if args:IsPlayer() then
			specWarnVoidZone:Show()
			specWarnVoidZone:Play("targetyou")
			yellVoidZone:Yell()
		end
	end
end

function mod:SPELL_SUMMON(args)
	if args.spellId == 46268 then
		warnFiend:Show()
	elseif args.spellId == 46282 then
		warnBlackHole:Show()
		timerBlackHoleCD:Start()
	end
end

function mod:UNIT_DIED(args)
	if self:GetCIDFromGUID(args.destGUID) == 25840 then
		DBM:EndCombat(self)
	end
end

