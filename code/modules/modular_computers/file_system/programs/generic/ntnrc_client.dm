/datum/computer_file/program/chat_client
	filename = "ntnrc_client"
	filedesc = "Chat Client"
	program_icon_state = "command"
	program_key_icon_state = "green_key"
	extended_desc = "This program allows communication over the NTRC network."
	size = 2
	requires_ntnet_feature = NTNET_COMMUNICATION
	program_type = PROGRAM_TYPE_ALL
	network_destination = "NTRC server"
	color = LIGHT_COLOR_GREEN

	var/datum/ntnet_user/my_user
	var/datum/ntnet_conversation/focused_conv

	var/netadmin_mode = FALSE		// Administrator mode (invisible to other users + bypasses passwords)
	var/set_offline = FALSE			// appear "invisible"
	var/ringtone = "beep"
	var/message_mute = FALSE
	var/syndi_auth = FALSE

/datum/computer_file/program/chat_client/Destroy()
	return ..()

/datum/computer_file/program/chat_client/proc/can_receive_notification(var/datum/computer_file/program/chat_client/from)
	return ((program_state > PROGRAM_STATE_KILLED || service_state > PROGRAM_STATE_KILLED) && from != src && get_signal(NTNET_COMMUNICATION))

/datum/computer_file/program/chat_client/proc/play_notification_sound(var/datum/computer_file/program/chat_client/from)
	if(!silent && src != from && (program_state == PROGRAM_STATE_BACKGROUND || (program_state == PROGRAM_STATE_KILLED && service_state == PROGRAM_STATE_ACTIVE)))
		playsound(computer, 'sound/machines/twobeep.ogg', 50, 1)
		computer.output_message("[icon2html(computer, world)] *[ringtone]*", 2)

/datum/computer_file/program/chat_client/service_activate()
	. = ..()
	if(istype(my_user) && get_signal(NTNET_COMMUNICATION))
		activate_chat_client()
		return TRUE
	else
		return FALSE

/datum/computer_file/program/chat_client/service_deactivate()
	. = ..()
	deactivate_chat_client()

/datum/computer_file/program/chat_client/run_program(var/mob/user)
	if(!istype(my_user))
		if(istype(computer, /obj/item/modular_computer/silicon))
			var/obj/item/modular_computer/silicon/SC = computer
			var/mob/living/silicon/S = SC.computer_host
			S.id_card.InitializeChatUser()
			my_user = S.id_card.chat_user
		else
			if((!computer.registered_id && !computer.register_account(src)))
				return
	if(service_state == PROGRAM_STATE_DISABLED)
		computer.enable_service(null, user, src)
	if(computer.hidden_uplink && syndi_auth)
		if(alert(user, "Resume or close and secure?", filedesc, "Resume", "Close") == "Resume")
			computer.hidden_uplink.trigger(user)
			return
		else
			syndi_auth = FALSE
	return ..(user)

/datum/computer_file/program/chat_client/event_registered()
	. = ..()
	computer.registered_id.InitializeChatUser()
	my_user = computer.registered_id.chat_user
	if(service_state > PROGRAM_STATE_KILLED)
		activate_chat_client()
	computer.update_static_data_for_all_viewers()

/datum/computer_file/program/chat_client/event_unregistered()
	. = ..()
	if(service_state > PROGRAM_STATE_KILLED)
		deactivate_chat_client()
	my_user = null
	computer.update_static_data_for_all_viewers()

/datum/computer_file/program/chat_client/event_silentmode()
	. = ..()
	silent = computer.silent
	computer.update_static_data_for_all_viewers()

/datum/computer_file/program/chat_client/event_networkfailure(background)
	computer.update_static_data_for_all_viewers()
	return ..()

/datum/computer_file/program/chat_client/proc/activate_chat_client()
	if(!istype(my_user))
		return
	if(!(src in my_user.clients))
		my_user.clients.Add(src)
	if(!(src in ntnet_global.chat_clients))
		ntnet_global.chat_clients.Add(src)
	computer.update_static_data_for_all_viewers()

/datum/computer_file/program/chat_client/proc/deactivate_chat_client()
	if(!istype(my_user))
		return
	if(src in my_user.clients)
		my_user.clients.Remove(src)
	if(src in ntnet_global.chat_clients)
		ntnet_global.chat_clients.Remove(src)
	computer.update_static_data_for_all_viewers()

/datum/computer_file/program/chat_client/ui_static_data(mob/user)
	var/list/data = list()
	data["service"] = service_state > PROGRAM_STATE_KILLED
	data["registered"] = istype(my_user)
	data["signal"] = get_signal(NTNET_COMMUNICATION)
	data["ringtone"] = ringtone
	data["netadmin_mode"] = netadmin_mode
	data["can_netadmin_mode"] = can_run(user, FALSE, access_network)
	data["message_mute"] = message_mute

	if(istype(my_user) && get_signal(NTNET_COMMUNICATION) && (service_state > PROGRAM_STATE_KILLED))
		data["channels"] = list()
		for(var/c in ntnet_global.chat_channels)
			var/datum/ntnet_conversation/channel = c
			if(istype(channel) && (channel.can_see(src)))
				var/ref = text_ref(channel)
				var/can_interact = channel.can_interact(src)
				var/can_manage = channel.can_manage(src)
				data["channels"][ref] = list(
					"title" = channel.get_title(src),
					"direct" = channel.direct,
					"password" = !!channel.password,
					"can_interact" = can_interact,
					"can_manage" = can_manage,
					"focused" = (focused_conv == channel)
				)
				if(can_interact)
					data["channels"][ref]["msg"] = channel.messages
					data["channels"][ref]["users"] = list()
					for(var/datum/ntnet_user/U in channel.users)
						var/uref = text_ref(U)
						data["channels"][ref]["users"][uref] = U.username

		data["users"] = list()
		for(var/u in ntnet_global.chat_users)
			var/datum/ntnet_user/ntnet_user = u
			if(ntnet_user != my_user)
				data["users"][text_ref(ntnet_user)] = ntnet_user.username

	return data

