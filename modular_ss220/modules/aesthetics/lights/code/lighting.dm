#define NIGHTSHIFT_LIGHT_MODIFIER 0.15
#define NIGHTSHIFT_COLOR_MODIFIER 0.10

/// When a tooltype_act proc is successful
#define TOOL_ACT_TOOLTYPE_SUCCESS (1<<0)
/// When [COMSIG_ATOM_TOOL_ACT] blocks the act
#define TOOL_ACT_SIGNAL_BLOCKING (1<<1)


/obj/machinery/light
	icon = 'modular_ss220/modules/aesthetics/lights/icons/lighting.dmi'
	overlayicon = 'modular_ss220/modules/aesthetics/lights/icons/lighting_overlay.dmi'
	var/maploaded = FALSE
	var/turning_on = FALSE
	var/constant_flickering = FALSE
	var/flicker_timer = null
	var/roundstart_flicker = FALSE
	var/fire_colour = "#FF3C3C" //The Light colour to use when working in fire alarm status
	var/fire_brightness = 5 ///The Light range to use when working in fire alarm status

/obj/item/light/tube
	icon = 'modular_ss220/modules/aesthetics/lights/icons/lighting.dmi'
	lefthand_file = 'modular_ss220/modules/aesthetics/lights/icons/lights_lefthand.dmi'
	righthand_file = 'modular_ss220/modules/aesthetics/lights/icons/lights_righthand.dmi'

/obj/machinery/light/proc/turn_on(trigger, play_sound = TRUE)
	if(QDELETED(src))
		return
	turning_on = FALSE
	if(!on)
		return
	var/area/A  = get_room_area(src)
	var/new_brightness = brightness
	var/new_power = bulb_power
	var/new_color = bulb_colour
	if (A?.fire)
		new_color = fire_colour
		new_brightness = fire_brightness
	else if (A && A.vacuum)
		new_color = bulb_vacuum_colour
		new_brightness = bulb_vacuum_brightness
	else if(color)
		new_color = color
	else if (nightshift_enabled)
		new_brightness -= new_brightness * NIGHTSHIFT_LIGHT_MODIFIER
		new_power -= new_power * NIGHTSHIFT_LIGHT_MODIFIER
		if(!color && nightshift_light_color)
			new_color = nightshift_light_color
		else if(color) // In case it's spraypainted.
			new_color = color
		else // Adjust light values to be warmer. I doubt caching would speed this up by any worthwhile amount, as it's all very fast number and string operations.
			// Convert to numbers for easier manipulation.
			var/red = GETREDPART(bulb_colour)
			var/green = GETGREENPART(bulb_colour)
			var/blue = GETBLUEPART(bulb_colour)

			red += round(red * NIGHTSHIFT_COLOR_MODIFIER)
			green -= round(green * NIGHTSHIFT_COLOR_MODIFIER * 0.3)
			red = clamp(red, 0, 255) // clamp to be safe, or you can end up with an invalid hex value
			green = clamp(green, 0, 255)
			blue = clamp(blue, 0, 255)
			new_color = "#[num2hex(red, 2)][num2hex(green, 2)][num2hex(blue, 2)]"  // Splice the numbers together and turn them back to hex.

	var/matching = light && new_brightness == light.light_range && new_power == light.light_power && new_color == light.light_color
	if(!matching)
		switchcount++
		if( prob( min(60, (switchcount**2)*0.01) ) )
			if(trigger)
				burn_out()
		else
			use_power = ACTIVE_POWER_USE
			set_light(new_brightness, new_power, new_color)
			if(play_sound)
				playsound(src.loc, 'modular_ss220/modules/aesthetics/lights/sound/light_on.ogg', 65, 1)

/obj/machinery/light/proc/set_on(turn_on)
	on = (turn_on && status == LIGHT_OK)
	update()

/obj/machinery/light/proc/start_flickering()
	on = FALSE
	update(FALSE, TRUE, FALSE)

	constant_flickering = TRUE

	flicker_timer = addtimer(CALLBACK(src, PROC_REF(flicker_on)), rand(5, 10))

/obj/machinery/light/proc/stop_flickering()
	constant_flickering = FALSE

	if(flicker_timer)
		deltimer(flicker_timer)
		flicker_timer = null

	set_on(has_power())

/obj/machinery/light/proc/alter_flicker(enable = TRUE)
	if(!constant_flickering)
		return
	if(has_power())
		on = enable
		update(FALSE, TRUE, FALSE)

/obj/machinery/light/proc/flicker_on()
	alter_flicker(TRUE)
	flicker_timer = addtimer(CALLBACK(src, PROC_REF(flicker_off)), rand(5, 10))

/obj/machinery/light/proc/flicker_off()
	alter_flicker(FALSE)
	flicker_timer = addtimer(CALLBACK(src, PROC_REF(flicker_on)), rand(5, 50))

/obj/machinery/light/Initialize(mapload = TRUE)
	. = ..()
	if(on)
		maploaded = TRUE

	if(roundstart_flicker)
		start_flickering()

/obj/machinery/light/multitool_act(mob/living/user, obj/item/multitool)
	if(!constant_flickering)
		balloon_alert(user, "ballast is already working!")
		return TOOL_ACT_TOOLTYPE_SUCCESS

	balloon_alert(user, "repairing the ballast...")
	if(do_after(user, 2 SECONDS, src))
		stop_flickering()
		balloon_alert(user, "ballast repaired!")
		return TOOL_ACT_TOOLTYPE_SUCCESS
	return ..()

///Get a valid powered area to reference for power use, mainly for wall-mounted machinery that isn't always mapped directly in a powered location.
/obj/machinery/proc/get_room_area(area/machine_room)
	var/area/machine_area = get_area(src)
	if(!machine_area.always_unpowered) ///check our loc first to see if its a powered area
		machine_room = machine_area
		return machine_room
	var/turf/mounted_wall = get_step(src,dir)
	if (mounted_wall && istype(mounted_wall, /turf/closed))
		var/area/wall_area = get_area(mounted_wall)
		if(!wall_area.always_unpowered) //loc area wasn't good, checking adjacent wall for a good area to use
			machine_room = wall_area
			return machine_room
	machine_room = machine_area ///couldn't find a proper powered area on loc or adjacent wall, defaulting back to loc and blaming mappers
	return machine_room

#undef NIGHTSHIFT_LIGHT_MODIFIER
#undef NIGHTSHIFT_COLOR_MODIFIER
