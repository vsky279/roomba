local FILE_READ_CHUNK = 1024

local _file = file
local file_exists, file_open = _file.exists, _file.open
local node_LFS_resource = node.LFS.resource -- luacheck: ignore

local file_lfs = {}

local function file_lfs_create (filename)
  local content = node_LFS_resource(filename)
  local pos = 1

  local read = function (_, n_or_char)
    local p1, p2
    if type(n_or_char) == "number" then
      p1, p2 = pos, pos + n_or_char
    elseif type(n_or_char) == "string" then
      p1 = pos
      local _
      _, p2 = content:find(n_or_char, p1)
      if not p2 then p2 = p1 + FILE_READ_CHUNK end
    else
      error("invalid parameter")
    end
    if p2 - p1 > FILE_READ_CHUNK then p2 = pos + FILE_READ_CHUNK end
    if p1>#content then return end
    pos = p2+1
    return content:sub(p1, p2)
  end

  local seek = function (_, whence, offset)
    if whence == "set" then
      pos = offset
    elseif whence == "cur" then
      pos = pos + offset
    elseif whence == "end" then
      pos = #content + offset
    elseif whence then -- not nil not one of above
      return -- on error return nil
    end
    return pos
  end

  local obj = {}
  obj.read = read
  obj.readline = function(self) return read(self, "\n") end
  obj.seek = seek

  setmetatable(obj, {
    __index = function (_, k)
      return function (...)
        return _file[k](...)
      end
    end
  })

  return obj
end

file_lfs.exists = function (filename)
  return (node_LFS_resource(filename) ~= nil) or file_exists(filename)
end

file_lfs.open = function (filename, mode)
  mode = mode or "r"
  if file_exists(filename) then
    return file_open(filename, mode)
  elseif node_LFS_resource(filename) and mode:find("r") then
    return file_lfs_create (filename)
  else
    return file_open(filename, mode)
  end
end

setmetatable(file_lfs, {
  __index = function (_, k)
    return function (...)
        local t = ...
        if type(t) == "table" then
          return t[k](...)
        else
          return _file[k](...)
        end
      end
  end
})

print ("[file_lfs] LFS file routines loaded")
return file_lfs