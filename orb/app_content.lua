#!/usr/bin/env wsapi.cgi

-- includes & defs ------------------------------------------------------
require "util"
require "monitor_util"
require "View"
require "orbit"
require "Model"
module(Model.name, package.seeall,orbit.new)

local app = Model.itvision:model "app"
local app_object = Model.itvision:model "app_object"
local app_relat = Model.itvision:model "app_relat"
local app_relat_type = Model.itvision:model "app_relat_type"
local objects = Model.nagios:model "objects"


-- models ------------------------------------------------------------

function app:select_apps(id)
   local clause = ""
   if id then
      clause = "id = "..id
   end
   return self:find_all(clause)
end


function app_object:select_app_objects(id)
   local clause = ""
   if id then
      clause = "app_id = "..id
   end
   return self:find_all(clause)
end


function app_relat:select_app_relat(id, from, to)
   local clause = ""
   if id then
      clause = "app_id = "..id
   end
   if from and to then
      if clause ~= "" then clause = clause.." and " end
      clause = clause.." from_object_id = "..from.." and to_object_id = "..to
   end
   return self:find_all(clause)
end


function app_relat:delete_app_relat(id, from, to)
   local clause = ""
   if id and from and to then
      clause = " app_id = "..id.." and from_object_id = "..from.." and to_object_id = "..to
   end
   --self:find_all(clause)
   --self:delete()
   Model.delete("itvision_app_relat", clause)
end


function app_relat_type:select_app_relat_type(id)
   local clause = ""
   if id then
      clause = "app_relat_type_id = "..id
   end
   return self:find_all(clause)
end


function objects:select_objects(id)
   local clause = ""
   if id then
      clause = "object_id = "..id
   else
      clause = "objecttype_id < 3"
   end
   return self:find_all(clause)
end


-- controllers ------------------------------------------------------------

function list(web, id)
   local APPS = app:select_apps()
   if type(tonumber(id)) ~= "number" then
      if ( id == "/" or id == "/list" ) and APPS[1] ~= nil then id = APPS[1].id else id = nil end
   end

   local APPOBJ = Model.select_app_app_objects(id)
   local AR = Model.select_app_relat_object(id)
   id = id or ""

   return render_list(web, APPOBJ, APPS, AR, id)
end
ITvision:dispatch_get(list, "/", "/list", "/list/(%d+)")


function show(web, id)
   return render_show(web, id)
end 
ITvision:dispatch_get(show, "/show/(%d+)")


function add(web, id, msg)
   local APPS = app:select_apps()
   if id == "/" then
      if APPS[1] then id = APPS[1].app_id else id = nil end
   end

   local HST = Model.select_service_object(nil, nil, nil, nil, id, true)
   local SVC = Model.select_service_object(nil, nil, nil, nil, id, nil)
   local APP = Model.select_service_object(nil, nil, nil, true)
   --local APP = Model.select_app_service_object(nil, nil, nil, id) --TODO: 1
   local APPOBJ = Model.select_app_app_objects(id)
   local AR = Model.select_app_relat_object(id)
   local RT = app_relat_type:select_app_relat_type()

   return render_add(web, HST, SVC, APP, APPOBJ, APPS, AR, RT, id, msg)
end
ITvision:dispatch_get(add, "/add/(%d+)")
ITvision:dispatch_get(add, "/add/(%d+):(.+)")



-- TODO: problema na inclusão de multiplos itens
function insert_obj(web)
   app_object:new()
--local r = ""
   if type(web.input.item) == "table" then
      for i, v in ipairs(web.input.item) do
         app_object.app_id = web.input.app_id
         app_object.type = web.input.type
         app_object.instance_id = Model.db.instance_id
         app_object.object_id = v
         app_object:save()
--r = r.."|"..v
      end
   else
      app_object.app_id = web.input.app_id
      app_object.type = web.input.type
      app_object.instance_id = Model.db.instance_id
      app_object.object_id = web.input.item
      app_object:save()
   end

   return web:redirect(web:link("/add/"..app_object.app_id))
end
ITvision:dispatch_post(insert_obj, "/insert_obj")


function insert_relat(web)
   local msg = ""
   local from, to

   app_relat:new()
   app_relat.app_id = web.input.app_id
   app_relat.from_object_id = web.input.from
   app_relat.to_object_id = web.input.to
   app_relat.instance_id = Model.db.instance_id
   app_relat.app_relat_type_id = web.input.relat

   if not ( web.input.from and web.input.to and web.input.relat ) then
      msg = ":"..error_message(7)
      return web:redirect(web:link("/add/"..app_relat.app_id)..msg)
   end

   local AR = Model.select_app_relat_object(web.input.app_id, web.input.from, web.input.to)
   if AR[1] then
      local v = AR[1]
      from = make_obj_name(v.from_name1, v.from_name2)
      to   = make_obj_name(v.to_name1,   v.to_name2)
      msg = ":"..error_message(8).." "..from.." -> "..to
   else
      app_relat:save()
   end

   return web:redirect(web:link("/add/"..app_relat.app_id)..msg)
end
ITvision:dispatch_post(insert_relat, "/insert_relat")


