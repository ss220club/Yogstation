/datum/gas/oxygen
	id = GAS_O2
	specific_heat = 20
	name = "Oxygen"

/datum/gas/nitrogen
	id = GAS_N2
	specific_heat = 20
	name = "Nitrogen"
	breath_alert_info = list(
		not_enough_alert = list(
			alert_category = "not_enough_nitro",
			alert_type = /atom/movable/screen/alert/not_enough_nitro
		),
		too_much_alert = list(
			alert_category = "too_much_nitro",
			alert_type = /atom/movable/screen/alert/too_much_nitro
		)
	)

/datum/gas/carbon_dioxide //what the fuck is this?
	id = GAS_CO2
	specific_heat = 30
	name = "Carbon Dioxide"
	breath_results = GAS_O2
	breath_alert_info = list(
		not_enough_alert = list(
			alert_category = "not_enough_co2",
			alert_type = /atom/movable/screen/alert/not_enough_co2
		),
		too_much_alert = list(
			alert_category = "too_much_co2",
			alert_type = /atom/movable/screen/alert/too_much_co2
		)
	)

/datum/gas/plasma
	id = GAS_PLASMA
	specific_heat = 200
	name = "Plasma"
	gas_overlay = "plasma"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS

/datum/gas/water_vapor
	id = GAS_H2O
	specific_heat = 40
	name = "Water Vapor"
	gas_overlay = "water_vapor"
	moles_visible = MOLES_GAS_VISIBLE
	breath_reagent = /datum/reagent/water
	fusion_power = 8

/datum/gas/hypernoblium
	id = GAS_HYPERNOB
	specific_heat = 2000
	name = "Hyper-noblium"
	gas_overlay = "freon"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS

/datum/gas/nitrous_oxide
	id = GAS_NITROUS
	specific_heat = 40
	name = "Nitrous Oxide"
	gas_overlay = "nitrous_oxide"
	moles_visible = MOLES_GAS_VISIBLE * 2
	fusion_power = 10
	flags = GAS_FLAG_DANGEROUS

/datum/gas/nitrium
	id = GAS_NITRIUM
	specific_heat = 10
	name = "Nitrium"
	gas_overlay = "nitrium"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 7

/datum/gas/tritium
	id = GAS_TRITIUM
	specific_heat = 10
	name = "Tritium"
	gas_overlay = "tritium"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 1

/datum/gas/bz
	id = GAS_BZ
	specific_heat = 20
	name = "BZ"
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 8

/datum/gas/pluoxium
	id = GAS_PLUOXIUM
	specific_heat = 80
	name = "Pluoxium"
	fusion_power = -10

/datum/gas/miasma
	id = GAS_MIASMA
	specific_heat = 20
	name = "Miasma"
	gas_overlay = "miasma"
	moles_visible = MOLES_GAS_VISIBLE * 60

/datum/gas/freon
	id = GAS_FREON
	specific_heat = 600
	name = "Freon"
	gas_overlay = "freon"
	moles_visible = MOLES_GAS_VISIBLE *30
	fusion_power = -5

/datum/gas/hydrogen
	id = GAS_H2
	specific_heat = 15
	name = "Hydrogen"
	flags = GAS_FLAG_DANGEROUS

/datum/gas/healium
	id = GAS_HEALIUM
	specific_heat = 10
	name = "Healium"
	gas_overlay = "healium"
	moles_visible = MOLES_GAS_VISIBLE

/datum/gas/pluonium
	id = GAS_PLUONIUM
	specific_heat = 30
	name = "Pluonium"
	flags = GAS_FLAG_DANGEROUS
	gas_overlay = "pluonium"
	moles_visible = MOLES_GAS_VISIBLE

/datum/gas/halon
	id = GAS_HALON
	specific_heat = 175
	name = "Halon"
	flags = GAS_FLAG_DANGEROUS
	gas_overlay = "halon"
	moles_visible = MOLES_GAS_VISIBLE

/datum/gas/antinoblium
	id = GAS_ANTINOB
	specific_heat = 1
	name = "Antinoblium"
	gas_overlay = "antinoblium"
	moles_visible = MOLES_GAS_VISIBLE
	fusion_power = 20

/datum/gas/zauker
	id = GAS_ZAUKER
	specific_heat = 350
	name = "Zauker"
	flags = GAS_FLAG_DANGEROUS
	gas_overlay = "zauker"
	moles_visible = MOLES_GAS_VISIBLE

/datum/gas/hexane
	id = GAS_HEXANE
	specific_heat = 5
	name = "Hexane"
	flags = GAS_FLAG_DANGEROUS
	gas_overlay = "hexane"
	moles_visible = MOLES_GAS_VISIBLE

/datum/gas/dilithium // Main point is that this helps fusion occur at a significantly lower temperature than normal
	id = GAS_DILITHIUM
	specific_heat = 55
	name = "Dilithium"
	fusion_power = 1
