-- luacheck: globals print r
local unpack, pairs = unpack, pairs
local tmr_now = tmr.now
local node_task_post, node_task_LOW_PRIORITY = node.task.post, node.task.LOW_PRIORITY
local tmr_ALARM_SINGLE = tmr.ALARM_SINGLE
local uwrite = uart.write

local rtctime_epoch2cal = rtctime.epoch2cal

local pattern = "(%d%d%d%d%d%d)-(%d%d%d%d)%.log"
local atom = "HbH" -- time in seconds (/5), sensor id + sing of value, sensor value (absolute value)

r = require('roomba')(function (c) uwrite(0, c) end)
local r, r_transmitting = r, r.transmitting

uart.setup(0, 115200, 8, uart.PARITY_NONE, 1, 0)
-- local s = softuart.setup(115200, 4, 3)

local rprint = print
print = function(...) if not r_transmitting() then rprint(...) end end
-- print = function(...)
  -- local arg = {...}
  -- for i, a in pairs(arg) do
    -- s:write(a)
    -- if arg[i+1] then s:write("\t") end
  -- end
  -- s:write("\n")
-- end
-- local print = print

local print, node_heap = print, node.heap
local function debug (fmt, ...) -- upval: cnt (, print, node_heap)
  -- if not logger.debug then return end
  if (...) then fmt = fmt:format(...) end
  print("[nunu]", node_heap(), fmt)
end


local n=require("ntp")

local l_open = require('logger').open

local sensors = {7, 8, 9, 10, 11, 12, 14, 15, 26, 28, 29, 30, 31,
  43, 44, 46, 47, 48, 49, 50, 51, 54, 55, 58}
--r.stream()
-- 19, 20 - distance, angle - useless for stream
-- 39, 40, 41, 42 - requested velocities/radius - returns nothing for stream


local previous = {}
local change = {}
local datagram_count = 0
local last_print = 0
local encoder_counts
local last_move = 0
local log, start

local function datagram(data)
  -- debug("%d\t%d\t%d", #data, data:byte(1), data:byte(2))
  local response = r.datagram(data)
  if not response then return end

  datagram_count = datagram_count + 1
  -- debug("Datagram # %d", datagram_count)

  for sensor, value in pairs(response) do
    if change[sensor]~=1 and value ~= previous[sensor] then
      if ((sensor>=28 and sensor<=31) or (sensor>=46 and sensor<=51)) and previous[sensor]
      then -- Cliff Signals
        local p = previous[sensor]
        local chg = (value - p) --/ p
        -- chg = chg < 0 and -chg or chg
        chg = ((chg/p>0.2 or chg/p<-0.2) and (chg>5 or chg<-5)) and 1 or 0
        change[sensor] = chg
        if chg == 1 then previous[sensor] = value end
      else
        change[sensor] = 1
        previous[sensor] = value
      end
    end
  end

  -- follow encoder counts to see if roomba is moving
  local enccnt = (response[43] or 0) + (response[44] or 0)
  encoder_counts = encoder_counts or enccnt

  local now = tmr_now()//1e5 -- 0.1 second precision

  if enccnt > encoder_counts then -- roomba is moving
    last_move = now
    encoder_counts = enccnt
    if not log then -- start log if not logging already
      debug("Roomba started moving, start logging.")
      local tm = n:ts2gmt(n:time())
      log = l_open(nil, pattern, atom,
        (tm[1] - 2000) * 10000 + tm[2] * 100 + tm[3], tm[4]*100 + tm[5])
      start = now
      -- r.stream(unpack(sensors))
    end
  end

  -- check whether roomba stopped moving
  do
    local diff = now - last_move
    diff = ((diff < 0) and (diff + 0x7fffffff) or diff)
    if log and diff > 50 then
      debug("Roomba stopped moving, stop logging.")
      -- r.streampauseresume(0)
      log:close()
      log = nil
      encoder_counts = nil
    end
  end

  for sensor, c in pairs(change) do
    if c == 1 then
      local value = response[sensor]

      if log then
        local runtime = now - start
        runtime = ((runtime < 0) and (runtime + 0x7fffffff) or runtime)
        -- log:write(runtime, sensor * (value<0 and -1 or 1), value>0 and value or -value)
        debug("Log write: %02x %02x %02x", runtime, sensor * (value<0 and -1 or 1), value>0 and value or -value)
      end

      local sensor_name, verbose = r.packetverbose(sensor, value)
      local diff = now - last_print
      diff = ((diff < 0) and (diff + 0x7fffffff) or diff)
      if diff > 5 then
        debug("Time:%.1f, Datagram #:%d, Packet:%d, Value:%d, %s, %s",
          now/10, datagram_count, sensor, value, sensor_name, verbose)
        last_print = now
      end
      change[sensor] = 0
    end
  end

end

local last = 0
local buffer = ""
local tmr_rx = tmr.create() -- timer to close datagram when no further data are received

local function rx(data)
  tmr_rx:stop()
  local now =  tmr_now()
  if now-last > 2e3 or #buffer > 150 then -- lets assume datagram ends with 2ms silence
    local buf = buffer
    buffer = ""
    node_task_post(node_task_LOW_PRIORITY, function() return datagram(buf) end)
  end
  buffer= buffer..data
  last = now
  if #data>0 then tmr_rx:alarm(100, tmr.ALARM_SINGLE, function() rx("") end) end
end

-- s:on("data", 1, rx)
uart.on("data", 0, rx, 0)

-- local cmd_tmr = tmr.create()

local function settime()
  local t = n:time()
  if t-n:tz() ~= 0 then
    local tm = rtctime_epoch2cal(t)
    local wday, hour, min = tm["wday"]-1, tm["hour"], tm["min"]
    debug("Setting time to %s, %02d:%02d",
      wday==0 and "Sun" or wday==1 and "Mon" or wday==2 and "Tue" or
      wday==3 and "Wed" or wday==4 and "Thu" or wday==5 and "Fri" or
      wday==6 and "Sat" or "Err",
      hour, min)
    r.settime(wday, hour, min)
  end
end

-- local function checkifmoving()
  -- if not log then -- if not log in progress then check if it's moving
    -- debug("Time %s, checking if roomba is moving.", n:format())
    -- change = {} -- print everything as it was new information
    -- settime()
    -- r.stream(43, 44)
    -- r.streampauseresume(1) -- enable stream
    -- cmd_tmr:alarm(1000, tmr_ALARM_SINGLE, function()
      -- if not log then -- if not loggin then stop stream
        -- debug("Roomba not moving. Sleep for 15 seconds")
        -- r.streampauseresume(0)
      -- end
      -- -- and check again in 15s
      -- cmd_tmr:alarm(15000, tmr_ALARM_SINGLE, checkifmoving)
    -- end)
  -- else -- otherwise check in 15s again
    -- cmd_tmr:alarm(15000, tmr_ALARM_SINGLE, checkifmoving)
  -- end
-- end

-- checkifmoving()

local function timeSync()
  n:sync(function() 
    settime()
    -- r.stream(unpack(sensors))
  end, timeSync)
end
timeSync()
