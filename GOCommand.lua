BINDING_HEADER_WOWPEDIAUIDEMO = "Custom Keybindings AddOn"
_G["BINDING_NAME_SPELL Moonfire"] = "Cast Moonfire"
BINDING_NAME_GOCOMMAND_FORWARD = "Reverse neutron flow polarity"
BINDING_NAME_GOCOMMAND_FORWARD2 = "Activate the ransmogrifier"

local LibTrinity = assert(LibStub("LibTrinityCore-1.0"))

GOCommand = {}
Parser = {}

function tonumberall(...)
    assertnotnil(...)
    local t = {...}
    local n = select("#", ...)
    for i = 1, n do
        t[i] = tonumber(t[i])
    end
    return unpack(t, 1, n)
end

function inttobool(...)
    local t = {...}
    local n = select("#", ...)
    for i = 1, n do
        assert(type(t[i]) == "number")
        t[i] = t[i] ~= 0
    end
    return unpack(t, 1, n)
end

function assertnotnil(v, ...)
    assert(v ~= nil)
    return v, ...
end

function ppairs(t)
    for k,v in pairs(t) do
        print(k,v)
    end
    return t
end

function pipairs(t)
    for k,v in ipairs(t) do
        print(k,v)
    end
    return t
end

local function merge_helper(t1, t2, ...)
    if not t2 then return end
    for k,v in pairs(t2) do
        t1[k] = v
    end
    merge_helper(t1, ...)
end
function merge(...)
    local t = {}
    merge_helper(t, ...)
    return t
end

function parseunitguid(guid)
    local typeid, entry, lowguid = tonumberall(string.match(guid, "0x(0000)(0000)(%d%d%d%d%d%d%d%d)"))
    return {typeid = typeid, lowguid = lowguid, entry = entry}
end

local function ParseErr(errhandler, ret, err)
    if not ret then
        if errhandler then
            if not errhandler(t) then
                print(strjoin("\n", "parse failed:", unpack(err)))
            end
        else
            print(strjoin("\n", "parse failed:", unpack(err)))
        end
        return
    end
    return ret
end
function makecallback(parser, callback, errhandler)
    return function(succ, t)
        if not succ then
            if errhandler then
                if not errhandler(t) then
                    print(strjoin("\n", "call failed:", unpack(t)))
                end
            else
                print(strjoin("\n", "call failed:", unpack(t)))
            end
            return
        end
        if callback then
            if parser then
                local ret = ParseErr(errhandler, parser(t), t)
                if ret then
                    callback(ret)
                end
                return
            end
            callback(t)
            return
        end
        if parser then
            ParseErr(errhandler, parser(t), t)
            return
        end
    end
end

