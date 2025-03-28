//- Are all the floors with or without air, as they should be? (regular or airless)
//- Does the area have an APC?
//- Does the area have an Air Alarm?
//- Does the area have a Requests Console?
//- Does the area have lights?
//- Does the area have a light switch?
//- Does the area have enough intercoms?
//- Does the area have enough security cameras? (Use the 'Camera Range Display' verb under Debug)
//- Is the area connected to the scrubbers air loop?
//- Is the area connected to the vent air loop? (vent pumps)
//- Is everything wired properly?
//- Does the area have a fire alarm and firedoors?
//- Do all pod doors work properly?
//- Are accesses set properly on doors, pod buttons, etc.
//- Are all items placed properly? (not below vents, scrubbers, tables)
//- Does the disposal system work properly from all the disposal units in this room and all the units, the pipes of which pass through this room?
//- Check for any misplaced or stacked piece of pipe (air and disposal)
//- Check for any misplaced or stacked piece of wire
//- Identify how hard it is to break into the area and where the weak points are
//- Check if the area has too much empty space. If so, make it smaller and replace the rest with maintenance tunnels.

GLOBAL_VAR_INIT(camera_range_display_status, 0)
GLOBAL_VAR_INIT(intercom_range_display_status, 0)

/obj/effect/debugging/camera_range
	icon = 'icons/480x480.dmi'
	icon_state = "25percent"

/obj/effect/debugging/camera_range/New()
	src.pixel_x = -224
	src.pixel_y = -224

/obj/effect/debugging/marker
	icon = 'icons/turf/areas.dmi'
	icon_state = "yellow"

/obj/effect/debugging/marker/Move()
	return 0

/client/proc/do_not_use_these()
	set category = "Mapping"
	set name = "-None of these are for ingame use!!"

/client/proc/camera_view()
	set category = "Mapping"
	set name = "Camera Range Display"

	if(GLOB.camera_range_display_status)
		GLOB.camera_range_display_status = 0
	else
		GLOB.camera_range_display_status = 1



	for(var/obj/effect/debugging/camera_range/C in world)
		qdel(C)

	if(GLOB.camera_range_display_status)
		for(var/obj/machinery/camera/C in GLOB.cameranet.cameras)
			new/obj/effect/debugging/camera_range(C.loc)
	feedback_add_details("admin_verb","mCRD") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!



