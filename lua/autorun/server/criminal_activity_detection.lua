-- Criminal Automated Balancing \\ Bots and wanted-levels to keep mass RDM'ers and such in check
local HOOK_ID = "CRIMINAL_ACTIVITY_DETECTION"
local KILL_TIME_DELTA = 15 -- must have a murder count of KILL_COUNT_TRIGGER in KILL_TIME_DELTA seconds or less
local KILL_COUNT_TRIGGER = 2

local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:GetLastKillTime()
	return self._lastKillTime or 0
end

-- TODO: rename "LastKillTime" keys to "FirstKillTime"
function PlayerMeta:SetLastKillTime(v)
	self._lastKillTime = v
end

-- prefixing with CAB to clarify that it's not the native 'total frags' field 
function PlayerMeta:GetCABKills()
	return self._cabKills or 0
end

function PlayerMeta:SetCABKills(v)
	self._cabKills = v
end

function PlayerMeta:ResetCABStats()
	self:SetLastKillTime(CurTime())
	self:SetCABKills(0)
end

local function getDeltaFromLastKillTime(player)
	return CurTime() - player:GetLastKillTime()
end

local function checkKillsForCountermeasure(killer)
	if killer:GetCABKills() < KILL_COUNT_TRIGGER then return end

	killer:ChatPrint("YOU'RE WANTED")
	killer:ResetCABStats()

	local manhack = ents.Create( "npc_combine_s" )
	manhack:Give("weapon_ar2")
	manhack:SetPos(killer:GetPos() + (killer:GetUp()) * 70)
	manhack:Spawn()

	for _, ent in ipairs(player.GetAll()) do
		if ent == killer then
			manhack:AddEntityRelationship( killer, D_HT, 99 )
		else
			manhack:AddEntityRelationship( ent, D_LI, 99 )
		end
	end
end

hook.Add("PlayerDeath", HOOK_ID, function(victim, _, killer)
	if not killer:IsPlayer() then return end 
	-- first, check if the kills are within the window of time
	if getDeltaFromLastKillTime(killer) <= KILL_TIME_DELTA then
		killer:SetCABKills(killer:GetCABKills() + 1)
		checkKillsForCountermeasure(killer)
	else
		-- current kill wasn't within the window of time, reset everything
		killer:ResetCABStats()
	end
end)