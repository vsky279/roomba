--[[
 Logger Lua module
 Written by Lukas Voborsky, @voborsky
]]

local logger = {}

local pattern = "(%d%d%d%d)%.log"
local atom = "<f"

-- -- Note that the space between debug and the arglist is there for a reason
-- -- so that a simple global edit "   debug(" -> "debug(" or v.v. to
-- -- toggle debug compiled into the module.
local print, node_heap = print, node.heap
local function debug (fmt, ...) -- upval: cnt (, print, node_heap)
  -- if not logger.debug then return end
  if (...) then fmt = fmt:format(...) end
  print("[logger]", node_heap(), fmt)
end

local logger_write
local logger_read
local logger_close

local file_open, file_list = file.open, file.list
local struct_pack, struct_unpack, struct_size = struct.pack, struct.unpack, struct.size
--------------------------- Set up the logger object ----------------------------
--
--
---------------------------------------------------------------------------------
function logger.open(fn, ppattern, latom, ...)
  local self, size
  atom = latom or atom
  local lpattern = ppattern or pattern
  if fn then
    local logfile = file_open(fn, "r")
    local fl = file_list(fn:gsub("([%-%.])","%%%1"))
    size = (fl[fn] or 0)//struct_size(atom)
    debug("open - opening logfile '%s' for reading (size: %d records)", fn, size)

    self = {
      read = logger_read,
      close = logger_close,
      logfile = logfile,
      atom = atom,
    }
  else
    lpattern = lpattern:gsub("%((.-)%)", function (m) return m end) -- remove capture
    lpattern = lpattern:gsub("%%([%(%)%.%%%+%-%*%?%[%^%$])", function (m) return m end) -- replace special characters
    -- compress all %d%d => %02d; %02d%d => %03d
    local c=1
    while c>0 do
        lpattern, c=lpattern:gsub("%%([0-9]*)d%%([0-9]*)d", function(a, b)
            return ("%%0%dd"%((a=="" and 1 or tonumber(a)) + (b=="" and 1 or tonumber(b))))
        end)
    end

    local logfile, name
    if (...) then
      name = lpattern:format(...)
    else
      local kpattern = ppattern or pattern
      local fl = file_list(kpattern:gsub("([%-%.])","%%%1"))
      local max=0
      for k,_ in pairs(fl) do
        local n = k:match(kpattern)
        n=tonumber(n)
        max = n>max and n or max
      end
      name = lpattern:format(max+1, 0, 0, 0, 0, 0)
    end
    debug("open - opening logfile '%s' for writing", name)
    logfile = file_open(name, "w")

    self = {
      write = logger_write,
      close = logger_close,
      logfile = logfile,
      atom = atom,
    }
  end
  return self, size
end

function logger.list(lpattern, latom)
  atom = latom or atom
  lpattern = lpattern or pattern
  debug("list: %s", lpattern)
  local fl = file_list(lpattern:gsub("([%-%.])","%%%1"))
  for k,v in pairs(fl) do
    fl[k] = v//struct_size(atom)
  end
  return fl
end

------------------------------------------------------------------------------
function logger_write(self, ...)
  if not self.logfile then error("no logfile open") end
  self.logfile:write(struct_pack(self.atom, ...))
end

function logger_read(self, n)
  n=n or 1
  local sz = struct_size(self.atom)
  local data = self.logfile and self.logfile:read(sz * n)
  local neof = self.logfile and self.logfile:read(sz) -- check eof
  if neof then self.logfile:seek("cur", sz) end -- if not eof then seek back
  if not data then
    if self.logfile then self.logfile:close() end
    self.logfile = nil
    return
  end
  n = #data//sz
  local s = self.atom
  local res = {}
  for _=1,n-1 do
    local r={struct_unpack(s, data:sub(1, sz))}
    r[#r]=nil -- remove last result of struct.unpack
    res[#res+1]=r
    data=data:sub(sz+1)
  end
  -- local res = {struct_unpack(s, data)}
  return res, not neof
end

function logger_close(self)
  if self.logfile then
    self.logfile:close()
    self.logfile = nil
  end
end

return logger
