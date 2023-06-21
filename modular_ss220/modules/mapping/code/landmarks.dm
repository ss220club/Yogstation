/obj/effect/landmark/stationroom/cyberiad/bar
	template_names = list("Bar Cyberiad", "Bar Old")
	icon = 'modular_ss220/modules/mapping/icons/rooms/cyberiad/bar.dmi'
	icon_state = "bar_box"

/obj/effect/landmark/stationroom/cyberiad/bar/load(template_name)
	GLOB.stationroom_landmarks -= src
	return TRUE

/obj/effect/landmark/stationroom/cyberiad/engine
	template_names = list("Engine SM" = 50, "Engine Singulo And Tesla" = 50, "Engine TEG" = 0)
	icon = 'modular_ss220/modules/mapping/icons/rooms/cyberiad/engine.dmi'
	icon_state = "engine"

/obj/effect/landmark/stationroom/cyberiad/engine/choose()
	. = ..()
	var/enginepicked = CONFIG_GET(number/engine_type)
	switch(enginepicked)
		if(1)
			return "Engine SM"
		if(2)
			return "Engine Singulo And Tesla"
		if(3)
			return . //We let the normal choose() do the work if we want to have all of them in play
		if(4)
			return "Engine TEG"