function Parser.gps(tbl)
    if #tbl == 1 and tbl[1]:find("No gameobjects found") then return false end
    assert(#tbl == 6 or #tbl == 7)
    local t = {}
    assertnotnil(tbl[1]:find("You are"))
    t.indoors = not tbl[1]:find("outdoors")
    t.outdoors = not t.indoors
    t.map, t.zone, t.area, t.phase = tonumberall(tbl[2]:match("Map: (%d+) .* Zone: (%d+) .* Area: (%d+) .* Phase: (%d+)"))
    t.x, t.y, t.z, t.o = tonumberall(tbl[3]:match("X: (%-?%d+%.%d+) Y: (%-?%d+%.%d+) Z: (%-?%d+%.%d+) Orientation: (%-?%d+%.%d+)"))
    t.instanceid = tonumberall(tbl[4]:match("InstanceID: (%d+)"))
    t.zonex, t.zoney = tonumberall(tbl[5]:match("ZoneX: (%-?%d+%.%d+) ZoneY: (%-?%d+%.%d+)"))
    t.groundz, t.floorz = tonumberall(tbl[6]:match("GroundZ: (%-?%d+%.%d+) FloorZ: (%-?%d+%.%d+)"))
    t.hasmap, t.hasvmap, t.hasmmap = inttobool(tonumberall(tbl[6]:match("Map: (%d) VMap: (%d) MMap: (%d)")))
    return t
end

function Parser.gobtarget(tbl)
    if #tbl == 1 and tbl[1]:find("Nothing found") then return false end
    assert(#tbl == 6)
    local t = {}
    t.name = assert(tbl[2]:match("%[(.*)%]"))
    t.guid, t.entry = tonumberall(tbl[2]:match("GUID: (%d+) ID: (%d+)"))
    t.x, t.y, t.z, t.map = tonumberall(tbl[3]:match("X: (%-?%d+%.%d+) Y: (%-?%d+%.%d+) Z: (%-?%d+%.%d+) MapId: (%d+)"))
    t.o = tonumberall(tbl[4]:match("Orientation: (%-?%d+%.%d+)"))
    return t
end

function Parser.gobnear(tbl)
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

function Parser.gobinfoguid(tbl)
    assert(#tbl == 14)
    local t = {}
    t.entry = tonumberall(tbl[4]:match("Entry: (%d+)"))
    t.type = tonumberall(tbl[5]:match("Type: (%d+)"))
    t.lootid = tonumberall(tbl[6]:match("Lootid: (%d+)"))
    t.displayid = tonumberall(tbl[7]:match("DisplayID: (%d+)"))
    t.name = assert(tbl[9]:match("Name: (.*)"))
    t.size = tonumberall(tbl[10]:match("Size: (%-?%d+%.%d+)"))
    t.faction, t.flags = tonumberall(tbl[11]:match("Faction: (%d+) Flags: (%d+)"))
    t.maxx, t.maxy, t.maxz, t.minx, t.miny, t.minz = tonumberall(tbl[14]:match("Model dimensions from center: Max X (%-?%d+%.%d+) Y (%-?%d+%.%d+) Z (%-?%d+%.%d+) Min X (%-?%d+%.%d+) Y (%-?%d+%.%d+) Z (%-?%d+%.%d+)"))
    return t
end

function Parser.gobinfoentry(tbl)
    assert(#tbl == 9)
    local t = {}
    t.entry = tonumberall(tbl[1]:match("Entry: (%d+)"))
    t.type = tonumberall(tbl[2]:match("Type: (%d+)"))
    t.lootid = tonumberall(tbl[3]:match("Lootid: (%d+)"))
    t.displayid = tonumberall(tbl[4]:match("DisplayID: (%d+)"))
    t.name = assert(tbl[5]:match("Name: (.*)"))
    t.size = tonumberall(tbl[6]:match("Size: (%-?%d+%.%d+)"))
    t.faction, t.flags = tonumberall(tbl[7]:match("Faction: (%d+) Flags: (%d+)"))
    t.maxx, t.maxy, t.maxz, t.minx, t.miny, t.minz = tonumberall(tbl[9]:match("Model dimensions from center: Max X (%-?%d+%.%d+) Y (%-?%d+%.%d+) Z (%-?%d+%.%d+) Min X (%-?%d+%.%d+) Y (%-?%d+%.%d+) Z (%-?%d+%.%d+)"))
    return t
end

function Parser.lookupobj(tbl)
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

function Parser.gobadd(tbl)
    assert(#tbl == 1)
    local t = {}
    t.entry, t.name, t.guid, t.x, t.y, t.z = tbl[1]:match(">> Add Game Object '(%d+)' %((.*)%) %(GUID: (%d+)%) added at '(%-?%d+%.%d+) (%-?%d+%.%d+) (%-?%d+%.%d+)'")
    t.entry, t.guid, t.x, t.y, t.z = tonumberall(t.entry, t.guid, t.x, t.y, t.z)
    return t
end

function GOCommand.gobadd(entry, callback)
    LibTrinity:DoCommand(string.format("gobject add %d", entry), makecallback(Parser.gobadd, callback))
end
function GOCommand.lookupobj(lowguid, callback)
    LibTrinity:DoCommand(string.format("gobject info guid %d", lowguid), makecallback(Parser.lookupobj, callback))
end
function GOCommand.gobinfoguid(lowguid, callback)
    LibTrinity:DoCommand(string.format("gobject info guid %d", lowguid), makecallback(Parser.gobinfoguid, callback))
end
function GOCommand.gobinfoentry(entry, callback)
    LibTrinity:DoCommand(string.format("gobject info %d", entry), makecallback(Parser.gobinfoentry, callback))
end
function GOCommand.listobj(entry, callback)
    LibTrinity:DoCommand(string.format("list object %d %d", entry, 0x7FFFFFFF), makecallback(Parser.gobnear, callback))
end
function GOCommand.gobnear(distance, callback)
    LibTrinity:DoCommand(string.format("gobject near %d", distance), makecallback(Parser.gobnear, callback))
end
function GOCommand.gobtargetname(namepart, callback)
    if string.find(namepart, " ") then
        print("name part cannot contain a string!")
        return
    end
    LibTrinity:DoCommand(string.format("gobject target %s", namepart), makecallback(Parser.gobtarget, callback))
end
function GOCommand.gobtargetentry(entry, callback)
    LibTrinity:DoCommand(string.format("gobject target %d", entry), makecallback(Parser.gobtarget, callback))
end
function GOCommand.gobtarget(callback)
    LibTrinity:DoCommand(string.format("gobject target"), makecallback(Parser.gobtarget, callback))
end
function GOCommand.gobdelete(lowguid, callback)
    LibTrinity:DoCommand(string.format("gobject delete %d", lowguid), makecallback(nil, callback))
end
function GOCommand.gobturn(lowguid, orientation, forward, right, callback)
    LibTrinity:DoCommand(string.format("gobject turn %d %f %f %f", lowguid, orientation, forward, right), makecallback(nil, callback))
end
function GOCommand.gobmove(lowguid, callback)
    LibTrinity:DoCommand(string.format("gobject move %d", lowguid), makecallback(nil, callback))
end
function GOCommand.gobmovepos(lowguid,x,y,z, callback)
    LibTrinity:DoCommand(string.format("gobject move %d %f %f %f", lowguid,x,y,z), makecallback(nil, callback))
end
function GOCommand.gooffset(x,y,z,o, callback)
    LibTrinity:DoCommand(string.format("go offset %f %f %f %f", x,y,z,o), makecallback(nil, callback))
end
function GOCommand.gogameobjectguid(lowguid, callback)
    LibTrinity:DoCommand(string.format("go gameobject %d", lowguid), makecallback(nil, callback))
end
function GOCommand.gogameobjectentry(entry, callback)
    LibTrinity:DoCommand(string.format("go gameobject id %d", entry), makecallback(nil, callback))
end
--- /run GOCommand.goxyz(0,0,0,0,0, ppairs)
function GOCommand.goxyz(map,x,y,z,o, callback)
    LibTrinity:DoCommand(string.format("go xyz %f %f %f %d %f", x,y,z,map,o), makecallback(nil, callback))
end
function GOCommand.gpsplayer(callback)
    LibTrinity:DoCommand(string.format("gps %s", UnitName("player")), makecallback(Parser.gps, callback))
end
--- /run GOCommand.gpsgob(21645, function(t) for k,v in pairs(t) do print(k,v,type(v)) end end)
function GOCommand.gpsgob(lowguid, callback, errhandler)
    LibTrinity:DoCommand(string.format("gps |Hgameobject:%d|h", lowguid), makecallback(Parser.gps, callback, errhandler))
end

function exists(tbl, guid)
    for k,v in ipairs(tbl) do
        if v.guid == guid then return true end
    end
end

function add(tbl, data)
    assert(data.guid)
    if not exists(tbl, data.guid) then
        tbl[#tbl+1] = data
        return true
    end
    return false
end

StoredList = {}
function StoredList.add(self, value)
    assert(value.guid)
    assert(value.entry)
    assert(value.name)
    assert(value.x)
    assert(value.y)
    assert(value.z)
    assert(value.o)
    add(self, value)
    value.selected = true
    if self.update then self:update() end
end
function StoredList.del(self, guid)
    assert(guid)
    for k,v in ipairs(self) do
        if v.guid == guid then
            tremove(self, k)
        end
    end
    if self.update then self:update() end
end
function StoredList.getselected(self)
    local t = {}
    for k,v in ipairs(self) do
        if v.selected then t[#t+1] = v end
    end
    return t
end
function StoredList.selectall(self)
    if not self[1] then return end
    local sel = not self[1].selected
    for k,v in ipairs(self) do
        v.selected = sel
    end
    if self.update then self:update() end
end
function StoredList.selectinverse(self)
    for k,v in ipairs(self) do
        v.selected = not v.selected
    end
    if self.update then self:update() end
end

function MakeTexture(parent)
    local texture = parent:CreateTexture()
    texture:SetTexture(random(), random(), random(), 1)
    return texture
end

function MakeFrame(name, parent, template)
    local frame = CreateFrame("Frame", name, parent, template)
    frame:SetSize(200, 200)
    frame:RegisterForDrag("LeftButton")
    MakeTexture(frame):SetAllPoints(frame)
    return frame
end

function MakeInput(name, parent, template)
    local input = CreateFrame("EditBox", name, parent, template)
    input:SetSize(100, 10)
    input:SetAutoFocus(false)
    input:SetScript("OnEnterPressed", input.ClearFocus)
    input:SetScript("OnEscapePressed", input.ClearFocus)
    input:SetScript("OnEvent", input.ClearFocus)
    input:RegisterEvent("CURSOR_UPDATE")
    MakeTexture(input):SetAllPoints(input)
    input:SetFont("Fonts/ARIALN.ttf", 30)
    input:SetScript("OnSizeChanged", function(self, w, h) self:SetFont("Fonts\\ARIALN.ttf", h) end)
    return input
end

function MakeSlider(name, parent, template)
    local slider = CreateFrame("Slider", name, parent, template)
    slider:SetSize(100, 17)
    slider:SetPoint("CENTER", parent, "CENTER", 0, -50)
    slider:SetValueStep(1)
    slider:SetMinMaxValues(0, 100)
    slider:SetValue(0)
    local texture = MakeTexture(slider)
    texture:SetAllPoints(slider)
    local thumbTexture = MakeTexture(slider)
    thumbTexture:SetSize(8, 8)
    slider:SetThumbTexture(thumbTexture)
    slider:SetOrientation("HORIZONTAL")
    slider:Show()
    return slider
end

function MakeButton(name, parent, template)
    local button = CreateFrame("Button", name, parent, template)
    button:SetSize(100, 30)
    button:SetPoint("CENTER", parent, "CENTER")
    button:EnableMouse(true)
    button:SetScript("OnMouseUp", function() if GetMouseFocus() and GetMouseFocus().ClearFocus then GetMouseFocus():ClearFocus() end end)
    -- local texture = MakeTexture(button)
    -- texture:SetAllPoints(button)
    -- button:SetNormalTexture(texture)
    local fontstring = MakeFontString(button)
    fontstring:SetAllPoints(button)
    button:SetFontString(fontstring)
    button:SetScript("OnSizeChanged", function(self, w, h) local fs = self:GetFontString() fs:SetFont(fs:GetFont(), h) end)
    return button
end

function MakeFontString(parent)
    local fontstring = parent:CreateFontString()
    fontstring:SetFont("Fonts/ARIALN.ttf", 11)
    return fontstring
end

function MakeLayer(parent)
    local f = CreateFrame("Frame", nil, parent)
    return f
end

local function tooltip(self)
    GameTooltip:SetOwner(UIParent, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine(self.tooltip, 1, 1, 1, true)
    GameTooltip:Show()
end
local function hidetooltip(self)
    GameTooltip:Hide()
end
function AllowTooltip(elem, tip)
    elem:EnableMouse(true)
    elem.tooltip = tip
    elem:SetScript("OnEnter", tooltip)
    elem:SetScript("OnLeave", hidetooltip)
end

function Export()
    local function callback(gps)
        -- local e = CreateFrame("EditBox")
        -- e:SetSize(600, 600)
        -- e:SetPoint("CENTER")
        -- MakeTexture(e):SetAllPoints(e)
        -- e:SetFont("Fonts/ARIALN.ttf", 11)
        -- e:SetMultiLine(true)
        
        local selected = StoredList:getselected()
        local s = ""
        for k,v in ipairs(selected) do
            if v.map == gps.map then
                s = s..string.format("{entry=%d, x=%f, y=%f, z=%f, o=%f},", v.entry, v.x, v.y, v.z, v.o)
            end
        end
        local exported = string.format("return {player=%s, data={%s}}", string.format("{x=%f, y=%f, z=%f, o=%f}", gps.x, gps.y, gps.z, gps.o), s)
        -- e:SetText(exported)
        EXPORT = exported
    end
    GOCommand.gpsplayer(callback)
end

function Import()
    local function callback(gps)
        local t = loadstring(EXPORT)()
        local p = t.player
        local d = t.data
        for k,v in ipairs(d) do
            GOCommand.gobadd(v.entry, function(data)
                local x,y,z = v.x-p.x+gps.x, v.y-p.y+gps.y, v.z-p.z+gps.z
                GOCommand.gobmovepos(data.guid, x, y, z)
                GOCommand.gobturn(data.guid, v.o, 0, 0)
            end)
        end
    end
    GOCommand.gpsplayer(callback)
end

local function MakeSelectList(data)
    local f = CreateFrame("Frame", "selectlist")
    f:SetToplevel(true)
    f:SetMinResize(10*4, 10*3)
    f:SetSize(100, 100)
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:SetResizable(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnHide", f.StopMovingOrSizing)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    MakeTexture(f):SetAllPoints(f)

    local b = MakeButton(nil, f)
    b:SetPoint("TOPRIGHT")
    b:SetSize(10, 10)
    b:SetText("X")
    MakeTexture(b):SetAllPoints(b)
    b:SetScript("OnClick", function(self) self:GetParent():Hide() end)

    local selectall = MakeButton(nil, f)
    selectall:SetPoint("TOPRIGHT", b, "TOPLEFT")
    selectall:SetSize(10, 10)
    selectall:SetText("A")
    MakeTexture(selectall):SetAllPoints(selectall)
    selectall:SetScript("OnClick", function(self) data:selectall() end)

    local selectinv = MakeButton(nil, f)
    selectinv:SetPoint("TOPRIGHT", selectall, "TOPLEFT")
    selectinv:SetSize(10, 10)
    selectinv:SetText("I")
    MakeTexture(selectinv):SetAllPoints(selectinv)
    selectinv:SetScript("OnClick", function(self) data:selectinverse() end)

    local i = MakeFontString(f)
    i:SetHeight(10)
    i:SetTextColor(0,0,0,0.5)
    i:SetText("Selection list")
    i:SetHeight(10)
    i:SetPoint("TOPLEFT", f, "TOPLEFT")
    i:SetPoint("TOPRIGHT", selectinv, "TOPLEFT")

    local r = MakeButton(nil, f)
    r:SetPoint("BOTTOMRIGHT")
    r:SetSize(10, 10)
    MakeTexture(r):SetAllPoints(r)
    r:RegisterForDrag("LeftButton")
    r:SetScript("OnDragStart", function(self) self:GetParent():StartSizing("BOTTOMRIGHT") end)
    r:SetScript("OnDragStop", function(self) self:GetParent():StopMovingOrSizing() end)

    local s = MakeSlider(nil, f)
    s:SetOrientation("VERTICAL")
    s:SetValue(0)
    s:SetValueStep(1)
    s:SetPoint("TOPLEFT", b, "BOTTOMLEFT")
    s:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT")
    s:SetPoint("BOTTOMLEFT", r, "TOPLEFT")
    s:SetPoint("BOTTOMRIGHT", r, "TOPRIGHT")

    local c = MakeLayer(f)
    c:SetPoint("TOPLEFT", i, "BOTTOMLEFT")
    c:SetPoint("TOPRIGHT", b, "BOTTOMLEFT")
    c:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT")
    c:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT")

    local head = MakeLayer(c)
    head:SetPoint("TOPLEFT")
    head:SetPoint("TOPRIGHT")
    head:SetPoint("BOTTOMLEFT", c, "TOPLEFT")
    head:SetPoint("BOTTOMRIGHT", c, "TOPRIGHT")
    local items = {}
    
    local function GetVisibleItemsCount()
        return floor(c:GetHeight()/10)
    end
    
    local function UpdateItemList()
        local value = s:GetValue()
        local visibleitems = GetVisibleItemsCount()
        local actualitems = #data
        for k,v in ipairs(items) do
            if k > visibleitems or value+k>actualitems then
                v:Hide()
            else
                local objinfo = data[value+k]
                v.label:SetText(objinfo.guid.." "..objinfo.name)
                if objinfo.selected then
                    v.label:GetFontString():SetTextColor(1, 0.8, 0)
                else
                    v.label:GetFontString():SetTextColor(1, 1, 1)
                end
                v:Show()
            end
        end
    end

    local function UpdateListSize()
        local neededItems = GetVisibleItemsCount()
        for i = #items+1, neededItems do
            local contact = items[i-1] or head
            local l = MakeLayer(c)
            l:SetPoint("TOPLEFT", contact, "BOTTOMLEFT")
            l:SetPoint("TOPRIGHT", contact, "BOTTOMRIGHT")
            l:SetHeight(10)
            local delete = MakeButton(nil, l)
            delete:SetSize(10, 10)
            delete:SetPoint("TOPRIGHT")
            delete:SetText("D")
            delete:SetScript("OnClick", function()
                local idx = s:GetValue()+i
                GOCommand.gobdelete(data[idx].guid)
                data:del(data[idx].guid)
            end)
            local tele = MakeButton(nil, l)
            tele:SetSize(10, 10)
            tele:SetPoint("TOPRIGHT", delete, "TOPLEFT")
            tele:SetText("T")
            tele:SetScript("OnClick", function()
                local idx = s:GetValue()+i
                GOCommand.gogameobjectguid(data[idx].guid)
            end)
            local t = MakeButton(nil, l)
            t:SetHeight(10)
            t:SetPoint("TOPLEFT")
            t:SetPoint("TOPRIGHT", tele, "TOPLEFT")
            local fontstring = MakeFontString(t)
            fontstring:SetAllPoints(t)
            fontstring:SetJustifyH("LEFT")
            t:SetFontString(fontstring)
            t:SetScript("OnClick", function()
                local idx = s:GetValue()+i
                data[idx].selected = not data[idx].selected
                UpdateItemList()
            end)
            l.label = t
            items[i] = l
        end
        UpdateItemList()
    end
    
    c:SetScript("OnSizeChanged", UpdateListSize)
    s:SetScript("OnValueChanged", UpdateItemList)
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(self, delta) s:SetValue(s:GetValue()-delta*(IsShiftKeyDown() and GetVisibleItemsCount()/4 or 1)) end)
    
    function data.update(self)
        s:SetMinMaxValues(0, max(#self-1, 0))
        UpdateListSize()
    end
    UpdateListSize()
    return f
end
MakeSelectList(StoredList)

local function MakeRotator()
    local width = 26
    local height = 10
    local f = CreateFrame("Frame", "rotator")
    f:SetToplevel(true)
    f:SetSize(width, height*4)
    f:RegisterForDrag("LeftButton")
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    MakeTexture(f):SetAllPoints(f)
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnHide", f.StopMovingOrSizing)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:RegisterForDrag("LeftButton")
    
    local l = MakeFontString(f)
    l:SetPoint("TOPLEFT")
    l:SetPoint("TOPRIGHT")
    l:SetHeight(height)
    l:SetTextColor(0,0,0,0.5)
    l:SetText("Rotation")

    local function normalize(o)
        return mod(o, 2 * math.pi)
    end
    local a,b,c
    local function thing()
        local objs = StoredList:getselected()
        local a,b,c = normalize(rad(a:GetNumber())), normalize(rad(b:GetNumber())), normalize(rad(c:GetNumber()))
        for k,v in ipairs(objs) do
            GOCommand.gobturn(v.guid, a,b,c)
        end
    end
    local function mouse(self, delta)
        local value = delta*(IsShiftKeyDown() and 1 or 10)
        local final = self:GetNumber()-value
        final = final%360
        final = tostring(final):sub(1,6)
        self:SetText(final)
    end
    a = MakeInput(nil, f)
    AllowTooltip(a, "orientation")
    a:SetText(0)
    a:SetHeight(height)
    a:SetPoint("TOPLEFT", l, "BOTTOMLEFT")
    a:SetPoint("TOPRIGHT", l, "BOTTOMRIGHT")
    a:SetScript("OnTextChanged", thing)
    a:SetScript("OnMouseWheel", mouse)
    a:EnableMouseWheel(true)
    a:SetMaxLetters(5)
    b = MakeInput(nil, f)
    AllowTooltip(b, "pitch")
    b:SetText(0)
    b:SetHeight(height)
    b:SetPoint("TOPLEFT", a, "BOTTOMLEFT")
    b:SetPoint("TOPRIGHT", a, "BOTTOMRIGHT")
    b:SetScript("OnTextChanged", thing)
    b:SetScript("OnMouseWheel", mouse)
    b:EnableMouseWheel(true)
    b:SetMaxLetters(5)
    c = MakeInput(nil, f)
    c:SetText(0)
    AllowTooltip(c, "yaw")
    c:SetHeight(height)
    c:SetPoint("TOPLEFT", b, "BOTTOMLEFT")
    c:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT")
    c:SetScript("OnTextChanged", thing)
    c:SetScript("OnMouseWheel", mouse)
    c:EnableMouseWheel(true)
    c:SetMaxLetters(5)
    
    f:Show()
end
MakeRotator()

local function MakeSelector()
    local width = 50
    local height = 10
    local f = CreateFrame("Frame", "selector")
    f:SetToplevel(true)
    f:SetSize(width, height*6)
    f:RegisterForDrag("LeftButton")
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    MakeTexture(f):SetAllPoints(f)
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnHide", f.StopMovingOrSizing)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:RegisterForDrag("LeftButton")
    
    local l = MakeFontString(f)
    l:SetPoint("TOPLEFT")
    l:SetPoint("TOPRIGHT")
    l:SetHeight(height)
    l:SetTextColor(0,0,0,0.5)
    l:SetText("Selector")
    
    local spawn = MakeInput(nil, f)
    AllowTooltip(spawn, "Spawn object of given entry")
    spawn:SetHeight(height)
    spawn:SetHistoryLines(50)
    spawn:SetPoint("TOPLEFT", l, "BOTTOMLEFT")
    spawn:SetPoint("TOPRIGHT", l, "BOTTOMRIGHT")
    spawn:SetMaxLetters(10)
    spawn:SetNumeric(true)
    spawn:SetScript("OnEnterPressed", function(self)
        local entry = self:GetNumber()
        if entry ~= 0 then
            GOCommand.gobadd(entry, function(info)
                self:AddHistoryLine(entry)
                GOCommand.gpsgob(info.guid, function(info2)
                    local mrg = merge(info, info2)
                    StoredList:add(mrg)
                end)
            end)
        end
    end)
    
    local selectnear = MakeInput(nil, f)
    AllowTooltip(selectnear, "Objects in given range")
    selectnear:SetHeight(height)
    selectnear:SetPoint("TOPLEFT", spawn, "BOTTOMLEFT")
    selectnear:SetPoint("TOPRIGHT", spawn, "BOTTOMRIGHT")
    selectnear:SetScript("OnEnterPressed", function(self)
        local range = self:GetNumber()
        GOCommand.gobnear(range, function(info)
            for k,v in ipairs(info) do
                GOCommand.gpsgob(v.guid,
                function(info2)
                    local mrg = merge(v, info2)
                    StoredList:add(mrg)
                end,
                function(tbl)
                    return #tbl == 1 and tbl[1]:find("No gameobjects found")
                end)
            end
        end)
    end)
    
    local targetname = MakeInput(nil, f)
    AllowTooltip(targetname, "Closest object having given name part")
    targetname:SetHistoryLines(50)
    targetname:SetHeight(height)
    targetname:SetPoint("TOPLEFT", selectnear, "BOTTOMLEFT")
    targetname:SetPoint("TOPRIGHT", selectnear, "BOTTOMRIGHT")
    targetname:SetScript("OnEnterPressed", function(self)
        local namepart = self:GetText()
        GOCommand.gobtargetname(namepart, function(info)
            self:AddHistoryLine(namepart)
            StoredList:add(info)
        end)
    end)
    
    local targetentry = MakeInput(nil, f)
    AllowTooltip(targetentry, "Closest object having given entry")
    targetentry:SetMaxLetters(10)
    targetentry:SetNumeric(true)
    targetentry:SetHeight(height)
    targetentry:SetPoint("TOPLEFT", targetname, "BOTTOMLEFT")
    targetentry:SetPoint("TOPRIGHT", targetname, "BOTTOMRIGHT")
    targetentry:SetScript("OnEnterPressed", function(self)
        local entry = self:GetNumber()
        if entry ~= 0 then
            GOCommand.gobtargetentry(entry, function(info)
                self:AddHistoryLine(entry)
                StoredList:add(info)
            end)
        end
    end)
    
    local target = MakeButton(nil, f)
    target:SetHeight(height)
    target:SetText("closest")
    target:SetPoint("TOPLEFT", targetentry, "BOTTOMLEFT")
    target:SetPoint("TOPRIGHT", targetentry, "BOTTOMRIGHT")
    target:SetScript("OnClick", function(self)
        GOCommand.gobtarget(function(data)
            StoredList:add(data)
        end)
    end)
    
    f:Show()
end
MakeSelector()
