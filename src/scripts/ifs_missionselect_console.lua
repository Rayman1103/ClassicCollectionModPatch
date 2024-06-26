-- ifs_missionselect_console_console.lua
--
-- attempt to use console version of mission select screen
-- Copyright (c) 2005 Pandemic Studios, LLC. All rights reserved.
--

-- Generalized mission select screen. Done to unify the varions
-- screens. BF1 unified to one screen for a while, then was fractured
-- for the platforms. Let's try and keep this together once again!

-- Internal set of pages:
-- this.iColumn == 0   -> map selection column
-- this.iColumn == 1   -> mode selection column
-- this.iColumn == 2   -> era selection column
-- this.iColumn == 3   -> playlist selection column
-- this.iColumn == 4   -> Game Options button at bottom
-- this.iColumn == 5   -> Launch Game button at bottom
-- this.iColumn == 6   -> Sorted/Random Order button at bottom
-- 
-- The built-up list of maps is put in gPickedMaplist, which has
-- entries in the following form:
--
-- gPickedMapList = {
--   { Map = "nab1c", Side = 1, SideChar = "r" },
--   { ... }
-- }

function GetUOPChangeTableFor(key)
	local chg = nil
	local currentMapListEntry = missionselect_listbox_contents[ifs_ms_MapList_layout_console.SelectedIdx]
	if( currentMapListEntry ~= nil and currentMapListEntry.change ~= nil and 
		currentMapListEntry.change[key] ~= nil) then
		chg = currentMapListEntry.change[key]
	end
	return chg
end

-- new state machine to manages hiding/showing of various list boxes.
local ifs_ms_state = {
	map = 0,			-- select map
	mode = 1,			-- select game mode
	era = 2, 			-- select era
	command = 3,			-- map commands: launch, add, remove, options
	playlist = 4,		-- select which map to remove from playlist
}

-- Helper function. Given a layout (x,y,width, height), returns a
-- fully-built item.
function ifs_ms_MapList_CreateItem_console(layout)
	-- Make a coordinate system pegged to the top-left of where the cursor would go.
	local Temp = NewIFContainer { 
		x = layout.x - 0.5 * layout.width, 
		y = layout.y,
		bHotspot = true,
		fHotspotH = layout.height,
		fHotspotW = layout.width,
		fHotspotX = 0,
		fHotspotY = -layout.height /2,
	}
	

	Temp.map = NewIFText { 
		x = 8,
		y = layout.height * -0.5 + 2,
		halign = "left", valign = "top",
		font = ifs_missionselect_console.listboxfont,
		textw = layout.width - 10, texth = layout.height,
		startdelay=math.random()*0.5, nocreatebackground=1, 
	}

	return Temp
end

-- Helper function. Given a layout (x,y,width, height), returns a
-- fully-built item.
function ifs_ms_ModeList_CreateItem_console(layout)
	-- Make a coordinate system pegged to the top-left of where the cursor would go.
	local Temp = NewIFContainer { 
		x = layout.x - 0.5 * layout.width, 
		y = layout.y,
		bHotspot = true,
		fHotspotH = layout.height,
		fHotspotX = 0,
		fHotspotW = layout.width,
		fHotspotY = -layout.height /2,
	}

	local IconHeight = layout.height * 0.75
	if ( gLangStr ~= "english" and gLangStr ~= "uk_english" ) then
	   IconHeight = 0.5 * IconHeight
	end

	Temp.mode = NewIFText { 
		x = 8,
		y = layout.height * -0.5 + 2,
		halign = "left", valign = "top",
		font = ifs_missionselect_console.listboxfont,
		textw = layout.width - IconHeight - 10, texth = layout.height,
		startdelay=math.random()*0.5, nocreatebackground=1, 
	}

	Temp.icon = NewIFImage {
		ZPos = 240, 
		localpos_l = layout.width - 5 - IconHeight,
		localpos_r = layout.width - 5,
		localpos_t = (IconHeight * -0.5) + 2,
		localpos_b = (IconHeight * 0.5) + 2,
	}
	return Temp
end

-- Helper function. Given a layout (x,y,width, height), returns a
-- fully-built item.
function ifs_ms_EraList_CreateItem_console(layout)
	-- Make a coordinate system pegged to the top-left of where the cursor would go.
	local Temp = NewIFContainer { 
		x = layout.x - 0.5 * layout.width, 
		y = layout.y,
		bHotspot = true,
		fHotspotH = layout.height,
		fHotspotW = layout.width,
		fHotspotX = 0,
		fHotspotY = -layout.height /2,
	}

	local IconHeight = layout.height * 0.375

	Temp.era = NewIFText { 
		x = 8,
		y = -0.5 * layout.height + 4,
		halign = "left", valign = "top",
		font = ifs_missionselect_console.listboxfont,
		textw = layout.width - IconHeight - 10, texth = layout.height,
		startdelay=math.random()*0.5, nocreatebackground=1, 
	}

	Temp.icon1 = NewIFImage {
		ZPos = 240, 
		localpos_l = layout.width - 5 - IconHeight,
		localpos_r = layout.width - 5,
		localpos_t = (IconHeight * -0.5) + 2,
		localpos_b = (IconHeight * 0.5) + 2,
		ColorR = 128,
		ColorG = 128,
		ColorB = 128,
	}

	return Temp
end

-- Helper function. Given a layout (x,y,width, height), returns a
-- fully-built item.
function ifs_ms_PlayList_CreateItem_console(layout)
	-- Make a coordinate system pegged to the top-left of where the cursor would go.
	local Temp = NewIFContainer { 
		x = layout.x - 0.5 * layout.width, 
		y = layout.y,
		bHotspot = true,
		fHotspotH = layout.height,
		fHotspotW = layout.width,
		fHotspotX = 0,
		fHotspotY = -layout.height /2,
	}

	local HAlign = "left"
	local WidthAdj = -10

	local IconHeight = layout.height * 0.75
	if ( gLangStr ~= "english" and gLangStr ~= "uk_english" ) then
	   IconHeight = 0.5 * IconHeight
	end

	Temp.map = NewIFText { 
		x = 8,
		y = layout.height * -0.5 + 2,
		halign = "left", valign = "top",
		font = ifs_missionselect_console.listboxfont,
		textw = layout.width - 2 * IconHeight + WidthAdj, texth = layout.height,
		startdelay=math.random()*0.5, 
		nocreatebackground=1, 
	}

	Temp.icon = NewIFImage {
		ZPos = 240, 
		localpos_l = layout.width - 5 - IconHeight,
		localpos_r = layout.width - 5,
		localpos_t = (IconHeight * -0.5) + 2,
		localpos_b = (IconHeight * 0.5) + 2,
	}

	Temp.icon1 = NewIFImage {
		ZPos = 240, 
		localpos_l = layout.width - 3 - IconHeight - 5 - IconHeight,
		localpos_r = layout.width - 3 - IconHeight - 5,
		localpos_t = (IconHeight * -0.5) + 2,
		localpos_b = (IconHeight * 0.5) + 2,
		ColorR = 128,
		ColorG = 128,
		ColorB = 128,
	}

	return Temp
end

-- Helper function. For a destination item (previously created w/
-- CreateItem), fills it in with data, which may be nil (==blank it)
function ifs_ms_MapList_PopulateItem_console(Dest, Data, bSelected, iColorR, iColorG, iColorB, fAlpha)
	if(Data) then
		
		if(Data.isModLevel) then
			local red = Data.red or 255
			local blue = Data.blue  or 128 
			local green = Data.green or 0
			IFObj_fnSetColor(Dest.map, 255,128,0)
		else
			IFObj_fnSetColor(Dest.map, iColorR, iColorG, iColorB)
		end
	   
	   IFObj_fnSetAlpha(Dest.map, fAlpha)

	   -- Show the data
	   local DisplayUStr,iSource = missionlist_GetLocalizedMapName(Data.mapluafile)

	   IFText_fnSetUString(Dest.map,DisplayUStr)
	end

	IFObj_fnSetVis(Dest.map,Data)
