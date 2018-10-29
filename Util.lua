assert(not GOCommand)
GOCommand = {}
GOCommand.util = {}
local util = GOCommand.util

function util.assertnotnil(v, ...)
    assert(v ~= nil)
    return v, ...
end

function util.asserttype(expectedtype, ...)
    local n = select("#", ...)
    for i = 1, n do
        local actualtype = type(select(i, ...))
        assert(actualtype == expectedtype, string.format("assertion failed for argument %d: expected %s but got %s", 1+i, expectedtype, actualtype))
    end
    return ...
end

function util.tonumberall(...)
    util.assertnotnil(...)
    local t = {...}
    local n = select("#", ...)
    for i = 1, n do
        t[i] = tonumber(t[i])
    end
    return unpack(t, 1, n)
end

function util.inttobool(...)
    local t = {...}
    local n = select("#", ...)
    for i = 1, n do
        assert(type(t[i]) == "number")
        t[i] = t[i] ~= 0
    end
    return unpack(t, 1, n)
end

function util.ppairs(t)
    for k,v in pairs(t) do
        print(k,v)
    end
    return t
end

function util.pipairs(t)
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
function util.merge(...)
    local t = {}
    merge_helper(t, ...)
    return t
end

function util.parseunitguid(guid)
    local typeid, entry, lowguid = util.tonumberall(string.match(guid, "0x(0000)(0000)(%d%d%d%d%d%d%d%d)"))
    return {typeid = typeid, lowguid = lowguid, entry = entry}
end

function util.copy(t, ...)
    local n = select("#", ...)
    local c = {}
    if n > 0 then
        for i = 1, n do
            local k = select(i, ...)
            local v = t[k]
            c[k] = v
        end
    else
        for k,v in pairs(t) do
            c[k] = v
        end
    end
    return c
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
function util.makecallback(parser, callback, errhandler)
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
