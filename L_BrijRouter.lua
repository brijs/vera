module ("L_BrijRouter", package.seeall)

-- [[
    This module provides funtionality to enable / disable port forwarding
    for a previously added service on your home router. (This implementation
    also assumes that the intended service/device to be controlled is the 
    first device in the list. The urls below are specific to Arris Touchstone
    wireless gateway model TG862G / TG852G)

    The following 2 methods are defined:
     - enableFoscamPortFwd
     - disableFoscamPortFwd
-- ]]

h = require "socket.http"

local HOME_ROUTER_IP = "http://10.0.0.1"

function updateFoscamPortFwd(enable_foscam_port_fwd)
	-- GET router's home page
	--  Force logout, and extract random idseed returned by router
	r, s, c = h.request(HOME_ROUTER_IP .. "/home_loggedout.php?&out=1")
	idseed = string.match(r, "name=\"idseed\" value=\"([^\"]+)\"")
	if (s ~= 200 or idseed == nil) then
		luup.log ("Router home access failed.")
		return false
	end
	-- POST; login into router & extract idseed returned by router
	r, s, c = h.request(HOME_ROUTER_IP .. "/home_loggedout.php", "idseed=" .. idseed .. "&username=admin&password=password")
	idseed = string.match(r, "name=\"idseed\" value=\"([^\"]+)\"")
	if (s ~= 200 or idseed == nil) then
		luup.log ("Router login failed.")
		return false
	end
	-- Enable or disable port forwarding
	r, s, c = h.request(HOME_ROUTER_IP .. "/port_forwarding.php", "idseed=" .. idseed .. "&portforward_active=" .. enable_foscam_port_fwd .. "&portforward_index=0")
	if (s ~= 200) then
		luup.log ("Router update failed.")
		return false
	end
end


-- public
function enableFoscamPortFwd()
	luup.call_delay("updateFoscamPortFwd", 1, "checked")
end

function disableFoscamPortFwd()
	luup.call_delay("updateFoscamPortFwd", 1, "unchecked")
end