end


-- Helper function. For a destination item (previously created w/
-- CreateItem), fills it in with data, which may be nil (==blank it)
function ifs_ms_ModeList_PopulateItem_console(Dest, Data, bSelected, iColorR, iColorG, iColorB, fAlpha)
	local bShowIcon = Data and (Data.icon)

	if(Data) then
	   IFObj_fnSetColor(Dest.mode, iColorR, iColorG, iColorB)
	   IFObj_fnSetAlpha(Dest.mode, fAlpha)

	   local DisplayUStr = ScriptCB_getlocalizestr(Data.showstr)
	   -- added for UOP mode handling
	   local theIcon = Data.icon1
	   local chg = GetUOPChangeTableFor(Data.key)
	   if( chg ~= nil ) then
			if(chg.name ~= nil) then
				DisplayUStr = ScriptCB_tounicode(chg.name)
			end
			if(chg.icon ~= nil) then
				theIcon = chg.icon
			end
		end

	   -- If Data.icon exists, set the texture on it.
	   if(bShowIcon) then
		  IFImage_fnSetTexture(Dest.icon, theIcon)
	   end

	   -- Show the data
	   IFText_fnSetUString(Dest.mode, DisplayUStr)
	end

	IFObj_fnSetVis(Dest.mode,Data)
	IFObj_fnSetVis(Dest.icon,bShowIcon)
end

-- Helper function. For a destination item (previously created w/
-- CreateItem), fills it in with data, which may be nil (==blank it)
function ifs_ms_EraList_PopulateItem_console(Dest, Data, bSelected, iColorR, iColorG, iColorB, fAlpha)
	local bShowIcon = Data and (Data.icon1)
	if(Data) then
	   IFObj_fnSetColor(Dest.era, iColorR, iColorG, iColorB)
	   IFObj_fnSetAlpha(Dest.era, fAlpha)

	   local DisplayUStr = ScriptCB_getlocalizestr(Data.showstr)
	   -- added for UOP Era handling
		local theIcon = Data.icon1
		local chg = GetUOPChangeTableFor(Data.key)
		if( chg ~= nil) then
			-- icon and text 
			if(chg.name ~= nil) then
				DisplayUStr = ScriptCB_tounicode(chg.name)
			end
			-- UOP seems to favor icon2 over icon1
			theIcon =  chg.icon1 or chg.icon2
		end

	   -- If Data.icon1 exists, set the texture on icons
	   if(bShowIcon) then
	      --IFImage_fnSetTexture(Dest.icon1, Data.icon1)
		  IFImage_fnSetTexture(Dest.icon1, theIcon )
	      IFObj_fnSetColor(Dest.icon1, iColorR, iColorG, iColorB)
	      IFObj_fnSetAlpha(Dest.icon1, fAlpha)
	   end

	   -- Show the data
	   IFText_fnSetUString(Dest.era, DisplayUStr)
	end

	IFObj_fnSetVis(Dest.era,Data)
	IFObj_fnSetVis(Dest.icon1,bShowIcon)
end

-- Helper function. For a destination item (previously created w/
-- CreateItem), fills it in with data, which may be nil (==blank it)
function ifs_ms_PlayList_PopulateItem_console(Dest, Data, bSelected, iColorR, iColorG, iColorB, fAlpha)
	local bShowIcon = Data
	local bShowIcon1 = Data

	
	if(Data) then
	   IFObj_fnSetColor(Dest.map, iColorR, iColorG, iColorB)
	   IFObj_fnSetAlpha(Dest.map, fAlpha)

	   local DisplayUStr,iSource = missionlist_GetLocalizedMapName(Data.Map)
	   IFText_fnSetUString(Dest.map,DisplayUStr)

	   local MapMode = missionlist_GetMapMode(Data.Map)
	   if((MapMode) and (MapMode.icon)) then
	      IFImage_fnSetTexture(Dest.icon, MapMode.icon)
	      IFObj_fnSetColor(Dest.icon, iColorR, iColorG, iColorB)
	      IFObj_fnSetAlpha(Dest.icon, fAlpha)
	   else
	      bShowIcon = nil
	   end

	   --  UOP Era stuff
	   local MapEra = missionlist_GetMapEra(Data.Map)
	   local theIcon = MapEra.icon1
	   local chg = GetUOPChangeTableFor(MapEra.key)
		if( chg ~= nil) then
			-- icon 
			theIcon =  chg.icon1 or chg.icon2
		end
	   
	   --if((MapEra) and (MapEra.icon1)) then
	   --   IFImage_fnSetTexture(Dest.icon1, MapEra.icon1)
	   --   IFObj_fnSetColor(Dest.icon1, iColorR, iColorG, iColorB)
	   --   IFObj_fnSetAlpha(Dest.icon1, fAlpha)
	   --else
		if((MapEra) and (theIcon)) then
			IFImage_fnSetTexture(Dest.icon1, theIcon)
			IFObj_fnSetColor(Dest.icon1, iColorR, iColorG, iColorB)
			IFObj_fnSetAlpha(Dest.icon1, fAlpha)
		 else
	      bShowIcon1 = nil
	   end
	   
	end

	-- don't show icons for the 'Remova All'
	if( Data and Data.bIsRemoveAll) then 
		bShowIcon = nil 
		bShowIcon1 = nil
	end
	-- Turn on/off depending on whether data's there or not
	IFObj_fnSetVis(Dest.map,Data)
	IFObj_fnSetVis(Dest.icon,bShowIcon)
	IFObj_fnSetVis(Dest.icon1,bShowIcon1)
end

-- snip

ifs_ms_MapList_layout_console = {
	name = "ifs_ms_MapList_layout_console",
	bCreateSlider = true,
	showcount = 10,
--	yTop = -130 + 13, -- auto-calc'd now
	yHeight = 20,
	ySpacing  = 0,
--	width = 260,
	x = 0,
	slider = 1,
	CreateFn = ifs_ms_MapList_CreateItem_console,
	PopulateFn = ifs_ms_MapList_PopulateItem_console,
}

ifs_ms_ModeList_layout_console = {
	name="ifs_ms_ModeList_layout_console",
	bCreateSlider = true,
	showcount = 10,
--	yTop = -130 + 13, -- auto-calc'd now
	yHeight = 20,
	ySpacing  = 0,
--	width = 260,
	x = 0,
	slider = 1,
	CreateFn = ifs_ms_ModeList_CreateItem_console,
	PopulateFn = ifs_ms_ModeList_PopulateItem_console,
}

ifs_ms_EraList_layout_console = {
	name = "ifs_ms_EraList_layout_console",
	bCreateSlider = true,
	showcount = 10,
-- 	showcount = 3,
--	yTop = -130 + 13, -- auto-calc'd now
	yHeight = 20,
	ySpacing  = 0,
--	width = 260,
	x = 0,
	slider = 1,
	CreateFn = ifs_ms_EraList_CreateItem_console,
	PopulateFn = ifs_ms_EraList_PopulateItem_console,
}

ifs_ms_PlayList_layout_console = {
	name ="ifs_ms_PlayList_layout_console",
	bCreateSlider = true,
	showcount = 7,
--	yTop = -130 + 13, -- auto-calc'd now
	yHeight = 22,
	ySpacing  = 0,
--	width = 260,
	x = 0,
	slider = 1,
	CreateFn = ifs_ms_PlayList_CreateItem_console,
	PopulateFn = ifs_ms_PlayList_PopulateItem_console,
}

