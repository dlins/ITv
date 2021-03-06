module("Model", package.seeall)

require "orbit"
require "config"

name = config.app_name
db   = config.database

local make_model = function( model )
	require("luasql." .. db.driver)
	local env = luasql[db.driver]()

	m = orbit.new()
	m.mapper.conn = env:connect(db.dbname, db.dbuser, db.dbpass)
	m.mapper.driver = db.driver
	m.mapper.table_prefix = model..'_'
	return m
end

itvision = make_model ( 'itvision' )
nagios   = make_model ( 'nagios' )
glpi     = make_model ( 'glpi' )

require "Access"

