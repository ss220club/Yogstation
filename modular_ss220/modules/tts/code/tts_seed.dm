#define STRIP_HTML_SIMPLE(text, limit) (GLOB.angular_brackets.Replace(copytext(text, 1, limit), ""))

/datum/tts_seed
	var/name = "STUB"
	var/value = "STUB"
	var/category = TTS_CATEGORY_OTHER
	var/gender = TTS_GENDER_ANY
	var/datum/tts_provider/provider = /datum/tts_provider
	var/donator_level = 0

/datum/tts_seed/vv_edit_var(var_name, var_value)
	return FALSE

/datum/preference/text
	abstract_type = /datum/preference/text

	/// What is the maximum length of the value allowed in this field?
	var/maximum_value_length = 256


/datum/preference/text/deserialize(input, datum/preferences/preferences)
	return copytext(input, 1, maximum_value_length)

/datum/preference/text/create_default_value()
	return ""

/datum/preference/text/is_valid(value)
	return istext(value) && length(value) < maximum_value_length

/datum/preference/text/compile_constant_data()
	return list("maximum_length" = maximum_value_length)

/datum/preference/text/tts_seed
	savefile_key = "tts_seed"
	savefile_identifier = PREFERENCE_CHARACTER

/datum/preference/text/tts_seed/create_default_value()
	return "Arthas"

/// Any movable atom
/atom/movable
	var/tts_seed

/datum/preference/text/tts_seed/apply_to_human(mob/living/carbon/human/target, value)
	target.tts_seed = value
