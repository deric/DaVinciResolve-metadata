-- A Tool for metadata synchronization from media files to clips in MediaStore

-- Check the current operating system platform
platform = (FuPLATFORM_WINDOWS and 'Windows') or (FuPLATFORM_MAC and 'Mac') or (FuPLATFORM_LINUX and 'Linux')

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local Cancelled = false

win = disp:AddWindow({
    ID = 'EditWin',
    TargetID = 'EditWin',
    Geometry = {100, 200, 550, 800},
    WindowTitle = 'EXIF Metadata Synchronizer',
    ui:VGroup{
        ID = "root",

        ui:HGroup{
          Weight = 0.1,
          ui:Label{
            ID = "LabelMapping", Text = "Metadata mapping",
            Alignment = { AlignHCenter = true, AlignVCenter = true },
          },
        },
        ui:VGap(5, 0.01),

        ui:VGroup{
          Weight = 0.1,
          ui:HGroup{
            Weight = 0.1,
            ui:Label{ID = "LabelResolve", Text = "DaVinci Resolve Field", ToolTip = 'Metadata fields within Resolve'},
            ui:Label{ID = "LabelExif", Text = "EXIF Field", ToolTip = 'Metadata fields within the scanned files'},
          },

          ui:VGap(5, 0.01),

          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckShot", Text = "Shot", Checked = true,},
            ui:ComboBox{ID = "ComboShot",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckDateRecorded", Text = "Date Recorded", Checked = true,},
            ui:ComboBox{ID = "ComboDateRecorded",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckCamera", Text = "Camera Type", Checked = true,},
            ui:ComboBox{ID = "ComboCamera",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckIso", Text = "ISO", Checked = true,},
            ui:ComboBox{ID = "ComboIso",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckLens", Text = "Lens", Checked = true,},
            ui:ComboBox{ID = "ComboLens",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckLensType", Text = "Lens Type", Checked = true,},
            ui:ComboBox{ID = "ComboLensType",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckMake", Text = "Camera Manufacturer", Checked = true,},
            ui:ComboBox{ID = "ComboMake",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckWhiteBalance", Text = "White Balance Tint", Checked = true,},
            ui:ComboBox{ID = "ComboWhiteBalance",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckCodecBitrate", Text = "Codec Bitrate", Checked = true,},
            ui:ComboBox{ID = "ComboCodecBitrate",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckShutterSpeed", Text = "Shutter Speed", Checked = true,},
            ui:ComboBox{ID = "ComboShutterSpeed",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckAperture", Text = "Camera Aperture", Checked = true,},
            ui:ComboBox{ID = "ComboAperture",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckCameraFPS", Text = "Camera FPS", Checked = true,},
            ui:ComboBox{ID = "ComboCameraFPS",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckCameraFirmware", Text = "Camera Firmware", Checked = true,},
            ui:ComboBox{ID = "ComboCameraFirmware",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckLocation", Text = "Location", Checked = false,},
            ui:ComboBox{ID = "ComboLocation", Enabled = false},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckComments", Text = "Comments", Checked = false,},
            ui:ComboBox{ID = "ComboComments", Enabled = false},
          },

        },
        
        ui:VGap(5, 0.01),

        ui:HGroup{
          Weight = 0.1,
          ui:VGroup{
            Weight = 0.1,
            ui:Button{ID = "BtnSelectAll", Text = "Select All",},
          },
          ui:VGroup{
            Weight = 0.1,
            ui:Button{ID = "BtnUnselectAll", Text = "Unselect All",},
          }
        },

      	ui:VGap(5, 0.01),

        ui:HGroup{
          Weight = 0.1,
          ui:Label{
            ID = "LabelSettings", Text = "Scan Settings",
            Alignment = { AlignHCenter = true, AlignVCenter = true },
          },
        },
        ui:VGap(5, 0.01),

        ui:HGroup{
          Weight = 0.1,
          ui:CheckBox{ID = "CheckExtractEmbedded", Text = "Extract Embedded Data", Checked = true, ToolTip = 'Disabling this will speedup scanning for files with GPS or motion data, but might skip metadata on certain cameras'},
          ui:CheckBox{ID = "CheckCurrentFolder", Text = "Scan Current Media Pool Folder Only", Checked = false, ToolTip = 'Only scan the files in the folder currently selected or open in the media pool'},
        },

        ui:VGap(5, 0.01),
        ui:HGroup{
            Weight = 0.1,
            ui:VGroup{
              Weight = 0.1,
              ui:Button{ID = "DryRun", Text = "Preview Scan", ToolTip = 'Scan the files without modifying any clip metadata in Resolve yet'},
            },
            ui:VGroup{
              Weight = 0.1,
              ui:Button{ID = "LoadMetadata", Text = "Scan And Apply", ToolTip = 'Scan and apply the EXIF metadata to the media pool clips in Resolve'},
            }
        },
        ui:HGroup{
        Weight = 1,
        ui:TextEdit{
            ID = 'TextEdit',
            TabStopWidth = 28,
            Font = ui:Font{
                Family = 'Droid Sans Mono',
                StyleName = 'Regular',
                PixelSize = 12,
                MonoSpaced = true,
                StyleStrategy = {
                    ForceIntegerMetrics = true
                },
                ReadOnly = true,
            },
            LineWrapMode = 'NoWrap',
            AcceptRichText = false,

            -- Use the Fusion hybrid lexer module to add syntax highlighting
            Lexer = 'fusion',
            },
        },

        ui:HGroup{
          Weight = 0.1,
          ui:VGroup{
            Weight = 0.1,
            ui:Button{ID = "BtnCancel", Text = "Cancel Scan" , Checkable = true, Enabled = false, ToolTip = 'Cancels the scan\nOnly click once to activate button, might react slow when code is busy'},
          }
        },
    },
})

itm = win:GetItems()

exifBoxes = {
  -- EXIF tag mapped by default to resolve field
  { exif = 'FileName', check = itm.CheckShot, combo = itm.ComboShot},
  { exif = 'CreateDate',check = itm.CheckDateRecorded, combo = itm.ComboDateRecorded},
  { exif = 'Model', check = itm.CheckCamera, combo = itm.ComboCamera},
  { exif = 'ISO', check = itm.CheckIso, combo = itm.ComboIso},
  { exif = 'Lens', check = itm.CheckLens, combo = itm.ComboLens},
  { exif = 'LensType', check = itm.CheckLensType, combo = itm.ComboLensType},
  { exif = 'Make', check = itm.CheckMake, combo = itm.ComboMake},
  { exif = 'WhiteBalance', check = itm.CheckWhiteBalance, combo = itm.ComboWhiteBalance},
  { exif = 'AvgBitrate', check = itm.CheckCodecBitrate, combo = itm.ComboCodecBitrate},
  { exif = 'ShutterSpeed', check = itm.CheckShutterSpeed, combo = itm.ComboShutterSpeed},
  { exif = 'Aperture', check = itm.CheckAperture, combo = itm.ComboAperture},
  { exif = 'VideoFrameRate', check = itm.CheckCameraFPS, combo = itm.ComboCameraFPS},
  { exif = 'FirmwareVersion', check = itm.CheckCameraFirmware, combo = itm.ComboCameraFirmware},
  { exif = 'GPSCoordinates', check = itm.CheckLocation, combo = itm.ComboLocation},
  { exif = 'Comment', check = itm.CheckComments, combo = itm.ComboComments},
}

  -- exiftool recognized attributes
exifAttributes = {
  'Aperture',
  'AudioChannels',
  'AudioSampleRate',
  'AvgBitrate',
  'Brightness',
  'CameraISO',
  'ColorMode',
  'ColorSpace',
  'Comment',
  'Contrast',
  'CreateDate',
  'CropHiSpeed',
  'DateTimeOriginal',
  'DaylightSavings',
  'FieldOfView',
  'FileName',
  'FilterEffect',
  'FirmwareVersion',
  'FrameRate',
  'GPSCoordinates',
  'HueAdjustment',
  'ISO',
  'Lens',
  'LensSpec',
  'LensType',
  'Make',
  'MediaCreateDate',
  'MediaModifyDate',
  'Megapixels',
  'Model',
  'ModifyDate',
  'Rotation',
  'Saturation',
  'Sharpness',
  'ShutterSpeed',
  'Software',
  'TimeZone',
  'ToningEffect',
  'VideoFrameRate',
  'WhiteBalance',
  'WhiteBalanceFineTune',
}


function ConvertDate(date)
  return date:gsub('(%d+):(%d+):(%d+) (%d+:%d+:%d+)','%1-%2-%3 %4')
end

-- disable comboBox when checkBox is not checked
function ToogleCheckbox(checkBox, comboBox)
  if checkBox.Checked then
    comboBox.Enabled = true
  else
    comboBox.Enabled = false
  end
end

function win.On.BtnSelectAll.Clicked(ev)
   -- Select all checkboxes
   SetExifBoxesState(true,false)
end

function win.On.BtnUnselectAll.Clicked(ev)
   -- Unelect all checkboxes
   SetExifBoxesState(false,false)
end

function SetExifBoxesState(State, Blocked)
  for i, attr in ipairs(exifBoxes) do
    if Blocked then attr['check'].Enabled = State else attr['check'].Checked = State end
    if Blocked and State and not attr['check'].Checked then else attr['combo'].Enabled = State end -- allways do unless the if conditions are met 
  end
end

-- The window was closed
function win.On.EditWin.Close(ev)
    disp:ExitLoop()
end

function inspect(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. inspect(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function split(pString, pPattern, Table)
   if Table == nil then Table = {} end -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
   end
   return Table
end

function fetchMeta(file, exifs, argfile, exiftool, cnt, extemd)
  local args = exifs .. '\n' .. extemd .. '\n-c\n%d° %.3f\'\n-csvDelim\n|\n-csv\n' .. file ..'\n-execute' .. cnt .. '\n'
  print((args:gsub('\n',' ')))
  argfile:write(args)
  argfile:flush()
  
  local header, values, line, stop
  int = 0
  repeat
    line = exiftool:read('*l')
    if CheckCancel() then return {} end
    if line == nil then
      log(' !! Error fetching metadata')
      return {}
    end
    stop = line:match('{ready%d*}')
    if stop == nil then
      if int == 0 then
        header = split(line, '|')
      else
        values = split(line, '|', values)
      end
      int = int + 1
    else
      LastLine = line:gsub('{ready%d*}','')
      if LastLine ~= '' and int ~= 0 then values = split(LastLine, '|', values) end
      print(stop)
      if header == nil or values == nil then
        log(' !! Failed to access file')
        return {}
      end
    end
  until stop ~= nil

  -- meta data as table
  local t = {}
  for i,v in ipairs(header) do
    -- format date fields, e.g. CreateDate, ModifyDate, DateTimeOriginal
    if string.match(v, '.*Date.*') ~= nil then
      t[v] = ConvertDate(values[i])
    elseif string.match(v, '.*GPS.*') ~= nil then
      t[v] = 'GPS: ' .. values[i]
    elseif string.match(v, '.*FileName.*') ~= nil then
      mod = values[i]:match('(.+)%..+$')
      if mod ~= nil then t[v] = mod end
    else
      t[v] = values[i]
    end
  end

  print(inspect(t))

  return t
end

function loadMediaPool()
  resolve = Resolve()
  local project = resolve:GetProjectManager():GetCurrentProject()
  local mp = project:GetMediaPool()
  local clips = {}
  local scanfolder = mp:GetRootFolder()
  if CheckCancel() then return end
  if itm.CheckCurrentFolder.Checked == true then
    scanfolder = mp:GetCurrentFolder()
  end

  -- load clips from pool into a table
  local count = 0

  count = recursiveLoadMedia(scanfolder, clips, count)
  if CheckCancel() then return end

  log("Loaded " .. count .. " media pool items")

  return clips
end

function recursiveLoadMedia(folder, clips, count)
  for i, val in ipairs(folder:GetClipList()) do
    local cname = val:GetClipProperty("Clip Name")
    if (type(cname) == "table") then
      cname = cname["Clip Name"]
    end
    cname = cname .. " [" .. val:GetMediaId() .."]"
    clips[cname] = val
    if CheckCancel() then return end
    count = count + 1
  end

  for i, subfolder in ipairs(folder:GetSubFolderList()) do
    log("Loading subfolder " .. subfolder:GetName())
    if CheckCancel() then return end
    count = recursiveLoadMedia(subfolder, clips, count)
  end

  return count
end

-- append message into TextEdit field
function log(message)
  local log = ''
  if message == nil then
    log = "(nil)"
  else
    log = message
  end
  itm.TextEdit:Append(log)
end

function CollectRequiredExifs()
  local t = {}
  local j = 1 -- concat doesn't work when numbering from zero
  if CheckCancel() then return end
  -- go through all checkboxes and find selected ones
  for i, attr in ipairs(exifBoxes) do
    if attr['check'].Checked then
      t[j] = attr['combo'].CurrentText
      j = j + 1
    end
  end

  if j == 1 then
    error("No check box was selected!")
  end

  return '-' .. table.concat(t,"\n-")
end

function SetBlockedState(State)
  local NotState = not State
  if State then
    itm.TextEdit.PlainText = ''
    Cancelled = false
  end
  SetExifBoxesState(NotState, true)
  itm.CheckExtractEmbedded.Enabled = NotState
  itm.CheckCurrentFolder.Enabled = NotState
  itm.BtnSelectAll.Enabled = NotState
  itm.BtnUnselectAll.Enabled = NotState
  itm.DryRun.Enabled = NotState
  itm.LoadMetadata.Enabled = NotState
  itm.BtnCancel.Enabled = State
end

-- The "LoadMetadata" button was pressed.
function win.On.LoadMetadata.Clicked(ev)
  SetBlockedState(true)
  log('Synchronizing metadata...')

  local clips = loadMediaPool()
  local exifs = CollectRequiredExifs()

  if Cancelled then log('Cancelled') else updateMetadata(clips, exifs, false) end
  SetBlockedState(false)
end

function win.On.DryRun.Clicked(ev)
  SetBlockedState(true)
  log('Only printing possible metadata changes')

  local clips = loadMediaPool()
  local exifs = CollectRequiredExifs()

  if Cancelled then log('Cancelled') else updateMetadata(clips, exifs, true) end
  SetBlockedState(false)
end

function CheckCancel()
  if Cancelled == false then
    Cancelled = itm.BtnCancel.Checked
    if Cancelled then
      itm.BtnCancel.Enabled = false
      itm.BtnCancel.Checked = false
      log('Cancelling...')
    end
  end
  return Cancelled
end

function setupexiftool(argfilename)
  local cmd = ''
  
  if platform == 'Mac' then 
      cmd = 'PATH=/usr/local/bin:/opt/homebrew/bin:$PATH; exiftool -stay_open true -@ "' .. argfilename .. '"'
  else
      cmd = 'exiftool -stay_open true -@ "' .. argfilename .. '"'
  end
  return io.popen(cmd, 'r')
end

-- noop = no-operation
function updateMetadata(clips, exifs, noop)
  local cnt = 0
  local argfilename = os.tmpname()
  print(argfilename)
  local argfile = io.open(argfilename,'w')
  local exiftool = setupexiftool(argfilename)
  local extemd = ''
  if itm.CheckExtractEmbedded.Checked == true then
    extemd = '-ee'
  end

  for name, clip in pairs(clips) do
    log("[Clip " .. cnt .. "] " .. name)
    -- actual path to clip's source on disk
    local clip_path = clip:GetClipProperty("File Path")
    if (type(clip_path) == "table") then
      -- property is yet another table in Resolve 16 (in Resolve 17, string will be returned)
      clip_path = clip_path["File Path"]
    end
    if clip_path == '' then
      -- e.g. Fusion clips don't have 'File Path' attribute
      -- there's probably no way how to retrieve original media file path
      -- print(inspect(clip:GetClipProperty()))
      log("(warning) Empty path can't fetch meta data")
    else
      -- log("Path: " .. clip_path)
      -- read EXIF
      local meta = fetchMeta(clip_path, exifs, argfile, exiftool, cnt, extemd)
      if CheckCancel() then break end
      -- update clip's metadata
      for i, attr in ipairs(exifBoxes) do
        if attr['check'].Checked then
          -- use attribute name from checkbox label
          local val = meta[attr['combo'].CurrentText]
          if val ~= nil then
            if noop then
              log(attr['check'].Text .. ': ' .. clip:GetMetadata(attr['check'].Text) .. ' -> ' .. val)
            else
              -- actually update attributes
              log(attr['check'].Text.. ' : '.. val)
              clip:SetMetadata(attr['check'].Text, val)
            end
          end
        end
      end
    end
    cnt = cnt + 1
    if CheckCancel() then break end
  end

  argfile:write('-stay_open\nFalse\n')
  argfile:flush()
  exiftool:close()
  argfile:close()
  os.remove(argfilename)
  if Cancelled then
    log("(Cancelled) Processed " .. cnt .. " media pool files")
  else
    log("(done) Processed " .. cnt .. " media pool files")
  end
end

function PopulateExifCombo(exifBoxes)
  for i, meta in ipairs(exifBoxes) do
    meta['combo']:AddItems(exifAttributes)   -- set all known EXIF keys
    meta['combo'].CurrentText = meta['exif'] -- set default value

    -- dynamic on click function declaration
    local comboBox = meta['combo']
    local checkBox = meta['check']

    local elmID =  checkBox['ID']

    win.On[elmID].Clicked = function(ev)
      ToogleCheckbox(checkBox, comboBox)
    end
  end
end

PopulateExifCombo(exifBoxes)

win:Show()
bgcol = { R=0.125, G=0.125, B=0.125, A=1 }
itm.TextEdit.BackgroundColor = bgcol
itm.TextEdit:SetPaletteColor('All', 'Base', bgcol)

-- The app:AddConfig() command that will capture the "Control + W" or "Control + F4" hotkeys so they will close the window instead of closing the foreground composite.
app:AddConfig('EditWin', {
    Target {
        ID = 'EditWin',
    },

    Hotkeys {
        Target = 'EditWin',
        Defaults = true,

        CONTROL_W = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
        CONTROL_F4 = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
    },
})

disp:RunLoop()
win:Hide()
