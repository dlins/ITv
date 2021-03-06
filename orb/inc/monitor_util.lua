require "Model"
require "App"
require "Checkcmds"
require "config"
require "util"

local cfg_dir = config.monitor.dir.."/etc/itvision/"


----------------------------- MAKE NAMES ----------------------------------

function make_obj_name(host, service)
   local name = ""

   if string.find(host,config.monitor.check_app) == nil then 
       name = host
   end
   --if service ~= config.monitor.check_host then
   if service then
      if name ~= "" then
         --name = " @ "..name
         name = name.." @ "
      else
         name = name.." #"
      end
      --name = service..name
      name = name..service
   end

   return name
end


----------------------------- CONFIG FILES ----------------------------------
--[[
          command_name        = PING
          command_line        = chck_ping
name1   = host_name           = Euler
name2   = service_description = My_PING
c_alias = alias               = euler
          check_command       = PING!400.0,20%!999.0,70%
p_id    = address             = 147.65.1.3


]]



function insert_host_cfg_file (hostname, alias, ip)
   if not  ( hostname and alias and ip ) then return false end
   -- hostname passa aqui a ser uma composicao do proprio hostname com o ip a ser monitorado
   local content, cmd
   local filename = config.monitor.dir.."/hosts/"..hostname..".cfg"

   local text = [[
define host{
        use]].."\t\t"..[[generic-host
        host_name]].."\t"..hostname..[[ 
        alias]].."\t\t"..alias..[[ 
        address]].."\t\t"..ip..[[ 
        } 
]]

   text_file_writer (filename, text)
   cmd = os.reset_monitor()

   return cmd
end



-- o parametro enable deve receber nulo ou 1 para abilitar e 0 para desligar.
function insert_service_cfg_file (hostname, service_desc, check_cmd, check_args, enable)
   local content, cmd, filename

   if enable == 0 then enable = false else enable = true end

   if check_args == nil then
      return false
   end

   filename = config.monitor.dir.."/services/"..hostname.."-"..service_desc..".cfg"

   local text = [[
define service{
        use]].."\t\t\t"..[[generic-service
        host_name]].."\t\t"..hostname..[[ 
        service_description]].."\t"..service_desc..[[ 
        check_command]].."\t\t"..check_cmd..check_args..[[ 
]]
   if enable then
      text = text..[[ 
        } 
]]
   else
      text = text..[[
        active_checks_enabled	0 
        }
]]
   end

   text_file_writer (filename, text)
   cmd = os.reset_monitor()
   return cmd
end



function remove_hst_cfg_file (hostname)
   local filename = config.monitor.dir.."/hosts/"..hostname..".cfg"
   remove_file(filename)
end



function remove_svc_cfg_file (hostname, service_desc)
   local filename = config.monitor.dir.."/services/"..hostname.."-"..service_desc..".cfg"
   remove_file(filename)
   local filename = config.monitor.dir.."/services/"..hostname..".cfg" -- arquivo de config do nagiosgrapher
   remove_file(filename)
end



function remove_contact_cfg_file (name)
   local filename = config.monitor.dir.."/contacts/"..name..".cfg"
   remove_file(filename)
end



function insert_contact_cfg_file (name, full_name, email, apps)
   -- name é o app_id que vem a ser o identificador univarsal da app
   local app_list = ""
   local sep, cmd
   local filename = config.monitor.dir.."/contacts/"..name..".cfg"

   for _,v in ipairs(apps) do
      if app_list == "" then 
         sep = ""; 
      else 
         sep = ","
      end

      app_list = app_list..sep..v.app_id
   end

   local text = [[
define contact{
        contact_name]].."\t\t\t"..name..[[ 
        alias]].."\t\t\t\t"..full_name..[[ 
        email]].."\t\t\t\t"..email..[[ 
        contact_groups]].."\t\t\t"..app_list..[[

        service_notification_period	24x7
        host_notification_period	24x7
        service_notification_options	w,u,c,r
        host_notification_options	n
        host_notification_commands	notify-host-by-email
        #service_notification_commands	notify-service-by-email
        service_notification_commands	notify-application-by-email
        }
]]

   text_file_writer (filename, text)
   cmd = os.reset_monitor()

   return true, cmd
end



--[[
TODO: 
   Falta criar grupos de contatos e poder remover contados dos grupos
   Falta ainda associar service tipo BP aos contatos ou aos grupos de contatos
]]

