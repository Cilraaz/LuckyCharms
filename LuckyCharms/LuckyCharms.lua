-- Localize API Globals
local CanViewOfficerNote = C_GuildInfo.CanViewOfficerNote
local GetAddOnMetadata   = C_AddOns.GetAddOnMetadata
local GetGuildInfo       = GetGuildInfo
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumGroupMembers = GetNumGroupMembers
local GetNumGuildMembers = GetNumGuildMembers
local IsInGuild          = IsInGuild
local SetRaidTarget      = SetRaidTarget
local UnitIsGroupLeader  = UnitIsGroupLeader
local UnitInParty        = UnitInParty
local UnitName           = UnitName

-- Lua Locals
local strfind = string.find
local strsub  = string.sub

-- Charms Table
local Charms = {}
Charms["Cilraaz"] = 1
Charms["Loki"]    = 2
Charms["Ceace"]   = 3
Charms["Dave"]    = 4
Charms["Arlee"]   = 7
Charms["Vely"]    = 6

-- Guild Table
local GuildMembers = {}

-- SavedVariables Table
if type(LuckyCharmsDB) ~= "table" then
    LuckyCharmsDB = {}
    LuckyCharmsDB.Paused = false
end

-- Check for empty variable
local function IsEmpty(var)
    return var == nil or var == ''
end

-- Create our Guild Table
local function CreateGuildList()
    if not IsInGuild() then return end
    local GuildMemberCount = GetNumGuildMembers()
    for i = 1, GuildMemberCount do
        local Name, _, _, _, _, _, _, OfficerNote = GetGuildRosterInfo(i)
        local HyphenPos = strfind(Name, "-")
        Name = strsub(Name, 1, HyphenPos - 1)
        GuildMembers[Name] = OfficerNote
    end
end

local function CheckPartyMembers()
    if not IsInGuild() or not UnitIsGroupLeader("player") or not UnitInParty("player") then return end
    
    if #GuildMembers == 0 then CreateGuildList() end

    local GuildName = GetGuildInfo("player")
    if GuildName == "Lucky Charms" then
        if not CanViewOfficerNote() then return end
        local MyName = UnitName("player")
        local MyNote = GuildMembers[MyName]
        SetRaidTarget(MyName, Charms[MyNote])
        for i = 1, GetNumGroupMembers() - 1 do
            local Name = UnitName("party"..i)
            local Note = GuildMembers[Name]
            local CharmType = Charms[Note]
            if not IsEmpty(Note) and not IsEmpty(CharmType) then
                SetRaidTarget(Name, CharmType)
            end
        end
    end
end

local DummyFrame = CreateFrame("Frame")
DummyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
DummyFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
DummyFrame:RegisterEvent("RAID_TARGET_UPDATE")
DummyFrame:SetScript("OnEvent", function(self, event, ...)
    if LuckyCharmsDB.Paused then return end
    if event == "PLAYER_ENTERING_WORLD" then
        CreateGuildList()
        CheckPartyMembers()
        DummyFrame:UnregisterEvent(event)
    else
        CheckPartyMembers()
    end
end)

SLASH_LUCKYCHARMS1 = "/lc"
SLASH_LUCKYCHARMS2 = "/luckycharms"
SlashCmdList["LUCKYCHARMS"] = function(msg)
    if msg == "pause" and not LuckyCharmsDB.Paused then
        print("[|cffff0000Lucky Charms|r]: Paused")
        --DummyFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        --DummyFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")
        --DummyFrame:UnregisterEvent("RAID_TARGET_UPDATE")
        LuckyCharmsDB.Paused = true
    elseif (msg == "pause" or msg == "unpause" or msg == "resume") and LuckyCharmsDB.Paused then
        print("[|cffff0000Lucky Charms|r]: Unpaused")
        --DummyFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        --DummyFrame:RegisterEvent("RAID_TARGET_UPDATE")
        LuckyCharmsDB.Paused = false
        CheckPartyMembers()
    elseif (msg == "unpause" or msg == "resume") and not LuckyCharmsDB.Paused then
        print("[|cffff0000Lucky Charms|r]: Addon is not paused")
    elseif msg == "status" then
        print("[|cffff0000Lucky Charms|r]: Addon is currently " .. (LuckyCharmsDB.Paused and "paused" or "unpaused"))
    elseif msg == "version" then
        local version = GetAddOnMetadata("LuckyCharms", "Version")
        print("[|cffff0000Lucky Charms|r]: Version " .. version)
    elseif msg == "help" then
        print("[|cffff0000Lucky Charms|r]: Commands List...")
        print("/lc pause - Pauses/Unpauses the addon")
        print("/lc unpause - Unpauses the addon")
        print("/lc resume - Unpauses the addon")
        print("/lc status - Prints the addon's status")
        print("/lc version - Prints the addon's version")
    end
end
