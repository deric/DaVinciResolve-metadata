-- A Tool for metadata synchronization from media files to clips in MediaStore

-- Check the current operating system platform
platform = (FuPLATFORM_WINDOWS and 'Windows') or (FuPLATFORM_MAC and 'Mac') or (FuPLATFORM_LINUX and 'Linux')

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

win = disp:AddWindow({
    ID = 'EditWin',
    TargetID = 'EditWin',
    Geometry = {100, 200, 600, 600},
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
            ui:Label{ID = "LabelResolve", Text = "DaVinci Resolve Field",},
            ui:Label{ID = "LabelExif", Text = "EXIF Field",},
          },

          ui:VGap(5, 0.01),

          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckShot", Text = "Shot", Checked = true,},
            ui:ComboBox{ID = "ComboShot",},
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
            ui:CheckBox{ID = "CheckShutterSpeed", Text = "Shutter", Checked = true,},
            ui:ComboBox{ID = "ComboShutterSpeed",},
          },
          ui:HGroup{
            Weight = 0.1,
            ui:CheckBox{ID = "CheckAperture", Text = "Camera Aperture", Checked = true,},
            ui:ComboBox{ID = "ComboAperture",},
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
            ui:Button{ID = "LoadMetadata", Text = "Sync MediaStore",},
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
    },
})

itm = win:GetItems()

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

function win.On.CheckShot.Clicked(ev)
  ToogleCheckbox(itm.CheckShot, itm.ComboShot)
end

function win.On.CheckCamera.Clicked(ev)
  ToogleCheckbox(itm.CheckCamera, itm.ComboCamera)
end

function win.On.CheckIso.Clicked(ev)
  ToogleCheckbox(itm.CheckIso, itm.ComboIso)
end

function win.On.CheckLens.Clicked(ev)
  ToogleCheckbox(itm.CheckLens, itm.ComboLens)
end

function win.On.CheckLensType.Clicked(ev)
  ToogleCheckbox(itm.CheckLensType, itm.ComboLensType)
end

function win.On.CheckMake.Clicked(ev)
  ToogleCheckbox(itm.CheckMake, itm.ComboMake)
end

function win.On.BtnSelectAll.Clicked(ev)
   -- Select all checkboxes
  for i, attr in ipairs(exifBoxes) do
    attr['check'].Checked = true
  end
end

function win.On.BtnUnselectAll.Clicked(ev)
   -- Unelect all checkboxes
  for i, attr in ipairs(exifBoxes) do
    attr['check'].Checked = false
  end
end

-- The window was closed
function win.On.EditWin.Close(ev)
    disp:ExitLoop()
end

function runCmd(cmd)
  local fileHandle = assert(io.popen(cmd, 'r'))
  local out = assert(fileHandle:read('*a'))
  fileHandle:close()
  return out
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

function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
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

function fetchMeta(file, exifs)
  -- file paths needs escaping whitespace with quotes
  local doc = itm.TextEdit.PlainText
  local cmd = 'exiftool -csv -ee '.. exifs .. ' "'.. file .. '"'
  print(cmd)
  local out = runCmd(cmd)

  local header, values
  i = 0
  for line in out:gmatch("[^\r\n]+") do
    if i == 0 then
      header = split(line, ',')
    else
      values = split(line, ',')
    end
    i = i + 1
  end

  -- meta data as table
  local t = {}
  for i,v in ipairs(header) do
    -- format date fields, e.g. CreateDate, ModifyDate, DateTimeOriginal
    if string.match(v, '.*Date.*') ~= nil then
      t[v] = ConvertDate(values[i])
    else
      t[v] = values[i]
    end
  end
  --print('CreateDate:' .. t['CreateDate'])

  return t
end

