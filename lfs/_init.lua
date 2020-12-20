-- init.lua, version 20.09
local fn= "roomba"
local reg = 10
local smph = {0x534d, 0x5048}


local pcall, dofile, print, unpack, require, table_concat, table_insert, string_dump =
  pcall, dofile, print, unpack, require, table.concat, table.insert, string.dump
local file_open = file.open
local uwrite, rtcmem_read32, rtcmem_write32, tmr_create, tmr_ALARM_SINGLE, tmr_ALARM_AUTO, enduser_setup_start,
  enduser_setup_stop, node_restart =
  uart.write, rtcmem.read32, rtcmem.write32, tmr.create, tmr.ALARM_SINGLE, tmr.ALARM_AUTO, enduser_setup.start,
  enduser_setup.stop, node.restart
local wifi_sta = wifi.sta
local wifi_sta_status, wifi_sta_getip, wifi_sta_getapinfo, wifi_sta_config, wifi_STA_GOTIP, wifi_STA_CONNECTING =
  wifi_sta.status, wifi_sta.getip, wifi_sta.getapinfo, wifi_sta.config, wifi.STA_GOTIP, wifi.STA_CONNECTING

-- Execute the LFS init
local lfs_t = node.LFS
package.loaders[3] = function(module) -- loader_flash
  return lfs_t[module]
end

local credentials={}

local function disarm()
  -- print("[init] disarming semaphore")
  rtcmem_write32(reg, 0, 0)
end

local function restart()
  disarm()
  -- print("[init] restarting")
  -- node_restart()
end

local function save_credentials()
  do
    local c=wifi_sta_getapinfo()
    local new=true
    if c then
      c=c[1]
      local s,check,a = pcall(dofile, "credentials.lc")
      if (s and check == "credentials") and a[1].ssid==c.ssid and a[1].pwd==c.pwd then
        return
      end

      for i = 1, #credentials do
        if credentials[i].ssid==c.ssid then credentials[i]=c; new=false end
      end
      if new then table_insert(credentials, 1, c) end
    end
  end

  local cred_s={}
  for i =1, #credentials do
    local c = credentials[i]
    cred_s[i]=('{ssid="%s",pwd="%s"}'):format(c.ssid, c.pwd)
  end
  local save_statement = 'return "credentials", {' .. table_concat(cred_s, ',') .. '}'
  -- print ("[init] Saving credentials")
  -- print(save_statement)
  local save_file = file_open("credentials.lc","w")
  save_file:write(string_dump(loadstring(save_statement)))
  save_file:close()
end

-- print("[init] Setting up WIFI...")

local s,check,a = pcall(dofile, "credentials.lc")
if s and check == "credentials" then
  for i = 1, #a do credentials[i]=a[i] end
end
-- print (("[init] %d credential(s) found"):format(#credentials))

-- print("[init] telnet/ftp")
require("telnet"):open()
-- require("ftpserver"):createServer('root', '123')

wifi.setmode(wifi.STATION)
-- wifi.setphymode(wifi.PHYMODE_G)
if credentials[1] then
  -- uwrite(0,"[init] Connecting to: "..credentials[1].ssid)
  wifi_sta_config(credentials[1])
end
wifi_sta.connect()

local tmr_wifi = tmr_create()
local tmr_enduser
local eus_start = true

tmr_wifi:alarm(500, tmr_ALARM_AUTO, function()
  -- uwrite(0,".")
  if wifi_sta_status() == wifi_STA_GOTIP then -- connected to wifi
    tmr_wifi:unregister()
    tmr_wifi = nil
    if tmr_enduser then tmr_enduser:stop() end
    enduser_setup_stop()
    -- print("\n[init] IP: "..wifi_sta_getip())
    save_credentials()

    if not (rtcmem_read32(reg) == smph[1] and  rtcmem_read32(reg+1) == smph[2]) then
      rtcmem_write32(reg, unpack(smph))
      tmr_create():alarm(60000, tmr_ALARM_SINGLE, disarm)
      -- print("[init] Starting", fn)
      -- require(fn)
    else
      -- print("[init] semaphore armed - stopping")
      tmr_create():alarm(180000, tmr_ALARM_SINGLE, restart)
    end
  end
  if (wifi_sta_status() ~= wifi_STA_GOTIP) and (wifi_sta_status() ~= wifi_STA_CONNECTING) then -- no wifi to connect to
    if credentials[1] then
      -- uwrite(0,"failed")
      -- rotate credentials
      local cred, nc=credentials[1], #credentials
      for i=2, nc do credentials[i-1]=credentials[i] end
      credentials[nc]=cred
      -- uwrite(0,"\n[init] Connecting to: "..credentials[1].ssid)
      wifi_sta_config(credentials[1])
    end

    if eus_start then
      -- print("\n[init] Starting EUS")
      eus_start=nil
      tmr_enduser = tmr_create()
      tmr_enduser:alarm(180000, tmr_ALARM_SINGLE, restart)
      enduser_setup_start()
     end
  end
end)
