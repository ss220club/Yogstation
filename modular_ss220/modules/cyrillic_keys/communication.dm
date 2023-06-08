/datum/keybinding/client/communication/say/down(client/user)
	. = ..()
	if(.)
		return
	winset(user, null, "command=.say")
	return TRUE

/datum/keybinding/client/communication/emote/down(client/user)
	. = ..()
	if(.)
		return
	winset(user, null, "command=.me")
	return TRUE

/datum/keybinding/client/communication/ooc/down(client/user)
	. = ..()
	if(.)
		return
	winset(user, null, "command=ooc")
	return TRUE
	
/datum/keybinding/client/communication/looc/down(client/user)
	. = ..()
	if(.)
		return
	winset(user, null, "command=looc")
	return TRUE

