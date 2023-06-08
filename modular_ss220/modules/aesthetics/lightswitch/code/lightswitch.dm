/obj/machinery/light_switch
	icon = 'modular_ss220/modules/aesthetics/lightswitch/icons/lightswitch.dmi'
	icon_state = "light-nopower"

obj/machinery/light_switch/update_icon()
	SSvis_overlays.remove_vis_overlay(src, managed_vis_overlays)
	if(!(stat & NOPOWER))
		if(area.lightswitch)
			SSvis_overlays.add_vis_overlay(src, icon, "light-emissive-on", ABOVE_LIGHTING_LAYER, ABOVE_LIGHTING_PLANE, dir)
		else
			SSvis_overlays.add_vis_overlay(src, icon, "light-emissive-off", ABOVE_LIGHTING_LAYER, ABOVE_LIGHTING_PLANE, dir)

/obj/machinery/light_switch/interact(mob/user)
	. = ..()
	playsound(src, 'modular_ss220/modules/aesthetics/lightswitch/sound/lightswitch.ogg', 100, 1)

/obj/machinery/light_switch/LateInitialize()
	. = ..()
	if(prob(50) && area.lightswitch) //50% chance for area to start with lights off.
		turn_off()

/obj/machinery/light_switch/proc/turn_off()
	if(!area.lightswitch)
		return
	area.lightswitch = FALSE
	area.update_icon()

	for(var/obj/machinery/light_switch/light_switch in area)
		light_switch.update_icon()

	area.power_change()
