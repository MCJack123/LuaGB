local require_paths = {"/rom/apis"}

local function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

_G.require = {}

function require.path()
    local str = ""
    for k,v in ipairs(require_paths) do if str == "" then str = v else str = str .. ":" .. v end end
    return str
end

function require.setPath(str)
    require_paths = split(str, ":")
end

function require.addPath(str)
    table.insert(require_paths, str)
end

function require.require(api)
    if api == "bit32" or api == "bit" then return bit end
    for k,v in pairs(require_paths) do 
        if fs.exists(v .. "/" .. api .. ".lua") then return dofile(v .. "/" .. api .. ".lua")
        elseif fs.exists(v .. "/" .. api .. "/init.lua") then return dofile(v .. "/" .. api .. "/init.lua") end
    end
    return nil
end

setmetatable(require, {__call = require.require})
return require