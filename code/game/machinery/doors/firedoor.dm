#define CONSTRUCTION_COMPLETE 0 //No construction done - functioning as normal
#define CONSTRUCTION_PANEL_OPEN 1 //Maintenance panel is open, still functioning
#define CONSTRUCTION_WIRES_EXPOSED 2 //Cover plate is removed, wires are available
#define CONSTRUCTION_GUTTED 3 //Wires are removed, circuit ready to remove
#define CONSTRUCTION_NOCIRCUIT 4 //Circuit board removed, can safely weld apart

/obj/machinery/door/firedoor
	name = "firelock"
	desc = "Apply crowbar."
	icon = 'icons/obj/doors/doorfireglass.dmi'
	icon_state = "door_open"
	opacity = FALSE
	density = FALSE
	max_integrity = 120
	resistance_flags = FIRE_PROOF
	heat_proof = TRUE
	glass = TRUE
	sub_door = TRUE
	explosion_block = 1
	safe = FALSE
	layer = BELOW_OPEN_DOOR_LAYER
	closingLayer = CLOSED_FIREDOOR_LAYER
	assemblytype = /obj/structure/firelock_frame
	armor = list(MELEE = 30, BULLET = 30, LASER = 20, ENERGY = 20, BOMB = 10, BIO = 100, RAD = 100, FIRE = 95, ACID = 70)
	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_REQUIRES_SILICON | INTERACT_MACHINE_OPEN
	air_tight = TRUE
	var/emergency_close_timer = 0
	var/nextstate = null
	var/boltslocked = TRUE
	var/list/affecting_areas

/obj/machinery/door/firedoor/Initialize(mapload, direct)
	. = ..()
	if(direct)
		setDir(direct)
	CalculateAffectingAreas()

/obj/machinery/door/firedoor/examine(mob/user)
	. = ..()
	if(!density)
		. += span_notice("It is open, but could be <b>pried</b> closed.")
	else if(!welded)
		. += span_notice("It is closed, but could be <i>pried</i> open. Deconstruction would require it to be <b>welded</b> shut.")
	else if(boltslocked)
		. += span_notice("It is <i>welded</i> shut. The floor bolts have been locked by <b>screws</b>.")
	else
		. += span_notice("The bolt locks have been <i>unscrewed</i>, but the bolts themselves are still <b>wrenched</b> to the floor.")

/obj/machinery/door/firedoor/proc/CalculateAffectingAreas()
	remove_from_areas()
	affecting_areas = get_adjacent_open_areas(src) | get_area(src)
	for(var/I in affecting_areas)
		var/area/A = I
		LAZYADD(A.firedoors, src)

/obj/machinery/door/firedoor/closed
	icon_state = "door_closed"
	opacity = TRUE
	density = TRUE

//see also turf/AfterChange for adjacency shennanigans

/obj/machinery/door/firedoor/proc/remove_from_areas()
	if(affecting_areas)
		for(var/I in affecting_areas)
			var/area/A = I
			LAZYREMOVE(A.firedoors, src)

/obj/machinery/door/firedoor/Destroy()
	remove_from_areas()
	affecting_areas.Cut()
	air_update_turf()
	return ..()

/obj/machinery/door/firedoor/Bumped(atom/movable/AM)
	if(panel_open || operating || welded || (stat & NOPOWER))
		return
	if(ismob(AM))
		var/mob/user = AM
		if(allow_hand_open(user))
			add_fingerprint(user)
			open()
			return TRUE
	if(ismecha(AM))
		var/obj/mecha/M = AM
		if(M.occupant && allow_hand_open(M.occupant))
			open()
			return TRUE
	return FALSE


/obj/machinery/door/firedoor/power_change()
	. = ..()
	latetoggle()

