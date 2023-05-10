/datum/status_effect/toxic_buildup
	id = "toxic_buildup"
	duration = -1 // we handle this ourselves
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/toxic_buildup
	var/stack = 0
	var/max_stack = 4
	var/stack_decay_time = 1 MINUTES
	var/current_stack_decay = 0

/datum/status_effect/toxic_buildup/on_creation(mob/living/new_owner, ...)
	. = ..()
	RegisterSignal(new_owner,COMSIG_REGEN_CORE_HEALED,.proc/cure)
	update_stack(1)

/datum/status_effect/toxic_buildup/tick()
	current_stack_decay += initial(tick_interval)
	if(current_stack_decay >= stack_decay_time)
		current_stack_decay = 0
		on_stack_decay()
		update_stack(-1)
		if(stack <= 0)
			qdel(src)
			return

	if(!ishuman(owner))
		return 
	var/mob/living/carbon/human/human_owner = owner	

	if(prob(10))
		if(!isipc(human_owner))
			to_chat(human_owner,span_alert("The toxins run a course through your veins, you feel sick."))	
			human_owner.adjust_disgust(5)
		else 
			to_chat(human_owner,span_alert("You are covered in a corrosive substance, it digs deep into your plating!"))
			human_owner.adjustToxLoss(5)


	switch(stack)
		if(1)
			human_owner.adjustToxLoss(0.5)
		if(2)
			human_owner.adjustToxLoss(1)
			if(prob(1))
				human_owner.vomit()
				current_stack_decay += 5 SECONDS
		if(3)
			human_owner.adjustToxLoss(2)
			if(prob(2))
				human_owner.vomit()
				current_stack_decay += 5 SECONDS
		if(4)
			human_owner.adjustToxLoss(3)
			if(prob(5))
				human_owner.vomit()
				current_stack_decay += 5 SECONDS


/datum/status_effect/toxic_buildup/proc/on_stack_decay()
	if(!ishuman(owner))
		return 
	var/mob/living/carbon/human/human_owner = owner	

	switch(stack)
		if(1)
			human_owner.adjustStaminaLoss(75)
			human_owner.adjustOrganLoss(ORGAN_SLOT_LIVER,10)
		if(2)
			human_owner.Jitter(1)
			human_owner.adjustStaminaLoss(150)
			human_owner.adjustOrganLoss(ORGAN_SLOT_LIVER,10)
		if(3)
			human_owner.Jitter(1)
			human_owner.Dizzy(1)
			human_owner.adjustStaminaLoss(300)
			human_owner.Paralyze(3 SECONDS)
			human_owner.adjustOrganLoss(ORGAN_SLOT_LIVER,10)
		if(4)
			human_owner.adjust_blurriness(0.5)
			human_owner.Dizzy(1)
			human_owner.Jitter(1)
			human_owner.adjustStaminaLoss(450)
			human_owner.Sleeping(5 SECONDS)
			human_owner.adjustOrganLoss(ORGAN_SLOT_LIVER,20)

/datum/status_effect/toxic_buildup/proc/cure()
	to_chat(owner,span_alert("The toxins are washed away from your body, you feel better."))
	qdel(src)

/datum/status_effect/toxic_buildup/proc/update_stack(amt)
	stack = min(stack + amt,max_stack)
	linked_alert = owner.throw_alert(id,alert_type,stack)

/datum/status_effect/toxic_buildup/refresh()
	update_stack(1)
	current_stack_decay = 0

/atom/movable/screen/alert/status_effect/toxic_buildup
	name = "Toxic buildup"
	desc = "Toxins have built up in your system, they cause sustained toxin damage, and once they leave your system cause additional harm as your bodies adjustments to the toxicity backfire. Maybe something the dryads have could help?"
	icon = 'yogstation/icons/mob/screen_alert.dmi'
	icon_state = "toxic_buildup"

/atom/movable/screen/alert/status_effect/tar_curse
	name = "Curse of Tar"
	desc = "You've been cursed by the tar priest, next attack by any tar monster will cause more damage and may have additional effects."
	icon = 'yogstation/icons/mob/screen_alert.dmi'
	icon_state = "tar_curse"

/datum/status_effect/tar_curse
	id = "tar_curse"
	duration = 60 SECONDS// we handle this ourselves
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/tar_curse


/datum/status_effect/tar_curse/on_apply()
	. = ..()
	RegisterSignal(owner,COMSIG_JUNGLELAND_TAR_CURSE_PROC,.proc/curse_used)

/datum/status_effect/tar_curse/proc/curse_used()
	qdel(src)


