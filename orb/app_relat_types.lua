#!/usr/bin/env wsapi.cgi

-- includes & defs ------------------------------------------------------
require "Auth"
require "Model"
require "Resume"
require "View"
require "util"

module(Model.name, package.seeall,orbit.new)

local app_relat_types = Model.itvision:model "app_relat_types"


-- models ------------------------------------------------------------


function app_relat_types:select_app_relat_types(id)
   local clause = ""
   if id then
      clause = "id = "..id
   end
   return self:find_all(clause)
end

-- controllers ------------------------------------------------------------

function list(web)
   local auth = Auth.check(web)
   if not auth then return Auth.redirect(web) end

   local A = app_relat_types:select_app_relat_types()
   return render_list(web, A)
end
ITvision:dispatch_get(list, "/", "/list")


function show(web, id)
   local auth = Auth.check(web)
   if not auth then return Auth.redirect(web) end

   local A = app_relat_types:select_app_relat_types(id)
   return render_show(web, A)
end ITvision:dispatch_get(show, "/show/(%d+)")


function edit(web, id)
   local auth = Auth.check(web)
   if not auth then return Auth.redirect(web) end

   local A = app_relat_types:select_app_relat_types(id)
   return render_add(web, A)
end
ITvision:dispatch_get(edit, "/edit/(%d+)")


function update(web, id)
   local auth = Auth.check(web)
   if not auth then return Auth.redirect(web) end

   local A = {}
   if id then
      local tables = "itvision_app_relat_types"
      local clause = "id = "..id
      A.name  = web.input.name
      A.type = web.input.type

      Model.update (tables, A, clause) 
      Glpi.log_event(id, "app_relation", auth.user_name, 19, web.input.name)
   end

   return web:redirect(web:link("/list"))
end
ITvision:dispatch_post(update, "/update/(%d+)")


function add(web)
   local auth = Auth.check(web)
   if not auth then return Auth.redirect(web) end

   return render_add(web)
end
ITvision:dispatch_get(add, "/add")


function insert(web)
   local auth = Auth.check(web)
   if not auth then return Auth.redirect(web) end

   app_relat_types:new()
   app_relat_types.name = web.input.name
   app_relat_types.type = web.input.type
   app_relat_types:save()

   Glpi.log_event(nil, "app_relation", auth.user_name, 17, web.input.name)

   return web:redirect(web:link("/list"))
end
ITvision:dispatch_post(insert, "/insert")


function remove(web, id)
   local auth = Auth.check(web)
   if not auth then return Auth.redirect(web) end

   local A = app_relat_types:select_app_relat_types(id)

   return render_remove(web, A)
end
ITvision:dispatch_get(remove, "/remove/(%d+)")


function delete(web, id)
   local auth = Auth.check(web)
   if not auth then return Auth.redirect(web) end
   A = app_relat_types:select_app_relat_types(id)

   Glpi.log_event(id, "app_relation", auth.user_name, 18, A[1].name)

   if id then
      local clause = "id = "..id
      local tables = "itvision_app_relat_types"
      Model.delete (tables, clause) 
   end


   return web:redirect(web:link("/list"))
end
ITvision:dispatch_get(delete, "/delete/(%d+)")


ITvision:dispatch_static("/css/%.css", "/script/%.js")


-- views ------------------------------------------------------------

function render_list(web, A)
   local rows = {}
   local res = {}
   local permission, auth = Auth.check_permission(web, "app_relat_type")
   
   for i, v in ipairs(A) do
      local img_blk = img{src="/pics/blank.png",  height="20px"}
      local img_edit, img_remove = img_blk, img_blk
      if permission == "w" then
         --button_remove = button_link(strings.remove, web:link("/remove/"..v.id), "negative")
         --button_edit = button_link(strings.edit, web:link("/edit/"..v.id))

         url_edit = web:link("/edit/"..v.id)
         url_remove = web:link("/remove/"..v.id)
         img_edit = a{ href=url_edit, title=strings.edit, img{src="/pics/pencil.png", height="20px"}}
         img_remove = a{ href=url_remove, title=strings.remove, img{src="/pics/trash.png",  height="20px"}}
      end
      rows[#rows + 1] = tr{ class='tab_bg_1',
         td{ v.name },
         td{ strings[v.type] },
         td{ img_edit },
         td{ img_remove },
      }
   end

   res[#res + 1]  = render_resume(web)
   web.prefix = "/orb/app_relat_types"
   if permission == "w" then
      res[#res + 1]  = render_content_header(auth, "Tipo de Relacionamento", web:link("/add"), web:link("/list"))
   else
      res[#res + 1]  = render_content_header(auth, "Tipo de Relacionamento", nil, web:link("/list"))
   end

   res[#res + 1]  = H("table") { border="0", class="tab_cadrehov",
      thead{ 
         tr{ class="tab_bg_2",
             th{ strings.name }, 
             th{ strings.type }, 
             th{ "" },
             th{ "" },
         }
      },
      tbody{
         rows
      }
   }

   return render_layout(res)
end


-- Esta funcao de render_show() estah desativada por parece inutil!
-- ela era acessada pelo link que agora estah comentado em render_add()
function render_show(web, A)
   A = A[1]
   local res = {}
   local auth = Auth.check(web)

--[[
   res[#res + 1] = p{ button_link(strings.add, web:link("/add")) }
   res[#res + 1] = p{ button_link(strings.remove, web:link("/remove/"..A.id)) }
   res[#res + 1] = p{ button_link(strings.edit, web:link("/edit/"..A.id)) }
   res[#res + 1] = p{ button_link(strings.list, web:link("/list")) }
   res[#res + 1] = p{ br(), br() }
]]

   res[#res+1] = render_resume(web)

   if A then
      web.prefix = "/orb/app_relat_types"
      render_content_header(auth, "Tipo de Relacionamento", web:link("/add"), web:link("/list"))
      res[#res + 1] = { H("table") { border="0", class="tab_cadrehov",
         tbody{
            tr{ th{ strings.name }, td{ A.name } },
            tr{ th{ strings.type }, td{ A.type } },
         }
      } }
   else
      web.prefix = "/orb/app_relat_types"
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
   local permission = Auth.check_permission(web, "app_relat_type", true)

   if edit then
      edit = edit[1]
      val1 = edit.name
      val2 = edit.type
      url = "/update/"..edit.id
   else
      val2 = "logical"
      url = "/insert"
   end

   -- LISTA DE OPERACOES 
   res[#res + 1] = p{ button_link(strings.list, web:link("/list")) }
   res[#res + 1] = p{ br(), br() }

   res[#res + 1] = form{
      name = "input",
      method = "post",
      action = web:link(url),

      strings.name..": ", input{ type="text", name="name", value = val1 },br(), 
      strings.type..": ", select_physical_logical("type", val2), br(),

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
      url_ok = web:link("/delete/"..A.id)
      url_cancel = web:link("/list")
   end

   res[#res + 1] = p{
      --"Voce tem certeza que deseja excluir o usuario "..A.name.."?",
      strings.exclude_quest.." "..strings.app_relat_type.." "..A.name.."?",
      p{ button_link(strings.yes, web:link(url_ok)) },
      p{ button_link(strings.cancel, web:link(url_cancel)) },
   }

   return render_layout(res)
end


orbit.htmlify(ITvision, "render_.+")

return _M


