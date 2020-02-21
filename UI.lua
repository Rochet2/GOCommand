BINDING_HEADER_WOWPEDIAUIDEMO = "Custom Keybindings AddOn"
_G["BINDING_NAME_SPELL Moonfire"] = "Cast Moonfire"
BINDING_NAME_GOCOMMAND_FORWARD = "Reverse neutron flow polarity"
BINDING_NAME_GOCOMMAND_FORWARD2 = "Activate the ransmogrifier"

assert(GOCommand).ui = {}
local util = assert(GOCommand.util)
local command = assert(GOCommand.command)

local function SetScript(frame, event, func)
    assert(frame)
    assert(event)
    assert(func)
    local old = frame:GetScript(event)
    frame:SetScript(event, old and function(...) old(...) func(...) end or func)
end

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
    util.asserttype("number", value.guid, value.entry)
    util.asserttype("string", value.name)
    util.asserttype("number", value.x, value.y, value.z, value.yaw, value.pitch, value.roll)
    local data = util.copy(value, "x", "y", "z", "yaw", "pitch", "roll", "name", "guid", "entry")
    data.selected = true
    add(self, data)
    self:update()
end
function StoredList.del(self, guid)
    util.asserttype("number", guid)
    for k,v in ipairs(self) do
        if v.guid == guid then
            tremove(self, k)
            break
        end
    end
    self:update()
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
    self:update()
end
function StoredList.selectinverse(self)
    for k,v in ipairs(self) do
        v.selected = not v.selected
    end
    self:update()
end
function StoredList.clear(self)
    local n = #self
    for i = 1, n do
        self[i] = nil
    end
    self:update()
end
function StoredList.update(self)
    if self.uiupdater then self:uiupdater() end
end

function MakeTexture(parent, r, g, b, o)
    local texture = parent:CreateTexture()
    texture:SetTexture(r or 0.5, g or 0.5, b or 0.5, o or 1)
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
    SetScript(input, "OnEnterPressed", input.ClearFocus)
    SetScript(input, "OnEscapePressed", input.ClearFocus)
    -- SetScript(input, "OnEvent", function(self, ...) self:ClearFocus() end)
    -- input:RegisterEvent("CURSOR_UPDATE")
    MakeTexture(input):SetAllPoints(input)
    input:SetFont("Fonts/ARIALN.ttf", 30)
    SetScript(input, "OnSizeChanged", function(self, w, h) self:SetFont("Fonts\\ARIALN.ttf", h) end)
    return input
end