/datum/computer_file/program/chat_client/ui_data(mob/user)
	var/list/data = list()
	return data

/datum/computer_file/program/chat_client/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE

	if(action == "ringtone")
		var/new_ringtone = params["ringtone"]
		var/obj/item/device/uplink/hidden/H = computer.hidden_uplink
		if(istype(H) && H.check_trigger(usr, lowertext(new_ringtone), lowertext(H.pda_code)))
			to_chat(usr, SPAN_NOTICE("\The [computer] softly beeps."))
			syndi_auth = TRUE
			SStgui.close_uis(src)
		else
			new_ringtone = sanitize(new_ringtone, 20)
			ringtone = new_ringtone
			computer.update_static_data_for_all_viewers()

/datum/computer_file/program/chat_client/Topic(href, href_list)
	if(..())
		return TRUE

	if(href_list["ringtone"])
		var/newRingtone = href_list["ringtone"]
		var/obj/item/device/uplink/hidden/H = computer.hidden_uplink
		if(istype(H) && H.check_trigger(usr, lowertext(newRingtone), lowertext(H.pda_code)))
			to_chat(usr, SPAN_NOTICE("\The [computer] softly beeps."))
			syndi_auth = TRUE
			SSvueui.close_uis(src)
		else
			newRingtone = sanitize(newRingtone, 20)
			ringtone = newRingtone
			SSvueui.check_uis_for_change(src)

	if(href_list["mute_message"])
		message_mute = !message_mute
		SSvueui.check_uis_for_change(src)

	// User only commands
	if(!istype(my_user))
		return
	// Following actions require signal
	if(!get_signal(NTNET_COMMUNICATION))
		to_chat(usr, FONT_SMALL(SPAN_WARNING("\The [src] displays, \"NETWORK ERROR - Unable to connect to NTNet. Please retry. If problem persists, contact your system administrator.\".")))
		return

	if(href_list["send"])
		var/mob/living/user = usr
		var/datum/ntnet_conversation/conv = locate(href_list["send"]["target"])
		var/message = href_list["send"]["message"]
		if(istype(conv) && message)
			if(ishuman(user))
				user.visible_message("[SPAN_BOLD("\The [user]")] taps on [user.get_pronoun("his")] [computer.lexical_name]'s screen.")
			conv.cl_send(src, message, user)
	if(href_list["focus"])
		var/mob/living/user = usr
		var/datum/ntnet_conversation/conv = locate(href_list["focus"])
		if(istype(conv))
			if(ishuman(user))
				user.visible_message("[SPAN_BOLD("\The [user]")] taps on [user.get_pronoun("his")] [computer.lexical_name]'s screen.")
			if(focused_conv == conv)
				focused_conv = null
			else
				focused_conv = conv
				computer.become_hearing_sensitive()
		SSvueui.check_uis_for_change(src)
	if(href_list["join"])
		var/datum/ntnet_conversation/conv = locate(href_list["join"]["target"])
		var/password = href_list["join"]["password"]
		if(istype(conv))
			if(conv.password)
				if(conv.password == password)
					conv.cl_join(src)
				else
					// How do I alert of password invalid?
			else
				conv.cl_join(src)
	if(href_list["leave"])
		var/datum/ntnet_conversation/conv = locate(href_list["leave"])
		if(istype(conv))
			conv.cl_leave(src)
		SSvueui.check_uis_for_change(src)
	if(href_list["kick"])
		var/datum/ntnet_conversation/conv = locate(href_list["kick"]["target"])
		var/datum/ntnet_user/tUser = locate(href_list["kick"]["user"])
		if(istype(conv) && istype(tUser))
			conv.cl_kick(src, tUser)
	if(href_list["set_password"])
		var/datum/ntnet_conversation/conv = locate(href_list["set_password"]["target"])
		var/password = href_list["set_password"]["password"]
		if(istype(conv))
			conv.cl_set_password(src, password)
	if(href_list["change_title"])
		var/datum/ntnet_conversation/conv = locate(href_list["change_title"]["target"])
		var/newTitle = href_list["change_title"]["title"]
		if(istype(conv))
			conv.cl_change_title(src, newTitle)
	if(href_list["new_channel"])
		ntnet_global.begin_conversation(src, sanitize(href_list["new_channel"]))
	if(href_list["delete"])
		var/datum/ntnet_conversation/conv = locate(href_list["delete"])
		if(istype(conv) && conv.can_manage(src))
			ntnet_global.chat_channels.Remove(conv)
			qdel(conv)
		SSvueui.check_uis_for_change(src)
	if(href_list["direct"])
		var/datum/ntnet_user/tUser = locate(href_list["direct"])
		ntnet_global.begin_direct(src, tUser)

	if(href_list["toggleadmin"])
		if(netadmin_mode)
			netadmin_mode = FALSE
		else
			var/mob/living/user = usr
			if(can_run(user, TRUE, access_network))
				netadmin_mode = TRUE
		SSvueui.check_uis_for_change(src)
	if(href_list["Reply"])
		var/mob/living/user = usr
		var/datum/ntnet_conversation/conv = locate(href_list["Reply"])
		var/message = input(user, "Enter message or leave blank to cancel: ")
		if(istype(conv) && message)
			if(ishuman(user))
				user.visible_message("[SPAN_BOLD("\The [user]")] taps on [user.get_pronoun("his")] [computer.lexical_name]'s screen.")
			conv.cl_send(src, message, user)
