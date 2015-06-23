module ("L_BrijSecurity", package.seeall)
-- [[
	This module implements helper methods to control your home security system
	via Vera connected to it via the AD2USB device. The following public
	methods are defined:
	 - bypassKitchenDoor
	 - bypassBedroomDoor
	 - bypassKitchenBedDoor
	 - sendStar

	 Note that the "zone" IDs below will likely need to be updated (for Kitchen, 
	 	Bed etc)
-- ]]

-- private
local ALARM_SID           = "urn:micasaverde-com:serviceId:VistaAlarmPanel1"
local ALARM_PARTITION_SID = "urn:micasaverde-com:serviceId:AlarmPartition2"
local ALARM_DID           = 7 -- Home Alarm device ID
local PIN                 = "1234"  -- Home Allarm system default PIN


local ActionTypes = {
	ARM_SECURITY = 0,
	DISARM_SECURITY = 1,
	BYPASS_SECURITY_ZONE = 2
}

local function Set (list)
      local set = {}
      for _, l in ipairs(list) do set[l] = true end
      return set
end

local function callAction(action_type, zoneIDs)
	if action_type == ActionTypes.ARM_SECURITY then
		return luup.call_action(ALARM_PARTITION_SID,
            "RequestArmMode",
            {State = "Stay", PINCode=PIN},
            ALARM_DID)
	elseif action_type == ActionTypes.DISARM_SECURITY then
		return luup.call_action(ALARM_PARTITION_SID,
            "RequestArmMode",
            {State = "Disarmed", PINCode=PIN},
            ALARM_DID)
	elseif action_type == ActionTypes.BYPASS_SECURITY_ZONE then
		return luup.call_action(ALARM_SID, 
                  "BypassZones",
                 {Zones = zoneIDs, PINCode=PIN},
                 ALARM_DID)		
	else
		luup.log ("L_BrijSecurity::callAction: Unknown Security Action type!")
		return -1
	end

end

local function callActionAndWait(action_type, zoneIDs)
	local SLEEP_MS = 500
	
	local lul_resultcode, lul_resultstring, lul_job, lul_returnarguments 
		= callAction(action_type, zoneIDs)
	if lul_resultcode ~= 0 then
		luup.log ("L_BrijSecurity::callActionAndWait: callAction failed with non zero code")
		return false
	end

	luup.sleep (SLEEP_MS)
	
	
	-- job completed already
	if lul_job == 0 then
		return true
	end

	-- 	wait for job to complete ; job_status:
	-- 0: Job waiting to start.
	-- 1: Job in progress.
	-- 2: Job error.
	-- 3: Job aborted.
	-- 4: Job done.
	-- 5: Job waiting for callback. Used in special cases.
	-- 6: Job requeue. If the job was aborted and needs to be started, use this special value.
	-- 7: Job in progress with pending data. This means the job is waiting for data, but can't take it now.

	local retry_count = 0
	local MAX_RETRIES = 10
	local PENDING_JOB_STATUSES = Set {0,1, 5,6,7}
	local SUCCESS_JOB_STATUSES = Set {4}
	local FAILURE_JOB_STATUSES = Set {-1, 2,3}
	
	while retry_count < MAX_RETRIES do
		local job_status, job_notes = luup.job.status(lul_job, ALARM_DID)
		
		if PENDING_JOB_STATUSES[job_status] then
			retry_count = retry_count + 1
			luup.log ( "L_BrijSecurity::callActionAndWait: sleep & retry; count: " .. retry_count)
			luup.sleep (SLEEP_MS)
			-- continue
		elseif SUCCESS_JOB_STATUSES[job_status] then
			return true
		elseif FAILURE_JOB_STATUSES[job_status] then
			luup.log ( "L_BrijSecurity::callActionAndWait: job status code: " .. job_status)
			return false
		else
			luup.log ("L_BrijSecurity::callActionAndWait: Unknown job status code: " .. job_status)
			return false
		end

	end


	end




local function bypass(zoneIDs)
	if not callActionAndWait(ActionTypes.DISARM_SECURITY) then
		luup.log ("L_BrijSecurity::bypass: failed to disarm")
		return false
	end

	if not callActionAndWait(ActionTypes.BYPASS_SECURITY_ZONE, zoneIDs) then
		luup.log ("L_BrijSecurity::bypass: failed to bypass zones" .. zoneIDs)
		return false
	end

	if not callActionAndWait(ActionTypes.ARM_SECURITY, zoneIDs) then
		luup.log ("L_BrijSecurity::bypass: failed to arm")
		return false
	end
	
end



--public
function bypassKitchenDoor()
	bypass("6")
end

function bypassBedroomDoor()
	bypass("8")
end

function bypassKitchenBedDoor()
	bypass("6 8")
end

function sendStar ()
	if (luup.io.is_connected(ALARM_DID) == false) then
		luup.log("L_BrijSecurity::sendStar: alarm device-id not set up for IO yet!")
		return false
	end
	luup.log("L_BrijSecurity::sendStar: done!")
	luup.io.write("*", ALARM_DID)
end