function MakeSlider(name, parent, template)
    local slider = CreateFrame("Slider", name, parent, template)
    slider:SetSize(100, 17)
    slider:SetPoint("CENTER", parent, "CENTER", 0, -50)
    slider:SetValueStep(1)
    slider:SetMinMaxValues(0, 100)
    slider:SetValue(0)
    local texture = MakeTexture(slider, nil, 1)
    texture:SetAllPoints(slider)
    local thumbTexture = MakeTexture(slider, 1)
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
    SetScript(button, "OnMouseUp", function() if GetCurrentKeyBoardFocus() then GetCurrentKeyBoardFocus():ClearFocus() end end)
    -- local texture = MakeTexture(button)
    -- texture:SetAllPoints(button)
    -- button:SetNormalTexture(texture)
    local fontstring = MakeFontString(button)
    fontstring:SetAllPoints(button)
    button:SetFontString(fontstring)
    SetScript(button, "OnSizeChanged", function(self, w, h) local fs = self:GetFontString() fs:SetFont(fs:GetFont(), h) end)
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
    SetScript(elem, "OnEnter", tooltip)
    SetScript(elem, "OnLeave", hidetooltip)
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
    SetScript(f, "OnDragStart", f.StartMoving)
    SetScript(f, "OnHide", f.StopMovingOrSizing)
    SetScript(f, "OnDragStop", f.StopMovingOrSizing)
    MakeTexture(f):SetAllPoints(f)

    local b = MakeButton(nil, f)
    b:SetPoint("TOPRIGHT")
    b:SetSize(10, 10)
    b:SetText("X")
    AllowTooltip(b, "close the menu")
    MakeTexture(b):SetAllPoints(b)
    SetScript(b, "OnClick", function(self) self:GetParent():Hide() end)

    local selectall = MakeButton(nil, f)
    selectall:SetPoint("TOPRIGHT", b, "TOPLEFT")
    selectall:SetSize(10, 10)
    selectall:SetText("A")
    AllowTooltip(selectall, "select all")
    MakeTexture(selectall):SetAllPoints(selectall)
    SetScript(selectall, "OnClick", function(self) data:selectall() end)

    local selectinv = MakeButton(nil, f)
    selectinv:SetPoint("TOPRIGHT", selectall, "TOPLEFT")
    selectinv:SetSize(10, 10)
    selectinv:SetText("I")
    AllowTooltip(selectinv, "select inverse")
    MakeTexture(selectinv):SetAllPoints(selectinv)
    SetScript(selectinv, "OnClick", function(self) data:selectinverse() end)

    local clear = MakeButton(nil, f)
    clear:SetPoint("TOPRIGHT", selectinv, "TOPLEFT")
    clear:SetSize(10, 10)
    clear:SetText("C")
    AllowTooltip(clear, "clear the list")
    MakeTexture(clear):SetAllPoints(clear)
    SetScript(clear, "OnClick", function(self) data:clear() end)

    local i = MakeFontString(f)
    i:SetHeight(10)
    i:SetTextColor(0,0,0)
    i:SetText("Selection list")
    i:SetHeight(10)
    i:SetPoint("TOPLEFT", f, "TOPLEFT")
    i:SetPoint("TOPRIGHT", clear, "TOPLEFT")

    local r = MakeButton(nil, f)
    r:SetPoint("BOTTOMRIGHT")
    r:SetSize(10, 10)
    MakeTexture(r, 1):SetAllPoints(r)
    r:RegisterForDrag("LeftButton")
    SetScript(r, "OnDragStart", function(self) self:GetParent():StartSizing("BOTTOMRIGHT") end)
    SetScript(r, "OnDragStop", function(self) self:GetParent():StopMovingOrSizing() end)

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
            SetScript(delete, "OnClick", function()
                local idx = s:GetValue()+i
                command.gobdelete(data[idx].guid)
                data:del(data[idx].guid)
            end)
            local tele = MakeButton(nil, l)
            tele:SetSize(10, 10)
            tele:SetPoint("TOPRIGHT", delete, "TOPLEFT")
            tele:SetText("T")
            SetScript(tele, "OnClick", function()
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
            SetScript(t, "OnClick", function()
                local idx = s:GetValue()+i
                data[idx].selected = not data[idx].selected
                UpdateItemList()
            end)
            SetScript(t, "OnEnter", function(...)
                if IsShiftKeyDown() and IsControlKeyDown() then
                    local idx = s:GetValue()+i
                    data[idx].selected = IsAltKeyDown()
                    UpdateItemList()
                end
            end)
            l.label = t
            items[i] = l
        end
        UpdateItemList()
    end
    
    SetScript(c, "OnSizeChanged", UpdateListSize)
    SetScript(s, "OnValueChanged", UpdateItemList)
    f:EnableMouseWheel(true)
    SetScript(f, "OnMouseWheel", function(self, delta) s:SetValue(s:GetValue()-delta*(IsShiftKeyDown() and GetVisibleItemsCount()/4 or 1)) end)
    
    function data.uiupdater(self)
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
    SetScript(f, "OnDragStart", f.StartMoving)
    SetScript(f, "OnHide", f.StopMovingOrSizing)
    SetScript(f, "OnDragStop", f.StopMovingOrSizing)
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
    -- local function thing()
    --     local objs = StoredList:getselected()
    --     local a,b,c = normalize(rad(a:GetNumber())), normalize(rad(b:GetNumber())), normalize(rad(c:GetNumber()))
    --     for k,v in ipairs(objs) do
    --         command.gobturn(v.guid, a,b,c)
    --     end
    -- end
    local function mouse(self, delta)
        local value = self:GetNumber()
        if value ~= 0 then
            local final = value*delta*(IsShiftKeyDown() and 1 or 10)
            local selected = StoredList:getselected()
            for k,v in ipairs(selected) do
                v[self.key] = v[self.key] + rad(final)
                command.Move(v)
            end
        end
    end
    a = MakeInput(nil, f)
    AllowTooltip(a, "orientation")
    a.key = "yaw"
    a:SetText(1)
    a:SetHeight(height)
    a:SetPoint("TOPLEFT", l, "BOTTOMLEFT")
    a:SetPoint("TOPRIGHT", l, "BOTTOMRIGHT")
    --SetScript(a, "OnTextChanged", thing)
    SetScript(a, "OnMouseWheel", mouse)
    a:EnableMouseWheel(true)
    a:SetMaxLetters(5)
    b = MakeInput(nil, f)
    AllowTooltip(b, "pitch")
    b.key = "pitch"
    b:SetText(1)
    b:SetHeight(height)
    b:SetPoint("TOPLEFT", a, "BOTTOMLEFT")
    b:SetPoint("TOPRIGHT", a, "BOTTOMRIGHT")
    --SetScript(b, "OnTextChanged", thing)
    SetScript(b, "OnMouseWheel", mouse)
    b:EnableMouseWheel(true)
    b:SetMaxLetters(5)
    c = MakeInput(nil, f)
    c:SetText(1)
    AllowTooltip(c, "roll")
    c.key = "roll"
    c:SetHeight(height)
    c:SetPoint("TOPLEFT", b, "BOTTOMLEFT")
    c:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT")
    --SetScript(c, "OnTextChanged", thing)
    SetScript(c, "OnMouseWheel", mouse)
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
    f:SetSize(width, height*7)
    f:RegisterForDrag("LeftButton")
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    MakeTexture(f):SetAllPoints(f)
    SetScript(f, "OnDragStart", f.StartMoving)
    SetScript(f, "OnHide", f.StopMovingOrSizing)
    SetScript(f, "OnDragStop", f.StopMovingOrSizing)
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
    SetScript(spawn, "OnEnterPressed", function(self)
        local entry = self:GetNumber()
        if entry ~= 0 then
            command.gobadd(entry, function(info)
                self:AddHistoryLine(entry)
                command.gobinfoguid(info.guid, function(info2)
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
    SetScript(selectnear, "OnEnterPressed", function(self)
        local range = self:GetNumber()
        command.gobnear(range, function(info)
            for k,v in ipairs(info) do
                command.gobinfoguid(v.guid,
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
    SetScript(targetname, "OnEnterPressed", function(self)
        local namepart = self:GetText()
        command.gobtargetname(namepart, function(info)
            self:AddHistoryLine(namepart)
            command.gobinfoguid(info.guid, function(info2)
                StoredList:add(util.merge(info, info2))
            end)
        end)
    end)
    
    local targetentry = MakeInput(nil, f)
    AllowTooltip(targetentry, "Closest object having given entry")
    targetentry:SetMaxLetters(10)
    targetentry:SetNumeric(true)
    targetentry:SetHeight(height)
    targetentry:SetPoint("TOPLEFT", targetname, "BOTTOMLEFT")
    targetentry:SetPoint("TOPRIGHT", targetname, "BOTTOMRIGHT")
    SetScript(targetentry, "OnEnterPressed", function(self)
        local entry = self:GetNumber()
        if entry ~= 0 then
            command.gobtargetentry(entry, function(info)
                self:AddHistoryLine(entry)
                command.gobinfoguid(info.guid, function(info2)
                    StoredList:add(util.merge(info, info2))
                end)
            end)
        end
    end)
    
    local byguid = MakeInput(nil, f)
    AllowTooltip(byguid, "Select object by given guid")
    byguid:SetMaxLetters(10)
    byguid:SetNumeric(true)
    byguid:SetHeight(height)
    byguid:SetPoint("TOPLEFT", targetentry, "BOTTOMLEFT")
    byguid:SetPoint("TOPRIGHT", targetentry, "BOTTOMRIGHT")
    SetScript(byguid, "OnEnterPressed", function(self)
        local guid = self:GetNumber()
        if guid ~= 0 then
            command.gobinfoguid(guid, function(info)
                self:AddHistoryLine(guid)
                StoredList:add(info)
            end)
        end
    end)
    
    local target = MakeButton(nil, f)
    target:SetHeight(height)
    target:SetText("closest")
    AllowTooltip(target, "select closest object")
    target:SetPoint("TOPLEFT", byguid, "BOTTOMLEFT")
    target:SetPoint("TOPRIGHT", byguid, "BOTTOMRIGHT")
    SetScript(target, "OnClick", function(self)
        command.gobtarget(function(data1)
            command.gobinfoguid(data1.guid, function(data2)
                StoredList:add(util.merge(data1, data2))
            end)
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
    f:SetSize(width, height*6)
    f:RegisterForDrag("LeftButton")
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    MakeTexture(f):SetAllPoints(f)
    SetScript(f, "OnDragStart", f.StartMoving)
    SetScript(f, "OnHide", f.StopMovingOrSizing)
    SetScript(f, "OnDragStop", f.StopMovingOrSizing)
    f:RegisterForDrag("LeftButton")
    
    local l = MakeLayer(f)
    l:SetPoint("TOPLEFT")
    l:SetPoint("TOPRIGHT")
    l:SetHeight(height)

    local orients_text = {"P", "O", "C"}
    local changeorient = MakeButton(nil, l)
    changeorient:SetPoint("TOPRIGHT")
    changeorient:SetSize(10, 10)
    changeorient.orient = 0
    changeorient:SetText(orients_text[(changeorient.orient%#orients_text)+1])
    AllowTooltip(changeorient, "Object is moved relative to\nP: player\nO: object\nC: compass")
    MakeTexture(changeorient):SetAllPoints(changeorient)
    SetScript(changeorient, "OnClick", function(self)
        self.orient = self.orient+1
        self:SetText(orients_text[(self.orient%#orients_text)+1])
    end)

    local move = MakeButton(nil, l)
    move:SetPoint("TOPRIGHT", changeorient, "TOPLEFT")
    move:SetSize(10, 10)
    move:SetText("M")
    AllowTooltip(move, "Move objects to your position")
    MakeTexture(move):SetAllPoints(move)
    SetScript(move, "OnClick", function(self)
        local objs = StoredList:getselected()
        command.gpsplayer(function(gpsplayer)
            print("woob")
            for k,v in ipairs(objs) do
                v.x, v.y, v.z = gpsplayer.x, gpsplayer.y, gpsplayer.z
                command.Move(v)
            end
        end)
    end)
    
    local t = MakeFontString(l)
    t:SetPoint("TOPLEFT")
    t:SetPoint("TOPRIGHT", move, "TOPLEFT")
    t:SetHeight(height)
    t:SetTextColor(0,0,0)
    t:SetText("Move")
    
    local function mouse(self, delta)
        local value = delta*self:GetNumber()
        if IsShiftKeyDown() then value = value/10 end
        if IsAltKeyDown() then value = value/100 end
        if IsControlKeyDown() then value = value/1000 end
        if value == 0 then return end
        local objs = StoredList:getselected()
        for k,v in ipairs(objs) do
            local offset = {x=0,y=0,z=0}
            offset[self.key] = value
            local orients = {GetPlayerFacing(), v.yaw, 0}
            local x, y, o = offset.x, offset.y, deg(orients[((changeorient.orient or 1)%(#orients))+1])
            offset.x = x*cos(o)-y*sin(o)
            offset.y = x*sin(o)+y*cos(o)
            v.x, v.y, v.z = v.x+offset.x, v.y+offset.y, v.z+offset.z
            command.Move(v)
        end
    end

    local x = MakeInput(nil, f)
    AllowTooltip(x, "forwards/backwards")
    x.key = "x"
    x:SetText(1)
    x:SetHeight(height)
    x:SetPoint("TOPLEFT", l, "BOTTOMLEFT")
    x:SetPoint("TOPRIGHT", l, "BOTTOMRIGHT")
    SetScript(x, "OnMouseWheel", mouse)
    x:EnableMouseWheel(true)

    local y = MakeInput(nil, f)
    AllowTooltip(y, "left/right")
    y.key = "y"
    y:SetText(1)
    y:SetHeight(height)
    y:SetPoint("TOPLEFT", x, "BOTTOMLEFT")
    y:SetPoint("TOPRIGHT", x, "BOTTOMRIGHT")
    SetScript(y, "OnMouseWheel", mouse)
    y:EnableMouseWheel(true)

    local z = MakeInput(nil, f)
    AllowTooltip(z, "up/down")
    z.key = "z"
    z:SetText(1)
    z:SetHeight(height)
    z:SetPoint("TOPLEFT", y, "BOTTOMLEFT")
    z:SetPoint("TOPRIGHT", y, "BOTTOMRIGHT")
    SetScript(z, "OnMouseWheel", mouse)
    z:EnableMouseWheel(true)

    local copydimensions = MakeInput(nil, f)
    AllowTooltip(copydimensions, "load dimensions of given object entry. Click, input a number and press enter.")
    copydimensions:SetNumeric(true)
    copydimensions:SetMaxLetters(10)
    copydimensions:SetHeight(height)
    copydimensions:SetPoint("TOPLEFT", z, "BOTTOMLEFT")
    copydimensions:SetPoint("TOPRIGHT", z, "BOTTOMRIGHT")
    SetScript(copydimensions, "OnEnterPressed", function(self)
        command.gobinfoentry(self:GetNumber(), function(info)
            x:SetText((info.maxx-info.minx)*info.size)
            y:SetText((info.maxy-info.miny)*info.size)
            z:SetText((info.maxz-info.minz)*info.size)
        end)
    end)

    local copydimensionsbutton = MakeButton(nil, f)
    AllowTooltip(copydimensionsbutton, "load dimensions of first found selected object")
    copydimensionsbutton:SetText("Load")
    copydimensionsbutton:SetHeight(height)
    copydimensionsbutton:SetPoint("TOPLEFT", copydimensions, "BOTTOMLEFT")
    copydimensionsbutton:SetPoint("TOPRIGHT", copydimensions, "BOTTOMRIGHT")
    SetScript(copydimensionsbutton, "OnClick", function(self)
        local selected = StoredList:getselected()
        if selected[1] then
          command.gobinfoentry(selected[1].entry, function(info)
              x:SetText((info.maxx-info.minx)*info.size)
              y:SetText((info.maxy-info.miny)*info.size)
              z:SetText((info.maxz-info.minz)*info.size)
          end)
        end
    end)

    local rotatearoundplayer = MakeInput(nil, f)
    AllowTooltip(rotatearoundplayer, "rotate objects around player")
    rotatearoundplayer:SetText(1)
    rotatearoundplayer:SetHeight(height)
    rotatearoundplayer:SetPoint("TOPLEFT", copydimensionsbutton, "BOTTOMLEFT")
    rotatearoundplayer:SetPoint("TOPRIGHT", copydimensionsbutton, "BOTTOMRIGHT")
    SetScript(rotatearoundplayer, "OnMouseWheel", function(self, delta)
        local odiff = delta*self:GetNumber() -- deg
        local selected = StoredList:getselected()
        command.gpsplayer(function(gpsplayer)
            for k,v in ipairs(selected) do
                local x, y, o = v.x-gpsplayer.x, v.y-gpsplayer.y, odiff
                local x1 = x*cos(o)-y*sin(o)
                local y1 = x*sin(o)+y*cos(o)
                v.x, v.y, v.yaw = gpsplayer.x+x1, gpsplayer.y+y1, v.yaw+rad(odiff)
                command.Move(v)
            end
        end)
    end)
    rotatearoundplayer:EnableMouseWheel(true)

    local rotatearoundgob = MakeInput(nil, f)
    AllowTooltip(rotatearoundgob, "rotate objects around their center of mass")
    rotatearoundgob:SetText(1)
    rotatearoundgob:SetHeight(height)
    rotatearoundgob:SetPoint("TOPLEFT", rotatearoundplayer, "BOTTOMLEFT")
    rotatearoundgob:SetPoint("TOPRIGHT", rotatearoundplayer, "BOTTOMRIGHT")
    SetScript(rotatearoundgob, "OnMouseWheel", function(self, delta)
        local odiff = delta*self:GetNumber() -- deg
        local selected = StoredList:getselected()
        
        -- calculate center point
        local centerx, centery = 0,0
        for k,v in ipairs(selected) do
            centerx = centerx+v.x
            centery = centery+v.y
        end
        centerx = centerx/#selected
        centery = centery/#selected
        
        -- move around center
        for k,v in ipairs(selected) do
            local x, y, o = v.x-centerx, v.y-centery, odiff
            local x1 = x*cos(o)-y*sin(o)
            local y1 = x*sin(o)+y*cos(o)
            v.x, v.y, v.yaw = centerx+x1, centery+y1, v.yaw+rad(odiff)
            command.Move(v)
        end
    end)
    rotatearoundgob:EnableMouseWheel(true)
    
    f:Show()
end
MakeMover()

local function MakeMassAction()
    local width = 32
    local height = 10
    local f = CreateFrame("Frame", "massaction")
    f:SetToplevel(true)
    f:SetSize(width, height*9)
    f:RegisterForDrag("LeftButton")
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    MakeTexture(f):SetAllPoints(f)
    SetScript(f, "OnDragStart", f.StartMoving)
    SetScript(f, "OnHide", f.StopMovingOrSizing)
    SetScript(f, "OnDragStop", f.StopMovingOrSizing)
    f:RegisterForDrag("LeftButton")
    
    local l = MakeFontString(f)
    l:SetPoint("TOPLEFT")
    l:SetPoint("TOPRIGHT")
    l:SetHeight(height)
    l:SetTextColor(0,0,0)
    l:SetText("Actions")
    
    local delete = MakeButton(nil, f)
    delete:SetText("Delete")
    AllowTooltip(delete, "delete selected objects")
    delete:SetHeight(height)
    delete:SetPoint("TOPLEFT", l, "BOTTOMLEFT")
    delete:SetPoint("TOPRIGHT", l, "BOTTOMRIGHT")
    SetScript(delete, "OnClick", function(self)
        local objs = StoredList:getselected()
        for k,v in ipairs(objs) do
            StoredList:del(v.guid)
            command.gobdelete(v.guid)
        end
    end)
    
    local ground = MakeButton(nil, f)
    ground:SetText("Ground")
    AllowTooltip(ground, "move selected objects to ground level")
    ground:SetHeight(height)
    ground:SetPoint("TOPLEFT", delete, "BOTTOMLEFT")
    ground:SetPoint("TOPRIGHT", delete, "BOTTOMRIGHT")
    SetScript(ground, "OnClick", function(self)
        local objs = StoredList:getselected()
        for k,v in ipairs(objs) do
            command.gpsgob(v.guid, function(gps)
                v.z = gps.groundz
                command.Move(v)
            end)
        end
    end)
    
    local floor = MakeButton(nil, f)
    floor:SetText("Floor")
    AllowTooltip(floor, "move selected objects to closest floor contact")
    floor:SetHeight(height)
    floor:SetPoint("TOPLEFT", ground, "BOTTOMLEFT")
    floor:SetPoint("TOPRIGHT", ground, "BOTTOMRIGHT")
    SetScript(floor, "OnClick", function(self)
        local objs = StoredList:getselected()
        for k,v in ipairs(objs) do
            command.gpsgob(v.guid, function(gps)
                v.z = gps.floorz
                command.Move(v)
            end)
        end
    end)
    
    local X = MakeButton(nil, f)
    X:SetText("X")
    AllowTooltip(X, "move selected objects to your X coordinate")
    X:SetHeight(height)
    X:SetPoint("TOPLEFT", floor, "BOTTOMLEFT")
    X:SetPoint("TOPRIGHT", floor, "BOTTOMRIGHT")
    SetScript(X, "OnClick", function(self)
        local objs = StoredList:getselected()
        for k,v in ipairs(objs) do
            command.gpsplayer(function(gpsplayer)
                v.x = gpsplayer.x
                command.Move(v)
            end)
        end
    end)
    
    local Y = MakeButton(nil, f)
    Y:SetText("Y")
    AllowTooltip(Y, "move selected objects to your Y coordinate")
    Y:SetHeight(height)
    Y:SetPoint("TOPLEFT", X, "BOTTOMLEFT")
    Y:SetPoint("TOPRIGHT", X, "BOTTOMRIGHT")
    SetScript(Y, "OnClick", function(self)
        local objs = StoredList:getselected()
        for k,v in ipairs(objs) do
            command.gpsplayer(function(gpsplayer)
                v.y = gpsplayer.y
                command.Move(v)
            end)
        end
    end)
    
    local Z = MakeButton(nil, f)
    Z:SetText("Z")
    AllowTooltip(Z, "move selected objects to your Z coordinate")
    Z:SetHeight(height)
    Z:SetPoint("TOPLEFT", Y, "BOTTOMLEFT")
    Z:SetPoint("TOPRIGHT", Y, "BOTTOMRIGHT")
    SetScript(Z, "OnClick", function(self)
        local objs = StoredList:getselected()
        for k,v in ipairs(objs) do
            command.gpsplayer(function(gpsplayer)
                v.z = gpsplayer.z
                command.Move(v)
            end)
        end
    end)
    
    local O = MakeButton(nil, f)
    O:SetText("Rotation")
    AllowTooltip(O, "rotate selected objects to your orientation")
    O:SetHeight(height)
    O:SetPoint("TOPLEFT", Z, "BOTTOMLEFT")
    O:SetPoint("TOPRIGHT", Z, "BOTTOMRIGHT")
    SetScript(O, "OnClick", function(self)
        local objs = StoredList:getselected()
        for k,v in ipairs(objs) do
            v.yaw = GetPlayerFacing()
            command.Move(v)
        end
    end)
    
    local copy = MakeButton(nil, f)
    copy:SetText("Dupe")
    AllowTooltip(copy, "spawn copies of selected objects")
    copy:SetHeight(height)
    copy:SetPoint("TOPLEFT", O, "BOTTOMLEFT")
    copy:SetPoint("TOPRIGHT", O, "BOTTOMRIGHT")
    SetScript(copy, "OnClick", function(self)
        local objs = StoredList:getselected()
        for k,v in ipairs(objs) do
            v.selected = false
            command.gobadd(v.entry, function(info)
                local c = util.copy(v)
                c.guid = info.guid
                StoredList:add(c)
                command.Move(c)
            end)
        end
        StoredList:update()
    end)
    
    f:Show()
end
MakeMassAction()

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

function MakeClipboard()
    local height = 10
    local f = MakeFrame("clipboard")
    f:SetToplevel(true)
    f:SetSize(30, height*5)
    f:RegisterForDrag("LeftButton")
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    MakeTexture(f):SetAllPoints(f)
    SetScript(f, "OnDragStart", f.StartMoving)
    SetScript(f, "OnHide", f.StopMovingOrSizing)
    SetScript(f, "OnDragStop", f.StopMovingOrSizing)
    f:RegisterForDrag("LeftButton")
    
    local l = MakeFontString(f)
    l:SetPoint("TOPLEFT")
    l:SetPoint("TOPRIGHT")
    l:SetHeight(height)
    l:SetTextColor(0,0,0)
    l:SetText("Clipboard")
    
    local clip = {playerorientation = 0, data = {}}
    local copy = MakeButton(nil, f)
    copy:SetText("Copy")
    AllowTooltip(copy, "place selected objects to clipboard")
    copy:SetHeight(height)
    copy:SetPoint("TOPLEFT", l, "BOTTOMLEFT")
    copy:SetPoint("TOPRIGHT", l, "BOTTOMRIGHT")
    SetScript(copy, "OnClick", function(self)
        local selected = StoredList:getselected()
        command.gpsplayer(function(gpsplayer)
            clip.playerorientation = GetPlayerFacing()
            clip.data = {}
            for k,v in ipairs(selected) do
                tinsert(clip.data, {entry = v.entry, x=v.x-gpsplayer.x, y=v.y-gpsplayer.y, z=v.z-gpsplayer.z, yaw=v.yaw, pitch=v.pitch, roll=v.roll})
            end
        end)
    end)
    local cut = MakeButton(nil, f)
    cut:SetText("Cut")
    AllowTooltip(cut, "place selected objects to clipboard and delete them")
    cut:SetHeight(height)
    cut:SetPoint("TOPLEFT", copy, "BOTTOMLEFT")
    cut:SetPoint("TOPRIGHT", copy, "BOTTOMRIGHT")
    SetScript(cut, "OnClick", function(self)
        local selected = StoredList:getselected()
        command.gpsplayer(function(gpsplayer)
            clip.playerorientation = GetPlayerFacing()
            clip.data = {}
            for k,v in ipairs(selected) do
                command.gpsgob(v.guid, function(gps)
                    if gpsplayer.map == gps.map then
                        tinsert(clip.data, {entry = v.entry, x=v.x-gpsplayer.x, y=v.y-gpsplayer.y, z=v.z-gpsplayer.z, yaw=v.yaw, pitch=v.pitch, roll=v.roll})
                        command.gobdelete(v.guid, function() StoredList:del(v.guid) end)
                    end
                end)
            end
        end)
    end)
    
    local paste = MakeButton(nil, f)
    paste:SetText("Paste")
    AllowTooltip(paste, "paste clipboard relative to player xyz")
    paste:SetHeight(height)
    paste:SetPoint("TOPLEFT", cut, "BOTTOMLEFT")
    paste:SetPoint("TOPRIGHT", cut, "BOTTOMRIGHT")
    SetScript(paste, "OnClick", function(self)
        for k,v in ipairs(clip.data) do
            command.gobadd(v.entry, function(info)
                info = util.merge(v, info)
                info.x, info.y, info.z, info.yaw, info.pitch, info.roll = info.x+v.x, info.y+v.y, info.z+v.z, v.yaw, v.pitch, v.roll
                StoredList:add(info)
                command.Move(info)
            end)
        end
    end)
    
    local pasterelative = MakeButton(nil, f)
    pasterelative:SetText("Paste relative")
    AllowTooltip(pasterelative, "paste clipboard relative to player xyz and orientation")
    pasterelative:SetHeight(height)
    pasterelative:SetPoint("TOPLEFT", paste, "BOTTOMLEFT")
    pasterelative:SetPoint("TOPRIGHT", paste, "BOTTOMRIGHT")
    SetScript(pasterelative, "OnClick", function(self)
        local odiff = GetPlayerFacing() - clip.playerorientation
        for k,v in ipairs(clip.data) do
            command.gobadd(v.entry, function(info)
                info = util.merge(v, info)
                local x, y, o = v.x, v.y, deg(odiff)
                local x1 = x*cos(o)-y*sin(o)
                local y1 = x*sin(o)+y*cos(o)
                info.x, info.y, info.z, info.yaw, info.pitch, info.roll = info.x+x1, info.y+y1, info.z+v.z, v.yaw+odiff, v.pitch, v.roll
                StoredList:add(info)
                command.Move(info)
            end)
        end
    end)
end
MakeClipboard()

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_SYSTEM")
SetScript(f, "OnEvent", function(self, event, message)
    local guid = nil
    guid = guid or message:match("Game Object %(GUID: (%d+)%) removed")
    guid = guid or message:match("Game Object %(GUID: (%d+)%) not found")
    guid = tonumber(guid)
    if guid then
        StoredList:del(guid)
    end
end)

local old = ChatFrame_OnHyperlinkShow
function ChatFrame_OnHyperlinkShow(self, link, text, button, ...)
    old(self, link, text, button, ...)
    local kbf = GetCurrentKeyBoardFocus()
    if not kbf then return end
    if IsControlKeyDown() then
        local value = link:match("^[^:]*:([^:]*)")
        if value then
            kbf:Insert(value)
        end
    end
end

-- GOCommandSV.bindings = {{code = "", key = ""}}

function MakeScroll(slider, contentarea, item_create, item_show, item_hide)
    local items = {}
    local requireditems = 0
    local itemheight = 0

    slider:SetValueStep(1)

    local head = MakeLayer(contentarea)
    head:SetPoint("TOPLEFT")
    head:SetPoint("TOPRIGHT")
    head:SetPoint("BOTTOMLEFT", contentarea, "TOPLEFT")
    head:SetPoint("BOTTOMRIGHT", contentarea, "TOPRIGHT")
    
    local function GetVisibleItemsCount()
        return floor(contentarea:GetHeight()/itemheight)
    end
    
    local function UpdateItemList()
        local value = slider:GetValue()
        local visibleitems = GetVisibleItemsCount()
        for k,v in ipairs(items) do
            local idx = value+k
            if k > visibleitems or value+k>requireditems then
                item_hide(v, idx)
                v:Hide()
            else
                item_show(v, idx)
                v:Show()
            end
        end
    end

    local function UpdateListSize()
        for i = #items+1, GetVisibleItemsCount() do
            local contact = items[i-1] or head
            local l = MakeLayer(contentarea)
            l:SetPoint("TOPLEFT", contact, "BOTTOMLEFT")
            l:SetPoint("TOPRIGHT", contact, "BOTTOMRIGHT")
            l:SetHeight(itemheight)
            items[i] = l
            local idx = slider:GetValue()+i
            item_create(l, idx)
        end
        UpdateItemList()
    end
    
    SetScript(contentarea, "OnSizeChanged", UpdateListSize)
    SetScript(slider, "OnValueChanged", UpdateItemList)
    
    local function SetItemCount(count)
        assert(count >= 0)
        requireditems = count
        slider:SetMinMaxValues(0, max(requireditems-1, 0))
        UpdateItemList()
    end
    
    local function SetItemHeight(height)
        assert(height >= 0)
        itemheight = height
        for k,v in ipairs(items) do
            v:SetHeight(itemheight)
        end
        UpdateListSize()
    end
    
    return {
        SetItemCount = SetItemCount,
        SetItemHeight = SetItemHeight,
        UpdateListSize = UpdateListSize,
        UpdateItemList = UpdateItemList,
    }
end

-- local function CreateBindButton(keycomb)
--     local b = CreateFrame("Button", "GOCommand_KEYBIND_"..keycomb)
--     b:SetScript("OnClick", function(...) b.fn(...) end)
--     return b
-- end
-- local function bindings(h, ...)
--     return h, {...}
-- end
-- local frame = CreateFrame("Frame")
-- frame:SetScript("OnEvent", function(self, event, addonName)
--     if addonName ~= "GOCommand" then
--         return
--     end
--     GOCommandSV.bindings = GOCommandSV.bindings or {}
--     for k,v in ipairs(GOCommandSV.bindings) do
--         local fn = assert(loadstring(v.code))
--         local btn = CreateBindButton(v.keycomb)
--         btn.fn = fn
--         SetOverrideBinding(frame, false, v.keycomb, "CLICK "..btn:GetName());
--     end
    
--     local f = MakeFrame("binder")
--     f:SetToplevel(true)
--     f:SetMinResize(10*4, 10*3)
--     f:SetSize(100, 100)
--     f:RegisterForDrag("LeftButton")
--     f:SetPoint("CENTER")
--     f:EnableMouse(true)
--     f:SetMovable(true)
--     f:SetResizable(true)
--     f:SetClampedToScreen(true)
--     MakeTexture(f):SetAllPoints(f)
--     SetScript(f, "OnDragStart", f.StartMoving)
--     SetScript(f, "OnHide", f.StopMovingOrSizing)
--     SetScript(f, "OnDragStop", f.StopMovingOrSizing)
--     f:RegisterForDrag("LeftButton")

--     local key = MakeButton(nil, f)
--     key:SetPoint("TOPLEFT", f, "BOTTOMLEFT")
--     key:SetSize(150, 10)
--     MakeTexture(key):SetAllPoints(key)
--     SetScript(key, "OnClick", function(self)
--         self:EnableKeyboard(true)
--     end)
--     SetScript(key, "OnKeyDown", function(self, key)
--         if key == "LSHIFT" then return end
--         if key == "LCTRL" then return end
--         if key == "LALT" then return end
--         if key == "RSHIFT" then return end
--         if key == "RCTRL" then return end
--         if key == "RALT" then return end
--         local prefix = ""
--         prefix = prefix..(IsAltKeyDown() and "ALT-" or "")
--         prefix = prefix..(IsControlKeyDown() and "CTRL-" or "")
--         prefix = prefix..(IsShiftKeyDown() and "SHIFT-" or "")
--         local keycomb = (prefix..key):upper()
--         if self.boundkeycomb then
--             SetOverrideBinding(frame, false, self.boundkeycomb, nil)
--         end
--         self.boundkeycomb = keycomb
--         self:SetText(keycomb)
--         local btn = _G["GOCommand_KEYBIND_"..keycomb] or CreateBindButton(keycomb)
--         SetOverrideBindingClick(frame, false, keycomb, btn:GetName())
--         btn.fn = function() print(keycomb) end
--         self:EnableKeyboard(false)
--     end)
    
--     sf = CreateFrame("ScrollFrame")
--     sf:SetPoint("LEFT", f, "RIGHT")
--     sf:SetSize(100, 100)
    
--     local codebox = MakeInput(sf)
--     codebox:SetAllPoints(sf)
--     codebox:SetMultiLine(true)
--     codebox:SetScript("OnSizeChanged", nil)
--     codebox:SetScript("OnEnterPressed", nil)
--     codebox:SetFont("Fonts\\ARIALN.ttf", 10)
    
--     codebox:SetScript("OnCursorChanged", function(this, arg1, arg2, arg3, arg4)
--         local vs = this:GetParent():GetVerticalScroll();
--         local h  = this:GetParent():GetHeight();

--         if vs+arg2 > 0 or 0 > vs+arg2-arg4+h then
--             this:GetParent():SetVerticalScroll(arg2*-1);
--         end
--     end)
    
--     sf:SetScrollChild(codebox)
    
--     local bindings = MakeLayer(f)
--     bindings:SetAllPoints(f)
    
--     local s = MakeSlider(nil, f)
--     s:SetWidth(10)
--     s:SetOrientation("VERTICAL")
--     s:SetPoint("TOPRIGHT", bindings, "TOPLEFT")
--     s:SetPoint("BOTTOMRIGHT", bindings, "BOTTOMLEFT")
    
--     local function item_create(v, idx)
--         local fs = MakeFontString(v)
--         fs:SetAllPoints(v)
--         fs:SetText("UNKNOWN")
--     end
    
--     local function item_show(v, idx)
--     end
    
--     local function item_hide(v, idx)
--     end
    
--     local funks = MakeScroll(s, bindings, item_create, item_show, item_hide)
--     funks.SetItemHeight(10)
--     funks.SetItemCount(#GOCommandSV.bindings)
--     funks.SetItemCount(1)
-- end)
-- frame:RegisterEvent("ADDON_LOADED")