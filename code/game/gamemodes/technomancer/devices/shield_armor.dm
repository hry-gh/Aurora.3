/datum/technomancer/equipment/shield_armor
	name = "Personal Shield Projector"
	desc = "This state-of-the-art technology uses the bleeding edge of energy distribution and field projection \
	to provide a personal shield around you, which can diffuse laser beams and reduce the velocity of bullets and close quarters \
	weapons, reducing their potential for harm severely.  All of this comes at a cost of of requiring a large amount of energy, \
	of which your Core can provide.  When you are struck by something, the shield will block 75% of the damage, deducting energy \
	proportional to the amount of force that was inflicted.  Armor penetration has no effect on the shield's ability to protect \
	you from harm, however the shield will fail if the energy supply cannot meet demand."
	cost = 200
	obj_path = /obj/item/clothing/suit/armor/shield

/obj/item/clothing/suit/armor/shield
	name = "shield projector"
	desc = "This armor has no inherent ability to absorb shock, as normal armor usually does.  Instead, this emits a strong field \
	around the wearer, designed to protect from most forms of harm, from lasers to bullets to close quarters combat.  It appears to \
	require a very potent supply of an energy of some kind in order to function."
	icon_state = "shield_armor_0"
	blood_overlay_type = "armor"
	slowdown = 0
	armor = list(
		MELEE = 0,
		BULLET = 0,
		LASER = 0,
		ENERGY = 0,
		BOMB = 0,
		BIO = 0,
		RAD = 0
	)
	action_button_name = "Toggle Shield Projector"
	var/active = 0
	var/damage_to_energy_multiplier = 50.0 //Determines how much energy to charge for blocking, e.g. 20 damage attack = 750 energy cost
	var/block_percentage = 75

/obj/item/clothing/suit/armor/shield/New()
	..()
	spark(src, 5, GLOB.cardinals)

/obj/item/clothing/suit/armor/shield/handle_shield(mob/user, var/on_back, var/damage, atom/damage_source = null, mob/attacker = null, var/def_zone = null, var/attack_text = "the attack")
	//Since this is a pierce of armor that is passive, we do not need to check if the user is incapacitated.
	if(!active)
		return BULLET_ACT_HIT

	var/modified_block_percentage = block_percentage

	if(issmall(user)) // Smaller shield means better protection.
		modified_block_percentage += 15


	var/damage_blocked = damage * (modified_block_percentage / 100)

	var/damage_to_energy_cost = (damage_to_energy_multiplier * damage_blocked)

	if(!user.technomancer_pay_energy(damage_to_energy_cost))
		to_chat(user, SPAN_DANGER("Your shield fades due to lack of energy!"))
		active = 0
		update_icon()
		return BULLET_ACT_HIT

	damage = damage - damage_blocked

	if(istype(damage_source, /obj/projectile))
		var/obj/projectile/P = damage_source
		P.sharp = 0
		P.edge = 0
		P.embed_chance = 0
		if(P.agony)
			var/agony_blocked = P.agony * (modified_block_percentage / 100)
			P.agony -= agony_blocked
		P.damage = P.damage - damage_blocked

	user.visible_message(SPAN_DANGER("\The [user]'s [src] absorbs [attack_text]!"))
	to_chat(user, SPAN_WARNING("Your shield has absorbed most of \the [damage_source]."))

	spark(src, 5, GLOB.cardinals)
	playsound(src, 'sound/weapons/blade.ogg', 50, 1)
	return BULLET_ACT_HIT // This shield does not block all damage, so returning 0 is needed to tell the game to apply the new damage.

/obj/item/clothing/suit/armor/shield/attack_self(mob/user)
	active = !active
	to_chat(user, SPAN_NOTICE("You [active ? "" : "de"]activate \the [src]."))
	update_icon()
	user.update_inv_wear_suit()
	user.update_action_buttons()

/obj/item/clothing/suit/armor/shield/update_icon()
	icon_state = "shield_armor_[active]"
	item_state = "shield_armor_[active]"
	if(active)
		set_light(2, 1, l_color = "#006AFF")
	else
		set_light(0, 0, l_color = "#000000")
	..()
	return
