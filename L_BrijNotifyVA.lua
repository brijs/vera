module ("L_BrijNotifyVA", package.seeall)

-- [[
    This module implements functionality to notify users if a device status 
    changes. Notification is sent via email (can include pictures from an IP
    camera), and optionally also announced on Sonos Home Speakers. For email 
    notifications, the Vera Alerts plugin is used.

    Methods:
     - notifyOnChange("some text", device_id)
     - notifyEmail("subject", "body", cam_device_id)
-- ]]


local VERA_DID          = 40 -- Vera Alerts Device ID
local SONOS_DID         = 27 -- Sonos Speakers Device ID
local VSWITCH_SONOS_DID = 41 -- Sonos Virtual Switch Device ID
-- local CAM_ID            = 3

-- private
function notify(doorName, status)
    local doorStatus = "closed"
    if (status == "1") then doorStatus = "opened" end
    local msg = doorName .. " " .. doorStatus

    -- send message as android alert
    luup.call_action("urn:richardgreen:serviceId:VeraAlert1", 
     "SendAlert", 
     {Message = msg,
     Recipients = "Vera-Alerts-BrijCell, Vera-Alerts-Cell2"}, VERA_DID)
     

    -- announce message on Sonos
    local SONOS_SID = "urn:micasaverde-com:serviceId:Sonos1"
    local VSWITCH_SONOS_SID = "urn:upnp-org:serviceId:SwitchPower1"
    local sonosEnabled, ts = luup.variable_get(VSWITCH_SONOS_SID, "Status", VSWITCH_SONOS_DID) or "0"
    if (sonosEnabled == "1") then
        luup.call_action(SONOS_SID, "Say",
                     {Text="Alert. " .. msg, Language="en",  Volume=55,
                     GroupZones="ALL"},
                     SONOS_DID)
    end
end


local function notifyEmail(subject, message, camDeviceID)
    local RECIPIENTS = "SMTP-Mail"
    local VERA_SID = "urn:richardgreen:serviceId:VeraAlert1"
    
    

    luup.call_action(VERA_SID, 
        "SendAlert", 
        {Message = subjectStr .. "{Choose(tripped, 0=Close, 1=Open, Other=Unknown)} Event occured on {DateTime(CurrentTime,%A %B %d, %Y at %H:%M)}. {Picture(3)}", 
        Recipients = "SMTP-Mail"}, VERA_DID)


end

local function statusChanged(prevTripped, currTripped)
    if (prevTripped == currTripped) then
        return false
    else
        return true
    end
end

-- public
function notifyOnChange(doorName, deviceID)
    -- constants
    local SS_SID = "urn:micasaverde-com:serviceId:SecuritySensor1"
    local SS_DID = tonumber(deviceID)
    local DOOR_NAME = doorName

    -- current states 
    -- 'armed' is already used at trigger level
    -- local armed = luup.variable_get(SS_SID, "Armed", SS_DID) or "0"
    local prevTripped, ts = luup.variable_get(SS_SID, "PrevTripped", SS_DID) or "0"
    local tripped,ts = luup.variable_get(SS_SID, "Tripped", SS_DID) or "0"
    -- update PrevTripped on device
    luup.variable_set(SS_SID, "PrevTripped", tripped, SS_DID)


    if (statusChanged(prevTripped, tripped)) then
        notify(DOOR_NAME, tripped)
    end
end



function notifyPictureAfterMinInterval(deviceId, minNotifyIntervalMinutes, subject)

    -- default values
    local SS_SID = "urn:micasaverde-com:serviceId:SecuritySensor1" -- Security Sensor Service ID
    local SS_DID = deviceId
    minNotifyIntervalMinutes = minNotifyIntervalMinutes or 0 -- default to 0, which means notify always
    subject = subject or "Motion detected"

    local VERA_SID = "urn:richardgreen:serviceId:VeraAlert1"

    
    local subjectStr = "{Subject=" .. subject .. "} "
    local  currTime = os.time()
    local lastNotifiedTime, ts = luup.variable_get (SS_SID, "LastNotifiedTime", SS_DID) or "0"

    if (os.difftime (currTime, tonumber (lastNotifiedTime)) >= (minNotifyIntervalMinutes*60)) then
        luup.call_action(VERA_SID, 
                "SendAlert", 
                {Message = subjectStr .. "Event occured on {DateTime(CurrentTime,%A %B %d, %Y at %H:%M)}. {Picture(3)}", 
                Recipients = "SMTP-Mail"}, VERA_DID)
        luup.variable_set(SS_SID, "LastNotifiedTime", currTime, SS_DID)
    else
        -- skip notification
    end

end


function notifyPictureOnChange(deviceId, subject)
    -- default values
    local SS_SID = "urn:micasaverde-com:serviceId:SecuritySensor1" -- Security Sensor Service ID
    local SS_DID = deviceId
    subject = subject or "Motion detected"

    local VERA_SID = "urn:richardgreen:serviceId:VeraAlert1"

    
    local subjectStr = "{Subject=" .. subject .. "} "
    local  currTime = os.time()
    
    local prevTripped, ts = luup.variable_get(SS_SID, "PrevTripped", SS_DID) or "0"
    local tripped,ts = luup.variable_get(SS_SID, "Tripped", SS_DID) or "0"
    -- update PrevTripped on device
    luup.variable_set(SS_SID, "PrevTripped", tripped, SS_DID)


    if (statusChanged(prevTripped, tripped)) then
        luup.call_action(VERA_SID, 
                "SendAlert", 
                {Message = subjectStr .. "{Choose(tripped, 0=Close, 1=Open, Other=Unknown)} Event occured on {DateTime(CurrentTime,%A %B %d, %Y at %H:%M)}. {Picture(3)}", 
                Recipients = "SMTP-Mail"}, VERA_DID)
        luup.variable_set(SS_SID, "LastNotifiedTime", currTime, SS_DID)
    else
        -- skip notification
    end
end
