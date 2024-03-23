
-- first things game_interface does: 	
--  gPlatformStr = ScriptCB_GetPlatform()
--  gOnlineServiceStr = ScriptCB_GetConnectType()
--  gLangStr,gLangEnum = ScriptCB_GetLanguage()
--  ScriptCB_DoFile("globals") -- our 'patch' is called from here

-- last  thing game_interface does: 	ScriptCB_DoFile("ifs_mpgs_friends")

print("Patch ingame start")

-- this will get the Fake console & Free Cam buttons to show
gFinalBuild = false

print("gFinalBuild: " .. tostring(gFinalBuild))

ScriptCB_DoFile("utility_functions2")
--print("game_interface: Reading in custom strings")
--ReadDataFile("v1.3patch_strings.lvl") -- where to put, root of'0'?

-- trim "path\\to\\file.lvl" to "file"
function trimToFileName(filePath)
    local separatorIndex = 0
    local lastSeparatorIndex = 0

    -- Find the last occurrence of '\\'
    local i = 1
    while true do
        local nextIndex = string.find(filePath, "\\", i, true)
        if nextIndex then
            lastSeparatorIndex = separatorIndex
            separatorIndex = nextIndex
            i = nextIndex + 1
        else
            break
        end
    end

    local extensionIndex = string.find(filePath, "%.[^.]+$") -- Find the last occurrence of '.' followed by characters not including '.'
    if extensionIndex then
        filePath = string.sub(filePath, 1, extensionIndex - 1) -- Trim file extension
    end

    -- Extract substring after the last separator
    if lastSeparatorIndex > 0 then
        return string.sub(filePath, lastSeparatorIndex + 1)
    else
        return filePath
    end
end

function RunUserScripts()

    print("RunUserScripts() Start")

    -- retrieve user scripts we saved in mission setup table
    if ScriptCB_IsMissionSetupSaved() then
        local missionSetup = ScriptCB_LoadMissionSetup()
        if missionSetup ~= nil then
            if missionSetup.userScripts ~= nil then
                for _, scriptPath in missionSetup.userScripts do
                    if ScriptCB_IsFileExist(scriptPath) then
                        ReadDataFile(scriptPath)
                        -- .lvl or .script file must contain a .lua file with matching name
                        -- that file will be the entrypoint of the user script
                        ScriptCB_DoFile(trimToFileName(scriptPath))
                    end
                end

                local hasOnlyUserScripts = true
                for key, value in missionSetup do
                    if key ~= "userScripts" then
                        hasOnlyUserScripts = false
                        break
                    end
                end

                if hasOnlyUserScripts then
                    -- if the missionSetup was only user scripts then clear items
                    ScriptCB_ClearMissionSetup()
                else
                    --remove the user scripts and save it again
                    --we don't really have to do this but i figure its a good idea
                    missionSetup.userScripts = nil
                    ScriptCB_SaveMissionSetup(missionSetup)
                end

            end

        end
    end

    print("RunUserScripts() End")
end
RunUserScripts()

