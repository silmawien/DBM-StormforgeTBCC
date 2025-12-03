local mod	= DBM:NewMod("Twins", "DBM-Sunwell")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20210623162544")
mod:SetCreatureID(25165, 25166)
mod:SetEncounterID(WOW_PROJECT_ID ~= (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5) and 727 or 2491)
mod:SetModelID(23334)
mod:SetUsedIcons(7, 8)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 9657 22442 45230 45347 45348",
	"SPELL_AURA_APPLIED_DOSE 45347 45348",
	"SPELL_CAST_START 45248",
	"SPELL_DAMAGE 45256",
	"SPELL_MISSED 45256",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

local warnBlade				= mod:NewSpellAnnounce(45248, 3)
local warnBlow				= mod:NewTargetAnnounce(45256, 3)
local warnConflag			= mod:NewTargetAnnounce(45333, 3)
local warnNova				= mod:NewTargetAnnounce(45329, 3)

local specWarnConflag		= mod:NewSpecialWarningYou(45333, nil, nil, nil, 1, 2)
local yellConflag			= mod:NewYell(45333, nil, true)
local specWarnNova			= mod:NewSpecialWarningYou(45329, nil, nil, nil, 1, 2)
local yellNova				= mod:NewYell(45329)
local specWarnPyro			= mod:NewSpecialWarningDispel(45230, "MagicDispeller", nil, 2, 1, 2)
local specWarnDarkTouch		= mod:NewSpecialWarningStack(45347, nil, 8, nil, nil, 1, 6)
local specWarnFlameTouch	= mod:NewSpecialWarningStack(45348, false, 5, nil, nil, 1, 6)

local specWarnSoak          = mod:NewSpecialWarningSoakPos(30616, nil, nil, nil, 4, 2)

local timerBladeCD			= mod:NewCDTimer(11.5, 45248, nil, "Melee", 2, 2)
local timerBlowCD			= mod:NewCDTimer(20, 45256, nil, nil, nil, 3)
local timerConflagCD		= mod:NewCDTimer(31, 45333, nil, nil, nil, 3)
local timerNovaCD			= mod:NewCDTimer(31, 45329, nil, nil, nil, 3)
local fireSoakCD            = mod:NewTimer(30, "Fire Soak", 22442, nil, nil, 2, nil, nil, 1, 3)
local shadowSoakCD          = mod:NewTimer(30, "Shadow Soak", 9657, nil, nil, 3, nil, nil, 1, 3)
local twinSoakCD            = mod:NewTimer(30, "Soak", 20228, nil, nil, 1, nil, nil, 1, 3)

local soakSoon             = mod:NewSpecialWarning("%s", nil, nil, nil, 3, 2)

local fireAffinity          = mod:NewCDTimer(75, 22442, nil, nil, nil, 3)
local shadowAffinity        = mod:NewCDTimer(75, 9657, nil, nil, nil, 3)

local timerConflag			= mod:NewCastTimer(3.5, 45333, nil, false, 2)
local timerNova				= mod:NewCastTimer(3.5, 45329, nil, false, 2)

local berserkTimer			= mod:NewBerserkTimer(360)

mod:AddBoolOption("RangeFrame", true)
mod:AddBoolOption("ConflagIcon", false)
mod:AddBoolOption("NovaIcon", false)

mod.vb.soakCounter = 0

