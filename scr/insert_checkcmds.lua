require "Model"


function insert_checkcmd_params(file)
   print (file)
   dofile(file)
   for i, v in pairs(cmds) do
      print(i)
      q = Model.query("nagios_objects", "name1 = '"..i.."'")
      if q[1] then id = q[1].object_id else id='NULL' end

      cmd = { cmd_object_id = id, command = v.command, label = v.label }
   
      Model.insert("itvision_checkcmds", cmd)
      r = Model.query("itvision_checkcmds", "cmd_object_id = "..id)

      print("CHEKCMDS: ", r[1].id, cmd.cmd_object_id, cmd.command, cmd.label )

      for j, w in pairs(v.args) do
         w.checkcmds_id = r[1].id
         print ("PARAMS: ", w.variable, w.description, w.checkcmds_id, w.default_value )
         Model.insert("itvision_checkcmd_default_params", w)
      end

      print()
   end
end


insert_checkcmd_params(arg[1])