ifs_ms_CommandButton_layout_console = {
   yTop = -130,
--    ySpacing = 10,
--    yHeight = 80,
--    UseYSpacing = 1,
--    bNoDefaultSizing = 1,
   HardWidthMax = 80,
   font = "gamefont_tiny",
   buttonlist = { 
      { tag = "launch", string = "ifs.missionselect.buttons.text.launch", },
      { tag = "add", string = "ifs.missionselect.buttons.text.add", },
      { tag = "remove", string = "ifs.missionselect.buttons.text.remove", },
      { tag = "options", string = "ifs.missionselect.buttons.text.options", },
   },
	 bAllSquareButtons = 1,
}

function ifs_missionselect_console_fnShowHideListboxes(this,bShowThem)
	local A1,A2
	local fAnimTime = 0.3

	if(bShowThem) then
		A1 = 0
		A2 = 1
	else
		A1 = 1
		A2 = 0
	end

	AnimationMgr_AddAnimation(this.MapListbox,  { fStartAlpha = A1, fEndAlpha = A2,})
	AnimationMgr_AddAnimation(this.ModeListbox, { fStartAlpha = A1, fEndAlpha = A2,})
	AnimationMgr_AddAnimation(this.EraListbox,  { fStartAlpha = A1, fEndAlpha = A2,})
	AnimationMgr_AddAnimation(this.PlayListbox, { fStartAlpha = A1, fEndAlpha = A2,})
end

-- Selection can have movieName and movieFile; if so then return those
local function GetMovieName(Selection)
    local movieName = this.movieBackground
    local movieFile = "movies\\shell"

    if(not Selection) then
		print("GetMovieName(): emergency bailout")
        return movieName, movieFile -- emergency bailout
    end

	if (Selection.movieName ~= nil and Selection.movieFile~= nil and 
	    ScriptCB_IsFileExist(Selection.movieFile ..".mvs") == 1 )  then
		-- this is behavior from the UOP
		movieName = Selection.movieName
		movieFile = Selection.movieFile
		-------------- EARLY RETURN --------------------------
		return movieName, movieFile
	end
	-- Extract the prefix from the map.
	local prefix = string.sub(Selection.mapluafile, 1, -6)

	-- Append 'fly.mvs' to the prefix.
	local filename = prefix .. "fly.mvs"
	local flyMoviesBasePath = "..\\..\\addon\\0\\movies\\fly\\"
	
	if (PREVIEW_MOVIE_CONFIG == nil  ) then  -- make sure we read in the config file for the preview movies
		if(ScriptCB_IsFileExist( flyMoviesBasePath .. "fly.lvl")  == 1) then 
			ReadDataFile( flyMoviesBasePath .. "fly.lvl")
			PREVIEW_MOVIE_CONFIG = 1
		end
	end
	-- look for a default fallback 
	if(ScriptCB_IsFileExist( flyMoviesBasePath .. "default.mvs")  == 1) then 
		movieFile = flyMoviesBasePath .. "default"
		movieName = "preview"
	end
	if(ScriptCB_IsFileExist(flyMoviesBasePath .. filename) == 1) then
		-- to keep consistent with the Zerted stuff, we'll append the ''.mvs' later when setting the video
		movieFile = flyMoviesBasePath .. prefix .. "fly"
		movieName = "preview"
	elseif( string.starts(prefix,"spa")) then
		-- default generic space preview to fallback on if there isn't a more specific one
		movieFile = flyMoviesBasePath .. "spa2fly"
		movieName = "preview"
	end
	-- the preview movie name is always 'preview'
	-- default movie is "shell_main", "movies\\shell"
	print("GetMovieName: " .. prefix .. " > " .. tostring(movieName))
	return movieName, movieFile
end

local function ResetMovie(this)
	print("ifs_missionselect_console.ResetMovie")
	this.movieFile = "MOVIES/shell"
	this.movieName = this.movieBackground
	SetMovie_console(this)
end

function ifs_missionselect_console_fnUpdateMovie(this)
	if (this.iState ~= ifs_ms_state.map) then
		return 
	end
	local movieName = nil
    local movieFile = nil
	local MapSelection = missionselect_listbox_contents[ifs_ms_MapList_layout_console.SelectedIdx]
	movieName, movieFile = GetMovieName(MapSelection)
	if (movieName) then
		this.movieName = movieName
		this.movieTime = 0.5
		this.movieFile = movieFile
	else
		this.movieFile = "MOVIES/shell"
		this.movieName = this.movieBackground
	end
	SetMovie_console( this)
end

function SetMovie_console(this)
	print("SetMovie_console:", tostring(this.movieFile), tostring(this.movieName))

	local fullpath = this.movieFile .. ".mvs"
	if( gMovieStream ~= fullpath) then
		ScriptCB_CloseMovie()
		gMovieStream = fullpath
		ScriptCB_OpenMovie(gMovieStream, "")
	end
	if( gMovieName ~= this.movieName) then
		gMovieName = this.movieName
		ScriptCB_StopMovie()
		ifelem_shellscreen_fnStartMovie(this.movieName,1, nil, true)
	end

	if not ScriptCB_IsMoviePlaying()  then
		print(" try to play movie", tostring(this.movieName))
		ScriptCB_CloseMovie()
		gMovieStream = fullpath
		ScriptCB_OpenMovie(gMovieStream, "")
		ScriptCB_StopMovie()
		ifelem_shellscreen_fnStartMovie(this.movieName,1, nil, true)
	end
end

-- Helper function: adjusts the helptext in the info boxes up top
function ifs_missionselect_console_fnUpdateInfoBoxes(this)
	local MapSelection = missionselect_listbox_contents[ifs_ms_MapList_layout_console.SelectedIdx]

	if (this.iState == ifs_ms_state.map) then
	   local DisplayUStr,iSource = missionlist_GetLocalizedMapDescr(MapSelection.mapluafile)
	   IFText_fnSetUString(this.InfoboxBot.Text1, DisplayUStr)
	elseif (this.iState == ifs_ms_state.mode) then
	   local ModeSelection = gMissionselectModes[ifs_ms_ModeList_layout_console.SelectedIdx]
	   --- added for UOP mode handling
	   if(MapSelection.change  and MapSelection.change[ModeSelection.key] and 
	   		MapSelection.change[ModeSelection.key].about ) then
			local ustr = ScriptCB_tounicode(MapSelection.change[ModeSelection.key].about)
			IFText_fnSetUString(this.InfoboxBot.Text1, ustr)
	   else
	   		IFText_fnSetString(this.InfoboxBot.Text1, ModeSelection.descstr)
	   end
	elseif (this.iState == ifs_ms_state.era) then
	   local DisplayUStr,iSource = missionlist_GetLocalizedMapName(MapSelection.mapluafile)
	   local ModeSelection = gMissionselectModes[ifs_ms_ModeList_layout_console.SelectedIdx]
	   local SuffixUStr = ScriptCB_getlocalizestr(ModeSelection.showstr)
	   local SpacesUStr = ScriptCB_tounicode(" ")
	   DisplayUStr = ScriptCB_usprintf("common.pctspcts", DisplayUStr, SpacesUStr)
	   DisplayUStr = ScriptCB_usprintf("common.pctspcts", DisplayUStr, SuffixUStr)

	   local EraSelection = gMissionselectEras[ifs_ms_EraList_layout_console.SelectedIdx]

	   -- UOP handling
	   local ustr = nil
	   	if(MapSelection.change  and MapSelection.change[EraSelection.key]) then
			if(MapSelection.change[EraSelection.key].about ) then
				ustr = ScriptCB_tounicode(MapSelection.change[EraSelection.key].about)
			elseif(MapSelection.change[EraSelection.key].name) then
				ustr = ScriptCB_tounicode(MapSelection.change[EraSelection.key].name)
			end
		end
		if(ustr ~= nil) then
			IFText_fnSetUString(this.InfoboxBot.Text1, ustr)
		else
			IFText_fnSetString(this.InfoboxBot.Text1, EraSelection.showstr)
		end		
	elseif (this.iState == ifs_ms_state.command) then
	   IFText_fnSetString(this.InfoboxBot.Text1, "ifs.missionselect.buttons.help." .. this.CurButton)
	elseif (this.iState == ifs_ms_state.playlist) then
	   local Selection = gPickedMapList[ifs_ms_PlayList_layout_console.SelectedIdx]
	   if(Selection.bIsRemoveAll) then
	      IFText_fnSetString(this.InfoboxBot.Text1, "")
	   else
	      local DisplayUStr,iSource
	      DisplayUStr,iSource = missionlist_GetLocalizedMapName(Selection.Map)
	      IFText_fnSetUString(this.InfoboxBot.Text1, DisplayUStr)

