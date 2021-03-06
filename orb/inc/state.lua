require "monitor_inc"


color = {
	blue =   "#0066ff",	-- blue color used by peding hosts and services
	green =  "#00ff33",	-- green color used by up hosts and ok services
	yellow = "#fff833",	-- yellow color used by unreachable hosts and unknown services
	orange = "#ff6600",	-- orange color used by warning services
	red =    "#d90000",	-- red color used by down hosts and critical services
	gray =   "#999999",	-- gray color used by all non problem status
	white =  "#ffffff",	-- white color used by "none" state
	purple = "#9900CC",	-- unused

        lightblue = "#AFEEEE",
	lightgreen = nil,
	lightyellow = "#F5F5DC",
	lightorange = "#FFA500",
	lightred = "#FA8072",
	lightred = "#FFE4E1",
	lightgray = "#D3D3D3",
	lightpurple = "#BA55D3",
}


applic_alert = {   
	[APPLIC_NONE]     = { name= "",			status = APPLIC_NONE,		color = color.white,	lightcolor = color.white,	color_name = "white" },
	[APPLIC_OK]       = { name= "NORMAL",		status = APPLIC_OK,		color = color.green,	lightcolor = color.lightgreen,	color_name = "green" },
	[APPLIC_WARNING]  = { name= "ANORMAL",	 	status = APPLIC_WARNING,	color = color.yellow,	lightcolor = color.lightyellow,	color_name = "yellow" },
	[APPLIC_CRITICAL] = { name= "CRITICO", 		status = APPLIC_CRITICAL,	color = color.red,	lightcolor = color.lightred,	color_name = "red" },
	[APPLIC_UNKNOWN]  = { name= "INDETERMINADO",	status = APPLIC_UNKNOWN,	color = color.gray,	lightcolor = color.lightgray,	color_name = "gray" },
	[APPLIC_PENDING]  = { name= "PENDENTE",		status = APPLIC_PENDING,	color = color.blue,	lightcolor = color.lightblue,	color_name = "blue" },
	[APPLIC_DISABLE]  = { name= "DESLIGADO",	status = APPLIC_DISABLE,	color = color.orange,	lightcolor = color.lightorange,	color_name = "orange" }
}


host_alert = {   
	[HOST_NONE]        = { name= "",		status = HOST_NONE,		color = color.white,	color_name = "white" },
	[HOST_UP]          = { name= "NORMAL",		status = HOST_UP,		color = color.green,	color_name = "green" },
	[HOST_DOWN]        = { name= "CRITICO", 	status = HOST_DOWN,		color = color.red,	color_name = "red" },
	[HOST_UNREACHABLE] = { name= "INDETERMINADO",	status = HOST_UNREACHABLE,	color = color.gray,	color_name = "gray" },
	[HOST_PENDING]     = { name= "PENDENTE", 	status = HOST_PENDING,		color = color.blue,	color_name = "blue" },
	[HOST_DISABLE]     = { name= "DESLIGADO",	status = HOST_DISABLE,		color = color.orange,	color_name = "orange" }
}


service_alert = {
	[STATE_NONE]     = { name= "",			status = STATE_NONE,		color = color.white,	color_name = "white" },
	[STATE_OK]       = { name= "NORMAL",		status = STATE_OK,		color = color.green,	color_name = "green" },
	[STATE_WARNING]  = { name= "ANORMAL",	 	status = STATE_WARNING,		color = color.yellow,	color_name = "yellow" },
	[STATE_CRITICAL] = { name= "CRITICO", 		status = STATE_CRITICAL,	color = color.red,	color_name = "red" },
	[STATE_UNKNOWN]  = { name= "INDETERMINADO",	status = STATE_UNKNOWN,		color = color.gray,	color_name = "gray" },
	[STATE_PENDING]  = { name= "PENDENTE",		status = STATE_PENDING,		color = color.blue,	color_name = "blue" },
	[STATE_DISABLE]  = { name= "DESLIGADO",		status = STATE_DISABLE,		color = color.orange,	color_name = "orange" }
}