-- Ainda nao está funcionando
function delete_cfg_file(filename, conf_type)
   filename = string.gsub(tostring(filename)," ","_")
   local cmd
   cmd = os.capture ("rm -f "..config.monitor.dir.."/"..conf_type.."/"..filename..".cfg", 1)
   cmd = os.reset_monitor()
end



--[[ ESTE PROCEDIMENTO ESTAh SENDO SUBSTITUIDO PELO METODO ABAIXO CHAMADO 'make_app_config_scr()'
  Cria arquivo de conf do business process para uma unica aplicacao. 

  display 0 - significa usar o template de service "generic-bp-detail-service" que possiu 
              os parametros de configuracao active_checks_enabled=0 e passive_checks_enabled=0
              para desligar os alertas de um servico no nagios

  display 1 - sinifica usar o template de service "generic-bp-service" que corresponde a
              um servico ativo.

  PS: na definicao do business process, "display"quer dizer outra coisa (visibilidade) 
      Veja em /usr/local/monitorbp/README
]]
function make_app_config(app, objs, flag)
   --app = app[1]
   local s = ""

   if app.type == "and" then op = " & " else op = " | " end

   for i, v  in ipairs(objs) do
      if s ~= "" then s = s..op end

      if v.obj_type == "app" then
         s = s..v.name2 
      else
         s = s..v.name1..";"..v.name2 
      end
      
   end

   --ref = string.gsub(string.gsub(app.name,"(%p+)","_")," ","_")
   ref = app.id

   s = "\n#\n#  "..app.name.."\n#\n"..ref.." = "..s.."\n"
   s = s.."display "..flag..";"..ref..";"..ref.."\n\n"

   return s
end


--[[
  Este é o novo metodo para criacao do arquivo nagios de configuracao para as aplicacoes.
  Ele se usa da nova devinicao do comando BUSPROC_SERVICE que eh definido no script lua
  itv/scr/check_app.lua e eh chamado pelo seu script shell associado.
]]
function make_app_config_scr(app)

   local text = [[
define service{
	use]].."\t\t\t"..[[BUSPROC_SERVICE
	service_description]].."\t"..app.id..[[ 
	check_command]].."\t\t"..[[BUSPROC_STATUS!]]..app.id..[[  
	contact_groups]].."\t\t"..app.id..[[

	active_checks_enabled]].."\t"..app.is_active..[[ 
	}  
 
]]

   return text

end

--[[
  Cria aquivo de conf para todas a aplicacoes
]]
function make_all_apps_config(apps)
   local s = ""
   local file_name = config.monitor.dir.."/apps/apps.cfg"

   for i, v  in ipairs(apps) do
      --local objs = App.select_app_app_objects(v.id)
      --if objs[1] then s = s .. make_app_config(v, objs, v.is_active) end
      --if objs[1] then s = s .. make_app_config_scr(v, objs, v.is_active) end

      --if tonumber(v.is_active) == 1 then
         s = s .. make_app_config_scr(v)
      --end
   end

   text_file_writer(file_name, s)
   --insert_bp_cfg_file()
   insert_contactgroup_cfg_file(apps)

   --os.sleep(1)
   os.reset_monitor()
end



--[[
  Cria arquivo de configuracao do nagios a partir do arquivo de configuracao do BP
  criado na funcao "activate_all_apps()" acima usando o script perl do proprio BP.
]]
function insert_bp_cfg_file()
   local cmd = config.monitor.bp_dir.."/bin/bp_cfg2service_cfg.pl"
   cmd = cmd .. " -f "..config.monitor.bp_dir.."/etc/nagios-bp.conf"
   cmd = cmd .. " -o "..config.monitor.dir.."/apps/apps.cfg"

   os.capture(cmd)
end



function insert_contactgroup_cfg_file (apps)
   if not apps then return false end
   local filename = config.monitor.dir.."/apps/contactgroups.cfg"
   local text = ""

   for _,v in ipairs(apps) do
      text = text ..[[
define contactgroup{
        contactgroup_name]].."\t"..v.id..[[ 
        alias]].."\t\t\t"..v.name..[[ 
        }


]]
   end

   text_file_writer (filename, text)
   cmd = os.reset_monitor()

   return true, cmd
end



