/*
Contains helper procs for airflow, handled in /connection_group.
*/

/mob/var/tmp/last_airflow_stun = 0
/mob/proc/airflow_stun()
	if(stat == 2)
		return 0
	if(last_airflow_stun > world.time - GLOB.vsc.airflow_stun_cooldown)	return 0

	if(!(status_flags & CANSTUN) && !(status_flags & CANWEAKEN))
		to_chat(src, SPAN_NOTICE("You stay upright as the air rushes past you."))
		return 0
	if(buckled_to)
		to_chat(src, SPAN_NOTICE("Air suddenly rushes past you!"))
		return 0
	if(!lying)
		to_chat(src, SPAN_WARNING("The sudden rush of air knocks you over!"))
	Weaken(5)
	last_airflow_stun = world.time

/mob/living/silicon/airflow_stun()
	return

/mob/living/carbon/slime/airflow_stun()
	return

/mob/living/carbon/human/airflow_stun()
	if(shoes)
		if(shoes.item_flags & ITEM_FLAG_NO_SLIP) return 0
	..()

/atom/movable/proc/check_airflow_movable(n)

	if(anchored && !ismob(src)) return 0

	if(!istype(src,/obj/item) && n < GLOB.vsc.airflow_dense_pressure) return 0

	return 1

/mob/check_airflow_movable(n)
	if(n < GLOB.vsc.airflow_heavy_pressure)
		return 0
	return 1

/mob/abstract/ghost/observer/check_airflow_movable()
	return 0

/mob/living/silicon/check_airflow_movable()
	return 0


/obj/item/check_airflow_movable(n)
	. = ..()
	switch(w_class)
		if(2)
			if(n < GLOB.vsc.airflow_lightest_pressure) return 0
		if(3)
			if(n < GLOB.vsc.airflow_light_pressure) return 0
		if(4,5)
			if(n < GLOB.vsc.airflow_medium_pressure) return 0

/atom/movable/var/tmp/turf/airflow_dest
/atom/movable/var/tmp/airflow_speed = 0
/atom/movable/var/tmp/airflow_time = 0
/atom/movable/var/tmp/last_airflow = 0

/atom/movable/proc/AirflowCanMove(n)
	return 1

/mob/AirflowCanMove(n)
	if(status_flags & GODMODE)
		return 0
	if(buckled_to)
		return 0
	var/obj/item/shoes = get_equipped_item(slot_shoes)
	if(istype(shoes) && (shoes.item_flags & ITEM_FLAG_NO_SLIP))
		return 0
	return 1

/*
/atom/movable/proc/GotoAirflowDest(n)
	and
/atom/movable/proc/RepelAirflowDest(n)
	have been moved to SSairflow.

*/

/atom/movable/proc/airflow_hit(atom/A)
	airflow_speed = 0
	airflow_dest = null

/mob/airflow_hit(atom/A)
	for(var/mob/M in hearers(src))
		M.show_message(SPAN_DANGER("\The [src] slams into \a [A]!"),1,
						SPAN_DANGER("You hear a loud slam!"),2)

	playsound(src.loc, 'sound/weapons/smash.ogg', 25, 1, -1)
	var/weak_amt
	if(istype(A, /obj/item))
		var/obj/item/I = A
		weak_amt = I.w_class
	else
		weak_amt = rand(1, 5)
	Weaken(weak_amt)
	. = ..()

/obj/airflow_hit(atom/A)
	for(var/mob/M in hearers(src))
		M.show_message(SPAN_DANGER("\The [src] slams into \a [A]!"),1,
						SPAN_DANGER("You hear a loud slam!"),2)

	playsound(src.loc, 'sound/weapons/smash.ogg', 25, 1, -1)
	. = ..()

/obj/item/airflow_hit(atom/A)
	airflow_speed = 0
	airflow_dest = null

/mob/living/carbon/human/airflow_hit(atom/A)
//	for(var/mob/M in hearers(src))
//		M.show_message(SPAN_DANGER("[src] slams into [A]!</span>",1,"<span class='danger'>You hear a loud slam!"),2)
	playsound(src.loc, /singleton/sound_category/punch_sound, 25, 1, -1)
	if (prob(33))
		loc:add_blood(src)
		bloody_body(src)
	var/b_loss = airflow_speed * GLOB.vsc.airflow_damage

	apply_damage(b_loss/3, DAMAGE_BRUTE, BP_HEAD, used_weapon = "Airflow")
	apply_damage(b_loss/3, DAMAGE_BRUTE, BP_CHEST, used_weapon = "Airflow")
	apply_damage(b_loss/3, DAMAGE_BRUTE, BP_GROIN, used_weapon = "Airflow")

	if(airflow_speed > 10)
		Paralyse(round(airflow_speed * GLOB.vsc.airflow_stun))
		Stun(paralysis + 3)
	else
		Stun(round(airflow_speed * GLOB.vsc.airflow_stun/2))
	. = ..()

/zone/proc/movables(list/origins)
	. = list()
	if (!origins?.len)
		return

	var/static/list/movables_tcache = typecacheof(list(/obj/effect, /mob/abstract))

	var/atom/movable/AM
	for (var/testing_turf in contents)
		CHECK_TICK
		for (var/am in testing_turf)
			AM = am
			CHECK_TICK
			if (AM.simulated && !AM.anchored && !movables_tcache[AM.type])
				for (var/source_turf in origins)
					if (get_dist(testing_turf, source_turf) <= EDGE_KNOCKDOWN_MAX_DISTANCE)
						.[AM] = TRUE
						break

					CHECK_TICK