/obj/machinery/door/firedoor/attack_hand(mob/user)
	. = ..()
	if(.)
		return

	if(!welded && !operating && !(stat & NOPOWER) && (!density || allow_hand_open(user)))
		add_fingerprint(user)
		if(density)
			emergency_close_timer = world.time + 30 // prevent it from instaclosing again if in space
			open()
		else
			close()
		return TRUE
	if(operating || !density)
		return
	user.changeNext_move(CLICK_CD_MELEE)

	user.visible_message("[user] bangs on \the [src].",
						 "You bang on \the [src].")
	playsound(loc, 'sound/effects/glassknock.ogg', 10, FALSE, frequency = 32000)

/obj/machinery/door/firedoor/attackby(obj/item/C, mob/user, params)
	add_fingerprint(user)
	if(operating)
		return

	if(welded)
		if(C.tool_behaviour == TOOL_WRENCH)
			if(boltslocked)
				to_chat(user, span_notice("There are screws locking the bolts in place!"))
				return
			C.play_tool_sound(src)
			user.visible_message(span_notice("[user] starts undoing [src]'s bolts..."), \
								 span_notice("You start unfastening [src]'s floor bolts..."))
			if(!C.use_tool(src, user, 50))
				return
			playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
			user.visible_message(span_notice("[user] unfastens [src]'s bolts."), \
								 span_notice("You undo [src]'s floor bolts."))
			deconstruct(TRUE)
			return
		if(C.tool_behaviour == TOOL_SCREWDRIVER)
			user.visible_message(span_notice("[user] [boltslocked ? "unlocks" : "locks"] [src]'s bolts."), \
								 span_notice("You [boltslocked ? "unlock" : "lock"] [src]'s floor bolts."))
			C.play_tool_sound(src)
			boltslocked = !boltslocked
			return

	return ..()

/obj/machinery/door/firedoor/try_to_activate_door(mob/user)
	return

/obj/machinery/door/firedoor/try_to_weld(obj/item/weldingtool/W, mob/user)
	if(!W.tool_start_check(user, amount=0))
		return
	user.visible_message(span_notice("[user] starts [welded ? "unwelding" : "welding"] [src]."), span_notice("You start welding [src]."))
	if(W.use_tool(src, user, 40, volume=50))
		welded = !welded
		to_chat(user, span_danger("[user] [welded?"welds":"unwelds"] [src]."), span_notice("You [welded ? "weld" : "unweld"] [src]."))
		update_icon()

/obj/machinery/door/firedoor/try_to_crowbar(obj/item/I, mob/user)
	if(welded || operating)
		return

	if(density)
		if(is_holding_pressure())
			// tell the user that this is a bad idea, and have a do_after as well
			to_chat(user, span_warning("As you begin crowbarring \the [src] a gush of air blows in your face... maybe you should reconsider?"))
			if(!do_after(user, 1.5 SECONDS, src)) // give them a few seconds to reconsider their decision.
				return
			log_game("[key_name_admin(user)] has opened a firelock with a pressure difference at [AREACOORD(loc)]") // there bibby I made it logged just for you. Enjoy.
			// since we have high-pressure-ness, close all other firedoors on the tile
			whack_a_mole()
		if(welded || operating || !density)
			return // in case things changed during our do_after
		emergency_close_timer = world.time + 60 // prevent it from instaclosing again if in space
		open()
	else
		close()

/obj/machinery/door/firedoor/proc/allow_hand_open(mob/user)
	var/area/A = get_area(src)
	if(A && A.fire)
		return FALSE
	return !is_holding_pressure()

/obj/machinery/door/firedoor/attack_ai(mob/user)
	add_fingerprint(user)
	if(welded || operating || stat & NOPOWER)
		return TRUE
	if(density)
		open()
	else
		close()
	return TRUE

/obj/machinery/door/firedoor/attack_robot(mob/user)
	return attack_ai(user)

/obj/machinery/door/firedoor/attack_alien(mob/user)
	add_fingerprint(user)
	if(welded)
		to_chat(user, span_warning("[src] refuses to budge!"))
		return
	if(user.a_intent == INTENT_HARM)
		return ..()
	else
		open()

