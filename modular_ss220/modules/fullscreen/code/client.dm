/datum/keybinding/client/fullscreen
	hotkey_keys = list("F11")
	name = "fullscreen"
	full_name = "Toggle Fullscreen"
	description = "Toggles fullscreen."	

/datum/keybinding/client/fullscreen/down(client/user)
	. = ..()
	user.toggle_fullscreen()
	return TRUE