function remove_obj(web, app_id, obj_id)
   local A = app:select_apps(app_id)
   local O = objects:select_objects(obj_id)
   return render_remove_obj(web, A, O)
end
ITvision:dispatch_get(remove_obj, "/remove_obj/(%d+):(%d+)")


function delete_obj(web, app_id, obj_id)
   if app_id and obj_id then
      local clause = "app_id = "..app_id.." and object_id = "..obj_id
      local tables = "itvision_app_object"
      Model.delete (tables, clause) 
   end

   web.prefix = "/orb/app_content"
   return web:redirect(web:link("/list/"..app_id))
end
ITvision:dispatch_get(delete_obj, "/delete_obj/(%d+):(%d+)")


function remove_relat(web, app_id, from, to)
   local A = app_relat:select_app_relat(app_id, from, to)
   local AR = Model.select_app_relat_object(id, from, to)
   return render_remove_relat(web, A, AR)
end
ITvision:dispatch_get(remove_relat, "/remove_relat/(%d+):(%d+):(%d+)")


function delete_relat(web, app_id, from, to)
   app_relat:delete_app_relat(app_id, from, to)
   return web:redirect(web:link("/list/"..app_id))
end
ITvision:dispatch_get(delete_relat, "/delete_relat/(%d+):(%d+):(%d+)")


ITvision:dispatch_static("/css/%.css", "/script/%.js")


-- views ------------------------------------------------------------

function make_app_object_table(web, A)
-- TODO: 2 (acho este TODO deve ficar aqui!)
   local row = {}

   for i, v in ipairs(A) do
      local obj = make_obj_name(v.name1, v.name2)

      --web.prefix = "/orb/app_content"

      row[#row + 1] = { 
         obj,
         name_hst_svc_app(v.obj_type),
         button_link(strings.remove, web:link("/remove_obj/"..v.app_id..":"..v.object_id), "negative"),
      }
   end

   return row
end


function make_app_relat_table(web, AR)
   local row = {}

   for i, v in ipairs(AR) do
      local from = make_obj_name(v.from_name1, v.from_name2)
      local to   = make_obj_name(v.to_name1, v.to_name2)

      if v.connection_type == "physical" then contype = strings.physical else contype = strings.logical end

      row[#row+1] = {
         from,
         v.rtype_name,
         to,
         button_link(strings.remove, web:link("/remove_relat/"..v.app_id..":"..v.from_object_id
             ..":"..v.to_object_id), "negative"),
      }
   end

   return row
end


