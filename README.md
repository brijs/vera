# vera

Collection of custom lua scripts & modules that I used for customizing vera Home control system (http://getvera.com/). I don't expect these modules to be used as-is, but it can be used as a reference to do something similar. The example code below can be run in the `Develop apps` section of your Vera portal, or as part of one or more `Scenes` in Vera. You ll need to upload the lua files (Portal > `Luup files`) in this project prior to using these modules.

### Modules
3 modules so far:
 - **L_BrijRouter**   - make changes to your wifi router 
 - **L_BrijSecurity** - control your home security system.
 - **L_BrijNotifyVA** - sends email, photos, plays audio on speakers when certain events occur.
 
#### L_BrijRouter
This module communicates with your home wifi router & provides funtionality to enable / disable port forwarding for a previously added service or device. (This implementation also assumes that the intended service/device to be controlled is the first device in the list of devices configured on your router. The IP address & urls used in the implementation are specific to Arris Touchstone  wireless gateway model TG862G / TG852G)

The following 2 methods are defined:
- `enableFoscamPortFwd`
- `disableFoscamPortFwd`

Example code(to disable NAT port forwarding to your IP camera on your home network):
```lua
require "L_BrijRouter" 
L_BrijRouter.disableFoscamPortFwd() -- disable port forwarding 
-- L_BrijRouter.enableFoscamPortFwd()  -- enable port forwarding 
```

#### L_BrijSecurity
This module implements helper methods to control your home security system via Vera connected to it via the **AD2USB** device. The following public methods are defined:
- `bypassKitchenDoor`
- `bypassBedroomDoor`
- `bypassKitchenBedDoor`
- `sendStar`

Note that the "zone" IDs below will likely need to be updated (for Kitchen, 	Bed etc). Also, the Security System PIN needs to be set prior to calling these methods.
	 
Example code (to bypass a certain door while your home security system is still armed):	
```lua
-- startup code
luup.log("SRS: setting 15 second delay then executing StorePinCode")
function callonme()
  local SECURITY_DEVICE_ID = 100
  luup.log("SRS: delay over, executing StorePinCode")
  luup.call_action("urn:micasaverde-com:serviceId:VistaAlarmPanel1", "StorePinCode", { PINCode="1234"}, SECURITY_DEVICE_ID)
end
luup.call_delay('callonme',15)

-- And the following will work in Scenes now
require L_BrijSecurity
L_BrijSecurity.bypassKitchenDoor()
```

#### L_BrijNotifyVA
This module implements functionality to notify users if a device status changes. Notification is sent via email (can include pictures from an IP camera), and optionally also announced on Sonos Home Speakers. For email notifications, the Vera Alerts plugin is used.
Methods:
- `notifyOnChange("some text", device_id)`
- `notifyEmail("subject", "body", cam_device_id)`

Example code:
```lua
require "L_BrijNotifyVA" 
local BASEMENT_DOOR_DEVICE_ID = 100
L_BrijNotifyVA.notifyOnChange("Basement Back Door", BASEMENT_DOOR_DEVICE_ID) 
```

