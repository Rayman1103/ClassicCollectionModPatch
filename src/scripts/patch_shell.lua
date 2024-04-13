print("patch_shell start")

--[[
  for patching ifs_ shell menu screens, we'll want to 'Catch' when they are passed to 'AddIfScreen'.
  We can manipulate/adjust the screen structure at that time. Adding buttons, adjusting location...
  But after 'AddIfScreen' is called, messing with the screen will make it look all janky or
  it won't work at all.


  For replacing a screen we can override 'ScriptCB_PushScreen' and/or 'ScriptCB_SetIFScreen'.
  'ScriptCB_SetIFScreen' is used infrequently though.
  (Prefer to do this in the '0' addme though)
]]

if (printf == nil) then
    function printf(...)
        print(string.format(unpack(arg)))
    end
end

if (tprint == nil) then
    function getn(v)
        local v_type = type(v);
        if v_type == "table" then
            return table.getn(v);
        elseif v_type == "string" then
            return string.len(v);
        else
            return;
        end
    end

    if string.starts == nil then
        function string.starts(str, Start)
            return string.sub(str, 1, string.len(Start)) == Start;
        end
    end

    function tprint(t, indent)
        if not indent then
            indent = 1, print(tostring(t) .. " {")
        end
        if t then
            for key, value in pairs(t) do
                if not string.starts(tostring(key), "__") then
                    local formatting = string.rep("    ", indent) .. tostring(key) .. "= ";
                    if value and type(value) == "table" then
                        print(formatting .. --[[tostring(value) ..]] " {")
                        tprint(value, indent + 1);
                    else
                        if (type(value) == "string") then
                            -- print(formatting .."'" .. tostring(value) .."'" ..",")
                            printf("%s'%s',", formatting, tostring(value))
                        else
                            print(formatting .. tostring(value) .. ",")
                        end
                    end
                end
            end
            print(string.rep("    ", indent - 1) .. "},")
        end
    end
end

if IsFileExist == nil then
    print("patch_shell: defining IsFileExist")
    IsFileExist = function(path)
        local testPath = "..\\..\\" .. path
        return ScriptCB_IsFileExist(testPath)
    end
end

ScriptCB_DoFile("zero_patch_fs")

-- trim "path\\to\\file.lvl" to "file"
function trimToFileName(filePath)
    -- Find the last directory separator
    local nameStart = 1
    local sepStart, sepEnd = string.find(filePath, "[/\\]", nameStart)
    while sepStart do
        nameStart = sepEnd + 1
        sepStart, sepEnd = string.find(filePath, "[/\\]", nameStart)
    end

    -- Extract the file name part
    local fileName = string.sub(filePath, nameStart)

    -- Attempt to remove the extension
    local dotPosition = string.find(fileName, ".[^.]*$")
    if dotPosition then
        fileName = string.sub(fileName, 1, dotPosition - 1)
    end

    return fileName
end


--================== CUSTOM Galactic Conquest Framework Begin ====================

function custom_PressedGCButton(tag)
    print("custom_PressedGCButton()")

    -- if we didn't handle this, return false
    return false
end

function custom_GetGCButtonList()
    print("custom_GetGCButtonList()")
    return {
        -- { tag = "1", string = "ifs.meta.Configs.1", },
        -- { tag = "2", string = "ifs.meta.Configs.2", },
        -- { tag = "3", string = "ifs.meta.Configs.3", },
        -- { tag = "4", string = "ifs.meta.Configs.4", },
        -- { tag = "custom", string = "ifs.meta.Configs.custom", },
        -- { tag = "campaign", string = "ifs.sp.campaign1.title", },
        -- { tag = "load", string = "ifs.meta.load.btnload", },
    }
end

function RunCustomGCFiles()
    print("info: RunCustomGCFiles START")
    local scriptName = ""
    local files = zero_patch_fs.getFiles("custom_gc")

    for i, value in ipairs(files) do
        if (string.find(value, "custom_gc_10.lvl")) then
            --  skip custom_gc_10, because that was a special one
            --  from zerted that loaded more custom_gc lvls
        else
            scriptName = trimToFileName(value)
            ReadDataFile(value)
            ScriptCB_DoFile(scriptName)
        end
    end
    print("info: RunCustomGCFiles END")
end
--================== CUSTOM Galactic Conquest Framework End ====================

-- good point of entry for the zero patch is just after the basic interface stuff is defined and
-- before the ifs screens are defined because we give a 'modify' oppurtunity to the gc scripts.
local old_ScriptCB_DoFile = ScriptCB_DoFile
ScriptCB_DoFile = function(...)
    -- print("ScriptCB_DoFile: " .. arg[1])
    if (arg[1] == "ifs_movietrans") then
        SetupZeroPatchDebugLog()
        local status, err = pcall(RunCustomGCFiles)
        if not status then
            local msg = "error caught in 'RunCustomGCFiles': " .. err
            print(msg)
        else
            -- Successful execution
        end
    end
    return old_ScriptCB_DoFile(unpack(arg))
end

-- filter debug messages to messages with 'info:', 'error' or 'warn' in them.
-- TODO: consider providing an override option where everything goes into the debug log? (when 'addon/0/debug.txt' exists?)
function zero_patch_is_worthy_for_debug(str)
    local test = string.lower(str)
    if (string.find(test, 'error') or string.find(test, 'warn') or string.find(test, 'info:') or
        string.find(test, 'debug')) then
        return true
    end
    return false
end

function SetupZeroPatchDebugLog()
    print("info: SetupZeroPatchDebugLog start")
    ScriptCB_DoFile("ifs_ingame_log")
    local oldPrint = print
    print = function(...)
        if (ifs_ingame_log ~= nil and zero_patch_is_worthy_for_debug(arg[1])) then
            ifs_ingame_log:AddToList(arg[1])
        end
        oldPrint(unpack(arg))
    end
    print("info: SetupZeroPatchDebugLog end")
end

print("patch_shell end")