function render_list(web, APPOBJ, APPS, AR, app_id)
   local res = {}
   local header

   -----------------------------------------------------------------------
   -- Objetos da aplicacao
   -----------------------------------------------------------------------
   res[#res+1] = render_content_header(strings.application, web:link("/add/"..app_id), web:link("/list"))
   res[#res+1] = render_bar( render_selector_bar(web, APPS, app_id, "/list") )
   res[#res+1] = render_content_header(strings.app_object)
   header = { strings.object.." ("..strings.service.."@"..strings.host..")", strings.type, "." }
   res[#res+1] = render_table(make_app_object_table(web, APPOBJ), header)

   -----------------------------------------------------------------------
   -- Relacionamentos da aplicacao
   -----------------------------------------------------------------------
   res[#res+1] = render_content_header(strings.app_relat)
   header =  { strings.origin.." ("..strings.service.."@"..strings.host..")", strings.type, 
                     strings.destiny.." ("..strings.service.."@"..strings.host..")", "." }
   res[#res+1] = render_table(make_app_relat_table(web, AR), header)

   return render_layout(res)
end


function render_show(web, A, app_id)
end


function render_add(web, HST, SVC, APP, APPOBJ, APPS, AR, RT, app_id, msg)
   local res = {}
   local url_app = "/insert_obj"
   local url_relat = "/insert_relat"
   local list_size = 2
   local header = ""

   res[#res+1] = render_content_header(strings.application, web:link("/add/"..app_id), web:link("/list"))
   res[#res+1] = render_bar( render_selector_bar(web, APPS, app_id, "/add") )

   -----------------------------------------------------------------------
   -- Objetos da Aplicacao
   -----------------------------------------------------------------------
   res[#res+1] = render_content_header(strings.app_object)
   header = { strings.object.." ("..strings.service.."@"..strings.host..")", strings.type, "." }
   res[#res+1] = render_table(make_app_object_table(web, APPOBJ), header)
   res[#res+1] = br()


   -- LISTA DE HOSTS PARA SEREM INCLUIDOS ---------------------------------
   local opt_hst = {}
   for i,v in ipairs(HST) do
     opt_hst[#opt_hst+1] = option{ value=v.object_id, v.name1 }
   end
   local hst = { render_form(web:link(url_app), web:link("/add/"..app_id),
               { H("select") { size=list_size, style="width: 100%;", name="item", opt_hst }, br(),
                 input{ type="hidden", name="app_id", value=app_id },
                 input{ type="hidden", name="type", value="hst" } } ) }
   

   -- LISTA DE SERVICES PARA SEREM INCLUIDOS ---------------------------------
   local opt_svc = {}
   for i,v in ipairs(SVC) do
      opt_svc[#opt_svc+1] = option{ value=v.object_id, make_obj_name(v.name1, v.name2) }
   end  
   local svc = { render_form(web:link(url_app), web:link("/add/"..app_id),
               { H("select") { size=list_size, style="width: 100%;", name="item", opt_svc }, br(),
                 input{ type="hidden", name="app_id", value=app_id },
                 input{ type="hidden", name="type", value="svc" } } ) }


   -- LISTA DE APPLIC PARA SEREM INCLUIDOS ---------------------------------
   local opt_app = {}
   for i,v in ipairs(APP) do
      opt_app[#opt_app+1] = option{ value=v.object_id, v.name2 }
   end  
   local app = { render_form(web:link(url_app), web:link("/add/"..app_id),
               { H("select") { size=list_size, style="width: 100%;", name="item", opt_app }, br(),
                 input{ type="hidden", name="app_id", value=app_id },
                 input{ type="hidden", name="type", value="app" } } ) }


   header = { strings.host, strings.service, strings.application }
   res[#res+1] = render_table({ {hst, svc, app} }, header)

   -----------------------------------------------------------------------
   -- Relacionamentos da aplicacao
   -----------------------------------------------------------------------
   res[#res+1] = br()
   res[#res+1] = render_content_header(strings.relation)
   header =  { strings.origin, strings.type, strings.destiny, "." }
   res[#res+1] = render_table(make_app_relat_table(web, AR), header)

   -- LISTA APP ORIGEM DOS RELACIONAMENTO ---------------------------------
   local opt_from = {}
   if APPOBJ[1] then
      for i,v in ipairs(APPOBJ) do
         ic = make_obj_name(v.name1, v.name2)
         opt_from[#opt_from+1] = option{ value=v.object_id, ic }
      end
   end
   --local from = H("select") { multiple="multiple", size=list_size, name="from", opt_from, }
   local from = H("select") { size=list_size, name="from", opt_from }

   -- LISTA TIPOS DE RELACIONAMENTO  ---------------------------------
   local opt_rel = {}
   for i,v in ipairs(RT) do
     opt_rel[#opt_rel+1] = option{ value=v.id, v.name }
   end
   local rel = H("select") { size=list_size, name="relat", opt_rel }

   -- LISTA APP DESTINO DOS RELACIONAMENTO ---------------------------------
   local opt_to = {}
   if APPOBJ[1] then
      for i,v in ipairs(APPOBJ) do
         ic = make_obj_name(v.name1, v.name2)
         opt_to[#opt_to+1] = option{ value=v.object_id, ic }
      end
   end
   local to = H("select") { size=list_size, name="to", opt_to }

   -- INFORMACAO OCULTA PARA A INCLUSAO DO RELACIONAMENTO  --------------------
   aid = input{ type="hidden", name="app_id", value=app_id }

   local t = { { from, rel, {to, aid} } }

   res[#res+1] = br()
   if msg ~= "/" and msg ~= "/list" and msg ~= "/list/" then res[#res+1] = p{ msg } end
   res[#res+1] = render_form_bar( render_table(t, header) , strings.add, web:link(url_relat), web:link("/add/"..app_id))

   return render_layout(res)
end


function render_remove_obj(web, A, O)
   local res = {}
   local url = ""
   local obj

   if A then
      A = A[1]
      if O then
         O = O[1]
         obj = make_obj_name(O.name1, O.name2)
      else
         obj = "noname"
      end
      url_ok = "/delete_obj/"..A.id..":"..O.object_id
      url_cancel = "/list"
   end

   res[#res + 1] = p{
      strings.exclude_quest.." o "..strings.host.."/"..strings.service.." "..obj.." da "..
         strings.application.." "..A.name.."?",
      p{ button_link(strings.yes, web:link("/delete_obj/"..A.id..":"..O.object_id)) },
      p{ button_link(strings.cancel, web:link("/list/"..A.id)) },
   }

   return render_layout(res)
end


function render_remove_relat(web, A, AR)
   local res = {}
   local url = ""
   local obj1, obj2

   if A then
      A = A[1]
      if AR then
         AR = AR[1]
         obj1 = make_obj_name(AR.from_name1, AR.from_name2)
         obj2 = make_obj_name(AR.to_name1,   AR.to_name2)
      else
         obj1 = "noname"
         obj2 = "noname"
      end
      url_ok = "/delete_relat/"..A.app_id..":"..AR.from_object_id..":"..AR.to_object_id
      url_cancel = "/list"
   end

   res[#res + 1] = strings.exclude_quest.." "..strings.relation.." \""..obj1.." -> "..obj2.."\" "
         ..strings.ofthe.." "..strings.application.." \""..A.name.."\"?"
   res[#res + 1] = button_link(strings.yes,
         web:link("/delete_relat/"..A.app_id..":"..AR.from_object_id..":"..AR.to_object_id))
   res[#res + 1] = button_link(strings.cancel, web:link("/list/"..A.app_id))

   return render_layout(res)
end



orbit.htmlify(ITvision, "render_.+")

return _M

