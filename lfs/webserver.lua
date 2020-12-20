local string_find, string_gmatch, string_sub, string_gsub =
      string.find, string.gmatch, string.sub, string.gsub
local file_open, file_list, file_remove = file.open, file.list, file.remove
local table_sort = table.sort

local W = {}
local modname = ...

local l=require("logger")
local pattern = "(%d%d%d%d%d%d)-(%d%d%d%d)%.log"
local atom = "HbH" -- time in 0.1 seconds, sensor id + sing of value, sensor value (absolute value)

local html_header =
[[
HTTP/1.1 200 OK
Content-Type: text/html
Connection: close

]]
local attachment_header =
[[
HTTP/1.1 200 OK
Content-Type: application/%s
Content-Disposition: attachment; filename="%s"
Connection: close

]]

-- -- Note that the space between debug and the arglist is there for a reason
-- -- so that a simple global edit "   -- debug(" -> "-- debug(" or v.v. to
-- -- toggle debug compiled into the module.
local print, node_heap = print, node.heap
local function debug (fmt, ...) -- upval: cnt (, print, node_heap)
  if (...) then fmt = fmt:format(...) end
  print("[webserver]", node_heap(), fmt)
end

local function sendlog(client, logfile, json)
  local data, eof = logfile:read(64)
  if data then
    -- specific way of storing roomba data
    for _,d in pairs(data) do
      local d2=d[2]
      d[3] = d[3] * (d2>0 and 1 or -1)
      d[2] = (d2>0 and d2 or -d2)
    end
    -- //specific way of storing roomba data
    local line = sjson.encode(data)
    if json then
      line = line .. (eof and "" or ",")
    else
      line = string_gsub(line, "%],%[", "\n")
      line = string_gsub(line, "[%[%]]", "") -- remove [ ]
      line = line..(eof and "" or "\n")
    end
    debug("sendlog: sending %d chars", #line)
    client:send(line, function() sendlog(client, logfile, json) end)
  else
    debug("sendlog: finalizing")
    if json then client:send("]") end
    logfile:close()
    client:close()
    client:on("sent", nil)
  end
end

local function webserver_session(socket)
  socket:on("receive", function(client, request)
    local _, _, method, path, vars = string_find(request, "([A-Z]+) (.+)?(.+) HTTP")
    if(method == nil)then
        _, _, method, path = string_find(request, "([A-Z]+) (.+) HTTP")
    end
    if method == "POST" then
      _, _, vars =  string_find(request, "\r*\n\r*\n(.+)")
    end
    debug("request: %s, %s, %s", method, path, vars)
    path = string_sub(path, 2) -- remove first char, i.e. "/"
    path = (path == "") and "index.html" or path
    local parser = (path == "index.html") or (path == "chart.html")
    local fd = file_open(path, "r")
    if not fd then
        return client:send("HTTP/1.0 404 Not Found\r\n\r\n404 Not Found\r\n")
    end

    if parser then -- process dynamic html page
      local _GET_section, _GET_id, _GET_action
      do
        local _GET = {}
        if (vars ~= nil)then
            for k, v in string_gmatch(vars, "(%w+)=([a-zA-Z0-9%%+%.%-]+)&*") do
                _GET[k] = v
            end
        end
         _GET_section, _GET_id, _GET_action = _GET.section, _GET.id, _GET.action
      end -- free _GET
      if _GET_section == "logfiles" then
        if _GET_action == "JSON" then -- download log as JSON
          fd:close()
          debug("JSON: %s", _GET_id)
          local logfile=l.open(_GET_id, pattern, atom)
          local fn = string_gsub(_GET_id, "log","json")
          return client:send(attachment_header:format("json", fn).."[",
            function() sendlog(client,  logfile, true) end)
        elseif _GET_action == "CSV" then -- download log as CSV
          fd:close()
          debug("CSV: %s", _GET_id)
          local logfile=l.open(_GET_id, pattern, atom)
          local fn = string_gsub(_GET_id, "log","csv")
          return client:send(attachment_header:format("csv", fn),
            function() sendlog(client, logfile) end)
        elseif _GET_action == "Delete" then
          debug("Delete: %s", _GET_id)
          file_remove(_GET_id)
        end
      end

      local function sendhtml()
        local line = fd:readline()
        if line then
          if string_find(line, "$LOGFILE") then -- dynamically compiled line
            local fls = {}
            if path == "chart.html" then
              fls[1]=_GET_id
            else
              do
                local fl = file_list(pattern)
                for n in pairs(fl) do table.insert(fls, n) end
              end -- free fl
              table_sort(fls)
              if #fls==0 then return sendhtml() end
            end

            local co=coroutine.create(function(lco)
              for _, logfile in pairs(fls) do
                debug("preparing index.html: %s", logfile)
                local lline = line
                lline = string_gsub(lline, "$LOGFILE", logfile)
                local lf, s= l.open(logfile, pattern, atom)
                lf:close()
                lline = string_gsub(lline, "$DETRECS", ("%d records")%s)
                client:send(lline, function()
                  local _, done =coroutine.resume(lco)
                  if done then
                    sendhtml()
                  end
                end)
                coroutine.yield()
              end
              return true
            end)
            coroutine.resume(co, co)
          else
            client:send(line, sendhtml)
          end
        else
          fd:close()
          client:close()
          client:on("sent", nil)
        end
      end

      client:send(html_header, sendhtml)
    else
      local function sendfile()
        local line=fd:read(1024)
        if line then
          client:send(line, sendfile)
        else
          fd:close()
          client:close()
          client:on("sent", nil)
        end
      end

      sendfile()
    end
  end)
end

function W.open(_, port)
  port = port or 80
  debug("Starting webserver on port %d", port)
  local srv=net.createServer()
  W.srv = srv

  local function srvListen()
    srv:listen(port, webserver_session)
  end

  if not pcall(srvListen) then
    debug("Unable to start server")
    -- tmr.create():alarm(1000, tmr.ALARM_AUTO, function(t)
      -- debug("Retrying start")
      -- if pcall(srvListen) then
        -- debug("Server started")
        -- t:stop()
        -- t:unregister()
      -- end
    -- end)
  end
end

function W.close(this)
  debug("Closing webserver")
  if this.svr then this.svr:close() end
  package.loaded[modname] = nil
end

return W