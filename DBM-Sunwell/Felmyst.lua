local mod	= DBM:NewMod("Felmyst", "DBM-Sunwell")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20210623162544")
mod:SetCreatureID(25038)
mod:SetEncounterID(WOW_PROJECT_ID ~= (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5) and 726 or 2490)
mod:SetModelID(22838)
mod:SetUsedIcons(8, 7)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 45855 45866",
	"SPELL_AURA_REMOVED 45855",
	"SPELL_CAST_START 45855",
	"SPELL_SUMMON 45392",
	"RAID_BOSS_EMOTE",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_SPELLCAST_SUCCEEDED"
)

local warnEncaps			= mod:NewTargetAnnounce(45665, 4)
local warnVapor				= mod:NewTargetAnnounce(45402, 3)
local warnPhase				= mod:NewAnnounce("WarnPhase", 1, 31550)
local warningFlameTargets	= mod:NewTargetNoFilterAnnounce(45855, 4)

--local specWarnGas			= mod:NewSpecialWarningSpell(45855, "Healer", nil, nil, 1, 2)
local specWarnCorrosion		= mod:NewSpecialWarningTaunt(45866, nil, nil, nil, 1, 2)
local specWarnEncaps		= mod:NewSpecialWarningYou(45665, nil, nil, nil, 1, 2)
local yellEncaps			= mod:NewYell(45665)
local specWarnEncapsNear	= mod:NewSpecialWarningClose(45665, nil, nil, nil, 1, 2)
local specWarnVapor			= mod:NewSpecialWarningYou(45402, nil, nil, nil, 1, 2)
local specWarnBreath		= mod:NewSpecialWarningCount(45717, nil, nil, nil, 3, 2)
local specWarnFlameWreath	= mod:NewSpecialWarningMove(45855, nil, nil, nil, 3, 2)

local timerGasCD			= mod:NewCDTimer(19, 45855, nil, nil, nil, 3)
local timerCorrosion		= mod:NewTargetTimer(10, 45866, nil, "Tank", 2, 5, nil, DBM_CORE_L.TANK_ICON)
local timerEncaps			= mod:NewTargetTimer(7, 45665, nil, nil, nil, 3)
local timerBreath			= mod:NewCDCountTimer(17, 45717, nil, nil, nil, 3, nil, DBM_CORE_L.DEADLY_ICON)
local timerPhase			= mod:NewTimer(60, "TimerPhase", 31550, nil, nil, 6)

local berserkTimer			= mod:NewBerserkTimer(45855)

local yellGas		        = mod:NewYell(45855)

mod:AddBoolOption("EncapsIcon", true)
mod:AddBoolOption("VaporIcon", true)

mod:AddSetIconOption("WreathIcons", 45855, true, false, {6, 7, 8})

mod.vb.breathCounter = 0

local WreathTargets = {}
mod.vb.flameWreathIcon = 8

local function warnFlameWreathTargets(self)
	if #WreathTargets > 2 then
		warningFlameTargets:Show(table.concat(WreathTargets, "<, >"))
		--timerFlame:Start()
		self:BossTargetScanner(25038, "EncapsulateTarget", 0.25, 60)
	end
	self.vb.flameWreathIcon = 8
	table.wipe(WreathTargets)
end

function mod:Groundphase()
	self.vb.breathCounter = 0
	warnPhase:Show(L.Ground)
	timerGasCD:Start(17)
	timerPhase:Start(60, L.Air)
end

function mod:EncapsulateTarget(targetname, uId)
	if not targetname then return end
	timerEncaps:Start(targetname)
	if self.Options.EncapsIcon then
		self:SetIcon(targetname, 7, 5)
	end
	if targetname == UnitName("player") then
		specWarnEncaps:Show()
		specWarnEncaps:Play("targetyou")
		yellEncaps:Yell()
	elseif self:CheckNearby(21, targetname) then
		specWarnEncapsNear:Show(targetname)
		specWarnEncapsNear:Play("runaway")
	else
		warnEncaps:Show(targetname)
	end
end

function mod:OnCombatStart(delay)
	self.vb.breathCounter = 0
	self.vb.flameWreathIcon = 8
	timerGasCD:Start(17-delay)
	timerPhase:Start(-delay, L.Air)
	berserkTimer:Start(-delay)
end


function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 45866 and not self:IsTrivial() then
		timerCorrosion:Start(args.destName)
		if not args:IsPlayer() then
			specWarnCorrosion:Show(args.destName)
			specWarnCorrosion:Play("tauntboss")
		end
	elseif args.spellId == 45855 then
		WreathTargets[#WreathTargets + 1] = args.destName
		if args:IsPlayer() then
			yellGas:Yell()
			specWarnFlameWreath:Show()
			specWarnFlameWreath:Play("keepmove")
		end
		if self.Options.WreathIcons then
			self:SetIcon(args.destName, self.vb.flameWreathIcon)
		end
		self.vb.flameWreathIcon = self.vb.flameWreathIcon - 1
		self:Unschedule(warnFlameWreathTargets)
		self:Schedule(0.3, warnFlameWreathTargets, self)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 45855 then
		if self.Options.WreathIcons then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:SPELL_SUMMON(args)
	if args.spellId == 45392 then
		if args.sourceName == UnitName("player") then
			specWarnVapor:Show()
			specWarnVapor:Play("targetyou")
		else
			warnVapor:Show(args.sourceName)
		end
		if self.Options.VaporIcon then
			self:SetIcon(args.sourceName, 8, 10)
		end
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 45855 then
		timerGasCD:Start()
		if not self:IsTrivial() then
			--specWarnGas:Show()
			--specWarnGas:Play("helpdispel")
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.AirPhase or msg:find(L.AirPhase) then
		self.vb.breathCounter = 0
		warnPhase:Show(L.Air)
		timerGasCD:Stop()
		timerBreath:Start(42, 1)
		timerPhase:Start(99, L.Ground)
		self:ScheduleMethod(99, "Groundphase")
	end
end

function mod:RAID_BOSS_EMOTE(msg)
	if msg == L.Breath or msg:find(L.Breath) then
		self.vb.breathCounter = self.vb.breathCounter + 1
		specWarnBreath:Show(self.vb.breathCounter)
		specWarnBreath:Play("breathsoon")
		if self.vb.breathCounter < 3 then
			timerBreath:Start(nil, self.vb.breathCounter+1)
		end
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	--if spellId == 45661 and self:AntiSpam(2, 1) then
	--	self:BossTargetScanner(25038, "EncapsulateTarget", 0.05, 10)
	--end
end