-- 	      local MapMode = missionlist_GetMapMode(Selection.Map)
-- 	      if(MapMode) then
-- 		 IFText_fnSetString(this.InfoboxBot.Text2, MapMode.showstr)
-- 	      else
-- 		 IFText_fnSetString(this.InfoboxBot.Text2, "")
-- 	      end

-- 	      local MapEra = missionlist_GetMapEra(Selection.Map)
-- 	      if(MapEra) then
-- 		 IFText_fnSetString(this.InfoboxBot.Text3, MapEra.showstr)
-- 	      else
-- 		 IFText_fnSetString(this.InfoboxBot.Text3, "")
-- 	      end
	   end
	end

end

-- Helper function: adjusts the helptext by the icons at the bottom
function ifs_missionselect_console_fnUpdateHelptext(this)
	local PlaylistSelection = gPickedMapList[ifs_ms_PlayList_layout_console.SelectedIdx]

	if(this.Helptext_Accept) then
-- 		if (this.iColumn == 5) then
-- 			IFText_fnSetString(this.Helptext_Accept.helpstr,"common.mp.launch")
-- 		elseif (this.iColumn == 6) then
-- 			IFText_fnSetString(this.Helptext_Accept.helpstr,"common.change")
-- 		else
			IFText_fnSetString(this.Helptext_Accept.helpstr,"common.select")
-- 		end
		gHelptext_fnMoveIcon(this.Helptext_Accept)
	end -- Helptext_Accept exists

	-- Adjust delete helptext, if present
-- 	if(this.Helptext_Delete) then
-- 		local DeleteAlpha = 0.25
-- 		if (this.iColumn == 3) then
-- 			if(not PlaylistSelection.bIsRemoveAll) then
-- 				DeleteAlpha = 1
-- 			end
-- 		end
-- 		IFObj_fnSetAlpha(this.Helptext_Delete, DeleteAlpha)		
-- 	end

end

-- Helper function: sets the text of the bottom buttons 
function ifs_missionselect_console_fnUpdateButtons(this)
   local dimmed = this.iState ~= ifs_ms_state.command

   local button = this.buttons[ifs_ms_CommandButton_layout_console.buttonlist[1].tag]
   button.bDimmed = dimmed or (table.getn(gPickedMapList) < 2)

   for i = 2,table.getn(ifs_ms_CommandButton_layout_console.buttonlist) do
      local button = this.buttons[ifs_ms_CommandButton_layout_console.buttonlist[i].tag]
      button.bDimmed = dimmed
   end

   if ( this.CurButton ) then
      ShowHideVerticalButtons(this.buttons, ifs_ms_CommandButton_layout_console)
   else
      this.CurButton = ShowHideVerticalButtons(this.buttons, ifs_ms_CommandButton_layout_console)
   end

   SetCurButton(this.CurButton)
end

-- Helper function: fills in the listboxes with appropriate contents
function ifs_missionselect_console_fnUpdateScreen(this)

	-- Refresh which modes * eras are available on this map
	if((this.iColumn == 0) or (this.iColumn == 1)) then
		local MapSelection = missionselect_listbox_contents[ifs_ms_MapList_layout_console.SelectedIdx]

		gMissionselectModes = missionlist_ExpandModelist(MapSelection.mapluafile)
		local NumModes = table.getn(gMissionselectModes)
		if(ifs_ms_ModeList_layout_console.SelectedIdx > NumModes) then
			ifs_ms_ModeList_layout_console.SelectedIdx = 1 -- back to top of list
		end

		local ModeSelection = gMissionselectModes[ifs_ms_ModeList_layout_console.SelectedIdx]
		gMissionselectEras = missionlist_ExpandEralist(MapSelection.mapluafile, ModeSelection)
		local NumEras = table.getn(gMissionselectEras)
		if(ifs_ms_EraList_layout_console.SelectedIdx > NumEras) then
			ifs_ms_EraList_layout_console.SelectedIdx = 1 -- back to top of list
		end
	end

	if (this.iState == ifs_ms_state.map) then
	   IFObj_fnSetVis(this.MapListbox, 1)
	   ifs_ms_MapList_layout_console.CursorIdx = ifs_ms_MapList_layout_console.SelectedIdx
	   ListManager_fnFillContents(this.MapListbox,missionselect_listbox_contents,ifs_ms_MapList_layout_console)
	   ListManager_fnSetFocus(this.MapListbox)

	   IFObj_fnSetVis(this.ModeListbox, nil)
	   ifs_ms_ModeList_layout_console.CursorIdx = nil

	   IFObj_fnSetVis(this.EraListbox, nil)
	   ifs_ms_EraList_layout_console.CursorIdx = nil

	   ifs_ms_PlayList_layout_console.CursorIdx = nil
	   ListManager_fnFillContents(this.PlayListbox,gPickedMapList,ifs_ms_PlayList_layout_console)
	elseif (this.iState == ifs_ms_state.mode) then
	   IFObj_fnSetVis(this.MapListbox, nil)
	   ifs_ms_MapList_layout_console.CursorIdx = nil

	   IFObj_fnSetVis(this.ModeListbox, 1)
	   ifs_ms_ModeList_layout_console.CursorIdx = ifs_ms_ModeList_layout_console.SelectedIdx
	   ListManager_fnFillContents(this.ModeListbox,gMissionselectModes,ifs_ms_ModeList_layout_console)
	   ListManager_fnSetFocus(this.ModeListbox)

	   IFObj_fnSetVis(this.EraListbox, nil)
	   ifs_ms_EraList_layout_console.CursorIdx = nil

	   ifs_ms_PlayList_layout_console.CursorIdx = nil
	   ListManager_fnFillContents(this.PlayListbox,gPickedMapList,ifs_ms_PlayList_layout_console)
	elseif (this.iState == ifs_ms_state.era) then
	   IFObj_fnSetVis(this.MapListbox, nil)
	   ifs_ms_MapList_layout_console.CursorIdx = nil

	   IFObj_fnSetVis(this.ModeListbox, nil)
	   ifs_ms_ModeList_layout_console.CursorIdx = nil
	   
	   IFObj_fnSetVis(this.EraListbox, 1)
	   ifs_ms_EraList_layout_console.CursorIdx = ifs_ms_EraList_layout_console.SelectedIdx
	   ListManager_fnFillContents(this.EraListbox,gMissionselectEras,ifs_ms_EraList_layout_console)
	   ListManager_fnSetFocus(this.EraListbox)

	   ifs_ms_PlayList_layout_console.CursorIdx = nil
	   ListManager_fnFillContents(this.PlayListbox,gPickedMapList,ifs_ms_PlayList_layout_console)
	elseif (this.iState == ifs_ms_state.command) then
	   IFObj_fnSetVis(this.MapListbox, 1)
	   ifs_ms_MapList_layout_console.CursorIdx = nil
	   ListManager_fnFillContents(this.MapListbox,missionselect_listbox_contents,ifs_ms_MapList_layout_console)

	   IFObj_fnSetVis(this.ModeListbox, nil)
	   ifs_ms_ModeList_layout_console.CursorIdx = nil

	   IFObj_fnSetVis(this.EraListbox, nil)
	   ifs_ms_EraList_layout_console.CursorIdx = nil

	   ifs_ms_PlayList_layout_console.CursorIdx = nil
	   ListManager_fnFillContents(this.PlayListbox,gPickedMapList,ifs_ms_PlayList_layout_console)

	   ListManager_fnSetFocus(nil)
	elseif (this.iState == ifs_ms_state.playlist) then
	   IFObj_fnSetVis(this.MapListbox, 1)
	   ifs_ms_MapList_layout_console.CursorIdx = nil
	   ListManager_fnFillContents(this.MapListbox,missionselect_listbox_contents,ifs_ms_MapList_layout_console)
	   ListManager_fnSetFocus(this.MapListbox)

	   IFObj_fnSetVis(this.ModeListbox, nil)
	   ifs_ms_ModeList_layout_console.CursorIdx = nil

	   IFObj_fnSetVis(this.EraListbox, nil)
	   ifs_ms_EraList_layout_console.CursorIdx = nil

	   ifs_ms_PlayList_layout_console.CursorIdx = ifs_ms_PlayList_layout_console.SelectedIdx
	   ListManager_fnFillContents(this.PlayListbox,gPickedMapList,ifs_ms_PlayList_layout_console)
	   ListManager_fnSetFocus(this.PlayListbox)
	end


	-- Always update the other chunks. Those are split off into their own
	-- functions for readability
	ifs_missionselect_console_fnUpdateButtons(this)
	ifs_missionselect_console_fnUpdateHelptext(this)
	ifs_missionselect_console_fnUpdateInfoBoxes(this)
	ifs_missionselect_console_fnUpdateMovie(this)
