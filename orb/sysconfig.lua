#!/usr/bin/env wsapi.cgi

require "orbit"
module("itvision", package.seeall, orbit.new)

-- configs ------------------------------------------------------------

require "config"
require "util"
require "view_utils"

mapper.conn, mapper.driver = config.setup_orbdb()

local ma = require "model_access"
local mr = require "model_rules"

-- models ------------------------------------------------------------

local sysconfig = itvision:model "sysconfig"

function sysconfig:select_sysconfig(id)
   local clause = ""
   if id then
      clause = "sysconfig_id = "..id
   end
   return self:find_all(clause)
end

-- controllers ------------------------------------------------------------

function list(web)
   local A = sysconfig:select_sysconfig()
   return render_list(web, A)
end
itvision:dispatch_get(list, "/", "/list")


function show(web, id)
   local A = sysconfig:select_sysconfig(id)
   return render_show(web, A)
end itvision:dispatch_get(show, "/show/(%d+)")


function edit(web, id)
   local A = sysconfig:select_sysconfig(id)
   return render_add(web, A)
end
itvision:dispatch_get(edit, "/edit/(%d+)")


function update(web, id)
   local sysconfig = {}
   if id then
      local tables = "itvision_sysconfig"
      local clause = "sysconfig_id = "..id
      --sysconfig:new()
      sysconfig.version = web.input.version
      sysconfig.created = web.input.created
      sysconfig.updated = web.input.updated
      sysconfig.home_dir = web.input.home_dir
      sysconfig.monitor_dir = web.input.monitor_dir
      sysconfig.monitor_bp_dir = web.input.monitor_bp_dir

      ma.update (tables, sysconfig, clause) 
   end

   return web:redirect(web:link("/list"))
end
itvision:dispatch_post(update, "/update/(%d+)")


function add(web)
   return render_add(web)
end
itvision:dispatch_get(add, "/add")


function insert(web)
   --sysconfig:new()
   sysconfig.version = web.input.version
   sysconfig.created = tonumber(web.input.created)
   sysconfig.created = sysconfig.created or 0
   sysconfig.updated = tonumber(web.input.updated)
   sysconfig.updated = sysconfig.updated or 0
   sysconfig.home_dir = web.input.home_dir
   sysconfig.monitor_dir = web.input.monitor_dir
   sysconfig.monitor_bp_dir = web.input.monitor_bp_dir
   sysconfig:save()
   return web:redirect(web:link("/list"))
end
itvision:dispatch_post(insert, "/insert")


function remove(web, id)
   local A = sysconfig:select_sysconfig(id)
   return render_remove(web, A)
end
itvision:dispatch_get(remove, "/remove/(%d+)")


function delete(web, id)
   if id then
      local clause = "sysconfig_id = "..id
      local tables = "itvision_sysconfig"
      ma.delete (tables, clause) 
   end

   return web:redirect(web:link("/list"))
end
itvision:dispatch_get(delete, "/delete/(%d+)")


itvision:dispatch_static("/css/%.css", "/script/%.js")


-- views ------------------------------------------------------------

function render_list(web, A)
   local rows = {}
   local res = {}
   
   res[#res + 1] = p{ button_link(strings.add, web:link("/add")) }
   res[#res + 1] = p{ br(), br() }

   for i, v in ipairs(A) do
      rows[#rows + 1] = tr{ 
         td{ a{ href= web:link("/show/"..v.sysconfig_id), v.version} },
         td{ v.created },
         td{ v.updated },
         td{ v.home_dir },
         td{ v.monitor_dir },
         td{ v.monitor_bp_dir },
         td{ button_link(strings.remove, web:link("/remove/"..v.sysconfig_id), "negative") },
         td{ button_link(strings.edit, web:link("/edit/"..v.sysconfig_id)) },
      }
   end

   res[#res + 1]  = H("table") { border=1, cellpadding=1,
      thead{ 
         tr{ 
             th{ strings.version }, 
             th{ strings.created }, 
             th{ strings.updated }, 
             th{ strings.home_dir }, 
             th{ strings.monitor_dir }, 
             th{ strings.monitor_bp_dir }, 
             th{ "." },
             th{ "." },
         }
      },
      tbody{
         rows
      }
   }

   return render_layout(res)
end


function render_show(web, A)
   A = A[1]
   local res = {}

   res[#res + 1] = p{ button_link(strings.add, web:link("/add")) }
   res[#res + 1] = p{ button_link(strings.remove, web:link("/remove/"..A.sysconfig_id)) }
   res[#res + 1] = p{ button_link(strings.edit, web:link("/edit/"..A.sysconfig_id)) }
   res[#res + 1] = p{ button_link(strings.list, web:link("/list")) }
   res[#res + 1] = p{ br(), br() }

   if A then
      res[#res + 1] = { H("table") { border=1, cellpadding=1,
         tbody{
            tr{ th{ strings.version }, td{ A.version } },
            tr{ th{ strings.created }, td{ A.created } },
            tr{ th{ strings.updated }, td{ A.updated } },
            tr{ th{ strings.home_dir }, td{ A.home_dir } },
            tr{ th{ strings.monitor_dir }, td{ A.monitor_dir } },
            tr{ th{ strings.monitor_bp_dir }, td{ A.monitor_bp_dir } },
         }
      } }
   else
      res = { error_message(3),
         p(),
         a{ href= web:link("/list"), strings.list}, " ",
         a{ href= web:link("/add"), strings.add}, " ",
      }
   end

   return render_layout(res)
end


function render_add(web, edit)
   local res = {}
   local s = ""
   local val1 = ""
   local val2 = ""
   local url = ""

   if edit then
      edit = edit[1]
      val1 = edit.version
      val2 = edit.created
      val3 = edit.updated
      val4 = edit.home_dir
      val5 = edit.monitor_dir
      val6 = edit.monitor_bp_dir
      url = "/update/"..edit.sysconfig_id
   else
      url = "/insert"
   end

   -- LISTA DE OPERACOES 
   res[#res + 1] = p{ button_link(strings.list, web:link("/list")) }
   res[#res + 1] = p{ br(), br() }

   res[#res + 1] = form{
      name = "input", method = "post",
      action = web:link(url),

      strings.version..": ", input{ type="text", name="version", value = val1 },br(),
      strings.created..": ", input{ type="date", name="created", value = val2 },br(),
      strings.updated..": ", input{ type="date", name="updated", value = val3 },br(),
      strings.home_dir..": ", input{ type="text", name="home_dir", value = val4},br(),
      strings.monitor_dir..": ", input{ type="text", name="monitor_dir", value = val5},br(),
      strings.monitor_bp_dir..": ", input{ type="text", name="monitor_bp_dir", value = val6},br(),

      p{ button_form(strings.send, "submit", "positive") },
      p{ button_form(strings.reset, "reset", "negative") },
   }

   return render_layout(res)
end


function render_remove(web, A)
   local res = {}
   local url = ""

   if A then
      A = A[1]
      url_ok = web:link("/delete/"..A.sysconfig_id)
      url_cancel = web:link("/list")
   end

   res[#res + 1] = p{
      strings.exclude_quest.." "..strings.sysconfig.." "..A.version.."?",
      p{ button_link(strings.yes, web:link(url_ok)) },
      p{ button_link(strings.cancel, web:link(url_cancel)) },
   }

   return render_layout(res)
end


orbit.htmlify(itvision, "render_.+")

return _M

