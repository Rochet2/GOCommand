assert(GOCommand).command = {}
local command = GOCommand.command
local util = assert(GOCommand.util)
local libtrinity = assert(LibStub("LibTrinityCore-1.0"))
local parser = {}

local tonumberall = assert(util.tonumberall)
local inttobool = assert(util.inttobool)
local assertnotnil = assert(util.assertnotnil)
local makecallback = assert(util.makecallback)

function parser.gps(tbl)
    if #tbl == 1 and tbl[1]:find("No gameobjects found") then return false end
    assert(#tbl == 6 or #tbl == 7)
    local t = {}
    assertnotnil(tbl[1]:find("You are"))
    t.indoors = not tbl[1]:find("outdoors")
    t.outdoors = not t.indoors
    t.map, t.zone, t.area, t.phase = tonumberall(tbl[2]:match("Map: (%d+) .* Zone: (%d+) .* Area: (%d+) .* Phase: (%d+)"))
    t.x, t.y, t.z, t.yaw = tonumberall(tbl[3]:match("X: (%-?%d+%.%d+) Y: (%-?%d+%.%d+) Z: (%-?%d+%.%d+) Orientation: (%-?%d+%.%d+)"))
    t.instanceid = tonumberall(tbl[4]:match("InstanceID: (%d+)"))
    t.zonex, t.zoney = tonumberall(tbl[5]:match("ZoneX: (%-?%d+%.%d+) ZoneY: (%-?%d+%.%d+)"))
    t.groundz, t.floorz = tonumberall(tbl[6]:match("GroundZ: (%-?%d+%.%d+) FloorZ: (%-?%d+%.%d+)"))
    t.hasmap, t.hasvmap, t.hasmmap = inttobool(tonumberall(tbl[6]:match("Map: (%d) VMap: (%d) MMap: (%d)")))
    return t
end

function parser.gobtarget(tbl)
    if #tbl == 1 and tbl[1]:find("Nothing found") then return false end
    local t = {}
    assert(tbl[1]:find("Selected object"))
    t.name = assert(tbl[2]:match("%[(.*)%]"))
    t.guid, t.entry = tonumberall(tbl[2]:match("GUID: (%d+) ID: (%d+)"))
    t.x, t.y, t.z, t.map = tonumberall(tbl[3]:match("X: (%-?%d+%.%d+) Y: (%-?%d+%.%d+) Z: (%-?%d+%.%d+) MapId: (%d+)"))
    t.yaw = tonumberall(tbl[4]:match("Orientation: (%-?%d+%.%d+)"))
    return t
end

function parser.gobnear(tbl)
    assert(tbl[#tbl]:match("Found"))
    local t = {}
    for i = 1, #tbl-1 do
        local tt = {}
        tt.entry, tt.guid, tt.name, tt.x, tt.y, tt.z, tt.map = tbl[i]:match("Entry: (%d+)%) .*|Hgameobject:(%d+)|h%[(.*) X:(%-?%d+%.%d+) Y:(%-?%d+%.%d+) Z:(%-?%d+%.%d+) MapId:(%d+)%]")
        tt.entry, tt.guid, tt.x, tt.y, tt.z, tt.map = tonumberall(tt.entry, tt.guid, tt.x, tt.y, tt.z, tt.map)
        t[i] = tt
    end
    return t
end

local matchers = {
    {{"entry"}, {"number"}, "^Entry: (%d+)"},
    {{"name"}, {"string"}, "^Name: (.*)"},
    {{"size"}, {"number"}, "^Size: (%-?%d+%.%d+)"},
    {{"guid", "x", "y", "z"}, {"number", "number", "number", "number"}, "^SpawnID: (%d+), location %((%-?%d+%.%d+), (%-?%d+%.%d+), (%-?%d+%.%d+)%)"},
    {{"yaw", "pitch", "roll"}, {"number", "number", "number"}, "^yaw: (.+) pitch: (.+) roll: (.+)"},
    {{"maxx", "maxy", "maxz", "minx", "miny", "minz"}, {"number", "number", "number", "number", "number", "number"}, "^Model dimensions from center: Max X (%-?%d+%.%d+) Y (%-?%d+%.%d+) Z (%-?%d+%.%d+) Min X (%-?%d+%.%d+) Y (%-?%d+%.%d+) Z (%-?%d+%.%d+)"},
}
function parser.gobinfo(tbl)
    local t = {}
    for k1,row in ipairs(tbl) do
        for k2,matchdata in ipairs(matchers) do
            local matched = {row:match(matchdata[3])}
            if matched[1] then
                for k3, expectedtype in ipairs(matchdata[2]) do
                    if expectedtype == "number" then
                        if matched[k3]:find("nan") or matched[k3]:find("inf") then
                            t[matchdata[1][k3]] = 0
                        else
                            t[matchdata[1][k3]] = assert(tonumber(matched[k3]), string.format("expected %s, got %s", expectedtype, matched[k3]))
                        end
                    elseif expectedtype == "string" then
                        t[matchdata[1][k3]] = matched[k3]
                    else
                        error("Invalid type given", 0)
                    end
                end
                break
            end
        end
    end
    return t
end

function parser.lookupobj(tbl)
    if #tbl == 1 and tbl[1]:find("No gameobjects found") then
        return {}
    end
    local t = {}
    for i = 1, #tbl-1 do
        if tbl[i]:find("Result limit reached") then
            return t
        end
        local tt = {}
        tt.entry, tt.name = tbl[i]:match("|Hgameobject_entry:(%d+)|h%[(.*)%]|h")
        tt.entry = tonumberall(tt.entry)
        t[i] = tt
    end
    return t
end

function parser.gobadd(tbl)
    assert(#tbl == 1)
    local t = {}
    t.entry, t.name, t.guid, t.x, t.y, t.z = tbl[1]:match(">> Add Game Object '(%d+)' %((.*)%) %(GUID: (%d+)%) added at '(%-?%d+%.%d+) (%-?%d+%.%d+) (%-?%d+%.%d+)'")
    t.entry, t.guid, t.x, t.y, t.z = tonumberall(t.entry, t.guid, t.x, t.y, t.z)
    return t
end

function command.gobadd(entry, ...)
    libtrinity:DoCommand(string.format("gobject add %d", entry), makecallback(parser.gobadd, ...))
end
function command.lookupobj(lowguid, ...)
    libtrinity:DoCommand(string.format("gobject info guid %d", lowguid), makecallback(parser.lookupobj, ...))
end
function command.gobinfoguid(lowguid, ...)
    libtrinity:DoCommand(string.format("gobject info guid %d", lowguid), makecallback(parser.gobinfo, ...))
end
function command.gobinfoentry(entry, ...)
    libtrinity:DoCommand(string.format("gobject info %d", entry), makecallback(parser.gobinfo, ...))
end
function command.listobj(entry, ...)
    libtrinity:DoCommand(string.format("list object %d %d", entry, 0x7FFFFFFF), makecallback(parser.gobnear, ...))
end
function command.gobnear(distance, ...)
    libtrinity:DoCommand(string.format("gobject near %d", distance), makecallback(parser.gobnear, ...))
end
function command.gobtargetname(namepart, ...)
    if string.find(namepart, " ") then
        print("name part cannot contain a string!")
        return
    end
    libtrinity:DoCommand(string.format("gobject target %s", namepart), makecallback(parser.gobtarget, ...))
end
function command.gobtargetentry(entry, ...)
    libtrinity:DoCommand(string.format("gobject target %d", entry), makecallback(parser.gobtarget, ...))
end
function command.gobtarget(...)
    libtrinity:DoCommand(string.format("gobject target"), makecallback(parser.gobtarget, ...))
end
function command.gobdelete(lowguid, ...)
    libtrinity:DoCommand(string.format("gobject delete %d", lowguid), makecallback(nil, ...))
end
function command.gobturn(lowguid, orientation, forward, right, ...)
    libtrinity:DoCommand(string.format("gobject turn %d %f %f %f", lowguid, orientation, forward, right), makecallback(nil, ...))
end
function command.gobmove(lowguid, ...)
    libtrinity:DoCommand(string.format("gobject move %d", lowguid), makecallback(nil, ...))
end
function command.gobmovepos(lowguid,x,y,z, ...)
    libtrinity:DoCommand(string.format("gobject move %d %f %f %f", lowguid,x,y,z), makecallback(nil, ...))
end
function command.gooffset(x,y,z,o, ...)
    libtrinity:DoCommand(string.format("go offset %f %f %f %f", x,y,z,o), makecallback(nil, ...))
end
function command.gogameobjectguid(lowguid, ...)
    libtrinity:DoCommand(string.format("go gameobject %d", lowguid), makecallback(nil, ...))
end
function command.gogameobjectentry(entry, ...)
    libtrinity:DoCommand(string.format("go gameobject id %d", entry), makecallback(nil, ...))
end
function command.goxyz(map,x,y,z,o, ...)
    libtrinity:DoCommand(string.format("go xyz %f %f %f %d %f", x,y,z,map,o), makecallback(nil, ...))
end
function command.gpsplayer(...)
    libtrinity:DoCommand(string.format("gps %s", UnitName("player")), makecallback(parser.gps, ...))
end
function command.gpsgob(lowguid, ...)
    libtrinity:DoCommand(string.format("gps |Hgameobject:%d|h", lowguid), makecallback(parser.gps, ...))
end

local movedata = {}
local function move(data)
    movedata[data.guid] = true
    local done = 0
    local function finished()
        done = done-1
        if done == 0 then
            if movedata[data.guid] == true then
                movedata[data.guid] = nil
            else
                move(movedata[data.guid])
            end
        end
    end
    if data.x or data.y or data.z then
        done = done+1
        util.asserttype("number", data.x, data.y, data.z)
        command.gobmovepos(data.guid, data.x, data.y, data.z, finished, finished)
    end
    if data.yaw or data.pitch or data.roll then
        done = done+1
        util.asserttype("number", data.yaw, data.pitch, data.roll)
        command.gobturn(data.guid, data.yaw, data.pitch, data.roll, finished, finished)
    end
end
function command.Move(data)
    if not movedata[data.guid] then
        move(data)
    else
        movedata[data.guid] = data
    end
end
