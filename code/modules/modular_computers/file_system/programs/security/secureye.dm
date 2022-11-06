#define DEFAULT_MAP_SIZE 15

/datum/computer_file/program/secureye
	filename = "secureye"
	filedesc = "SecurEye"
	category = PROGRAM_CATEGORY_SEC
	ui_header = "borg_mon.gif"
	program_icon_state = "generic"
	extended_desc = "This program allows access to standard security camera networks."
	requires_ntnet = TRUE
	transfer_access = ACCESS_BRIG
	usage_flags = PROGRAM_CONSOLE | PROGRAM_LAPTOP | PROGRAM_INTEGRATED // Probably not a good idea to let borgs use this, though im curious how it will pan out
	size = 10
	tgui_id = "NtosSecurEye"
	program_icon = "eye"

	var/list/network = list("ss13")
	var/obj/machinery/camera/active_camera
	/// The turf where the camera was last updated.
	var/turf/last_camera_turf
	var/list/concurrent_users = list()

	// Stuff needed to render the map
	var/map_name
	var/atom/movable/screen/map_view/cam_screen
	/// All the plane masters that need to be applied.
	var/list/cam_plane_masters
	var/atom/movable/screen/background/cam_background

/datum/computer_file/program/secureye/New()
	. = ..()
	// Map name has to start and end with an A-Z character,
	// and definitely NOT with a square bracket or even a number.
	map_name = "camera_console_[REF(src)]_map"
	// Convert networks to lowercase
	for(var/i in network)
		network -= i
		network += lowertext(i)
	// Initialize map objects
	cam_screen = new
	cam_screen.name = "screen"
	cam_screen.assigned_map = map_name
	cam_screen.del_on_map_removal = FALSE
	cam_screen.screen_loc = "[map_name]:1,1"
	cam_plane_masters = list()
	for(var/plane in subtypesof(/atom/movable/screen/plane_master))
		var/atom/movable/screen/instance = new plane()
		instance.assigned_map = map_name
		instance.del_on_map_removal = FALSE
		instance.screen_loc = "[map_name]:CENTER"
		cam_plane_masters += instance
	cam_background = new
	cam_background.assigned_map = map_name
	cam_background.del_on_map_removal = FALSE

/datum/computer_file/program/secureye/Destroy()
	qdel(cam_screen)
	QDEL_LIST(cam_plane_masters)
	qdel(cam_background)
	return ..()

/datum/computer_file/program/secureye/ui_interact(mob/user, datum/tgui/ui)
	// Update UI
	ui = SStgui.try_update_ui(user, src, ui)

	// Update the camera, showing static if necessary and updating data if the location has moved.
	update_active_camera_screen()

	if(!ui)
		var/user_ref = REF(user)
		var/is_living = isliving(user)
		// Ghosts shouldn't count towards concurrent users, which produces
		// an audible terminal_on click.
		if(is_living)
			concurrent_users += user_ref
		// Register map objects
		user.client.register_map_obj(cam_screen)
		for(var/plane in cam_plane_masters)
			user.client.register_map_obj(plane)
		user.client.register_map_obj(cam_background)
		return ..()

/datum/computer_file/program/secureye/ui_data()
	var/list/data = get_header_data()
	data["network"] = network
	data["activeCamera"] = null
	if(active_camera)
		data["activeCamera"] = list(
			name = active_camera.c_tag,
			status = active_camera.status,
		)
	return data

/datum/computer_file/program/secureye/ui_static_data()
	var/list/data = list()
	data["mapRef"] = map_name
	var/list/cameras = get_available_cameras()
	data["cameras"] = list()
	for(var/i in cameras)
		var/obj/machinery/camera/C = cameras[i]
		data["cameras"] += list(list(
			name = C.c_tag,
		))

	return data

/datum/computer_file/program/secureye/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(action == "switch_camera")
		var/c_tag = params["name"]
		var/list/cameras = get_available_cameras()
		var/obj/machinery/camera/selected_camera = cameras[c_tag]
		active_camera = selected_camera
		playsound(src, get_sfx("terminal_type"), 25, FALSE)

		if(!selected_camera)
			return TRUE

		update_active_camera_screen()

		return TRUE

/datum/computer_file/program/secureye/ui_close(mob/user)
	. = ..()
	var/user_ref = REF(user)
	var/is_living = isliving(user)
	// Living creature or not, we remove you anyway.
	concurrent_users -= user_ref
	// Unregister map objects
	user.client.clear_map(map_name)
	// Turn off the console
	if(length(concurrent_users) == 0 && is_living)
		active_camera = null
		playsound(src, 'sound/machines/terminal_off.ogg', 25, FALSE)

/datum/computer_file/program/secureye/proc/update_active_camera_screen()
	// Show static if can't use the camera
	if(!active_camera?.can_use())
		show_camera_static()
		return

	var/originator = active_camera
	if(active_camera.built_in)
		originator = get_turf(active_camera.built_in)

	var/list/visible_turfs = list()
	for(var/turf/T in (active_camera.isXRay() \
			? range(active_camera.view_range, originator) \
			: view(active_camera.view_range, originator)))
		visible_turfs += T

	var/list/bbox = get_bbox_of_atoms(visible_turfs)
	var/size_x = bbox[3] - bbox[1] + 1
	var/size_y = bbox[4] - bbox[2] + 1

	cam_screen.vis_contents = visible_turfs
	cam_background.icon_state = "clear"
	cam_background.fill_rect(1, 1, size_x, size_y)

/datum/computer_file/program/secureye/proc/show_camera_static()
	cam_screen.vis_contents.Cut()
	cam_background.icon_state = "scanline2"
	cam_background.fill_rect(1, 1, DEFAULT_MAP_SIZE, DEFAULT_MAP_SIZE)

// Returns the list of cameras accessible from this computer
/datum/computer_file/program/secureye/proc/get_available_cameras()
	var/list/L = list()
	for (var/obj/machinery/camera/cam in GLOB.cameranet.cameras)
		if(!(is_station_level(cam.z) || is_mining_level(cam.z) || !isnull(cam.built_in)))//Only show station cameras.
			continue
		L.Add(cam)
	var/list/camlist = list()
	for(var/obj/machinery/camera/cam in L)
		if(!cam.network)
			stack_trace("Camera in a cameranet has no camera network")
			continue
		if(!(islist(cam.network)))
			stack_trace("Camera in a cameranet has a non-list camera network")
			continue
		var/list/tempnetwork = cam.network & network
		if(tempnetwork.len)
			camlist["[cam.c_tag]"] = cam
	return camlist

//////////////////
//Mining Cameras//
//////////////////

///A program that allows you to view the cameras on the Mining Base
/datum/computer_file/program/secureye/mining
	filename = "overwatch"
	filedesc = "OverWatch"
	category = PROGRAM_CATEGORY_SUPL
	extended_desc = "This program allows access to the mining base camera network."
	transfer_access = ACCESS_MINING
	size = 5
	program_icon = "globe"

	network = list("mine", "auxbase")

//////////////////////
//Labor Camp Cameras//
//////////////////////

///A program that allows you to view the cameras on the Labor Camp
/datum/computer_file/program/secureye/laborcamp
	filename = "overseer"
	filedesc = "OverSeer"
	extended_desc = "This program allows access to the labor camp camera network."
	transfer_access = ACCESS_ARMORY
	size = 5
	program_icon = "dungeon"

	network = list("labor")
