/obj/machinery/door/poddoor
	icon = 'modular_ss220/modules/aesthetics/shutters/icons/blast_door.dmi'
	icon_state = "open"
	var/blast_door_sound = 'modular_ss220/modules/aesthetics/shutters/sound/blast_door.ogg'

/obj/machinery/door/poddoor/do_animate(animation)
	switch(animation)
		if("opening")
			flick("opening", src)
			playsound(src, blast_door_sound, 30, TRUE)
		if("closing")
			flick("closing", src)
			playsound(src, blast_door_sound, 30, TRUE)

/obj/machinery/door/poddoor/shutters
	var/door_open_sound = 'modular_ss220/modules/aesthetics/shutters/sound/shutters_open.ogg'
	var/door_close_sound = 'modular_ss220/modules/aesthetics/shutters/sound/shutters_close.ogg'

/obj/machinery/door/poddoor/shutters/do_animate(animation)
	switch(animation)
		if("opening")
			flick("opening", src)
			playsound(src, door_open_sound, 30, TRUE)
		if("closing")
			flick("closing", src)
			playsound(src, door_close_sound, 30, TRUE)
