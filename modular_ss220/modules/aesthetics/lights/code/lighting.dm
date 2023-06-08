/// Dynamically calculate nightshift brightness. How TG does it is painful to modify.
#define NIGHTSHIFT_LIGHT_MODIFIER 0.15
#define NIGHTSHIFT_COLOR_MODIFIER 0.10

/atom
	light_power = 1.25

/obj/machinery/light
	icon = 'modular_ss220/modules/aesthetics/lights/icons/lighting.dmi'

/obj/machinery/light/proc/turn_on(trigger, play_sound = TRUE)
	playsound(src.loc, 'modular_ss220/modules/aesthetics/lights/sound/light_on.ogg', 65, 1)

/obj/item/light/tube
	icon = 'modular_ss220/modules/aesthetics/lights/icons/lighting.dmi'
	lefthand_file = 'modular_ss220/modules/aesthetics/lights/icons/lights_lefthand.dmi'
	righthand_file = 'modular_ss220/modules/aesthetics/lights/icons/lights_righthand.dmi'
	