--[[
 Logger Lua module
 Written by Lukas Voborsky, @voborsky
]]

local logger = {}

local pattern = "(%d%d%d%d)%.log"
local atom = "<f"

-- -- Note that the space between debug and the arglist is there for a reason
-- -- so that a simple global edit "   -- debug(" -> "-- debug(" or v.v. to
-- -- toggle debug compiled into the module.
local print, node_heap = print, node.heap
local function debug (fmt, ...) -- upval: cnt (, print, node_heap)
  -- if not mpu9250.debug then return end
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
function logger.open(fn, ppattern, latom)
  local self, size
  atom = latom or atom
  local lpattern = ppattern or pattern
  if fn then
    debug("open - opening logfile '%s' for reading", fn)
    local logfile = file_open(fn, "r")
    local fl = file_list(fn)
    size = (fl[fn] or 0)//struct_size(atom)

    self = {
      read = logger_read,
      close = logger_close,
      logfile = logfile,
      atom = atom,
    }
  else
    local fl = file_list(lpattern)
    local max=0
    for k,_ in pairs(fl) do
      local n = tonumber(k:match(lpattern))
      max = n>max and n or max
    end

    local i=0
    lpattern = lpattern:gsub("%((.+)%)", function (m) return m end) -- remove capture
    lpattern = lpattern:gsub("%%([%(%)%.%%%+%-%*%?%[%^%$])", function (m) return m end) -- replace special characters
    lpattern:gsub("%%d", function() i=i+1 end)
    lpattern = lpattern:gsub(("%%d"):rep(4), ("%%%%0%dd")%4)
    debug("open - opening logfile '%s' for writing", lpattern:format(max + 1))
    local logfile = file_open(lpattern:format(max + 1), "w")

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
  local fl = file_list(lpattern)
  for k,v in pairs(fl) do
    fl[k] = v//struct_size(atom)
  end
  return fl
end

------------------------------------------------------------------------------
function logger_write(self, data)
  if not self.logfile then error("no logfile open") end
  self.logfile:write(struct_pack(self.atom, data))
end

function logger_read(self, n)
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
  local s = self.atom:rep(n)
  local res = {struct_unpack(s, data)}
  res[n+1]=nil
  return res, not neof
end

function logger_close(self)
  if self.logfile then
    self.logfile:close()
    self.logfile = nil
  end
end

return logger
