-- A Tool for metadata synchronization from media files to clips in MediaStore

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

win = disp:AddWindow({
    ID = 'EditWin',
    TargetID = 'EditWin',
    Geometry = {0, 0, 600, 600},
    WindowTitle = 'EXIF Metadata Synchronizer',
    ui:VGroup{
        ID = "root",

        ui:HGroup{
          ui:Label{ID = "LabelMaxTreeDepth", Text = "Max subfolder level shown",},
          -- ui:Slider{ID = 'MaxSourceTreeDepth', Minimum = 1, Maximum = 32},
          ui:SpinBox{ID = 'MaxSourceTreeDepth', Minimum = 1, Maximum = 32, Value = 6},
        },
        ui:VGap(5, 0.01),
        ui:HGroup{
          ui:Label{ID = "LabelSelectFolder", Text = "Select media folder",},
          ui:ComboBox{ID = "ComboMediaRoot"},
        },

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

-- Display the volumes attached to the system
function ListVolumes()
  resolve = Resolve()
  local ms = resolve:GetMediaStorage()
  return ms:GetMountedVolumes()
end

-- Display the subfolders in the MediaStorage
function ListSubFolders(index)
  resolve = Resolve()
  local ms = resolve:GetMediaStorage()
  local vol = ListVolumes()
  return ms:GetSubFolders(index)
end

-- preload several top folders
function LoadMediaStore(maxDepth)
  local vol = ListVolumes()

  for i, value in ipairs(vol) do
    ListMediaSubfolders(value, 1, maxDepth)
  end
end

function ListMediaSubfolders(folder, currLevel, maxLevel)
  if currLevel >= maxLevel then
    return
  end
  local folders = ListSubFolders(folder)
  for j, val in ipairs(folders) do
    itm.ComboMediaRoot:AddItem(val)
    currLevel = currLevel + 1
    ListMediaSubfolders(val, currLevel, maxLevel)
  end
end

function ConvertDate(date)
  return (date:gsub('(%d+):(%d+):(%d+) (%d+:%d+:%d+)','%1-%2-%3 %4'))
end

-- filename from path
function GetFileName(path)
  return path:match("^.+/(.+)$")
end


function win.On.MaxSourceTreeDepth.ValueChanged(ev)
  print('SpinBox: '.. itm.MaxSourceTreeDepth.Value)

  itm.ComboMediaRoot:Clear()
  -- show only top level volumes (depending on maxDepth)
  LoadMediaStore(itm.MaxSourceTreeDepth.Value)
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

-- The window was closed
function win.On.EditWin.Close(ev)
    disp:ExitLoop()
end

function runCmd(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s:match( "(.-)%s*$" ) -- remove trailing space
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

function fetchMeta(file, exifs)
  -- file paths needs escaping whitespace with quotes
  local doc = itm.TextEdit.PlainText
  local cmd = 'exiftool -csv '.. exifs .. ' "'.. file .. '"'
  print(cmd)
  local out = runCmd(cmd, true)

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
  for i, val in ipairs(mp:GetRootFolder():GetClipList()) do
    clips[val:GetName()] = val
  end

  return clips
end

-- match existing media file with a file in media pool
function matchMeta(file, clips, exifs)
  --fetchMeta(file)
  local fn = GetFileName(file)
  if clips[fn] ~= nil then
    local log = itm.TextEdit.PlainText
    log = log .. fn .. "\n"
    local clip = clips[fn]
    -- print('matched ' .. fn .. ' with: ' .. clip:GetMediaId())
    local meta = fetchMeta(file, exifs)

    -- update clip metadata
    for i, attr in ipairs(exifBoxes) do
      if attr['check'].Checked then
        -- use attribute name from checkbox label
        local val = meta[attr['combo'].CurrentText]
        if val ~= nil then
          log = log .. attr['check'].Text.. ' : '.. val .. "\n"
          clip:SetMetadata(attr['check'].Text, val)
        end
      end
    end
    itm.TextEdit.PlainText = log
    itm.TextEdit:MoveCursor("Start", "MoveAnchor")
  end
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
  print('[Update] Synchronizing metadata...')

  itm.TextEdit.PlainText = ''

  local clips = loadMediaPool()

  resolve = Resolve()
  local ms = resolve:GetMediaStorage()
  local dir = itm.ComboMediaRoot.CurrentText

  local files = ms:GetFileList(dir)
  local exifs = CollectRequiredExifs()

  for i, val in ipairs(files) do
    matchMeta(val, clips, exifs)
  end

  for i, val in ipairs(ms:GetSubFolderList(dir)) do
    local sub = ms:GetFileList(val)
    for j, file in ipairs(sub) do
      matchMeta(file, clips, exifs)
    end
  end
end

exifBoxes = {
  -- EXIF tag mapped by default to resolve field
  { exif = 'CreateDate', check = itm.CheckShot, combo = itm.ComboShot, },
  { exif = 'Model', check = itm.CheckCamera, combo = itm.ComboCamera, },
  { exif = 'ISO', check = itm.CheckIso, combo = itm.ComboIso, },
  { exif = 'Lens', check = itm.CheckLens, combo = itm.ComboLens, },
  { exif = 'LensType', check = itm.CheckLensType, combo = itm.ComboLensType, },
  { exif = 'Make', check = itm.CheckMake, combo = itm.ComboMake, },
}

function PopulateExifCombo(exifBoxes)
  -- exiftool recognized attributes
  exif = {
    'CreateDate',
    'ISO',
    'Lens',
    'LensType',
    'LensSpec',
    'Make',
    'Model',
    'ModifyDate',
    'MediaCreateDate',
    'MediaModifyDate',
  }

  for i, meta in ipairs(exifBoxes) do
    meta['combo']:AddItems(exif)        -- set all known EXIF keys
    meta['combo'].CurrentText = meta['exif'] -- set default value
  end
end

PopulateExifCombo(exifBoxes)
LoadMediaStore(itm.MaxSourceTreeDepth.Value)

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