/obj/machinery/door/firedoor/do_animate(animation)
	switch(animation)
		if("opening")
			flick("door_opening", src)
		if("closing")
			flick("door_closing", src)

/obj/machinery/door/firedoor/update_icon()
	cut_overlays()
	if(density)
		icon_state = "door_closed"
		if(welded)
			add_overlay("welded")
	else
		icon_state = "door_open"
		if(welded)
			add_overlay("welded_open")
	SSdemo.mark_dirty(src)
	air_update_turf()

/obj/machinery/door/firedoor/open()
	. = ..()
	latetoggle()

/obj/machinery/door/firedoor/close()
	. = ..()
	latetoggle()

/obj/machinery/door/firedoor/proc/whack_a_mole()
	for(var/cdir in GLOB.cardinals)
		if((flags_1 & ON_BORDER_1) && cdir != dir)
			continue
		whack_a_mole_part(get_step(src, cdir))
	if(flags_1 & ON_BORDER_1)
		whack_a_mole_part(get_turf(src))

/obj/machinery/door/firedoor/proc/whack_a_mole_part(turf/start_point)
	var/list/doors_to_close = list()
	var/list/turfs = list()
	turfs[start_point] = 1
	for(var/i = 1; (i <= turfs.len && i <= 11); i++) // check up to 11 turfs.
		var/turf/open/T = turfs[i]
		if(istype(T, /turf/open/space))
			return -1
		for(var/T2 in T.atmos_adjacent_turfs)
			if(turfs[T2])
				continue
			var/is_cut_by_unopen_door = FALSE
			for(var/obj/machinery/door/firedoor/FD in T2)
				if((FD.flags_1 & ON_BORDER_1) && get_dir(T2, T) != FD.dir)
					continue
				if(FD.operating || FD == src || FD.welded || FD.density)
					continue
				doors_to_close += FD
				is_cut_by_unopen_door = TRUE

			for(var/obj/machinery/door/firedoor/FD in T)
				if((FD.flags_1 & ON_BORDER_1) && get_dir(T, T2) != FD.dir)
					continue
				if(FD.operating || FD == src || FD.welded || FD.density)
					continue
				doors_to_close += FD
				is_cut_by_unopen_door= TRUE
			if(!is_cut_by_unopen_door)
				turfs[T2] = 1
	if(turfs.len > 10)
		return // too big, don't bother
	for(var/obj/machinery/door/firedoor/FD in doors_to_close)
		FD.emergency_pressure_stop(FALSE)

/obj/machinery/door/firedoor/proc/emergency_pressure_stop(consider_timer = TRUE)
	if(density || operating || welded)
		return
	if(world.time >= emergency_close_timer || !consider_timer)
		emergency_pressure_close()

//this is here to prevent sleeps from messing with decomp, by closing firedoors instantly
/obj/machinery/door/firedoor/proc/emergency_pressure_close()
	density = TRUE
	air_update_turf()
	layer = closingLayer
	update_icon()
	if(visible && !glass)
		set_opacity(1)
	update_freelook_sight()
	if(!(flags_1 & ON_BORDER_1))
		crush()

/obj/machinery/door/firedoor/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1) && disassembled)
		var/obj/structure/firelock_frame/F = new assemblytype(get_turf(src))
		F.constructionStep = CONSTRUCTION_PANEL_OPEN
		F.update_icon()
	qdel(src)


/obj/machinery/door/firedoor/proc/latetoggle()
	if(operating || stat & NOPOWER || !nextstate)
		return
	switch(nextstate)
		if(FIREDOOR_OPEN)
			nextstate = null
			open()
		if(FIREDOOR_CLOSED)
			nextstate = null
			close()

/obj/machinery/door/firedoor/border_only
	icon = 'icons/obj/doors/edge_Doorfire.dmi'
	flags_1 = ON_BORDER_1
	CanAtmosPass = ATMOS_PASS_PROC
	assemblytype = /obj/structure/firelock_frame/border

