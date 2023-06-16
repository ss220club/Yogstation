/obj/item/organ/body_egg
	name = "body egg"
	desc = "All slimy and yuck."
	icon_state = "innards"
	visual = TRUE
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_PARASITE_EGG

/obj/item/organ/body_egg/on_find(mob/living/finder)
	..()
	to_chat(finder, span_warning("You found an unknown alien organism in [owner]'s [zone]!"))

/obj/item/organ/body_egg/New(loc)
	if(iscarbon(loc))
		src.Insert(loc)
	return ..()

/obj/item/organ/body_egg/Insert(mob/living/carbon/M, special = 0)
	..()
	ADD_TRAIT(owner, TRAIT_XENO_HOST, TRAIT_GENERIC)
	START_PROCESSING(SSobj, src)
	owner.med_hud_set_status()
	INVOKE_ASYNC(src, PROC_REF(AddInfectionImages), owner)

/obj/item/organ/body_egg/Remove(mob/living/carbon/M, special = 0)
	STOP_PROCESSING(SSobj, src)
	if(owner)
		REMOVE_TRAIT(owner, TRAIT_XENO_HOST, TRAIT_GENERIC)
		owner.med_hud_set_status()
		INVOKE_ASYNC(src, PROC_REF(RemoveInfectionImages), owner)
	..()

/obj/item/organ/body_egg/process()
	if(!owner)
		return
	if(!(src in owner.internal_organs))
		Remove(owner)
		return
	egg_process()

/obj/item/organ/body_egg/proc/egg_process()
	return

/obj/item/organ/body_egg/proc/RefreshInfectionImage()
	RemoveInfectionImages()
	AddInfectionImages()

/obj/item/organ/body_egg/proc/AddInfectionImages()
	return

/obj/item/organ/body_egg/proc/RemoveInfectionImages()
	return
