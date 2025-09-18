local mod	= DBM:NewMod("Janalai", "DBM-ZulAman")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20210813015935")
mod:SetCreatureID(23578)
mod:SetEncounterID(1191, 2484)
mod:SetZone()
mod:SetUsedIcons(1)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"CHAT_MSG_MONSTER_YELL"
)

local warnAddsSoon		= mod:NewSoonAnnounce(43962, 3)

local specWarnAdds		= mod:NewSpecialWarningSpell(43962, "dps", nil, nil, 1, 2)
local specWarnBomb		= mod:NewSpecialWarningDodge(42630, nil, nil, nil, 2, 2)

local timerBomb			= mod:NewCastTimer(11, 42630, nil, nil, nil, 3)--Cast bar?
local timerAdds			= mod:NewNextTimer(90, 43962, nil, nil, nil, 1, nil, DBM_CORE_L.DAMAGE_ICON)

local berserkTimer		= mod:NewBerserkTimer(300)

function mod:OnCombatStart(delay)
	timerAdds:Start(11)
	berserkTimer:Start(-delay)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(43140) then
		self:BossTargetScanner(args.sourceGUID, "FlameTarget", 0.1, 8)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellAdds or msg:find(L.YellAdds) then
		specWarnAdds:Show()
		warnAddsSoon:Schedule(80)
		timerAdds:Start()
	elseif msg == L.YellBomb or msg:find(L.YellBomb) then
		specWarnBomb:Show()
		specWarnBomb:Play("watchstep")
		timerBomb:Start()
	end
end
