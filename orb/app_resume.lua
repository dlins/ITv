#!/usr/bin/env wsapi.cgi

-- includes & defs ------------------------------------------------------
require "Model"
require "Monitor"
require "Auth"
require "View"
require "util"
require "monitor_util"

module(Model.name, package.seeall,orbit.new)

local objects  = Model.nagios:model "objects"
local monitors = Model.itvision:model "monitors"

-- models ------------------------------------------------------------


function objects:select(name1, name2)
   local clause = ""
   if name1 ~= nil then
      clause = " name1 = '"..name1.."'"
   else
      clause = " name1 like '"..config.monitor.check_app.."%'"
   end

   if name2 ~= nil then
      clause = clause.." and name2 = '"..name2.."'"
   else
      clause = clause.." and name2 is NULL"
   end
   clause = clause .. " and is_active = 1"

   return Model.query("nagios_objects", clause)
end


function objects:select_host(name1)
   local clause = ""
   if name1 ~= nil then
      clause = " o.name1 = '"..name1.."'"
   else
      clause = " o.name1 like '"..config.monitor.check_app.."%' "
   end

   clause = clause .. " and objecttype_id = 1 and o.name2 is null and o.is_active = 1"

   return Model.query("nagios_objects o", clause)
end


-- controllers ------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
function list(web, msg)
   local auth = Auth.check(web)
   if not auth then return Auth.redirect(web) end

   local clause = nil

   if web.input.hostname ~= "" and web.input.hostname ~= nil then clause = " c.name like '%"..web.input.hostname.."%' " end
   if web.input.inventory ~= "" and web.input.inventory ~= nil then 
      local a = ""
      if clause then a = " and " else clause = "" end
      clause = clause..a.."c.otherserial like '%"..web.input.inventory.."%' "
   end
   if web.input.sn ~= "" and web.input.sn ~= nil then 
      local a = ""
      if clause then a = " and " else clause = ""  end
      clause = clause..a.."c.serial like '%"..web.input.sn.."%' "
   end
   local a = ""
   if clause then a = " and " else clause = "" end
   clause = clause..a.." p.entities_id in "..Auth.make_entity_clause(auth)

   local ics = Monitor.select_monitors_app_objs(nil, clause)

   return render_list(web, ics, msg)
end
ITvision:dispatch_get(list, "/", "/list", "/list/(.+)")
ITvision:dispatch_post(list, "/list", "/list/(.+)")





-- views ------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
function render_filter(web)
   local res = {}

   res[#res+1] = {strings.name..": ", input{ type="text", name="hostname", value = web.input.hostname }, " "}
   -- EXEMPLO res[#res+1] = {strings.inventory..": ", input{ type="text", name="inventory", value = web.input.inventory }, " "} 

   return res
end



---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
function render_list(web, ics, msg)
   local permission, auth = Auth.check_permission(web, "checkcmds")
   local row, res, link, url = {}, {}, {}, ""
   local refresh_time = 60

   local header = { 
      strings.alias.."/"..strings.name, strings.status, "IP", "CHECAGEM", strings.type, "."
   }

   for i, v in ipairs(ics) do
      local probe = v.m_name
      local serv, ip, itemtype, id, hst_name, alias = "", "", "", "", nil, nil
      if v.sw_name ~= "" and v.sv_name ~= nil then serv = v.sw_name.." / "..v.sv_name end

      -- muitos dos ifs abaixo existem em funcao da direrenca entre as queries com Computer e as com Network
      v.c_id = v.c_id or 0 v.n_id = v.n_id or 0 v.p_id = v.p_id or 0 v.sv_id = v.sv_id or 0
      hst_name = find_hostname(v.c_alias, v.c_name, v.c_itv_key)
      -- DEBUG: if hst_name == nil then hst_name = v.a_name.." ["..v.a_id..":"..v.o_object_id.."]" end
      if hst_name == nil then hst_name = v.ax_name end
      alias = v.m_name

      if v.p_itemtype then 
         itemtype = v.p_itemtype 
      else 
         if v.a_app_type_id == "1" then 
            itemtype = strings.entity 
         else 
            itemtype = strings.application 
         end
      end
      if v.p_ip then ip = v.p_ip else ip = v.n_ip end
      if v.c_id ~= 0 then c_id = v.c_id else c_id = v.n_id end

      if v.s_check_command_object_id == nil then 
         if permission == "w" then
            if tonumber(v.m_service_object_id) == -1 then
               link = font{ color="orange", "Pendente" }
            elseif serv ~= "" then
               link = a{ href= web:link("/add/"..v[1]..":"..c_id..":"..v.p_id..":"..v.sv_id), strings.add }
            else
               link = a{ href= web:link("/insert_host/"..v.p_id..":"..v.sv_id..":"..v.c_id..":"..v.n_id..":"
                                         ..hst_name..":"..ip), strings.add.." host" }
            end
         else
            link = "--"
         end
      else
         link = "--"
      end

      web.prefix = "/servdesk"
      if itemtype == "Computer" then
         url = web:link("/front/computer.form.php?id="..c_id)
      elseif itemtype == "NetworkEquipment" then
         url = web:link("/front/networkequipment.form.php?id="..c_id)
      else 
         web.prefix = "/orb/app_tabs"
         url = web:link("/list/"..v.ax_id..":2")
         probe = ""
      end

      if v.sw_name ~= "" then itemtype = "Service" end
      web.prefix = "/orb/app_resume"

      local name
      if permission == "w" then
         name = a{ href=url, hst_name}
      else
         name = hst_name
      end

      local state
      if tonumber(v.ss_has_been_checked) == 1 then
         if tonumber(v.m_state) == 0 then
            state = tonumber(APPLIC_DISABLE)
         else
            state = tonumber(v.ss_current_state)
         end

      else
         state = 4
      end
      local statename = applic_alert[state].name
      row[#row + 1] = { status={state=state, colnumber=2}, name, statename, ip, probe, itemtype, v.ss_output }
   end

   res[#res+1] = render_content_header(auth, "Monitoração", nil, web:link("/list"))
   if msg ~= "/" and msg ~= "/list" and msg ~= "/list/" then res[#res+1] = p{ font{ color="red", msg } } end
   res[#res+1] = render_form_bar( render_filter(web), strings.search, web:link("/list"), web:link("/list") )
   res[#res+1] = render_table(row, header)
   res[#res+1] = { br(), br(), br(), br() }

   return render_layout(res, refresh_time)
end



orbit.htmlify(ITvision, "render_.+")

return _M