end

-- Helper function: clears the playlist
function ifs_missionselect_console_fnClearPlaylist(this)
	gPickedMapList = {
		{ Map = gDelAllMapsStr, bIsRemoveAll = 1, },
	}
end

-- Callback function: list of maps is full, and user got a dialog to
-- that effect. This is called when that dialog is dismissed.
function ifs_missionselect_console_fnFullPopupDone()
	local this = ifs_missionselect_console
	ifs_missionselect_console_fnShowHideListboxes(this,1)
end

-- Helper function: given a map, mode & era, none of which are
-- wildcards, adds the map to the list.
function ifs_missionselect_console_fnAddMap4(this, MapSelection, ModeSelection, EraSelection)
	-- Map & mode must not be a wildcard to get here.
	assert(not MapSelection.bIsWildcard)
	assert(not ModeSelection.bIsWildcard)
	assert(not EraSelection.bIsWildcard)

	local Idx = table.getn(gPickedMapList) + 1

	-- If playlist is full, notify the user, don't add it.
	if(Idx > (this.iMaxMissions+1)) then
		ifs_missionselect_console_fnShowHideListboxes(this,nil)
		Popup_Ok.fnDone = ifs_missionselect_console_fnFullPopupDone
		Popup_Ok:fnActivate(1)
		gPopup_fnSetTitleStr(Popup_Ok, "ifs.missionselect.listfull")
		return
	end

	local NewMapfile = string.format(MapSelection.mapluafile, EraSelection.subst, ModeSelection.subst)
	print("Adding map ", NewMapfile)
	gPickedMapList[Idx] = { 
		Map = NewMapfile,
		mapluafile = NewMapfile,
		dnldable = MapSelection.dnldable,
		mapluafile = MapSelection.mapluafile,
		Side = 1,
		SideChar = EraSelection.tag,
		Team1 = EraSelection.Team1Name,
		Team2 = EraSelection.Team2Name,
	}

	-- Auto-scroll playlist cursor to last item.
	local Count = table.getn(gPickedMapList)
	ifs_ms_PlayList_layout_console.SelectedIdx = Count

end

-- Helper function: given a map, mode & era, expands the mode(s)
-- and adds the map based on that.
function ifs_missionselect_console_fnAddMap3(this, MapSelection, ModeSelection, EraSelection)

	-- Map must not be a wildcard to get here.
	assert(not MapSelection.bIsWildcard)
	assert(not EraSelection.bIsWildcard)

	if(ModeSelection.bIsWildcard) then
		-- Add all maps with given params
		local i
    for i = 1,table.getn(gMissionselectModes) do
			local ModeSelection2 = gMissionselectModes[i]
			if(not ModeSelection2.bIsWildcard) then
				-- Ensure this map supports this mode before adding.
				local Key = ModeSelection2.key .. "_" .. EraSelection.subst
				if(MapSelection[Key]) then
					ifs_missionselect_console_fnAddMap3(this, MapSelection, ModeSelection2, EraSelection)
				end
			end
		end
	else
		-- Not adding all maps. Call child function, if mode exists on this map
		local Key = ModeSelection.key .. "_" .. EraSelection.subst
		if(MapSelection[Key]) then
			ifs_missionselect_console_fnAddMap4(this, MapSelection, ModeSelection, EraSelection)
		end
	end
end

-- Helper function: given a map, mode & era, expands the era(s)
-- and adds maps based on that.
function ifs_missionselect_console_fnAddMap2(this, MapSelection, ModeSelection, EraSelection)
	-- Map & mode must not be a wildcard to get here.
	assert(not MapSelection.bIsWildcard)

	if(EraSelection.bIsWildcard) then
		-- Add all maps with given params
		local i
    for i = 1,table.getn(gMissionselectEras) do
			local EraSelection2 = gMissionselectEras[i]
			if(not EraSelection2.bIsWildcard) then
				-- Ensure this map supports this era before adding.
				local Key = EraSelection2.key
				if(MapSelection[Key]) then
					ifs_missionselect_console_fnAddMap3(this, MapSelection, ModeSelection, EraSelection2)
				end
			end
		end
	else
		-- Not adding all maps. Call child function, if era exists on this map
		local Key = EraSelection.key
		if(MapSelection[Key]) then
			ifs_missionselect_console_fnAddMap3(this, MapSelection, ModeSelection, EraSelection)
		end
	end
	-- snip

end

-- Helper function: given a map, mode & era, expands the map(s)
-- and adds maps based on that.
function ifs_missionselect_console_fnAddMap1(this, MapSelection, ModeSelection, EraSelection)
	if(MapSelection.bIsWildcard) then
		-- Add all maps with given params
		local i
    for i = 1,table.getn(missionselect_listbox_contents) do
			local MapSelection2 = missionselect_listbox_contents[i]
			if(not MapSelection2.bIsWildcard) then
				ifs_missionselect_console_fnAddMap2(this, MapSelection2, ModeSelection, EraSelection)
			end
		end
	else
		-- Not adding all maps. Call child function
		ifs_missionselect_console_fnAddMap2(this, MapSelection, ModeSelection, EraSelection)
	end
end

-- Given the current selections in the listboxes, adds the map(s)
-- selected to the listbox
function ifs_missionselect_console_fnAddMap(this)
	local MapSelection = missionselect_listbox_contents[ifs_ms_MapList_layout_console.SelectedIdx]
	local ModeSelection = gMissionselectModes[ifs_ms_ModeList_layout_console.SelectedIdx]
	local EraSelection = gMissionselectEras[ifs_ms_EraList_layout_console.SelectedIdx]
	-- Call helper functions to expand things as necessary
	ifs_missionselect_console_fnAddMap1(this, MapSelection, ModeSelection, EraSelection)