function uop_PatchFakeConsole()
    print("uop_PatchFakeConsole start")
    ifs_fakeconsole.Enter = function(this, bFwd)
        gConsoleCmdList = {}
        
        -- MUST do this after AddIFScreen! This is done here, and not in
        -- Enter to make the memory footprint more consistent.
        fakeconsole_listbox_layout.FirstShownIdx = 1
        fakeconsole_listbox_layout.SelectedIdx = 1
        fakeconsole_listbox_layout.CursorIdx = 1
        ScriptCB_SndPlaySound("shell_menu_enter")
        --ScriptCB_GetConsoleCmds() -- puts contents in gConsoleCmdList
        ff_rebuildFakeConsoleList()
    
        ListManager_fnFillContents(ifs_fakeconsole.listbox,gConsoleCmdList,fakeconsole_listbox_layout)
    end
    
    ifs_fakeconsole.Input_Accept = function(this)
        if(gMouseListBoxSlider) then
            ListManager_fnScrollbarClick(gMouseListBoxSlider)
            return
        end
        if(gMouseListBox) then
            ScriptCB_SndPlaySound("shell_select_change")
            gMouseListBox.Layout.SelectedIdx = gMouseListBox.Layout.CursorIdx
            ListManager_fnFillContents(gMouseListBox,gMouseListBox.Contents,gMouseListBox.Layout)
    --			return
        end
    
        if(this.CurButton == "_back") then -- Make PC work better - NM 8/5/04
            this:Input_Back()
            return
        end
    
        local Selection = gConsoleCmdList[fakeconsole_listbox_layout.SelectedIdx]
        ScriptCB_SndPlaySound("shell_menu_enter");
        
        local r2 = fakeconsole_listbox_layout.CursorIdx
        local r3 = fakeconsole_listbox_layout.FirstShownIdx
        local r4 = r2 - r3 
        r4 = r4 +1 
        
        IFObj_fnSetColor(this.listbox[r4].showstr, 255,0,255)
        if ( Selection.run ) then 
            print("ifs_fakeconsole: Is runnable:", Selection.ShowStr, Selection.run)
            ff_serverDidFCCmd()
            Selection.run()
            IFObj_fnSetColor(this.listbox[r4].showstr,0,255,255)
        else 
            ScriptCB_DoConsoleCmd(Selection.ShowStr)
        end 
        --ScriptCB_PopScreen()
    end
    
    ifs_fakeconsole.Input_KeyDown = function( this, iKey ) 
        if (iKey  == 27 ) then  -- handle Escape 
            --this:Input_Back() -- soft locks BF CC
        end 
        --[[
            Keys that are handled in the ifs scripts:
            8: Backspace 
            9:  Tab 
            10: Newline 
            13: Carriage Return 
            27: Esc 
            32: Space 
            43: * 
            44: , 
            45: - 
            61: = 
            95: _ (underscore) 
            -59: F1 
            -211: Delete 
        ]]--
    end
    
    ifs_fakeconsole.Update = function(this, fDt ) 
        -- Yes; I'm aware this code looks really ugly.
        -- But it is functionally the same as the luac -l listing 
        --  -cbadal 
        local r2 = gConsoleCmdList
        local r3 = fakeconsole_listbox_layout.SelectedIdx
        r2 = r2[r3]
        if ( not  r2 ) then 
            return 
        end 
        r3 = this.lastDescribedCommand
        if ( r3 == fakeconsole_listbox_layout.SelectedIdx ) then 
            return 
        end 
        r3 = fakeconsole_listbox_layout
        r3 = r3.SelectedIdx
        this.lastDescribedCommand = r3 
        r3 = r2.ShowStr 
        if ( r3 == "" ) then 
            r2.info = "" 
        end 
        r3 = r2.info 
        if ( not r3  ) then 
            r3 = "Note: No known description"
        end 
        
        IFText_fnSetString(this.description,r3, this.description.case) 
    end
    print("uop_PatchFakeConsole end")
end

local function SetupAddIfScreenCatching()
    --[[
    for patching ifs_ menu screens, we'll want to 'Catch' when they are passed to 'AddIfScreen'.
    We can manipulate/adjust the screen structure at that time. Adding buttons, adjusting location...
    But after 'AddIfScreen' is called, messing with the screen will make it look all janky or
    it won't work at all.

    For replacing a screen we can override 'ScriptCB_PushScreen' and/or 'ScriptCB_SetIFScreen'.
    'ScriptCB_SetIFScreen' is used infrequently though.
    ]]
    print("Setup 'catch' point for ifs_fakeconsole")

    local old_AddIFScreen = AddIFScreen
    AddIFScreen = function(...)
        print("AddIFScreen: " .. arg[2])
        if( arg[2] == "ifs_fakeconsole") then 
            uop_PatchFakeConsole()
        end
        return old_AddIFScreen(unpack(arg))
    end
end

local function uop_do_files()
    ScriptCB_DoFile("fakeconsole_functions")
    ScriptCB_DoFile("popup_prompt")
end 

local old_ScriptCB_DoFile = ScriptCB_DoFile
ScriptCB_DoFile = function(...)
    print("ScriptCB_DoFile: " .. arg[1])
    if(arg[1] == "ifs_pausemenu") then 
        uop_do_files() -- do these before pause menu
    elseif(arg[1] == "ifs_opt_top")then
        SetupAddIfScreenCatching()
    end
    return old_ScriptCB_DoFile(unpack(arg))
end 