--[[

   TABLE
   CSV
   FILE
   OS

]]
require "config"

loop = 500000


----------------------------- TABLE ----------------------------------



table.dump = function (t, tab, recur)
   local tab_, col = "   ", ""
   if tab then tab = tab..tab_ else tab = "" end
   local s = tab.."{\n"

   for i,v in pairs (t) do
      if type(v) == "table" then
         s = s..tab..tab_..i.." = "..table.dump(v, tab, true)
      else
         if type(v) ~= "number" then qts="\"" else qts="" end
         if type(tonumber(i)) ~= "number" then lbl=i.." = " else lbl="" end
         s = s..string.format("%s%s%s%s%s,\n", tab..tab_, lbl, qts, tostring(v), qts)
      end
   end
   if recur == true then col = "," end
   s = s..tab.."}"..col.."\n"

   return s
end


table.toString = function (t)
   local s = "{"
   for i,v in pairs (t) do
      s = s .. "\n"
      if type(v) == "table" then
         local vv = "{\n"
         for a,b in pairs(v) do
            --vv = string.format ("%s  %s = \"%s\",\n", vv, a, tostring(b))  -- with numbers naming the fields
            vv = string.format ("%s  \"%s\",\n", vv, tostring(b))
         end
         v = vv.." },"
         --s = s .. (string.format (" %s = %s", i, tostring(v)))   -- with numbers naming the fields
         s = s .. (string.format (" %s", tostring(v))) 
      else
         --s = s .. (string.format (" %s = \"%s\",", i, tostring(v)))  -- with numbers naming the fields
         s = s .. (string.format (" \"%s\",", tostring(v)))
      end
   end
   if next(t) then
      s = s .. "\n" 
   end
   s = s .. "}\n"

   return s
end


table.count = function(t, item)
   local count = 0
   for i,v in pairs(t) do
      if item == v then count = count + 1 end
   end
   return count
end