end

-- Deletes a map from the playlist. Done by creating a new list,
-- copying everything but the selected one over, swapping lists.
function ifs_missionselect_console_fnDeleteMap(this, idx)
	local Count = table.getn(gPickedMapList)
	if(Count > 0) then
		local i
		local j = 1
		local NewList = {}
		for i=1,Count do
			if(i ~= idx) then
				NewList[j] = gPickedMapList[i]
				j = j + 1
			end
		end
		
		gPickedMapList = NewList
	end -- has entries to delete
end

function ifs_missionselect_console_fnLaunch(this)
	-- First entry is always "remove all", so we need to have more entries than
	-- that in the list.
	if(table.getn(gPickedMapList) > 1) then
		this.SelectedMap = 1
		ifs_missionselect_console_fnDeleteMap(this, 1) -- delete the "remove all entry"
		ScriptCB_SetMissionNames(gPickedMapList,ifs_instant_options_GetRandomizePlaylist())

		-- This screen is a replacement for 'ifs_missionselect'.
		-- The system will sometimes place a function on a screen that needs to get called.
		-- Here we gotta check for a 'fnDone' applied to ifs_missionselect and call that one.
		if(ifs_missionselect.fnDone ~= nil) then
			ifs_missionselect.SelectedMap = 1
			ifs_missionselect.fnDone()
		else
			ScriptCB_SetTeamNames(0,0)
			ScriptCB_EnterMission()
		end
	else
		ifelm_shellscreen_fnPlaySound(this.errorSound)
	end
end

function HackBGTextureForWidescreen()
	local right, bottom, b, w = ScriptCB_GetScreenInfo()
	if (w ~= 1.0) then
		return "iface_instant_action_wide"
	end
	return "iface_instant_action"
end