/obj/machinery/door/firedoor/border_only/closed
	icon_state = "door_closed"
	opacity = TRUE
	density = TRUE

/obj/machinery/door/firedoor/border_only/close()
	if(density)
		return TRUE
	if(operating || welded)
		return
	check_pulls()
	. = ..()

/obj/machinery/door/firedoor/border_only/emergency_pressure_close()
	check_pulls()
	. = ..()

/obj/machinery/door/firedoor/border_only/proc/check_pulls()
	var/turf/T1 = get_turf(src)
	var/turf/T2 = get_step(T1, dir)
	for(var/mob/living/M in T1)
		if(M.stat == CONSCIOUS && M.pulling && M.pulling.loc == T2 && !M.pulling.anchored && M.pulling.move_resist <= M.move_force)
			var/mob/living/M2 = M.pulling
			if(!istype(M2) || !M2.buckled || !M2.buckled.buckle_prevents_pull)
				to_chat(M, span_notice("You pull [M.pulling] through [src] right as it closes"))
				M.pulling.forceMove(T1)
				M.start_pulling(M2)

	for(var/mob/living/M in T2)
		if(M.stat == CONSCIOUS && M.pulling && M.pulling.loc == T1 && !M.pulling.anchored && M.pulling.move_resist <= M.move_force)
			var/mob/living/M2 = M.pulling
			if(!istype(M2) || !M2.buckled || !M2.buckled.buckle_prevents_pull)
				to_chat(M, span_notice("You pull [M.pulling] through [src] right as it closes"))
				M.pulling.forceMove(T2)
				M.start_pulling(M2)

/obj/machinery/door/firedoor/border_only/allow_hand_open(mob/user)
	var/area/A = get_area(src)
	if((!A || !A.fire) && !is_holding_pressure())
		return TRUE
	whack_a_mole(TRUE) // WOOP WOOP SIDE EFFECTS
	var/turf/T = loc
	var/turf/T2 = get_step(T, dir)
	if(!T || !T2)
		return
	var/status1 = check_door_side(T)
	var/status2 = check_door_side(T2)	
	if((status1 == 1 && status2 == -1) || (status1 == -1 && status2 == 1))
		to_chat(user, span_warning("Access denied. Try closing another firedoor to minimize decompression, or using a crowbar."))
		return FALSE
	return TRUE

/obj/machinery/door/firedoor/border_only/proc/check_door_side(turf/open/start_point)
	var/list/turfs = list()
	turfs[start_point] = 1
	for(var/i = 1; (i <= turfs.len && i <= 11); i++) // check up to 11 turfs.
		var/turf/open/T = turfs[i]
		if(istype(T, /turf/open/space))
			return -1
		for(var/T2 in T.atmos_adjacent_turfs)
			turfs[T2] = 1
	if(turfs.len <= 10)
		return 0 // not big enough to matter
	return start_point.air.return_pressure() < 20 ? -1 : 1

/obj/machinery/door/firedoor/border_only/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover) && (mover.pass_flags & PASSGLASS))
		return TRUE
	if(!(get_dir(loc, target) == dir)) //Make sure looking at appropriate border
		return TRUE

/obj/machinery/door/firedoor/border_only/CheckExit(atom/movable/mover as mob|obj, turf/target)
	if(istype(mover) && (mover.pass_flags & PASSDOOR)) // I mean it's a door
		return TRUE
	if(istype(mover) && (mover.pass_flags & PASSGLASS))
		return TRUE
	if(get_dir(loc, target) == dir)
		return !density
	else
		return TRUE

/obj/machinery/door/firedoor/border_only/CanAtmosPass(turf/T)
	if(get_dir(loc, T) == dir)
		return !density
	else
		return TRUE

/obj/machinery/door/firedoor/border_only/BlockThermalConductivity(opp_dir)
	if(opp_dir == dir)
		return density
	else
		return FALSE