table.unique = function(t)
   local n = {}
   for i,v in ipairs(t) do
      if(table.count(n, v) == 0) then
         n[#n+1] = v
      end
   end
   return n
end



table.count_item = function(t, entry, item)
   local count = 0
   for i,v in pairs(t) do
      if entry[item] == v[item] then count = count + 1 end
   end
   return count
end


table.unique_item = function(t, item)
   local n = {}
   for i,v in ipairs(t) do
      if(table.count_item(n, v, item) == 0) then
         n[#n+1] = v
      end
   end
   return n
end


----------------------------- STRING ----------------------------------

string.toid = function (str)
   return string.gsub(string.gsub(str,"(%p+)"," "),"(%s+)","_")
end

string.extract_latlon = function(str)
   str = string.gsub(str, "%s+", "")

   -- tratar corretamente (converter) geotab no formato:  22°51'33.20"S,43°23'17.42"O
   -- agora simplesmente eliminaremos estas entradas.
   -- procurar expressao como esta em obj_info.lua:render_geotag()
   if string.find(str, "°") ~= nil or string.find(str, "'") ~= nil then
      return nil, nil
   end

   local lat, lon = nil, nil
   local b, c = string.find(str, ",")

   if b and c then
      lat = tonumber(string.sub(str,1,b-1))
      lon = tonumber(string.sub(str,b+1,-1))
   end

   if type(lat) == "number" and type(lon) == "number" then
      if lat < -180 or lat > 180 or lon < -90 or lon > 90 then
         lat, lon = nil, nil
      end
   else
      lat, lon = nil, nil
   end

   return lat, lon
end

string.extract_datetime = function(str, splited)
   local _, _, Y, m, d, H, M, S = string.find(str, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")

   Y = Y or "0"
   m = m or "0"
   d = d or "0"
   H = H or "00"
   M = M or "00"
   S = S or "00"

   if splited then
      return Y, m, d, H, M, S
   else
      return d.."-"..m.."-"..Y.." "..H..":"..M..":"..S
   end

end

----------------------------- ECT ----------------------------------

find_hostname = function( a, h, k ) 
   local host_name

   if a ~= "" and a ~= nil then host_name = a end
   if host_name == nil and h ~= "" and h ~= nil then host_name = h end
   if host_name == nil and k ~= "" and k ~= nil then host_name = k end

   return host_name
end


----------------------------- CSV ----------------------------------

-- Transform an array of strings into CSV 
function toCSV (t, sep)
   sep = sep or ','     -- my default, use 'semi-colon' (,) as field delimiter instead of 'comma' (;)
   local s = ""
   local p

   for _,p in pairs(t) do
      --s = s .. sep .. escapeCSV(p, sep)
      s = s .. sep .. p 
   end
   return string.sub(s, 2)      -- remove first comma
end


-- If a string has commas or quotes inside, enclose it between quotes and escape its original quotes
function escapeCSV (s, sep)
   sep = sep or ','     -- use 'semi-colon' as field delimiter instead of 'comma'
   --local s = ""

   if string.find(s, '['..sep..'"]') then
      s = '"' .. string.gsub(s, '"', '""') .. '"'
   end
   return s
end


-- Transform a CSV line string into an array of strings
-- Return a table
function fromCSV (s, sep)
   sep = sep or ';'     -- use 'semi-colon' as field delimiter instead of 'comma'
   s = s .. sep
   local t = {}         -- table to collect fields
   local fieldstart = 1
   repeat
         if string.find(s, '^"', fieldstart) then        -- next field is quoted? (start with '"'?)
            local a, c
            local i = fieldstart
            repeat
               a, i, c = string.find(s, '"("?)', i+1)  -- find closing quote
            until c ~= '"'                              -- quote not followed by quote?
            if not i then error('unmatched "') end
            local f = string.sub(s, fieldstart+1, i-1)
            table.insert(t, (string.gsub(f, '""', '"')))
            fieldstart = string.find(s, sep, i) + 1
         else                                             -- unquoted; find next comma
            local nexti = string.find(s, sep, fieldstart)
            table.insert(t, string.sub(s, fieldstart, nexti-1))
            fieldstart = nexti + 1
         end
   until fieldstart > string.len(s)
   return t
end


----------------------------- FILE ----------------------------------

function remove_control_caracter(str)
   local res, i = str, nil
   res, i = string.gsub(res,"%c", "_")
   --res, i = string.gsub(res,"[^%a%s]", "")
   return res
end


-- Return a table where each entry is a line
function line_reader(filename)

   --[[ OLD IMPLEMENTATION
   io.input(filename)
   local lines = {}
   -- read the lines in table 'lines'
   for line in io.lines() do
      table.insert(lines, line)
   end
   return lines
   ]]--

   local f = io.open(filename, "r")
   local lines = {}
   local line = ""

   if not f then return nil end

   while true do
      line = f:read("*line")
      if not line then 
         break 
      else
         table.insert(lines, line)
      end
   end
   f:close()

   return lines
end


function line_writer(filename, table_of_tables, sep)
   -- Empty file
   local f = io.open(filename, 'w')
   f:close()

   f = io.open(filename, 'a')
   -- Append each table in CSV format to the file
   for _, v in ipairs(table_of_tables) do
      f:write(toCSV(v,sep).."\n")
   end
   f:close()

end


function text_file_reader(filename)
   local text
   local f = io.open(filename, 'r')
   if f ~= nil then 
      text = f:read("*all")
      f:close()
   end

   return text
end


function text_file_appender(filename, text)
   local f = io.open(filename, 'a')
   f:write(text)
   f:close()
end


function text_file_writer(filename, text)
   local f = io.open(filename, 'w')
   f:write(text)
   f:close()
end


function remove_file(filename)
   return os.capture("/bin/rm -f "..filename)
end

----------------------------- OS ----------------------------------

function os.splittime(time_)
   D, H = math.modf( time_ / 24 / 60 / 60 )
   H, M = math.modf(H * 24)
   M, S = math.modf(M * 60)
   S, _ = math.modf(S * 60)

   return D, H, M, S
end


function os.week_pt(week)
   local weeks = { [0] = "Domingo",
                   [1] = "Segunda-feira",
                   [2] = "Terça-feira", 
                   [3] = "Quarta-feira", 
                   [4] = "Quinta-feira", 
                   [5] = "Sexta-feira", 
                   [6] = "Sábado" }

    return weeks[tonumber(week)]
end


function os.month_pt(month)
   local months = { [1] = "Janeiro", 
                    [2] = "Fevereiro", 
                    [3] = "Março", 
                    [4] = "Abril", 
                    [5] = "Maio", 
                    [6] = "Junho", 
                    [7] = "Julho", 
                    [8] = "Agosto", 
                    [9] = "Setembro", 
                    [10] = "Outubro", 
                    [11] = "Novembro", 
                    [12] = "Dezembro" }
   return months[tonumber(month)]
end


function os.capture(cmd, raw)
--DEBUG: text_file_writer("/tmp/cmd", cmd)
   local f = assert(io.popen(cmd, 'r'))
   local s = assert(f:read('*a'))
   f:close()
   if raw then return s end
   s = string.gsub(s, '^%s+', '')
   s = string.gsub(s, '%s+$', '')
   s = string.gsub(s, '[\n\r]+', ' ')
   return s
end


function os.sleep(seg)
   os.capture("sleep "..tonumber(seg))
end


function os.reboot()
   return os.capture("/sbin/reboot")
end


function os.shutdown()
   return os.capture("/sbin/poweroff")
end


function os.reset_monitor()
   return os.capture("/usr/sbin/invoke-rc.d nagios3 reload")
end


function os.reinit_monitor()
   return os.capture("/usr/sbin/invoke-rc.d nagios3 restart")
end


function os.reset_monitor_db()
   return os.capture(config.path.itvision.."/bin/rendo")
end