ifs_missionselect_console = NewIFShellScreen {
	nologo = 1,
	bAcceptIsSelect = 1,
	--bg_texture = HackBGTextureForWidescreen(),
	movieBackground =  "shell_main",

	fnDone = nil, -- Callback function to do something when the user is done
	-- Sub-mode for full/era switch is on.

	iColumn = 0, -- default: leftmost column
        iState = ifs_ms_state.map,
	
-- 	Helptext_Delete = NewHelptext {
-- 		ScreenRelativeX = 0.35, -- Left of center, but not in the normal 'back' position
-- 		ScreenRelativeY = 1.0, -- bot
-- 		y = -15,
-- 		buttonicon = "btnmisc",
-- 		string = "ifs.profile.delete",
-- 	},

	buttons = NewIFContainer {
	   ScreenRelativeX = 0.5, -- center
	   ScreenRelativeY = gDefaultButtonScreenRelativeY,
	},

	Enter = function(this, bFwd)
		gIFShellScreenTemplate_fnEnter(this, bFwd) -- call base class

		ifs_instant_options_fnResetDefaults()

		-- stop the current movie
-- 		ifelem_shellscreen_fnStopMovie()

-- 		if(gPlatformStr == "XBox") then
-- 			ScriptCB_CloseMovie();
-- 			ScriptCB_OpenMovie("movies\\fly.mvs", "")
-- 		end

		-- Added chunk for error handling...
		if(not bFwd) then
			local ErrorLevel,ErrorMessage = ScriptCB_GetError()
			if(ErrorLevel >= 6) then -- session or login error, must keep going further
				ScriptCB_PopScreen()
				return
			end
		end

		this.iColumn = 0 -- default: leftmost column (all maps list)

		if(bFwd) then
			missionlist_ExpandMaplist(this.bForMP)

			-- Determine how many missions can be queued.
			this.iMaxMissions = ScriptCB_GetMaxMissionQueue()

			if(not this.bEverEntered) then
				this.bEverEntered = 1
				ifs_missionselect_console_fnClearPlaylist(this)
			end
		end

		-- does this work?
		ScriptCB_ReadAllControllers(1)

		this.iState = ifs_ms_state.command
		ifs_missionselect_console_fnUpdateScreen(this)
	end,

	Exit = function(this, bFwd)
		if(not bFwd) then
			this.SelectedMap = nil -- clear this
		end

		-- play, what's this do?
		ScriptCB_ReadAllControllers(nil)
	end,
	
	Update = function(this, fDt)
		-- Call base class functionality
		gIFShellScreenTemplate_fnUpdate(this, fDt)
	end,

	Input_Accept = function(this)
		print("ifs_missionselect_console.Input_Accept: this.CurButton:" .. tostring(this.CurButton))
		--print("ifs_missionselect_console.Input_Accept: iState: " .. this.iState)

		-- If base class handled this work, then we're done
		if(gShellScreen_fnDefaultInputAccept(this,1)) then
			-- this code chunk helps/makes slider function
			return
		end

		-- Mouse Support code
		-- (from ifs_missionselect_pcmulti)
		if(gMouseListBox) then
			if( ( gMouseListBox == this.ModeListbox ) or
				( gMouseListBox == this.MapListbox ) or
				( gMouseListBox == this.EraListbox ) ) then
				--this.bClicked = 1
				if( ( gMouseListBox.Layout.SelectedIdx == gMouseListBox.Layout.CursorIdx ) and
					( this.lastDoubleClickTime ) and
					( ScriptCB_GetMissionTime()<this.lastDoubleClickTime+0.4 ) ) then
					print( "+++1111 DoubleClicked " )
					-- double clicked
					this.iLastClickTime = nil
					this.bDoubleClicked = 1
				else
					-- single clicked
					this.iLastClickTime = ScriptCB_GetMissionTime()
					gMouseListBox.Layout.SelectedIdx = gMouseListBox.Layout.CursorIdx
					ListManager_fnMoveCursor(gMouseListBox,gMouseListBox.Layout)
				end
			end
			
			--ScriptCB_SndPlaySound("shell_select_change")
--			if( gMouseListBox.Layout.SelectedIdx == gMouseListBox.Layout.CursorIdx )then
			if( gMouseListBox.Layout.SelectedIdx == gMouseListBox.Layout.CursorIdx and this.lastDoubleClickTime and ScriptCB_GetMissionTime()<this.lastDoubleClickTime+0.4) then
				this.lastDoubleClickTime = nil
--				if(gMouseListBox == this.listboxL) then
--					this.CurButton = "_add"
--				else
--					this.CurButton = "_del"
--				end
			else
				this.lastDoubleClickTime = ScriptCB_GetMissionTime()
				gMouseListBox.Layout.SelectedIdx = gMouseListBox.Layout.CursorIdx
				ListManager_fnMoveCursor(gMouseListBox,gMouseListBox.Layout)
				--ListManager_fnFillContents(gMouseListBox,gMouseListBox.Contents,gMouseListBox.Layout)
				--start to play the movie
				--ifs_missionselect_pcMulti_fnSetMapPreview(this)
				return 1 -- note we did all the work
			end
		end

		local sound = this.acceptSound
		if(this.CurButton == "_back") then 
			this.Input_Back(this)
		elseif (this.iState == ifs_ms_state.map) then
		   this.iState = ifs_ms_state.mode
		elseif (this.iState == ifs_ms_state.mode) then
		   this.iState = ifs_ms_state.era
		elseif (this.iState == ifs_ms_state.era) then
		   ifs_missionselect_console_fnAddMap(this)
		   this.iState = ifs_ms_state.command
		   SetCurButton("launch")
		elseif (this.iState == ifs_ms_state.command) then
		   if ( this.CurButton == "launch" ) then
			  ifs_missionselect_console_fnLaunch(this)
		   elseif ( this.CurButton == "add" ) then
		      this.iState = ifs_ms_state.map
		   elseif ( this.CurButton == "remove" ) then
		      this.iState = ifs_ms_state.playlist
		   elseif ( this.CurButton == "options" ) then
		      ifs_movietrans_PushScreen(ifs_instant_options_overview)
		   end
		elseif (this.iState == ifs_ms_state.playlist) then
		   local Selection = gPickedMapList[ifs_ms_PlayList_layout_console.SelectedIdx]
		   if (Selection.bIsRemoveAll) then
		      sound = this.errorSound
		      ifs_missionselect_console_fnClearPlaylist(this)
		   else
		      ifs_missionselect_console_fnDeleteMap(this, ifs_ms_PlayList_layout_console.SelectedIdx)

		      -- If we were on the last item, then auto-move up.
		      local Count = table.getn(gPickedMapList)
		      ifs_ms_PlayList_layout_console.SelectedIdx = math.min(ifs_ms_PlayList_layout_console.SelectedIdx, Count)

		      ifs_missionselect_console_fnUpdateScreen(this)
		   end

		   this.iState = ifs_ms_state.command
		   if ( table.getn(gPickedMapList) < 2 ) then
		      SetCurButton("add")
		   else
		      SetCurButton("launch")
		   end
		end

		ifelm_shellscreen_fnPlaySound(sound)
		ifs_missionselect_console_fnUpdateScreen(this)

--		local Selection = missionselect_listbox_contents[ifs_ms_MapList_layout_console.SelectedIdx]
		-----------------------------------
		-- set to non-spectator mode 
		ScriptCB_SetSpectatorMode( 0, nil )
		-----------------------------------
		
	end, -- end of Input_Accept
	HandleMouse = function(this, x, y)
		gHandleMouse(this,x,y)
		ifs_missionselect_console_fnUpdateInfoBoxes(this)
	end,

	Input_Back = function(this)
		print("ifs_missionselect_console.Input_Back: iState=".. tostring(this.iState))
		if (this.iState == ifs_ms_state.map) then
		   this.iState = ifs_ms_state.command
			ResetMovie(this)
		elseif (this.iState == ifs_ms_state.mode) then
		   this.iState = ifs_ms_state.map
		elseif (this.iState == ifs_ms_state.era) then
		   this.iState = ifs_ms_state.mode
		elseif (this.iState == ifs_ms_state.command) then
		   ScriptCB_PopScreen()
		elseif (this.iState == ifs_ms_state.playlist) then
		   this.iState = ifs_ms_state.command
		end
		   
		ifelm_shellscreen_fnPlaySound(this.exitSound)
		ifs_missionselect_console_fnUpdateScreen(this)
	end,
	
-- 	Input_Start = function(this)
-- 		--if we're on the first page, start should do the "launch" button
-- 		if(this.iPage == 0) then
-- 			ifs_missionselect_console_fnLaunch(this)
-- 		end
-- 	end,

	-- Delete a map from selected list. Done by creating a new list, copying
	-- everything but the selected one over, swapping lists.
	Input_Misc = function(this)
-- 		if (this.iColumn == 3) then
-- 			local Selection = gPickedMapList[ifs_ms_PlayList_layout_console.SelectedIdx]
-- 			if(Selection.bIsRemoveAll) then
-- 				ifelm_shellscreen_fnPlaySound(this.errorSound)
-- 			else
-- 				ifs_missionselect_console_fnDeleteMap(this, ifs_ms_PlayList_layout_console.SelectedIdx)

-- 				-- If we were on the last item, then auto-move up.
-- 				local Count = table.getn(gPickedMapList)
-- 				ifs_ms_PlayList_layout_console.SelectedIdx = math.min(ifs_ms_PlayList_layout_console.SelectedIdx, Count)

-- 				ifs_missionselect_console_fnUpdateScreen(this)
-- 			end
-- 		end -- column == 3
	end,

	Input_GeneralUp = function(this)
		local CurListbox = ListManager_fnGetFocus()
		if(CurListbox) then
			ListManager_fnNavUp(CurListbox)
			ifs_missionselect_console_fnUpdateScreen(this)
		end
		if ( this.iState == ifs_ms_state.command ) then
		   gDefault_Input_GeneralUp(this)
		   ifs_missionselect_console_fnUpdateScreen(this)
		end
	end,

	Input_GeneralDown = function(this)
		local CurListbox = ListManager_fnGetFocus()
		if(CurListbox) then
			ListManager_fnNavDown(CurListbox)
			ifs_missionselect_console_fnUpdateScreen(this)
		end
		if ( this.iState == ifs_ms_state.command ) then
		   gDefault_Input_GeneralDown(this)
		   ifs_missionselect_console_fnUpdateScreen(this)
		end
	end,

	Input_LTrigger = function(this)
		local CurListbox = ListManager_fnGetFocus()
		if(CurListbox) then
			ListManager_fnPageUp(CurListbox)
			ifs_missionselect_console_fnUpdateScreen(this)
		end
	end,

	Input_RTrigger = function(this)
		local CurListbox = ListManager_fnGetFocus()
		if(CurListbox) then
			ListManager_fnPageDown(CurListbox)
			ifs_missionselect_console_fnUpdateScreen(this)
		end
	end,

	-- decent reference on key mappings:
	--https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.keys
	Input_KeyDown = function(this, iKey)
		--[[
			B			66	The B key.
			Back		8	The BACKSPACE key.
			Escape		27	The ESC key.
			PageDown	34	The PAGE DOWN key.
			PageUp		33	The PAGE UP key.
			Space		32	The Space bar key.
		]]
		print("ifs_missionselect_console.Input_KeyDown: key=".. iKey)
		if(iKey == 27 or iKey == 8 or iKey == 66) then
			this.Input_Back(this)
		elseif(iKey == 33) then
			this.Input_LTrigger(this)
		elseif(iKey == 34) then
			this.Input_RTrigger(this)
		elseif (iKey == 32) then  -- spacebar 
			-- because Jump is  mapped to spacebar by default. Also Windows uses spacebar for a button press :)
			this:Input_Accept()
		end
	end,

}

function ifs_missionselect_console_fnBuildScreen(this)
	local w,h = ScriptCB_GetSafeScreenInfo() -- of the usable screen

	if(gPlatformStr == "PC") then
		--this.listboxfont = "gamefont_small"
		this.listboxfont = "gamefont_medium"
	elseif(gPlatformStr == "PS2") then
		this.listboxfont = "gamefont_tiny"
	else
		this.listboxfont = "gamefont_medium"
	end

	local ColumnWidthL = (w * 0.375)
	local ColumnWidthC = (w * 0.25)
	local ColumnWidthR = (w * 0.375)

	-- -35 is the normal space for scrollbars, but +20 as the scrollbars
	-- have recently gotten thinner. We need as much space for text onscreen
	-- as possible
	ifs_ms_MapList_layout_console.width = ColumnWidthL - 35 
	ifs_ms_ModeList_layout_console.width = ColumnWidthL - 35
	ifs_ms_EraList_layout_console.width = ColumnWidthL - 35 
	ifs_ms_PlayList_layout_console.width = ColumnWidthR - 35

	-- Now, do the boxes above and below the columns
	local TopBoxHeight = 78

	local yHeight
	local padding
	if ( gLangStr == "english" or gLangStr == "uk_english" ) then
	   yHeight = ScriptCB_GetFontHeight(ifs_missionselect_console.listboxfont) + 2
	   padding = 30
	else
	   yHeight = 2 * (ScriptCB_GetFontHeight(ifs_missionselect_console.listboxfont) + 2)
	   padding = 44
	end

	ifs_ms_MapList_layout_console.yHeight = yHeight
	ifs_ms_ModeList_layout_console.yHeight = yHeight
	ifs_ms_EraList_layout_console.yHeight = 2 * (ScriptCB_GetFontHeight(ifs_missionselect_console.listboxfont) + 4)
	ifs_ms_PlayList_layout_console.yHeight = yHeight

	local ListEntryHeight = (ifs_ms_MapList_layout_console.yHeight + ifs_ms_MapList_layout_console.ySpacing)

	ifs_ms_MapList_layout_console.showcount = math.min(16,math.max(4, math.floor((h - 240) / ListEntryHeight)))

	ifs_ms_ModeList_layout_console.showcount = ifs_ms_MapList_layout_console.showcount
	ifs_ms_PlayList_layout_console.showcount = ifs_ms_MapList_layout_console.showcount
	ifs_ms_EraList_layout_console.showcount = 0.5 * ifs_ms_MapList_layout_console.showcount
