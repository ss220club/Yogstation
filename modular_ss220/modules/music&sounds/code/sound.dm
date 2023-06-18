/client/playtitlemusic(vol = 50)
	if(!SSticker || !SSticker.login_music)
		return
	if(prefs && (prefs.toggles & SOUND_LOBBY))
		SEND_SOUND(src, sound(SSticker.login_music, repeat = 0, wait = 0, volume = 20, channel = CHANNEL_LOBBYMUSIC))