/atom/movable/screen/alert/status_effect/dryad
	name = "Blessing of the forest"
	desc = "The heart of the dryad fuels you, it's tendrils engulfed you temporarily increasing your capabilities"
	icon = 'yogstation/icons/mob/screen_alert.dmi'
	icon_state = "dryad_heart"

/datum/status_effect/regenerative_core/dryad
	alert_type = /atom/movable/screen/alert/status_effect/dryad

/datum/status_effect/corrupted_dryad
	id = "corrupted_dryad"
	duration = 80 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/corrupted_dryad
	var/health_multiplier = 1.5
	var/initial_health = 100

/datum/status_effect/corrupted_dryad/on_apply()
	. = ..()
	initial_health = owner.maxHealth
	owner.setMaxHealth(initial_health * health_multiplier)
	owner.adjustBruteLoss(-50)
	owner.adjustFireLoss(-50)
	owner.remove_CC()
	owner.bodytemperature = BODYTEMP_NORMAL
	ADD_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, id)
	SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "corruption", /datum/mood_event/corrupted_dryad)

/datum/status_effect/corrupted_dryad/on_remove()
	owner.setMaxHealth(initial_health)
	if(iscarbon(owner))
		var/mob/living/carbon/C = owner
		C.vomit(10, TRUE, TRUE, 3)
	owner.Dizzy(30)
	owner.Jitter(30)
	REMOVE_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, id)
	SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "corruption", /datum/mood_event/corrupted_dryad_bad)
	return ..()

/atom/movable/screen/alert/status_effect/corrupted_dryad
	name = "Corruption of the forest"
	desc = "Your heart beats unnaturally strong, you feel empowered, but nothing is bound to last..."
	icon = 'yogstation/icons/mob/screen_alert.dmi'
	icon_state = "rage"

/datum/status_effect/tar_shield
	id = "tar_shield"
	duration = 5 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	var/mutable_appearance/cached_image
	alert_type = null

/datum/status_effect/tar_shield/on_apply()
	. = ..()
	cached_image = mutable_appearance('yogstation/icons/effects/effects.dmi',"tar_shield")
	owner.add_overlay(cached_image)
	RegisterSignal(owner,COMSIG_MOB_CHECK_SHIELDS,.proc/react_to_attack)

/datum/status_effect/tar_shield/on_remove()
	owner.cut_overlay(cached_image)
	UnregisterSignal(owner,COMSIG_MOB_CHECK_SHIELDS)
	. = ..()
	
/datum/status_effect/tar_shield/proc/react_to_attack(datum/source ,atom/AM, var/damage, attack_text, attack_type, armour_penetration)
	new /obj/effect/better_animated_temp_visual/tar_shield_pop(get_turf(owner))
	owner.visible_message(span_danger("[owner]'s shields absorbs [attack_text]!"))
	qdel(src)

/datum/status_effect/bounty_of_the_forest
	id = "bounty_of_the_forest"
	duration = -1 // we handle this ourselves
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/bounty_of_the_forest
	var/stack = 0
	var/max_stack = 4
	var/stack_decay_time = 5 SECONDS
	var/current_stack_decay = 0

	var/healing_per_stack = 2

/datum/status_effect/bounty_of_the_forest/tick()
	current_stack_decay += initial(tick_interval)
	if(current_stack_decay >= stack_decay_time)
		current_stack_decay = 0
		update_stack(-1)
		if(stack <= 0)
			qdel(src)
			return

	if(!ishuman(owner))
		return 
	var/mob/living/carbon/human/human_owner = owner

	human_owner.adjustBruteLoss(-healing_per_stack * (stack + 1))
	human_owner.adjustFireLoss(-healing_per_stack * (stack + 1))
	human_owner.adjustToxLoss(-healing_per_stack * (stack + 1))
	human_owner.adjustOxyLoss(-healing_per_stack * (stack + 1))

/datum/status_effect/bounty_of_the_forest/proc/update_stack(amt)
	stack = min(stack + amt,max_stack)
	linked_alert = owner.throw_alert(id,alert_type,stack)

/datum/status_effect/bounty_of_the_forest/refresh()
	update_stack(1)
	current_stack_decay = 0

/datum/status_effect/bounty_of_the_forest/on_creation(mob/living/new_owner, ...)
	. = ..()
	update_stack(1)
/atom/movable/screen/alert/status_effect/bounty_of_the_forest
	name = "Bounty of the forest"
	desc = "The forest takes and the forest provides. In this circumstance I'm on the better end of the stick."
	icon = 'yogstation/icons/mob/screen_alert.dmi'
	icon_state = "bounty_of_the_forest"

