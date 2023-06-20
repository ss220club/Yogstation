/obj/effect/landmark/stationroom/cyberiad/bar
	template_names = list("Bar Cyberiad", "Bar Old")
	icon = 'modular_ss220/modules/mapping/icons/rooms/cyberiad/bar.dmi'
	icon_state = "bar_box"

/obj/effect/landmark/stationroom/cyberiad/bar/load(template_name)
	GLOB.stationroom_landmarks -= src
	return TRUE