-- 	ifs_ms_ModeList_layout_console.showcount = ifs_ms_MapList_layout_console.showcount - 4
-- 	ifs_ms_PlayList_layout_console.showcount = ifs_ms_MapList_layout_console.showcount

	local ListHeightL = ifs_ms_MapList_layout_console.showcount * ListEntryHeight + padding

	local inherent_offcenteredness_of_the_world = 2

	this.MapListbox = NewButtonWindow { 
		ZPos = 200, 
		ScreenRelativeX = 0.5, -- left side of screen
		ScreenRelativeY = 0, -- top
		x = -((ColumnWidthR + ColumnWidthC) * 0.5) - inherent_offcenteredness_of_the_world,
		y = TopBoxHeight + ListHeightL * 0.5 + 6,
		width = ColumnWidthL,
		height = ListHeightL,
		titleText = "ifs.missionselect.selectplanet"
	}

	local ListHeightC = ifs_ms_ModeList_layout_console.showcount * ListEntryHeight + 30 - 4
	local ListHeightC2 = ifs_ms_EraList_layout_console.showcount * ListEntryHeight + 30 - 8
	this.ModeListbox = NewButtonWindow { 
		ZPos = 200, 
		ScreenRelativeX = 0.5, -- center of screen
		ScreenRelativeY = 0, -- top
		x = -((ColumnWidthR + ColumnWidthC) * 0.5) - inherent_offcenteredness_of_the_world,
		y = TopBoxHeight + ListHeightL * 0.5 + 6,
		width = ColumnWidthL,
		height = ListHeightL,
-- 		x = (ColumnWidthL + ColumnWidthC * 0.5),
-- 		y = TopBoxHeight + ListHeightC * 0.5,
-- 		width = ColumnWidthC,
-- 		height = ListHeightC,
		titleText = "ifs.missionselect.selectmode"
	}

	this.EraListbox = NewButtonWindow { 
		ZPos = 200, 
		ScreenRelativeX = 0.5, -- center of screen
		ScreenRelativeY = 0, -- top
		x = -((ColumnWidthR + ColumnWidthC) * 0.5) - inherent_offcenteredness_of_the_world,
		y = TopBoxHeight + ListHeightL * 0.5 + 6,
		width = ColumnWidthL,
		height = ListHeightL,
-- 		x = (ColumnWidthL + ColumnWidthC * 0.5),
-- 		y = TopBoxHeight + ListHeightC + ListHeightC2 * 0.5 + 2,
-- 		width = ColumnWidthC,
-- 		height = ListHeightC2,
		titleText = "ifs.missionselect.selectera"
	}

	local ListHeightR = ifs_ms_PlayList_layout_console.showcount * ListEntryHeight + 30
	this.PlayListbox = NewButtonWindow { 
		ZPos = 200, 
		ScreenRelativeX = 0.5,
		ScreenRelativeY = 0, -- top
		x = (ColumnWidthR + ColumnWidthC) * 0.5 - inherent_offcenteredness_of_the_world,
		y = TopBoxHeight + ListHeightR * 0.5 + 6,
		width = ColumnWidthR,
		height = ListHeightR,
		titleText = "ifs.missionselect.playlist"
	}

	local BotBoxHeight = 76

	this.InfoboxBot = NewButtonWindow { 
		ScreenRelativeX = 0.5,
		ScreenRelativeY = 0, -- top
		x =  -inherent_offcenteredness_of_the_world,
		y = TopBoxHeight + ListHeightL + BotBoxHeight * 0.5 + 10, -- Below main listboxes
		width = w,
		height = BotBoxHeight,

		-- Text1 is triple-height, for long descriptions. We'll either use
		-- Text1-only @ triple-height, or Text1/Text2/Text3, with one line
		-- of text in each.
		Text1 = NewIFText { 
			x = -0.5 * w + 15,
			y = -BotBoxHeight * 0.5 + 4,
			halign = "left", valign = "top",
			font = "gamefont_tiny", 
			textw = ColumnWidthL + ColumnWidthC + ColumnWidthR - 20, texth = BotBoxHeight,
			startdelay=math.random()*0.5, nocreatebackground=1,
			textcolorr = gSelectedTextColor[1],
			textcolorg = gSelectedTextColor[2],
			textcolorb = gSelectedTextColor[3],
		},

-- 		Text2 = NewIFText { 
-- 			x = -0.5 * w + 10,
-- 			y = BotBoxHeight * 0.5 - 10,
-- 			halign = "left", valign = "top",
-- 			font = this.listboxfont,
-- 			textw = ColumnWidthL + ColumnWidthC + ColumnWidthR - 20, texth = BotBoxHeight * 0.333333,
-- 			startdelay=math.random()*0.5, nocreatebackground=1, 
-- 			textcolorr = gSelectedTextColor[1],
-- 			textcolorg = gSelectedTextColor[2],
-- 			textcolorb = gSelectedTextColor[3],
-- 		},

-- 		Text3 = NewIFText { 
-- 			x = -0.5 * w + 10,
-- 			y = BotBoxHeight * 0.75 - 10,
-- 			halign = "left", valign = "top",
-- 			font = this.listboxfont, 
-- 			textw = ColumnWidthL + ColumnWidthC + ColumnWidthR - 20, texth = BotBoxHeight * 0.333333,
-- 			startdelay=math.random()*0.5, nocreatebackground=1, 
-- 			textcolorr = gSelectedTextColor[1],
-- 			textcolorg = gSelectedTextColor[2],
-- 			textcolorb = gSelectedTextColor[3],
-- 		},
	}

	AddVerticalButtons(this.buttons, ifs_ms_CommandButton_layout_console)

	--size the background
	local wScreen,hScreen,vScreen,widescreen = ScriptCB_GetScreenInfo()
	-- calc the position of the movie preview window
	if(gPlatformStr == "PS2") then
		this.movieX = wScreen - 380
		this.movieY = hScreen - 260
		this.movieW = 380
		this.movieH = 310
	else
		this.movieW = 480.0
		this.movieH = 360.0
		this.movieX = wScreen - this.movieW
		this.movieY = hScreen - this.movieH + 24.0
	end

	-- Create our listboxes
	ListManager_fnInitList(this.MapListbox,ifs_ms_MapList_layout_console)
	ListManager_fnInitList(this.ModeListbox,ifs_ms_ModeList_layout_console)
	ListManager_fnInitList(this.EraListbox,ifs_ms_EraList_layout_console)
	ListManager_fnInitList(this.PlayListbox,ifs_ms_PlayList_layout_console)
end

ifs_missionselect_console_fnBuildScreen(ifs_missionselect_console)
ifs_missionselect_console_fnBuildScreen = nil -- dump out of memory to save

AddIFScreen(ifs_missionselect_console,"ifs_missionselect_console")