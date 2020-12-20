local ipairs, tostring, type, error = ipairs, tostring, type, error
local struct_unpack = struct.unpack
local table_remove = table.remove

local queue = {}
setmetatable(queue, { __shl = function (t,v) for _, i in ipairs(v) do t[#t+1]=i end return t end})

local write

local sender = tmr.create()
sender:alarm(21, tmr.ALARM_AUTO, function()
  if #queue > 0 then
    local c=table_remove(queue, 1)
    write(c)
  end
end)

local function sgn(v) return v>=0 and 1 or -1 end
-- local function abs(v) return sgn(v)*v end

local roomba = {}

-- commands

roomba.stop = function() local _ = queue << {128, 173} end
roomba.reset = function() local _ = queue << {128, 7} end
-- Baud Code: Baud Rate in BPS
-- 0: 300; 1: 600; 2: 1200; 3: 2400; 4: 4800; 5: 9600; 6: 14400; 7: 19200; 8: 28800; 9: 38400; 10: 57600; 11: 115200
roomba.baud = function(baud_code) local _ = queue << {128, 129, baud_code} end
roomba.safe = function() local _ = queue << {128, 131} end
roomba.full = function() local _ = queue << {128, 132} end
roomba.clean = function() local _ = queue << {128, 135} end
roomba.max = function() local _ = queue << {128, 136} end
roomba.spot = function() local _ = queue << {128, 134} end
roomba.seekdock = function() local _ = queue << {128, 143} end
roomba.power = function() local _ = queue << {128, 133} end
-- To disable scheduled cleaning, send all 0s.
-- Times are sent in 24 hour format. Hour (0-23) Minute (0-59)
-- [Days] - set bit 0 to 6, 0: Sun, 1: Mon, ..., Sat: 6
-- [Sun Hour] [Sun Minute] [Mon Hour] [Mon Minute] [Tue Hour] [Tue Minute]
-- [Wed Hour] [Wed Minute] [Thu Hour] [Thu Minute] [Fri Hour] [Fri Minute]
-- [Sat Hour] [Sat Minute]
roomba.schedule = function(...) local _ = queue << {128, 167, ...} end
roomba.settime = function(day, hour, minute) local _ = queue << {128, 168, day, hour, minute} end

roomba.drive = function(velocity, radius)
  local s
  s = sgn(velocity)
  velocity = s*(s*velocity > 500 and 500 or s*velocity)
  if radius==0 then
    radius = 0x8000
  else
    s = sgn(radius); radius = s*radius
    radius = s*(radius > 2000 and 2000 or radius)
  end
  local _ = queue << {128, 137, (velocity >> 8) & 0xff, velocity & 0xff, (radius >> 8) & 0xff, radius & 0xff}
end

-- Bits 0-2: 0 = off, 1 = on at 100% pwm duty cycle
-- Bits 3 & 4: 0 = motor’s default direction, 1 = motor’s opposite direction.
-- Default direction for the side brush is counterclockwise.
-- Default direction for the main brush/flapper is inward.
-- bit 4 - Main Brush Direction
-- bit 3 - Side Brush Clock-wise?
-- bit 2 - Main Brush
-- bit 1 - Vacuum
-- bit 0 - Side brush
roomba.motors = function(motors)
  local _ = queue << {128, 138, motors & 0x1f}
end

 -- [Main Brush PWM] [Side Brush PWM] [Vacuum PWM]
 -- 128 = 100%
roomba.pwmmotors = function(main, side, vacuum)
  local s
  s = sgn(main); main = s*main
  main = s*(main > 128 and 128 or main)
  s = sgn(side); side = s*side
  side = s*(side > 128 and 128 or side)
  vacuum = vacuum > 128 and 128 or vacuum
  vacuum = vacuum < 0 and 0 or vacuum
  local _ = queue << {128, 144, main & 0xff, side & 0xff, vacuum & 0xff}
end

roomba.led = function(led, color, intensity)
  local _ = queue << {128, 139, led & 0xf, color & 0xff, intensity & 0xff}
end

roomba.sensors = function(packet)
  local _ = queue << {128, 142, packet & 0x7}
end

roomba.query = function(...)
  local ids = {...}
  local _ = queue << {128, 149, #ids, ...}
end

roomba.stream = function(...)
  local ids = {...}
  local _ = queue << {128, 148, #ids, ...}
end

roomba.streampauseresume = function(onoff)
  local _ = queue << {128, 148, onoff & 0x1}
end

-- sensors
-- default is low byte first (little endian) (maybe 22, 23, 25, 26?)
local resp_type = {[7]="B",[8]="B",[9]="B",[10]="B",[11]="B",[12]="B",[13]="B",
  [14]="B",[15]="B",[16]="B",[17]="B",[18]="B",[19]=">h",[20]=">h",[21]="B",
  [22]=">H",[23]=">h",[24]="b",[25]=">H",[26]=">h",[27]=">H",[28]=">H",[29]=">H",
  [30]=">H",[31]=">H",[34]="B",[35]="B",[36]="B",[37]="B",[38]="B",[39]=">H",
  [40]=">h",[41]=">h",[42]=">h",[43]=">H",[44]=">H",[45]="B",[46]=">H",[47]=">H",
  [48]=">H",[49]=">H",[50]=">H",[51]=">H",[54]=">h",[55]=">h",[56]=">h",[57]=">h",[58]="B"}
local type_size = {["B"]=1,["b"]=1,["h"]=2,["H"]=2,[">H"]=2,[">h"]=2}
local sensor_name = {
  [7] = "Bumps and Wheel Drops",
  [8] = "Wall",
  [9] = "Cliff Left",
  [10] = "Cliff Front Left",
  [11] = "Cliff Front Right",
  [12] = "Cliff Right",
  [13] = "Virtual Wall",
  [14] = "Wheel Overcurrents",
  [15] = "Dirt Detect",
  [16] = "Unused",
  [17] = "Infrared Character Omni",
  [18] = "Buttons",
  [19] = "Distance",
  [20] = "Angle",
  [21] = "Charging State",
  [22] = "Voltage",
  [23] = "Current",
  [24] = "Temperature",
  [25] = "Battery Charge",
  [26] = "Battery Capacity",
  [27] = "Wall Signal",
  [28] = "Cliff Left Signal",
  [29] = "Cliff Front Left Signal",
  [30] = "Cliff Front Right Signal",
  [31] = "Cliff Right Signal",
  [34] = "Charging Sources Available",
  [35] = "OI Mode",
  [36] = "Song Number",
  [37] = "Song Playing",
  [38] = "Number of Stream Packets",
  [39] = "Requested Velocity",
  [40] = "Requested Radius",
  [41] = "Requested Right Velocity",
  [42] = "Requested Left Velocity",
  [43] = "Left Encoder Counts",
  [44] = "Right Encoder Counts",
  [45] = "Light Bumper",
  [46] = "Light Bump Left Signal",
  [47] = "Light Bump Front Left Signal",
  [48] = "Light Bump Center Left Signal",
  [49] = "Light Bump Center Right Signal",
  [50] = "Light Bump Front Right Signal",
  [51] = "Light Bump Right Signal",
  [54] = "Left Motor Current",
  [55] = "Right Motor Current",
  [56] = "Main Brush Motor Current",
  [57] = "Side Brush Motor Current Stasis",
  [58] = "Stasis"
}

local packetverbose = function(packetid, value)
  local verbose
  local sensor = sensor_name[packetid]
  if packetid == 7 then
    verbose = ("Bumb Right: %s; Bump Left: %s; Wheel Drop Right: %s; Wheel Drop Left: %s"):format(
      (value & 0x1 == 0) and "no bump" or "bump",
      (value & 0x2 == 0) and "no bump" or "bump",
      (value & 0x4 == 0) and "wheel raised" or "wheel dropped",
      (value & 0x8 == 0) and "wheel raised" or "wheel dropped"
    )
  elseif packetid == 8 then
    verbose = (value & 0x1 == 0) and "no wall" or "wall seen"
  elseif packetid == 9 or packetid == 10 or packetid == 11 or packetid == 12 then
    verbose = (value & 0x1 == 0) and "no " or "" .. "cliff"
  elseif packetid == 13 then
    verbose = (value & 0x1 == 0) and "no " or "" .. "virtual wall detected"
  elseif packetid == 14 then
    verbose = ("Side Brush: %s; Main Brush: %s; Right wheel: %s; Left Wheel: %s"):format(
      (value & 0x1 == 0) and "ok" or "overcurrent",
      (value & 0x4 == 0) and "ok" or "overcurrent",
      (value & 0x8 == 0) and "ok" or "overcurrent",
      (value & 0x10 == 0) and "ok" or "overcurrent"
    )
  elseif packetid == 18 then
    verbose = ("%s%s%s%s%s%s%s%s"):format(
      (value & 0x1 == 0) and "" or "Clean, ",
      (value & 0x2 == 0) and "" or "Spot, ",
      (value & 0x4 == 0) and "" or "Dock, ",
      (value & 0x8 == 0) and "" or "Minute, ",
      (value & 0x10 == 0) and "" or "Hour, ",
      (value & 0x20 == 0) and "" or "Day, ",
      (value & 0x40 == 0) and "" or "Schedule, ",
      (value & 0x80 == 0) and "" or "Clock, "
    )
    verbose = verbose:sub(1, -3)
  elseif packetid == 19 or packetid == 40 then
    verbose = ("%d mm")%value
  elseif packetid == 20 then
    verbose = ("%d°")%value
  elseif packetid == 22 then
    verbose = ("%d mV")%value
  elseif packetid == 23 or packetid == 25 or packetid == 26 or
  packetid == 54 or packetid == 55 or packetid == 56 or packetid == 57 then
    verbose = ("%d mA")%value
  elseif packetid == 24 then
    verbose = ("%d °C")%value
  elseif packetid == 21 then
    verbose =
      value == 0 and "Not charging" or
      value == 1 and "Reconditioning Charging" or
      value == 2 and "Full Charging" or
      value == 3 and "Trickle Charging" or
      value == 4 and "Waiting" or
      value == 5 and "Charging Fault Condition" or "undefined value"
  elseif packetid == 34 then
    verbose =
      value == 0 and "No charging source" or
      value == 1 and "Internal Charger" or
      value == 2 and "Home Base" or "undefined value"
  elseif packetid == 35 then
    verbose =
      value == 0 and "Off" or
      value == 1 and "Passive" or
      value == 2 and "Safe" or
      value == 3 and "Full" or "undefined value"
  elseif packetid == 37 then
    verbose =
      value == 0 and "OI song not playing" or "OI song playing"
  elseif packetid == 39 or packetid == 41 or packetid == 42then
    verbose = ("%d mm/s")%value
  elseif packetid == 45 then
    verbose = ("Lt Bumber Left: %s; Lt Bumber Front Left: %s; Lt Bumber Center Left: %s; "..
    "Lt Bumber Center Right: %s; Lt Bumber Front Right: %s; Lt Bumber Right: %s"
    ):format(
      (value & 0x1 == 0) and "no bump" or "bump",
      (value & 0x2 == 0) and "no bump" or "bump",
      (value & 0x4 == 0) and "no bump" or "bump",
      (value & 0x8 == 0) and "no bump" or "bump",
      (value & 0x10 == 0) and "no bump" or "bump",
      (value & 0x20 == 0) and "no bump" or "bump")
  elseif packetid == 58 then
    verbose =
      value == 0 and "no forward progress" or "forward progress"
  end
  verbose = verbose or tostring(value)
  return sensor, verbose
end

roomba.packetverbose = packetverbose

local function packet(packetid, response, doverbose)
  local value, sensor, verbose

  local rtype = resp_type[packetid]
  local rsize = type_size[rtype]
  if not rtype or not rsize then
    -- error(("Uknown Packet ID %d or type size '%s' or sensor name."):format(packetid, rtype))
    rtype = "B"
    rsize = 1
    sensor = "uknown"
    value = response:sub(1, rsize)
    response = response:sub(rsize+1,-1)
    value = struct_unpack(rtype, value)
    return value, response, 1, sensor, tostring(value)
  end
  if rsize > #response then
    return nil, response, 0
  end
  value = response:sub(1, rsize)
  response = response:sub(rsize+1,-1)
  value = struct_unpack(rtype, value)
  if doverbose then
    sensor = sensor_name[packetid]
    verbose = packetverbose(packetid, value)
  end
  return value, response, rsize, sensor, verbose
end

roomba.packet = packet

roomba.datagram = function(data)
  -- first byte is 19
  if data:byte() ~= 19 then return end
  data = data:sub(2,-1)

  -- second byte is number of bytes to follow
  local bytes = data:byte()
  data = data:sub(2,-1)

  -- print(("datagram length: %d, signalled: %d"):format(#data, bytes or -1))
  -- check datagram length: bytes + 1 byte for checksum
  if not bytes or bytes+1 ~= #data then return end

  local checksum = 19 + bytes
  for i=1,bytes+1 do
    checksum=checksum+data:byte(i)
  end

  -- print(("checksum: %d"):format(checksum & 0xff))
  if (checksum & 0xff) ~= 0 then return end

  local response = {}
  while #data > 1 do
    local pkt = data:byte()
    data = data:sub(2,-1)
    local value
    value, data = packet(pkt, data)
    response[pkt] = value
  end

  return response
end

roomba.transmitting = function()
  return #queue > 0
end

local function init(lwrite)
  if type(lwrite)~="function" then error("Invalid parameter. Function expected.") end
  write = lwrite
  return roomba
end

return init