/obj/machinery/door/firedoor/heavy
	name = "heavy firelock"
	icon = 'icons/obj/doors/doorfire.dmi'
	glass = FALSE
	explosion_block = 2
	assemblytype = /obj/structure/firelock_frame/heavy
	max_integrity = 350

/obj/machinery/door/firedoor/window
	name = "window shutter"
	icon = 'icons/obj/doors/doorfirewindow.dmi'
	desc = "A second window that slides in when the original window is broken, designed to protect against hull breaches. Truly a work of genius by NT engineers."
	glass = TRUE
	explosion_block = 0
	max_integrity = 50
	resistance_flags = 0 // not fireproof
	heat_proof = FALSE

/obj/machinery/door/firedoor/window/allow_hand_open()
	return TRUE

/obj/item/electronics/firelock
	name = "firelock circuitry"
	custom_price = 5
	desc = "A circuit board used in construction of firelocks."
	icon_state = "mainboard"

/obj/structure/firelock_frame
	name = "firelock frame"
	desc = "A partially completed firelock."
	icon = 'icons/obj/doors/doorfire.dmi'
	icon_state = "frame1"
	anchored = FALSE
	density = TRUE
	var/constructionStep = CONSTRUCTION_NOCIRCUIT
	var/reinforced = 0
	var/border = FALSE

/obj/structure/firelock_frame/border
	icon = 'icons/obj/doors/edge_Doorfire.dmi'
	border = TRUE

/obj/structure/firelock_frame/border/Initialize(mapload)
	. = ..()
	var/static/rotation_flags = ROTATION_ALTCLICK | ROTATION_CLOCKWISE | ROTATION_COUNTERCLOCKWISE | ROTATION_VERBS
	AddComponent(/datum/component/simple_rotation, rotation_flags)

/obj/structure/firelock_frame/border/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover) && (mover.pass_flags & PASSGLASS))
		return TRUE
	if(!(get_dir(loc, target) == dir)) //Make sure looking at appropriate border
		return TRUE

/obj/structure/firelock_frame/border/CheckExit(atom/movable/mover as mob|obj, turf/target)
	if(istype(mover) && (mover.pass_flags & PASSGLASS))
		return TRUE
	if(get_dir(loc, target) == dir)
		return !density
	else
		return TRUE

/obj/structure/firelock_frame/examine(mob/user)
	. = ..()
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			. += span_notice("It is <i>unbolted</i> from the floor. A small <b>loosely connected</b> metal plate is covering the wires.")
			if(!reinforced)
				. += span_notice("It could be reinforced with plasteel.")
		if(CONSTRUCTION_WIRES_EXPOSED)
			. += span_notice("The maintenance plate has been <i>pried away</i>, and <b>wires</b> are trailing.")
		if(CONSTRUCTION_GUTTED)
			. += span_notice("The maintenance panel is missing <i>wires</i> and the circuit board is <b>loosely connected</b>.")
		if(CONSTRUCTION_NOCIRCUIT)
			. += span_notice("There are no <i>firelock electronics</i> in the frame. The frame could be <b>cut</b> apart.")

/obj/structure/firelock_frame/update_icon()
	..()
	icon_state = "frame[constructionStep]"

/obj/structure/firelock_frame/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.mode == RCD_DECONSTRUCT)
		return list("mode" = RCD_DECONSTRUCT, "delay" = 50, "cost" = 16)
	return FALSE

/obj/structure/firelock_frame/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	if(passed_mode == RCD_DECONSTRUCT)
		to_chat(user, span_notice("You deconstruct [src]."))
		qdel(src)
		return TRUE
	return FALSE