function mod:OnCombatStart(delay)
	berserkTimer:Start(-delay)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show()
	end
	self.vb.soakCounter = 0
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	shadowSoakCD:Stop()
	fireSoakCD:Stop()
	twinSoakCD:Stop()
	self:Unschedule(WarnSoak)
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 45230 and not args:IsDestTypePlayer() then
		specWarnPyro:Show(args.destName)
		specWarnPyro:Play("dispelboss")
	elseif args.spellId == 45347 and args:IsPlayer() then
		if (args.amount or 1) >= 8 then
			specWarnDarkTouch:Show(args.amount)
			specWarnDarkTouch:Play("stackhigh")
		end
	elseif args.spellId == 45348 and args:IsPlayer() then
		if (args.amount or 1) >= 5 then
			specWarnFlameTouch:Show(args.amount)
			specWarnFlameTouch:Play("stackhigh")
		end
	elseif args.spellId == 9657 and args:IsPlayer() then
		shadowAffinity:Start()
		shadowSoakCD:Start(-15)
		self:ScheduleWarnSoak(0, 15)
		self.vb.soakCounter = 0
	elseif args.spellId == 22442 and args:IsPlayer() then
		fireAffinity:Start()
		fireSoakCD:Start(-15)
		self:ScheduleWarnSoak(0, 15)
		self.vb.soakCounter = 0
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_DAMAGE(_, _, _, _, _, destName, _, _, spellId)
	if spellId == 45256 then
		warnBlow:Show(destName)
		timerBlowCD:Start()
	end
end

function mod:SPELL_MISSED(_, _, _, _, _, _, _, _, spellId)
	if spellId == 45256 then
		timerBlowCD:Start()
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 45248 then
		warnBlade:Show()
		timerBladeCD:Start()
	end
end

function WarnSoak(count)
	if UnitIsGroupLeader("player") then
		if (count % 2 == 0) then
	 		SendChatMessage("*** First Soak in 5 seconds! ***", "RAID_WARNING")
			soakSoon:Show("Soak #1 soon")
		else
			SendChatMessage("*** Second Soak in 5 seconds! ***", "RAID_WARNING")
			soakSoon:Show("Soak #2 soon")
		end
	end
end

function mod:ScheduleWarnSoak(count, time)
	self:Unschedule(WarnSoak)
	self:Schedule(time - 5, WarnSoak, count)
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg, _, _, _, target)
	if (msg == L.Nova or msg:find(L.Nova)) and target then
		target = DBM:GetUnitFullName(target)
		timerNova:Start()
		timerNovaCD:Start()
		if target == UnitName("player") then
			specWarnNova:Show()
			specWarnNova:Play("targetyou")
			yellNova:Yell()
		else
			warnNova:Show(target)
		end
		if self.Options.NovaIcon then
			self:SetIcon(target, 7, 5)
		end
	elseif (msg == L.Conflag or msg:find(L.Conflag)) and target then
		target = DBM:GetUnitFullName(target)
		timerConflag:Start()
		timerConflagCD:Start()
		if target == UnitName("player") then
			specWarnConflag:Show()
			specWarnConflag:Play("targetyou")
			yellConflag:Yell()
		else
			warnConflag:Show(target)
		end
		if self.Options.ConflagIcon then
			self:SetIcon(target, 8, 5)
		end
	elseif msg:find("begins to cast Blast Nova") then
		if self.vb.soakCounter < 1 then
			self:ScheduleWarnSoak(1, 30)
			fireSoakCD:Start()
		end
		self.vb.soakCounter = self.vb.soakCounter + 1
	elseif msg:find("begins to summon Shadow Clones") then
		if self.vb.soakCounter < 1 then
			self:ScheduleWarnSoak(1, 30)
			shadowSoakCD:Start()
		end
		self.vb.soakCounter = self.vb.soakCounter + 1
	elseif msg:find("Magic Affinity has been disrupted") then
		fireSoakCD:Stop()
		shadowSoakCD:Stop()
		self:ScheduleWarnSoak(0, 15)
		twinSoakCD:Start(-15)
		self.vb.soakCounter = 0
	elseif msg:find("The twins begin to unleash powerful spells") then
		-- extra delay after every 2nd soak
		if (self.vb.soakCounter == 0) then
			self.vb.soakCounter = 1
			twinSoakCD:Start(30)
			self:ScheduleWarnSoak(1, 30)
		else
			self.vb.soakCounter = 0
			twinSoakCD:Start(45)
			self:ScheduleWarnSoak(0, 45)
		end
	end
end