function loadMediaPool()
  resolve = Resolve()
  local project = resolve:GetProjectManager():GetCurrentProject()
  local mp = project:GetMediaPool()
  local clips = {}

  -- load clips from pool into a table
  local count = 0

  count = recursiveLoadMedia(mp:GetRootFolder(), clips, count)

  log("Loaded " .. count .. " media pool items")

  return clips
end

function recursiveLoadMedia(folder, clips, count)
  for i, val in ipairs(folder:GetClipList()) do
    clips[val:GetName()] = val
    count = count + 1
  end

  for i, subfolder in ipairs(folder:GetSubFolderList()) do
    log("Loading subfolder " .. subfolder:GetName())
    count = recursiveLoadMedia(subfolder, clips, count)
  end

  return count
end

-- append message into TextEdit field
function log(message)
  local log = itm.TextEdit.PlainText
  if message == nil then
    log = log .. "(nil) \n"
  else
    log = log .. message .. "\n"
  end
  itm.TextEdit.PlainText = log
  itm.TextEdit:MoveCursor("End", "MoveAnchor")
end

function CollectRequiredExifs()
  local t = {}
  local j = 1

  -- go through all checkboxes and find selected ones
  for i, attr in ipairs(exifBoxes) do
    if attr['check'].Checked then
      t[i] = attr['combo'].CurrentText
      j = i
    end
  end

  if j == 1 then
    error("No check box was selected!")
  end

  return '-' .. table.concat(t," -")
end


-- The "LoadMetadata" button was pressed.
function win.On.LoadMetadata.Clicked(ev)
  itm.TextEdit.PlainText = ''
  log('Synchronizing metadata...')

  local clips = loadMediaPool()
  local exifs = CollectRequiredExifs()

  updateMetadata(clips, exifs)
end

function updateMetadata(clips, exifs)
  local cnt = 1
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
      log("Path: " .. clip_path)
      -- read EXIF
      local meta = fetchMeta(clip_path, exifs)

      -- update clip's metadata
      for i, attr in ipairs(exifBoxes) do
        if attr['check'].Checked then
          -- use attribute name from checkbox label
          local val = meta[attr['combo'].CurrentText]
          if val ~= nil then
            log(attr['check'].Text.. ' : '.. val)
            clip:SetMetadata(attr['check'].Text, val)
          end
        end
      end
    end
    cnt = cnt + 1
  end
  log("(done) Processed " .. cnt .. " media pool files")
end

exifBoxes = {
  -- EXIF tag mapped by default to resolve field
  { exif = 'CreateDate', check = itm.CheckShot, combo = itm.ComboShot, },
  { exif = 'Model', check = itm.CheckCamera, combo = itm.ComboCamera, },
  { exif = 'ISO', check = itm.CheckIso, combo = itm.ComboIso, },
  { exif = 'Lens', check = itm.CheckLens, combo = itm.ComboLens, },
  { exif = 'LensType', check = itm.CheckLensType, combo = itm.ComboLensType, },
  { exif = 'Make', check = itm.CheckMake, combo = itm.ComboMake, },
  { exif = 'WhiteBalance', check = itm.CheckWhiteBalance, combo = itm.ComboWhiteBalance, },
  { exif = 'ShutterSpeed', check = itm.CheckShutterSpeed, combo = itm.ComboShutterSpeed },
  { exif = 'Aperture', check = itm.CheckAperture, combo = itm.ComboAperture}
}

function PopulateExifCombo(exifBoxes)
  -- exiftool recognized attributes
  exif = {
    'CreateDate',
    'DateTimeOriginal',
    'ShutterSpeed',
    'Aperture',
    'ISO',
    'Lens',
    'LensType',
    'LensSpec',
    'Make',
    'Model',
    'ModifyDate',
    'MediaCreateDate',
    'MediaModifyDate',
    'WhiteBalance',
  }

  for i, meta in ipairs(exifBoxes) do
    meta['combo']:AddItems(exif)        -- set all known EXIF keys
    meta['combo'].CurrentText = meta['exif'] -- set default value
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