/client/proc/sec_camera_report()
	set category = "Mapping"
	set name = "Camera Report"

	if(!Master)
		alert(usr,"Master_controller not found.","Sec Camera Report")
		return 0

	var/list/obj/machinery/camera/CL = list()

	for(var/obj/machinery/camera/C in GLOB.cameranet.cameras)
		if (isturf(C.loc))
			CL += C

	var/output = {"<B>CAMERA ANNOMALITIES REPORT</B><HR>
<B>The following annomalities have been detected. The ones in red need immediate attention: Some of those in black may be intentional.</B><BR><ul>"}

	for(var/obj/machinery/camera/C1 in CL)
		if(C1.c_tag == null)
			output += "<li><span class='warning'>null c_tag for sec camera at \[[C1.x], [C1.y], [C1.z]\] ([C1.loc.loc])</span></li>"
		for(var/obj/machinery/camera/C2 in CL)
			if(C1 != C2)
				if(C1.c_tag == C2.c_tag)
					output += "<li><span class='warning'>c_tag match for sec. cameras at \[[C1.x], [C1.y], [C1.z]\] ([C1.loc.loc]) and \[[C2.x], [C2.y], [C2.z]\] ([C2.loc.loc]) - c_tag is [C1.c_tag]</span></li>"
				if(C1.loc == C2.loc && C1.dir == C2.dir && C1.pixel_x == C2.pixel_x && C1.pixel_y == C2.pixel_y)
					output += "<li><span class='warning'>FULLY overlapping sec. cameras at \[[C1.x], [C1.y], [C1.z]\] ([C1.loc.loc]) Networks: [C1.network] and [C2.network]</span></li>"
				if(C1.loc == C2.loc)
					output += "<li>overlapping sec. cameras at \[[C1.x], [C1.y], [C1.z]\] ([C1.loc.loc]) Networks: [C1.network] and [C2.network]</font></li>"
		var/turf/T = get_step(C1,turn(C1.dir,180))
		if(!T || !isturf(T) || !T.density )
			if(!(locate(/obj/structure/grille,T)))
				var/window_check = 0
				for(var/obj/structure/window/W in T)
					if (W.dir == turn(C1.dir,180) || (W.dir in list(5,6,9,10)))
						window_check = 1
						break
				if(!window_check)
					output += "<li><font color='red'>Camera not connected to wall at \[[C1.x], [C1.y], [C1.z]\] ([C1.loc.loc]) Network: [C1.network]</color></li>"
	output += "</ul>"
	usr << browse(HTML_SKELETON(output), "window=airreport;size=1000x500")
	feedback_add_details("admin_verb","mCRP") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/intercom_view()
	set category = "Mapping"
	set name = "Intercom Range Display"

	if(GLOB.intercom_range_display_status)
		GLOB.intercom_range_display_status = 0
	else
		GLOB.intercom_range_display_status = 1

	for(var/obj/effect/debugging/marker/M in world)
		qdel(M)

	if(GLOB.intercom_range_display_status)
		for(var/obj/item/device/radio/intercom/I in world)
			for(var/turf/T in orange(7,I))
				var/obj/effect/debugging/marker/F = new/obj/effect/debugging/marker(T)
				if (!(F in view(7,I.loc)))
					qdel(F)
	feedback_add_details("admin_verb","mIRD") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

GLOBAL_LIST_INIT(debug_verbs, list(
	/client/proc/do_not_use_these
	,/client/proc/camera_view
	,/client/proc/sec_camera_report
	,/client/proc/intercom_view
	,/client/proc/Cell
	,/client/proc/atmosscan
	,/client/proc/powerdebug
	,/client/proc/count_objects_on_z_level
	,/client/proc/count_objects_all
	,/client/proc/cmd_assume_direct_control
	,/client/proc/jump_to_dead_group
	,/client/proc/set_server_fps
	,/client/proc/cmd_admin_grantfullaccess
	,/client/proc/kaboom
	,/client/proc/splash
	,/client/proc/cmd_admin_areatest
	,/client/proc/cmd_admin_rejuvenate
	,/datum/admins/proc/show_traitor_panel
	,/client/proc/print_jobban_old
	,/client/proc/print_jobban_old_filter
	,/client/proc/forceEvent
	,/client/proc/break_all_air_groups
	,/client/proc/regroup_all_air_groups
	,/client/proc/kill_pipe_processing
	,/client/proc/kill_air_processing
	,/client/proc/disable_communication
	,/client/proc/disable_movement
	,/client/proc/Zone_Info
	,/client/proc/Test_ZAS_Connection
	//,/client/proc/ZoneTick
	,/client/proc/rebootAirMaster
	,/client/proc/hide_debug_verbs
	,/client/proc/testZAScolors
	,/client/proc/testZAScolors_remove
	,/datum/admins/proc/setup_supermatter
	,/client/proc/atmos_toggle_debug
	,/client/proc/spawn_tanktransferbomb
	,/client/proc/get_bad_fdoors
	,/client/proc/get_bad_doors
	,/client/proc/analyze_openturf
	))


/client/proc/enable_debug_verbs()
	set category = "Debug"
	set name = "Debug Verbs"

	if(!check_rights(R_DEBUG|R_DEV)) return

	add_verb(src, GLOB.debug_verbs)

	feedback_add_details("admin_verb","mDV") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/hide_debug_verbs()
	set category = "Debug"
	set name = "Hide Debug verbs"

	if(!check_rights(R_DEBUG|R_DEV)) return

	remove_verb(src, GLOB.debug_verbs)

	init_verbs()
	feedback_add_details("admin_verb","hDV") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!


/client/var/list/testZAScolors_turfs = list()
/client/var/list/testZAScolors_zones = list()
/client/var/usedZAScolors = 0
/client/var/list/image/ZAScolors = list()

/client/proc/recurse_zone(var/zone/Z, var/recurse_level =1)
	testZAScolors_zones += Z
	if(recurse_level > 10)
		return
	var/icon/yellow = new('icons/misc/debug_group.dmi', "yellow")

	for(var/turf/T in Z.contents)
		images += image(yellow, T, "zasdebug", TURF_LAYER)
		testZAScolors_turfs += T
	for(var/connection_edge/zone/edge in Z.edges)
		var/zone/connected = edge.get_connected_zone(Z)
		if(connected in testZAScolors_zones)
			continue
		recurse_zone(connected,recurse_level+1)


/client/proc/testZAScolors()
	set category = "ZAS"
	set name = "Check ZAS connections"

	if(!check_rights(R_DEBUG|R_DEV)) return
	testZAScolors_remove()

	var/turf/simulated/location = get_turf(usr)

	if(!istype(location, /turf/simulated)) // We're in space, let's not cause runtimes.
		to_chat(usr, SPAN_WARNING("this debug tool cannot be used from space"))
		return

	var/icon/red = new('icons/misc/debug_group.dmi', "red")		//created here so we don't have to make thousands of these.
	var/icon/green = new('icons/misc/debug_group.dmi', "green")
	var/icon/blue = new('icons/misc/debug_group.dmi', "blue")

	if(!usedZAScolors)
		to_chat(usr, "ZAS Test Colors")
		to_chat(usr, "Green = Zone you are standing in")
		to_chat(usr, "Blue = Connected zone to the zone you are standing in")
		to_chat(usr, "Yellow = A zone that is connected but not one adjacent to your connected zone")
		to_chat(usr, "Red = Not connected")
		usedZAScolors = 1

	testZAScolors_zones += location.zone
	for(var/turf/T in location.zone.contents)
		images += image(green, T,"zasdebug", TURF_LAYER)
		testZAScolors_turfs += T
	for(var/connection_edge/zone/edge in location.zone.edges)
		var/zone/Z = edge.get_connected_zone(location.zone)
		testZAScolors_zones += Z
		for(var/turf/T in Z.contents)
			images += image(blue, T,"zasdebug",TURF_LAYER)
			testZAScolors_turfs += T
		for(var/connection_edge/zone/z_edge in Z.edges)
			var/zone/connected = z_edge.get_connected_zone(Z)
			if(connected in testZAScolors_zones)
				continue
			recurse_zone(connected,1)

	for(var/turf/T in range(25,location))
		if(!istype(T))
			continue
		if(T in testZAScolors_turfs)
			continue
		images += image(red, T, "zasdebug", TURF_LAYER)
		testZAScolors_turfs += T

/client/proc/testZAScolors_remove()
	set category = "ZAS"
	set name = "Remove ZAS connection colors"

	testZAScolors_turfs.Cut()
	testZAScolors_zones.Cut()

	if(images.len)
		for(var/image/i in images)
			if(i.icon_state == "zasdebug")
				images.Remove(i)

/client/proc/rebootAirMaster()
	set category = "ZAS"
	set name = "Reboot ZAS"

	if(alert("This will destroy and remake all zone geometry on the whole map.","Reboot ZAS","Reboot ZAS","Nevermind") == "Reboot ZAS")
		SSair.reboot()

/client/proc/count_objects_on_z_level()
	set category = "Mapping"
	set name = "Count Objects On Level"
	var/level = input("Which z-level?","Level?") as text
	if(!level) return
	var/num_level = text2num(level)
	if(!num_level) return
	if(!isnum(num_level)) return

	var/type_text = input("Which type path?","Path?") as text
	if(!type_text) return
	var/type_path = text2path(type_text)
	if(!type_path) return

	var/count = 1

	var/list/atom/atom_list = list()

	for(var/atom/A in world)
		if(istype(A,type_path))
			var/atom/B = A
			while(!(isturf(B.loc)))
				if(B && B.loc)
					B = B.loc
				else
					break
			if(B)
				if(B.z == num_level)
					count++
					atom_list += A

	to_world("There are [count] objects of type [type_path] on z-level [num_level]")
	feedback_add_details("admin_verb","mOBJZ") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/count_objects_all()
	set category = "Mapping"
	set name = "Count Objects All"

	var/type_text = input("Which type path?","") as text
	if(!type_text) return
	var/type_path = text2path(type_text)
	if(!type_path) return

	var/count = 0

	for(var/atom/A in world)
		if(istype(A,type_path))
			count++

	to_world("There are [count] objects of type [type_path] in the game world")
	feedback_add_details("admin_verb","mOBJ") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!


// var/global/prevent_airgroup_regroup = 0

/client/proc/break_all_air_groups()
	set category = "Mapping"
	set name = "Break All Airgroups"

	/*prevent_airgroup_regroup = 1
	for(var/datum/air_group/AG in SSair.air_groups)
		AG.suspend_group_processing()
	message_admins("[src.ckey] used 'Break All Airgroups'")*/

/client/proc/regroup_all_air_groups()
	set category = "Mapping"
	set name = "Regroup All Airgroups Attempt"

	to_chat(usr, SPAN_WARNING("Proc disabled."))

	/*prevent_airgroup_regroup = 0
	for(var/datum/air_group/AG in SSair.air_groups)
		AG.check_regroup()
	message_admins("[src.ckey] used 'Regroup All Airgroups Attempt'")*/

/client/proc/kill_pipe_processing()
	set category = "Mapping"
	set name = "Kill pipe processing"

	to_chat(usr, SPAN_WARNING("Proc disabled."))

	/*pipe_processing_killed = !pipe_processing_killed
	if(pipe_processing_killed)
		message_admins("[src.ckey] used 'kill pipe processing', stopping all pipe processing.")
	else
		message_admins("[src.ckey] used 'kill pipe processing', restoring all pipe processing.")*/

/client/proc/kill_air_processing()
	set category = "Mapping"
	set name = "Kill air processing"

	to_chat(usr, SPAN_WARNING("Proc disabled."))

//This proc is intended to detect lag problems relating to communication procs
var/global/say_disabled = 0
/client/proc/disable_communication()
	set category = "Mapping"
	set name = "Disable all communication verbs"

	to_chat(usr, SPAN_WARNING("Proc disabled."))

	/*say_disabled = !say_disabled
	if(say_disabled)
		message_admins("[src.ckey] used 'Disable all communication verbs', killing all communication methods.")
	else
		message_admins("[src.ckey] used 'Disable all communication verbs', restoring all communication methods.")*/

//This proc is intended to detect lag problems relating to movement
var/global/movement_disabled = 0
var/global/movement_disabled_exception //This is the client that calls the proc, so he can continue to run around to gauge any change to lag.
/client/proc/disable_movement()
	set category = "Mapping"
	set name = "Disable all movement"

	to_chat(usr, SPAN_WARNING("Proc disabled."))

	/*movement_disabled = !movement_disabled
	if(movement_disabled)
		message_admins("[src.ckey] used 'Disable all movement', killing all movement.")
		movement_disabled_exception = usr.ckey
	else
		message_admins("[src.ckey] used 'Disable all movement', restoring all movement.")*/

/client/proc/get_bad_doors()
	set category = "Mapping"
	set name = "Find Bad Doors"

	for(var/obj/machinery/door/airlock/A in world)
		var/turf/T = get_turf(A)
		if(istype(T, /turf/space) || istype(T, /turf/simulated/floor/exoplanet/asteroid) || isopenturf(T) || T.density)
			to_chat(usr, "Airlock [A] with bad turf at ([A.x],[A.y],[A.z]) in [T.loc].")

/client/proc/get_bad_fdoors()
	set category = "Mapping"
	set name = "Find Bad Fire Doors"

	for(var/obj/machinery/door/firedoor/F in world)
		var/turf/T = get_turf(F)
		var/firelock_increment = 0
		for(var/obj/machinery/door/firedoor/FD in T)
			firelock_increment += 1
		if(firelock_increment > 1)
			to_chat(usr, "Double firedoor [F] at ([F.x],[F.y],[F.z]) in [T.loc].")

#ifdef TESTING
GLOBAL_LIST_EMPTY(dirty_vars)
#endif
