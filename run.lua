function getopt( arg, options )
  local tab = {}
  for k, v in ipairs(arg) do
    if string.sub( v, 1, 2) == "--" then
      local x = string.find( v, "=", 1, true )
      if x then tab[ string.sub( v, 3, x-1 ) ] = string.sub( v, x+1 )
      else      tab[ string.sub( v, 3 ) ] = true
      end
    elseif string.sub( v, 1, 1 ) == "-" then
      local y = 2
      local l = string.len(v)
      local jopt
      while ( y <= l ) do
        jopt = string.sub( v, y, y )
        if string.find( options, jopt, 1, true ) then
          if y < l then
            tab[ jopt ] = string.sub( v, y+1 )
            y = l
          else
            tab[ jopt ] = arg[ k + 1 ]
          end
        else
          tab[ jopt ] = true
        end
        y = y + 1
      end
    end
  end
  return tab
end

function open_temp_script()
  local handle
  local fname
  while true do
    fname = "yourfile" .. tostring(math.random(11111111,99999999) .. ".bat")
    handle = io.open(fname, "r")
    if not handle then
      handle = io.open(fname, "w")
      break
    end
    io.close(handle)
  end
  return handle, fname
end

function gitGetDefaultDir(options)
  local path,file = string.match(options["repo"], "(.-)([^\\/]-%.?([^%.\\/]*))$")
  local i,j = file:find('.', 1, true)
  return options["out"].. "\\"..string.sub(file, 1, i-1)
end

function gitGetVersion(path)
  script, name = open_temp_script()
  script:write("pushd " .. path .. "\n")
  script:write("git rev-parse HEAD > version.txt\n")
  script:write("popd")
  io.close(script)  
  local f = io.popen(name)
  local l = f:read("*all")
  f:close()
  os.remove(name)
  local f = io.open(path.."/version.txt","r")
  local version = f:read("*line")
  f:close()
  os.remove(path.."/version.txt")
  return version  
end

function exists(file)
  local ok, err, code = os.rename(file, file)
  if not ok then
     if code == 13 then
        -- Permission denied, but it exists
        return true
     end
  end
  return ok, err
end

function gitClone(options)
  script, name = open_temp_script()
  script:write("pushd " .. options["out"] .. "\n")
  script:write("git clone -q --branch " .. options["version"] .. " \"" .. options["repo"] .. "\"\n")
  script:write("popd")
  io.close(script)  
  local f = io.popen(name)
  local l = f:read("*all")
  f:close()
  os.remove(name)
  return out
end

local result = {path = ""}
options = getopt(arg, "")
--options["repo"]
--options["hash"]
--options["version"]
--options["out"]
result.path = gitGetDefaultDir(options)
if not exists(result.path) then
  gitClone(options)
end
if (gitGetVersion(result.path) == options["hash"]) then
  return result
else
  print("Repo version "..gitGetVersion(result.path).." and expected version "..options["hash"].." mismatch!")
  os.exit(1)
end