local mod	= DBM:NewMod("Akilzon", "DBM-ZulAman")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20210813015935")
mod:SetCreatureID(23574)
mod:SetEncounterID(1189, 2482)
mod:SetZone()
mod:SetUsedIcons(1)

mod:RegisterCombat("combat")
--mod:RegisterCombat("combat_yell", L.YellPull)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 43648"
)

local warnStorm			= mod:NewTargetNoFilterAnnounce(43648, 4)
local specWarnStorm		= mod:NewSpecialWarningSpell(43648, nil, nil, nil, 2, 2)

local timerStorm		= mod:NewCastTimer(8, 43648, nil, nil, nil, 2, nil, DBM_CORE_L.HEALER_ICON)
local timerStormCD		= mod:NewCDTimer(66, 43648, nil, nil, nil, 3)

local berserkTimer		= mod:NewBerserkTimer(480)

mod:AddSetIconOption("StormIcon", 43648, true, false, {1})

function mod:OnCombatStart(delay)
	timerStormCD:Start(50)
	berserkTimer:Start(-delay)
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(43648) then
		warnStorm:Show(args.destName)
		specWarnStorm:Show()
		specWarnStorm:Play("specialsoon")
		timerStorm:Start()
		timerStormCD:Start()
		if self.Options.StormIcon then
			self:SetIcon(args.destName, 1, 1)
		end
	end
end