/obj/structure/firelock_frame/attackby(obj/item/C, mob/user)
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			if(C.tool_behaviour == TOOL_CROWBAR)
				C.play_tool_sound(src)
				user.visible_message(span_notice("[user] starts prying something out from [src]..."), \
									 span_notice("You begin prying out the wire cover..."))
				if(!C.use_tool(src, user, 50))
					return
				if(constructionStep != CONSTRUCTION_PANEL_OPEN)
					return
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				user.visible_message(span_notice("[user] pries out a metal plate from [src], exposing the wires."), \
									 span_notice("You remove the cover plate from [src], exposing the wires."))
				constructionStep = CONSTRUCTION_WIRES_EXPOSED
				update_icon()
				return
			if(C.tool_behaviour == TOOL_WRENCH)
				for(var/obj/machinery/door/firedoor/door in get_turf(src)) //go through each obj/machinery/door/firedoor in the turf
					if(istype(door,/obj/machinery/door/firedoor/border_only)) //check if it's a full-tile or a directional one
						if(door.dir == dir) //check if the direction of the firelock is the same as the one we wanna make
							to_chat(user,span_warning("There is already a directional firelock there.")) //if it is then then them there's already one here
							return //cancel construction
					else //since we know there's a fulltile here we just cancel it then
						to_chat(user, span_warning("There's already a firelock there."))
						return    
				C.play_tool_sound(src)
				user.visible_message(span_notice("[user] starts bolting down [src]..."), \
									 span_notice("You begin bolting [src]..."))
				if(!C.use_tool(src, user, 30))
					return
				//sanity check time, do this dumb ass check again SOMEBODY FIX THIS
				for(var/obj/machinery/door/firedoor/door in get_turf(src)) 
					if(istype(door,/obj/machinery/door/firedoor/border_only)) 
						if(door.dir == dir) 
							return 
					else 
						return    
				user.visible_message(span_notice("[user] finishes the firelock."), \
									 span_notice("You finish the firelock."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(border)
					new /obj/machinery/door/firedoor/border_only(get_turf(src), dir)
				else if(reinforced)
					new /obj/machinery/door/firedoor/heavy(get_turf(src))
				else
					new /obj/machinery/door/firedoor(get_turf(src))
				qdel(src)
				return
			if(istype(C, /obj/item/stack/sheet/plasteel))
				var/obj/item/stack/sheet/plasteel/P = C
				if(border)
					to_chat(user, span_warning("[src] cannot be reinforced."))
					return
				if(reinforced)
					to_chat(user, span_warning("[src] is already reinforced."))
					return
				if(P.get_amount() < 2)
					to_chat(user, span_warning("You need more plasteel to reinforce [src]."))
					return
				user.visible_message(span_notice("[user] begins reinforcing [src]..."), \
									 span_notice("You begin reinforcing [src]..."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(do_after(user, 6 SECONDS, src))
					if(constructionStep != CONSTRUCTION_PANEL_OPEN || reinforced || P.get_amount() < 2 || !P)
						return
					user.visible_message(span_notice("[user] reinforces [src]."), \
										 span_notice("You reinforce [src]."))
					playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
					P.use(2)
					reinforced = 1
				return

		if(CONSTRUCTION_WIRES_EXPOSED)
			if(C.tool_behaviour == TOOL_WIRECUTTER)
				C.play_tool_sound(src)
				user.visible_message(span_notice("[user] starts cutting the wires from [src]..."), \
									 span_notice("You begin removing [src]'s wires..."))
				if(!C.use_tool(src, user, 60))
					return
				if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
					return
				user.visible_message(span_notice("[user] removes the wires from [src]."), \
									 span_notice("You remove the wiring from [src], exposing the circuit board."))
				new/obj/item/stack/cable_coil(get_turf(src), 5)
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
			if(C.tool_behaviour == TOOL_CROWBAR)
				C.play_tool_sound(src)
				user.visible_message(span_notice("[user] starts prying a metal plate into [src]..."), \
									 span_notice("You begin prying the cover plate back onto [src]..."))
				if(!C.use_tool(src, user, 80))
					return
				if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
					return
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				user.visible_message(span_notice("[user] pries the metal plate into [src]."), \
									 span_notice("You pry [src]'s cover plate into place, hiding the wires."))
				constructionStep = CONSTRUCTION_PANEL_OPEN
				update_icon()
				return
		if(CONSTRUCTION_GUTTED)
			if(C.tool_behaviour == TOOL_CROWBAR)
				user.visible_message(span_notice("[user] begins removing the circuit board from [src]..."), \
									 span_notice("You begin prying out the circuit board from [src]..."))
				if(!C.use_tool(src, user, 50, volume=50))
					return
				if(constructionStep != CONSTRUCTION_GUTTED)
					return
				user.visible_message(span_notice("[user] removes [src]'s circuit board."), \
									 span_notice("You remove the circuit board from [src]."))
				new /obj/item/electronics/firelock(drop_location())
				constructionStep = CONSTRUCTION_NOCIRCUIT
				update_icon()
				return
			if(istype(C, /obj/item/stack/cable_coil))
				var/obj/item/stack/cable_coil/B = C
				if(B.get_amount() < 5)
					to_chat(user, span_warning("You need more wires to add wiring to [src]."))
					return
				user.visible_message(span_notice("[user] begins wiring [src]..."), \
									 span_notice("You begin adding wires to [src]..."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(do_after(user, 6 SECONDS, src))
					if(constructionStep != CONSTRUCTION_GUTTED || B.get_amount() < 5 || !B)
						return
					user.visible_message(span_notice("[user] adds wires to [src]."), \
										 span_notice("You wire [src]."))
					playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
					B.use(5)
					constructionStep = CONSTRUCTION_WIRES_EXPOSED
					update_icon()
				return
		if(CONSTRUCTION_NOCIRCUIT)
			if(C.tool_behaviour == TOOL_WELDER)
				if(!C.tool_start_check(user, amount=1))
					return
				user.visible_message(span_notice("[user] begins cutting apart [src]'s frame..."), \
									 span_notice("You begin slicing [src] apart..."))

				if(C.use_tool(src, user, 40, volume=50, amount=1))
					if(constructionStep != CONSTRUCTION_NOCIRCUIT)
						return
					user.visible_message(span_notice("[user] cuts apart [src]!"), \
										 span_notice("You cut [src] into metal."))
					var/turf/T = get_turf(src)
					new /obj/item/stack/sheet/metal(T, 3)
					if(reinforced)
						new /obj/item/stack/sheet/plasteel(T, 2)
					qdel(src)
				return
			if(istype(C, /obj/item/electronics/firelock))
				user.visible_message(span_notice("[user] starts adding [C] to [src]..."), \
									 span_notice("You begin adding a circuit board to [src]..."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(!do_after(user, 4 SECONDS, src))
					return
				if(constructionStep != CONSTRUCTION_NOCIRCUIT)
					return
				qdel(C)
				user.visible_message(span_notice("[user] adds a circuit to [src]."), \
									 span_notice("You insert and secure [C]."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
			if(istype(C, /obj/item/electroadaptive_pseudocircuit))
				var/obj/item/electroadaptive_pseudocircuit/P = C
				if(!P.adapt_circuit(user, 30))
					return
				user.visible_message(span_notice("[user] fabricates a circuit and places it into [src]."), \
				span_notice("You adapt a firelock circuit and slot it into the assembly."))
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
	return ..()

/obj/structure/firelock_frame/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if((constructionStep == CONSTRUCTION_NOCIRCUIT) && (the_rcd.upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS))
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)	
	return FALSE

/obj/structure/firelock_frame/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			user.visible_message(span_notice("[user] fabricates a circuit and places it into [src]."), \
			span_notice("You adapt a firelock circuit and slot it into the assembly."))
			constructionStep = CONSTRUCTION_GUTTED
			update_icon()
			return TRUE
	return FALSE

/obj/structure/firelock_frame/heavy
	name = "heavy firelock frame"
	reinforced = TRUE

#undef CONSTRUCTION_COMPLETE
#undef CONSTRUCTION_PANEL_OPEN
#undef CONSTRUCTION_WIRES_EXPOSED
#undef CONSTRUCTION_GUTTED
#undef CONSTRUCTION_NOCIRCUIT
