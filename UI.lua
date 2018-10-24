BINDING_HEADER_WOWPEDIAUIDEMO = "Custom Keybindings AddOn"
_G["BINDING_NAME_SPELL Moonfire"] = "Cast Moonfire"
BINDING_NAME_GOCOMMAND_FORWARD = "Reverse neutron flow polarity"
BINDING_NAME_GOCOMMAND_FORWARD2 = "Activate the ransmogrifier"

assert(GOCommand).ui = {}
local util = assert(GOCommand.util)
local command = assert(GOCommand.command)

local function exists(tbl, guid)
    for k,v in ipairs(tbl) do
        if v.guid == guid then return true end
    end
end

local function add(tbl, data)
    assert(data.guid)
    if not exists(tbl, data.guid) then
        tbl[#tbl+1] = data
        return true
    end
    return false
end

local StoredList = {}
function StoredList.add(self, value)
    util.asserttype("number", value.guid, value.entry, value.x, value.y, value.z, value.o)
    util.asserttype("string", value.name)
    add(self, value)
    value.selected = true
    if self.update then self:update() end
end
function StoredList.del(self, guid)
    util.asserttype("number", guid)
    for k,v in ipairs(self) do
        print(v.guid, guid, v.guid == guid)
        if v.guid == guid then
            tremove(self, k)
            print("removed")
            break
        end
    end
    if self.update then self:update() end
    print("updated")
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

function MakeFrame(...)
    local frame = CreateFrame("Frame", ...)
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
    GameTooltip:AddLine(type(self.tooltip) == "string" and self.tooltip or self.tooltip(self), 1, 1, 1, true)
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
    command.gpsplayer(callback)
end

function Import()
    local function callback(gps)
        local t = loadstring(EXPORT)()
        local p = t.player
        local d = t.data
        for k,v in ipairs(d) do
            command.gobadd(v.entry, function(data)
                local x,y,z = v.x-p.x+gps.x, v.y-p.y+gps.y, v.z-p.z+gps.z
                command.gobmovepos(data.guid, x, y, z)
                command.gobturn(data.guid, v.o, 0, 0)
            end)
        end
    end
    command.gpsplayer(callback)
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
    i:SetTextColor(0,0,0)
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
                command.gobdelete(data[idx].guid)
                data:del(data[idx].guid)
            end)
            local tele = MakeButton(nil, l)
            tele:SetSize(10, 10)
            tele:SetPoint("TOPRIGHT", delete, "TOPLEFT")
            tele:SetText("T")
            tele:SetScript("OnClick", function()
                local idx = s:GetValue()+i
                command.gogameobjectguid(data[idx].guid)
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
    l:SetTextColor(0,0,0)
    l:SetText("Rotation")

    local function normalize(o)
        return mod(o, 2 * math.pi)
    end
    local a,b,c
    local function thing()
        local objs = StoredList:getselected()
        local a,b,c = normalize(rad(a:GetNumber())), normalize(rad(b:GetNumber())), normalize(rad(c:GetNumber()))
        for k,v in ipairs(objs) do
            command.gobturn(v.guid, a,b,c)
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
    l:SetTextColor(0,0,0)
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
            command.gobadd(entry, function(info)
                self:AddHistoryLine(entry)
                command.gpsgob(info.guid, function(info2)
                    local mrg = util.merge(info, info2)
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
        command.gobnear(range, function(info)
            for k,v in ipairs(info) do
                command.gpsgob(v.guid,
                function(info2)
                    local mrg = util.merge(v, info2)
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
        command.gobtargetname(namepart, function(info)
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
            command.gobtargetentry(entry, function(info)
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
        command.gobtarget(function(data)
            StoredList:add(data)
        end)
    end)
    
    f:Show()
end
MakeSelector()

local function MakeMover()
    local width = 50
    local height = 10
    local f = MakeFrame("mover")
    f:SetToplevel(true)
    f:SetSize(width, height*5)
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
    l:SetTextColor(0,0,0)
    l:SetText("Move")
    
    local moveque = {}
    local movecomplete, movenext
    function movecomplete()
        tremove(moveque, 1)
        movenext()
    end
    function movenext()
        local v = moveque[1]
        if v then
            command.gpsgob(v.guid, function(gps)
                gps[v.key] = gps[v.key] + v.value
                command.gobmovepos(v.guid, gps.x, gps.y, gps.z, movecomplete, movecomplete)
            end, movecomplete)
        end
    end
    local function mouse(self, delta)
        local value = delta*self:GetNumber()
        if IsShiftKeyDown() then value = value/10 end
        if IsAltKeyDown() then value = value/100 end
        if IsControlKeyDown() then value = value/1000 end
        if value == 0 then return end
        local objs = StoredList:getselected()
        for k,v in ipairs(objs) do
            moveque[#moveque+1] = {guid = v.guid, value = value, key = self.key}
            if #moveque == 1 then
                movenext()
            end
        end
    end

    local x = MakeInput(nil, f)
    AllowTooltip(x, "forwards/backwards")
    x.key = "x"
    x:SetText(1)
    x:SetHeight(height)
    x:SetPoint("TOPLEFT", l, "BOTTOMLEFT")
    x:SetPoint("TOPRIGHT", l, "BOTTOMRIGHT")
    x:SetScript("OnMouseWheel", mouse)
    x:EnableMouseWheel(true)

    local y = MakeInput(nil, f)
    AllowTooltip(y, "left/right")
    y.key = "y"
    y:SetText(1)
    y:SetHeight(height)
    y:SetPoint("TOPLEFT", x, "BOTTOMLEFT")
    y:SetPoint("TOPRIGHT", x, "BOTTOMRIGHT")
    y:SetScript("OnMouseWheel", mouse)
    y:EnableMouseWheel(true)

    local z = MakeInput(nil, f)
    AllowTooltip(z, "up/down")
    z.key = "z"
    z:SetText(1)
    z:SetHeight(height)
    z:SetPoint("TOPLEFT", y, "BOTTOMLEFT")
    z:SetPoint("TOPRIGHT", y, "BOTTOMRIGHT")
    z:SetScript("OnMouseWheel", mouse)
    z:EnableMouseWheel(true)

    local copydimensions = MakeInput(nil, f)
    AllowTooltip(copydimensions, "load dimensions of given object entry")
    copydimensions:SetNumeric(true)
    copydimensions:SetMaxLetters(10)
    copydimensions:SetHeight(height)
    copydimensions:SetPoint("TOPLEFT", z, "BOTTOMLEFT")
    copydimensions:SetPoint("TOPRIGHT", z, "BOTTOMRIGHT")
    copydimensions:SetScript("OnEnterPressed", function(self)
        command.gobinfoentry(self:GetNumber(), function(info)
            x:SetText(info.maxx-info.minx)
            y:SetText(info.maxy-info.miny)
            z:SetText(info.maxz-info.minz)
        end)
    end)
    
    f:Show()
end
MakeMover()

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:SetScript("OnEvent", function(self, event, message)
    local guid = nil
    guid = guid or message:match("Game Object %(GUID: (%d+)%) removed")
    guid = guid or message:match("Game Object %(GUID: (%d+)%) not found")
    guid = tonumber(guid)
    if guid then
        StoredList:del(guid)
    end
end)
