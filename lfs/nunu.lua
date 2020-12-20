-- luacheck: globals print telnet r
local unpack, table, pairs = unpack, table, pairs
local tmr_now = tmr.now
local node_task_post, node_task_LOW_PRIORITY = node.task.post, node.task.LOW_PRIORITY
local uwrite = uart.write

local rtctime_epoch2cal = rtctime.epoch2cal

uart.setup(0, 115200, 8, uart.PARITY_NONE, 1, 0)
-- local s = softuart.setup(115200, 4, 3)

local n=require("ntp")
r = require('roomba')(function (c) uwrite(0, c) end)
local r = r

-- local rprint = print
-- -- print = function(...) if telnet then rprint(...) end end
-- print = function(...)
  -- local arg = {...}
  -- for i, a in pairs(arg) do
    -- s:write(a)
    -- if arg[i+1] then s:write("\t") end
  -- end
  -- s:write("\n")
-- end
-- local print = print

local sensors = {7, 8, 9, 10, 11, 12, 14, 15, 26, 28, 29, 30, 31,
  43, 44, 46, 47, 48, 49, 50, 51, 54, 55, 58}
--r.stream()
-- 19, 20 - distance, angle - useless for stream
-- 39, 40, 41, 42 - requested velocities/radius - returns nothing for stream


local previous = {}
local change = {}
local datagram_count = 0
local last_print = 0

local function datagram(data)
  -- print(#data, data:byte(1), data:byte(2))
  local response = r.datagram(data)
  if not response then return end

  datagram_count = datagram_count + 1
  -- print(datagram_count)

  for index, value in pairs(response) do
    if change[index]~=1 and value ~= previous[index] then
      if ((index>=28 and index<=31) or (index>=46 and index<=51)) and previous[index]
      then -- Cliff Signals
        local p = previous[index]
        local chg = (value - p) --/ p
        -- chg = chg < 0 and -chg or chg
        change[index] = ((chg/p>0.2 or chg/p<-0.2) and (chg>5 or chg<-5)) and 1 or 0
      else
        change[index] = 1
      end
      previous[index] = value
    end
  end

  local now = tmr_now()
  if now - last_print < 500e3 then return end
  last_print = now

  for index, c in pairs(change) do
    if c == 1 then
      local value = response[index]
      local sensor, verbose = r.packetverbose(index, value)
      print(("Time:%.1f, #:%d, Packe:%d, Value:%d, %s, %s"):format(
        now/1e6, datagram_count, index, value, sensor, verbose))
      change[index] = 0
    end
  end
end

local last = 0
local buffer = ""
-- local tmr_rx = tmr.create() -- timer to close datagram when no further data are received

local function rx(data)
  -- tmr_rx:stop()
  local now =  tmr_now()
  if now-last > 2e3 or #buffer > 150 then -- lets assume datagram ends with 2ms silence
    local buf = buffer
    buffer = ""
    node_task_post(node_task_LOW_PRIORITY, function() return datagram(buf) end)
  end
  buffer= buffer..data
  last = now
  -- if #data>0 then tmr_rx:alarm(100, tmr.ALARM_SINGLE, function() rx("") end) end
end

-- s:on("data", 1, rx)
uart.on("data", 0, rx, 0)

local commands = {
  function()
    print("Sending reset command")
    r.reset()
  end,
  function()
    local tm = rtctime_epoch2cal(n:time())
    local wday, hour, min = tm["wday"]-1, tm["hour"], tm["min"]
    print(("Setting time to %s, %02d:%02d"):format(
      wday==0 and "Sun" or wday==1 and "Mon" or wday==2 and "Tue" or
      wday==3 and "Wed" or wday==4 and "Thu" or wday==5 and "Fri" or
      wday==6 and "Sat" or "Err",
      hour, min))
    r.settime(wday, hour, min)
  end,
  function()
    print("Starting datastream")
    r.stream(unpack(sensors))
  end,
}

local cmd_tmr = tmr.create()

local function cmd_exec()
  if #commands > 0 then
    local cmd=table.remove(commands, 1)
    cmd()
  else
    cmd_tmr:unregister()
    cmd_tmr = nil
  end
end

cmd_tmr:register(2000, tmr.ALARM_AUTO, cmd_exec)

local function timeSync()
  n:sync(function() cmd_tmr:start() end, timeSync)
end
timeSync()
