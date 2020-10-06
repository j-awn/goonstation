//MEDBOT
//MEDBOT PATHFINDING
//MEDBOT ASSEMBLY

/obj/machinery/bot/medbot
	name = "Medibot"
	desc = "A little medical robot. He looks somewhat underwhelmed."
	icon = 'icons/obj/bots/medbots.dmi'
	icon_state = "medibot"
	layer = 5.0 //TODO LAYER
	density = 0
	anchored = 0
	luminosity = 2
	req_access = list(access_medical)
	access_lookup = "Medical Doctor"
	flags = NOSPLASH
	on = 1
	health = 20
	var/stunned = 0 //It can be stunned by tasers. Delicate circuits.
	locked = 1

	var/obj/item/reagent_containers/glass/reagent_glass = null //Can be set to draw from this for reagents.
	var/skin = null // options are brute1/2, burn1/2, toxin1/2, brain1/2, O21/2/3/4, berserk1/2/3, and psyche
	var/frustration = 0
	var/list/path = null
	var/mob/living/carbon/patient = null
	var/mob/living/carbon/oldpatient = null
	var/list/current_treatments = list()
	var/oldloc = null
	var/last_found = 0
	var/last_newpatient_speak = 0 //Don't spam the "HEY I'M COMING" messages
	var/currently_healing = 0
	var/injection_amount = 10 //How much reagent do we inject at a time?
	var/heal_threshold = 15 //Start healing when they have this much damage in a category
	var/oxy_additional_heal_threshold = 15 // additional heal threshold for oxy damage
	var/brain_heal_threshold = 10 // hardcoded brain heal threshold
	var/blood_pressure_hypertensive_status = "HYPERTENSIVE"
	var/blood_pressure_hypotensive_status = "HYPOTENSIVE"
	var/histamine_overdose_amount = null
	var/eye_damage_threshold = 12 // hardcoded eye heal threshold
	var/use_beaker = 0 //Use reagents in beaker instead of default treatment agents.
	//Setting which reagents to use to treat what by default. By id.
	var/treatment_brute = "saline"
	var/treatment_oxy = "salbutamol"
	var/treatment_fire = "saline"
	var/treatment_tox = "charcoal"
	var/treatment_virus = "spaceacillin"
	var/treatment_hypertension = null
	var/treatment_hypotension = null
	var/treatment_eye_ear = null
	var/treatment_anaphylaxis = null
	var/treatment_rad = null
	var/treatment_brain = null
	var/treatment_crit = null
	var/treatment_emag = "pancuronium"
	var/treatment_terrifying = "haloperidol"
	var/terrifying = 0 // for making the medbots all super fucked up

/obj/machinery/bot/medbot/no_camera
	no_camera = 1

/obj/machinery/bot/medbot/mysterious
	name = "Mysterious Medibot"
	desc = "International Medibot of mystery."
	skin = "berserk"

/obj/machinery/bot/medbot/terrifying
	name = "Medibot"
	desc = "You don't recognize this model."
	icon = 'icons/misc/evilreaverstation.dmi'
	health = 50
	density = 1
	emagged = 1
	terrifying = 1
	anchored = 1 // don't drag it into space goddamn jerks
	no_camera = 1

/obj/machinery/bot/medbot/head_surgeon
	name = "Medibot - 'Head Surgeon'"
	desc = "The HS sure looks different today! Maybe he got a haircut?"
	skin = "hs"
	access_lookup = "Head Surgeon"
	text2speech = 1

/obj/machinery/bot/medbot/head_surgeon/no_camera
	no_camera = 1

/obj/machinery/bot/medbot/psyche
	name = "Psychedelic Medibot"
	desc = "He's high on a hell of a lot more than life!"
	skin = "psyche"
	treatment_brute = "LSD"
	treatment_oxy = "psilocybin"
	treatment_fire = "LSD"
	treatment_tox = "psilocybin"
	treatment_virus = "loose screws"
	no_camera = 1

/obj/item/firstaid_arm_assembly
	name = "first aid/robot arm assembly"
	desc = "A first aid kit with a robot arm permanently grafted to it."
	icon = 'icons/obj/bots/medbots.dmi'
	icon_state = "medskin-firstaid"
	item_state = "firstaid"
	pixel_y = 4 // so we don't have to have two sets of the skin sprites, we're just gunna bump this up a bit
	var/build_step = 0
	var/created_name = "Medibot" //To preserve the name if it's a unique medbot I guess
	var/skin = null // same as the bots themselves: options are brute1/2, burn1/2, toxin1/2, brain1/2, O21/2/3/4, berserk1/2/3, and psyche
	w_class = 3.0

/obj/item/firstaid_arm_assembly/New()
	..()
	SPAWN_DBG(0.5 SECONDS)
		if (src.skin)
			src.overlays += "medskin-[src.skin]"
			src.overlays += "medibot-arm"

/obj/machinery/bot/medbot/proc/update_icon(var/stun = 0, var/heal = 0)
	if (src.overlays)
		src.overlays = null

	if (src.terrifying)
		src.icon_state = "medibot[src.on]"
		if (stun)
			src.overlays += "medibota"
		if (heal)
			src.overlays += "medibots"
		return

	else
		src.icon_state = "medibot"
		if (src.skin)
			src.overlays += "medskin-[src.skin]"
		src.overlays += "medibot-scanner"
		if (heal)
			src.overlays += "medibot-arm-syringe"
			src.overlays += "medibot-light-flash"
		else
			src.overlays += "medibot-arm"
			if (stun)
				src.overlays += "medibot-light-stun"
			else
				src.overlays += "medibot-light[src.on]"
		/*
		if (emagged)
			src.overlays += "medibot-spark"
		*/
		return

/obj/machinery/bot/medbot/New()
	..()
	add_simple_light("medbot", list(220, 220, 255, 0.5*255))
	SPAWN_DBG(0.5 SECONDS)
		if (src)
			src.botcard = new /obj/item/card/id(src)
			src.botcard.access = get_access(src.access_lookup)
			src.update_icon()
			var/datum/reagent/dummy = /datum/reagent/harmful/histamine // hack to make sure histamine overdose amount is set correctly
			src.histamine_overdose_amount = initial(dummy.overdose)
			if (src.skin)
				src.initialize_custom_skin()
	return

/obj/machinery/bot/medbot/proc/initialize_custom_skin()
	if ((src.skin == "brute1") || (src.skin == "brute2") || (src.skin == "brute3") || (src.skin == "brute3"))
		src.treatment_brute = "salicylic_acid"
		src.treatment_hypertension = "heparin"
		src.treatment_hypotension = "filgrastim"
		src.treatment_emag = "ants"
	else if ((src.skin == "burn1") || (src.skin == "burn2") || (src.skin == "burn3") || (src.skin == "burn4"))
		src.treatment_fire = "menthol"
		src.treatment_eye_ear = "oculine"
		src.treatment_emag = "acetaldehyde"
	else if ((src.skin == "toxin1") || (src.skin == "toxin2") || (src.skin == "toxin3") || (src.skin == "toxin4"))
		src.treatment_tox = "ammoniumbicarbonate"
		src.treatment_rad = "anti_rad"
		src.treatment_emag = "weedkiller"
	else if ((src.skin == "O21") || (src.skin == "O22") || (src.skin == "O23") || (src.skin == "O24"))
		src.treatment_oxy = "perfluorodecalin"
		src.treatment_anaphylaxis = "antihistamine"
		src.treatment_emag = "cyanide"
	else if ((src.skin == "brain1") || (src.skin == "brain2") || (src.skin == "brain3"))
		src.treatment_virus = "robustussin"
		src.treatment_brain = "synaptizine"
		src.treatment_emag = "neurotoxin"
	else if ((src.skin == "berserk1") || (src.skin == "berserk2") || (src.skin == "berserk3"))
		src.treatment_crit = "epinephrine"
		src.treatment_emag = "formaldehyde"
	else if (src.skin == "psych")
		src.treatment_brute = "LSD"
		src.treatment_oxy = "psilocybin"
		src.treatment_fire = "LSD"
		src.treatment_tox = "psilocybin"
		src.treatment_virus = "loose screws"
	else if (src.skin == "hs")
		src.treatment_brute = "salicylic_acid"
		src.treatment_fire = "menthol"
		src.treatment_tox = "smelling_salt"
		src.treatment_oxy = "perfluorodecalin"
		src.treatment_virus = "robustussin"
		src.treatment_emag = "sarin"

/obj/machinery/bot/medbot/attack_ai(mob/user as mob)
	return toggle_power()

/obj/machinery/bot/medbot/attack_hand(mob/user as mob, params)
	if (src.terrifying)
		return

	var/dat
	dat += "<TT><B>Automatic Medical Unit v1.0</B></TT><BR><BR>"
	dat += "Status: <A href='?src=\ref[src];power=1'>[src.on ? "On" : "Off"]</A><BR>"
	dat += "Beaker: "
	if (src.reagent_glass)
		dat += "<A href='?src=\ref[src];eject=1'>Loaded \[[src.reagent_glass.reagents.total_volume]/[src.reagent_glass.reagents.maximum_volume]\]</a>"
	else
		dat += "None Loaded"
	dat += "<br>Behaviour controls are [src.locked ? "locked" : "unlocked"]"
	if (!src.locked)
		dat += "<hr><TT>Healing Threshold: "
		dat += "<a href='?src=\ref[src];adj_threshold=-10'>--</a> "
		dat += "<a href='?src=\ref[src];adj_threshold=-5'>-</a> "
		dat += "[src.heal_threshold] "
		dat += "<a href='?src=\ref[src];adj_threshold=5'>+</a> "
		dat += "<a href='?src=\ref[src];adj_threshold=10'>++</a>"
		dat += "</TT><br>"

		dat += "<TT>Injection Level: "
		dat += "<a href='?src=\ref[src];adj_inject=-5'>-</a> "
		dat += "[src.injection_amount] "
		dat += "<a href='?src=\ref[src];adj_inject=5'>+</a> "
		dat += "</TT><br>"

		dat += "Reagent Source: "
		dat += "<a href='?src=\ref[src];use_beaker=1'>[src.use_beaker ? "Loaded Beaker (When available)" : "Internal Synthesizer"]</a><br>"

	if (user.client.tooltipHolder)
		user.client.tooltipHolder.showClickTip(src, list(
			"params" = params,
			"title" = "Medibot v1.0 controls",
			"content" = dat,
			"size" = "260xauto"
		))

	return

/obj/machinery/bot/medbot/Topic(href, href_list)
	if(..())
		return
	src.add_dialog(usr)
	src.add_fingerprint(usr)
	if ((href_list["power"]) && (src.allowed(usr)))
		src.toggle_power()

	else if ((href_list["adj_threshold"]) && (!src.locked))
		var/adjust_num = text2num(href_list["adj_threshold"])
		src.heal_threshold += adjust_num
		if (src.heal_threshold < 5)
			src.heal_threshold = 5
		if (src.heal_threshold > 75)
			src.heal_threshold = 75

	else if ((href_list["adj_inject"]) && (!src.locked))
		var/adjust_num = text2num(href_list["adj_inject"])
		src.injection_amount += adjust_num
		if (src.injection_amount < 5)
			src.injection_amount = 5
		if (src.injection_amount > 15)
			src.injection_amount = 15

	else if ((href_list["use_beaker"]) && (!src.locked))
		src.use_beaker = !src.use_beaker

	else if (href_list["eject"] && (!isnull(src.reagent_glass)))
		if (!src.locked)
			src.reagent_glass.set_loc(get_turf(src))
			usr.put_in_hand_or_eject(src.reagent_glass) // try to eject it into the users hand, if we can
			src.reagent_glass = null
		else
			boutput(usr, "You cannot eject the beaker because the panel is locked!")

	src.updateUsrDialog()
	return


/obj/machinery/bot/medbot/Move(var/turf/NewLoc, direct)
	..()
	if (src.patient && (get_dist(src,src.patient) <= 1))
		if (!src.currently_healing)
			src.currently_healing = 1
			src.frustration = 0
			src.medicate_patient(src.patient)

/obj/machinery/bot/medbot/emag_act(var/mob/user, var/obj/item/card/emag/E)
	if (!src.emagged)
		if(user)
			boutput(user, "<span class='alert'>You short out [src]'s reagent synthesis circuits.</span>")
		SPAWN_DBG(0)
			for(var/mob/O in hearers(src, null))
				O.show_message("<span class='alert'><B>[src] buzzes oddly!</B></span>", 1)
		src.patient = null
		src.oldpatient = user
		src.currently_healing = 0
		src.last_found = world.time
		src.anchored = 0
		src.emagged = 1
		src.on = 1
		src.update_icon()
		logTheThing("station", user, null, "emagged a [src] at [log_loc(src)].")
		return 1
	return 0


/obj/machinery/bot/medbot/demag(var/mob/user)
	if (!src.emagged)
		return 0
	if (user)
		user.show_text("You repair [src]'s reagent synthesis circuits.", "blue")
	src.emagged = 0
	src.patient = null
	src.oldpatient = user
	src.currently_healing = 0
	src.last_found = world.time
	src.anchored = 0
	src.update_icon()
	return 1

/obj/machinery/bot/medbot/attackby(obj/item/W as obj, mob/user as mob)
	//if (istype(W, /obj/item/card/emag)) // this gets to stay here because it is a good story
		/*
		I caught a fish once, real little feller, it was.
		As I was preparing to throw it back into the lake this gray cat came up to me.
		Without a sound he stands on his hind legs next to me, silently watching what I'm doing.
		He stands like that for several minutes, looking at the fish, then at me, then back at the fish
		Eventually I gave him the fish.
		He followed me home.
		Good catte.

		Also the override is here so you don't thwap the bot with the emag
		*/
		//return
	if (istype(W, /obj/item/device/pda2) && W:ID_card)
		W = W:ID_card
	if (istype(W, /obj/item/card/id))
		if (src.allowed(user))
			src.locked = !src.locked
			boutput(user, "Controls are now [src.locked ? "locked." : "unlocked."]")
			src.updateUsrDialog()
		else
			boutput(user, "<span class='alert'>Access denied.</span>")

	else if (isscrewingtool(W))
		if (src.health < initial(src.health))
			src.health = initial(src.health)
			src.visible_message("<span class='notice'>[user] repairs [src]!</span>", "<span class='notice'>You repair [src].</span>")

	else if (istype(W, /obj/item/reagent_containers/glass))
		if (src.locked)
			boutput(user, "You cannot insert a beaker because the panel is locked!")
			return
		if (!isnull(src.reagent_glass))
			boutput(user, "There is already a beaker loaded!")
			return

		user.drop_item()
		W.set_loc(src)
		src.reagent_glass = W
		boutput(user, "You insert [W].")
		src.updateUsrDialog()
		return

	else
		switch(W.hit_type)
			if (DAMAGE_BURN)
				src.health -= W.force * 0.75
			else
				src.health -= W.force * 0.5
		if (src.health <= 0)
			src.explode()
		else if (W.force)
			step_to(src, (get_step_away(src,user)))
		..()

/obj/machinery/bot/medbot/proc/point(var/mob/living/carbon/target) // I stole this from the chefbot <3 u marq ur a beter codr then me
	visible_message("<b>[src]</b> points at [target]!")
	if (iscarbon(target))
		var/D = new /obj/decal/point(get_turf(target))
		SPAWN_DBG(2.5 SECONDS)
			qdel(D)

/obj/machinery/bot/medbot/proc/reset_status(var/last_found = null)
	src.oldpatient = src.patient
	src.patient = null
	src.current_treatments = list()
	src.currently_healing = 0
	src.last_found = last_found
	src.path = null

/obj/machinery/bot/medbot/process()
	if (!src.on)
		src.stunned = 0
		return

	if (src.stunned)
		src.update_icon(stun = 1)
		src.stunned--

		src.reset_status()

		if(src.stunned <= 0)
			src.stunned = 0
			src.update_icon()
		return

	if (src.frustration > 8)
		src.reset_status(world.time)

	if (!src.patient)
		if(prob(1))
			var/message = pick("Radar, put a mask on!","I'm a doctor.","There's always a catch, and it's the best there is.","I knew it, I should've been a plastic surgeon.","What kind of medbay is this? Everyone's dropping like dead flies.","Delicious!")
			src.speak(message)

		for (var/mob/living/carbon/C in view(7,src)) //Time to find a patient!
			if ((isdead(C)) || !ishuman(C))
				continue

			if ((C == src.oldpatient) && (world.time < src.last_found + 100))
				continue
			for (var/treatment in src.assess_patient(C))
				if (!isnull(treatment))
					src.current_treatments += treatment

			if (src.current_treatments.len > 0)
				src.patient = C
				src.oldpatient = C
				src.last_found = world.time
				SPAWN_DBG(0)
					if ((src.last_newpatient_speak + 100) < world.time) //Don't spam these messages!
						var/message = pick("Hey, you! Hold on, I'm coming.","Wait! I want to help!","You appear to be injured!","Don't worry, I'm trained for this!")
						src.speak(message)
						src.last_newpatient_speak = world.time
					src.point(C.name)
				break
			else
				continue


	if (src.patient && (get_dist(src,src.patient)<= 1))
		if (!src.currently_healing)
			src.currently_healing = 1
			src.frustration = 0
			var/applied_treatment = src.medicate_patient(src.patient)
			src.current_treatments -= applied_treatment
		return

	else if (src.patient && src.path && src.path.len && (get_dist(src.patient,src.path[src.path.len]) > 2))
		src.path = null
		src.currently_healing = 0
		src.last_found = world.time

	if (src.patient && (!src.path || src.path.len == 0) && (get_dist(src,src.patient) > 1))
		SPAWN_DBG(0)
			if (!isturf(src.loc))
				return
			src.path = AStar(src.loc, get_turf(src.patient), /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, adjacent_param = botcard)
			if (!src.path)
				src.reset_status(world.time)
		return

	if(src.path && src.path.len && src.patient)
		step_to(src, src.path[1])
		src.path -= src.path[1]
		SPAWN_DBG(0.3 SECONDS)
			if(src.path && src.path.len)
				step_to(src, src.path[1])
				src.path -= src.path[1]

	if(src.path && src.path.len > 8 && src.patient)
		src.frustration++

	return

/obj/machinery/bot/medbot/proc/toggle_power()
	src.on = !src.on
	if (src.on)
		add_simple_light("medbot", list(220, 220, 255, 0.5*255))
	else
		remove_simple_light("medbot")
	src.patient = null
	src.oldpatient = null
	src.oldloc = null
	src.path = null
	src.currently_healing = 0
	src.last_found = world.time
	src.update_icon()
	src.updateUsrDialog()
	return

/obj/machinery/bot/medbot/proc/brute_check(mob/living/carbon/C as mob)
	var/brute = C.get_brute_damage()
	return (brute >= heal_threshold)

/obj/machinery/bot/medbot/proc/burn_check(mob/living/carbon/C as mob)
	var/burn = C.get_burn_damage()
	return (burn >= heal_threshold)

/obj/machinery/bot/medbot/proc/tox_check(mob/living/carbon/C as mob)
	var/tox = C.get_toxin_damage()
	return (tox >= heal_threshold)

/obj/machinery/bot/medbot/proc/oxy_check(mob/living/carbon/C as mob)
	var/oxy = C.get_oxygen_deprivation()
	return (oxy >= heal_threshold + oxy_additional_heal_threshold)

/obj/machinery/bot/medbot/proc/brain_check(mob/living/carbon/C as mob)
	var/brain = C.get_brain_damage()
	return (brain >= brain_heal_threshold)

/obj/machinery/bot/medbot/proc/crit_check(mob/living/carbon/C as mob)
	var/health = C.health
	return (health <= 0)

/obj/machinery/bot/medbot/proc/health_check(mob/living/carbon/C as mob)
	var/health_percent = 100 * C.health / C.max_health
	return (100 - health_percent >= heal_threshold)

/obj/machinery/bot/medbot/proc/rad_check(mob/living/carbon/C as mob)
	var/datum/statusEffect/simpledot/radiation/R = C.hasStatus("radiation")
	return (!isnull(R))

/obj/machinery/bot/medbot/proc/hypertension_check(mob/living/carbon/C as mob)
	var/blood_pressure_status = C.blood_pressure["status"]
	return (blood_pressure_status == blood_pressure_hypertensive_status)

/obj/machinery/bot/medbot/proc/hypotension_check(mob/living/carbon/C as mob)
	var/blood_pressure_status = C.blood_pressure["status"]
	return (blood_pressure_status == src.blood_pressure_hypotensive_status)

/obj/machinery/bot/medbot/proc/anaphylaxis_check(mob/living/carbon/C as mob)
	var/histamine_amt = C.reagents.get_reagent_amount("histamine")
	return (histamine_amt >= histamine_overdose_amount)

/obj/machinery/bot/medbot/proc/eye_ear_check(mob/living/carbon/C as mob)
	var/eye = C.get_eye_damage()
	var/ear = C.get_ear_damage()
	var/ear_natural_threshold = C.get_ear_damage_natural_healing_threshold()
	return ((eye >= src.eye_damage_threshold) || (ear >= ear_natural_threshold))
/obj/machinery/bot/medbot/proc/virus_check(mob/living/carbon/C as mob)
	for(var/datum/ailment_data/disease/am in C.ailments)
		if((am.stage > 1) || (am.spread == "Airborne"))
			return 1 //STOP DISEASE FOREVER
	return 0

/obj/machinery/bot/medbot/proc/assess_patient(mob/living/carbon/C as mob)
	.= list()
	//Time to see if they need medical help!
	if(isdead(C))
		return //welp too late for them!

	else if(C.suiciding)
		return //Kevorkian school of robotic medical assistants.

	else if(src.terrifying)
		.+= pick(src.treatment_emag, src.treatment_terrifying)

	else if(src.emagged) //Everyone needs our medicine. (Our medicine is toxins)
		.+= src.treatment_emag

	else if((src.reagent_glass) && (src.use_beaker) && (health_check(C)))
		.+= "internal_beaker"

	else
		if(brute_check(C))
			.+= src.treatment_brute
		if(burn_check(C))
			.+= src.treatment_fire
		if(tox_check(C))
			.+= src.treatment_tox
		if(oxy_check(C))
			.+= src.treatment_oxy
		if(brain_check(C))
			.+= src.treatment_brain
		if(crit_check(C))
			.+= src.treatment_crit
		if(rad_check(C))
			.+= src.treatment_rad
		if(hypertension_check(C))
			.+= src.treatment_hypertension
		if(hypotension_check(C))
			.+= src.treatment_hypotension
		if(anaphylaxis_check(C))
			.+= src.treatment_anaphylaxis
		if(eye_ear_check(C))
			.+= treatment_eye_ear
		if(virus_check(C))
			.+= treatment_virus

/obj/machinery/bot/medbot/proc/medicate_patient(mob/living/carbon/C as mob)
	if(!src.on)
		return

	if(!istype(C))
		src.reset_status(world.time)
		return

	if(isdead(C))
		var/death_message = pick("No! NO!","Live, damnit! LIVE!","I...I've never lost a patient before. Not today, I mean.")
		src.speak(death_message)
		src.reset_status(world.time)
		return

	var/reagent_id = null

	while (src.current_treatments.len > 0)
		var/potential_reagent = src.current_treatments[1]
		if((potential_reagent == src.treatment_emag) || (potential_reagent == src.treatment_terrifying))
			reagent_id = potential_reagent
		else if((src.reagent_glass) && (src.use_beaker) && (potential_reagent == "internal_beaker"))
			var/contains_all_beaker_reagents = 1
			for(var/current_id in reagent_glass.reagents.reagent_list)
				if(!C.reagents.has_reagent(current_id))
					contains_all_beaker_reagents = 0
					break
			if(!contains_all_beaker_reagents)
				reagent_id = potential_reagent
		else if(!C.reagents.has_reagent(potential_reagent))
			reagent_id = potential_reagent
		if (isnull(reagent_id)) // the reagent isn't valid, so keep trying
			src.current_treatments -= potential_reagent
		else // the reagent is valid, so stop going through the list
			break

	if (!reagent_id) //If they don't need any of that they're probably cured!
		src.reset_status(world.time)
		var/message = pick("All patched up!","An apple a day keeps me away.","Feel better soon!")
		src.speak(message)
		src.update_icon()
		return
	else
		src.update_icon(stun = 0, heal = 1)
		src.visible_message("<span class='alert'><B>[src] is trying to inject [src.patient]!</B></span>")
		SPAWN_DBG(3 SECONDS)
			if ((get_dist(src, src.patient) <= 1) && (src.on))
				if ((reagent_id == "internal_beaker") && (src.reagent_glass) && (src.reagent_glass.reagents.total_volume))
					src.reagent_glass.reagents.trans_to(src.patient,src.injection_amount) //Inject from beaker instead.
					src.reagent_glass.reagents.reaction(src.patient, 2, src.injection_amount)
				else
					src.patient.reagents.add_reagent(reagent_id,src.injection_amount)
				src.visible_message("<span class='alert'><B>[src] injects [src.patient] with the syringe!</B></span>")
				.= reagent_id

			src.update_icon()
			src.currently_healing = 0

			if (src.terrifying)
				if (prob(20))
					var/message = pick("It will be okay.","You're okay.", "Everything will be alright,","Please remain calm.","Please calm down, sir.","You need to calm down.","CODE BLUE.","You're going to be just fine.","Hold stIll.","Sedating patient.","ALERT.","I think we're losing them...","You're only hurting yourself.","MEM ERR BLK 0  ADDR 30FC500 HAS 010F NOT 0000","MEM ERR BLK 3  ADDR 55005FF HAS 020A NOT FF00","ERROR: Missing or corrupted resource filEs. Plea_-se contact a syst*m administrator.","ERROR: Corrupted kernel. Ple- - a", "This will all be over soon.")
					src.speak(message)
				else
					src.visible_message("<b>[src] [pick("freaks out","glitches out","tweaks out", "malfunctions", "twitches")]!</b>")
					var/glitchsound = pick('sound/machines/romhack1.ogg', 'sound/machines/romhack2.ogg', 'sound/machines/romhack3.ogg','sound/machines/glitch1.ogg','sound/machines/glitch2.ogg','sound/machines/glitch3.ogg','sound/machines/glitch4.ogg','sound/machines/glitch5.ogg')
					playsound(src.loc, glitchsound, 50, 1)
					// let's grustle a bit
					SPAWN_DBG(1 DECI SECOND)
						src.pixel_x += rand(-2,2)
						src.pixel_y += rand(-2,2)
						sleep(0.1 SECONDS)
						src.pixel_x += rand(-2,2)
						src.pixel_y += rand(-2,2)
						sleep(0.1 SECONDS)
						src.pixel_x += rand(-2,2)
						src.pixel_y += rand(-2,2)
						sleep(0.1 SECONDS)
						src.pixel_x = 0
						src.pixel_y = 0

			return

	return

// copied from transposed scientists

#define fontSizeMax 3
#define fontSizeMin -3

/obj/machinery/bot/medbot/terrifying/speak(var/message)
	if ((!src.on) || (!message))
		return

	var/list/audience = hearers(src, null)
	if (!audience || !audience.len)
		return

	var/fontSize = 1
	var/fontIncreasing = 1
	var/messageLen = length(message)
	var/processedMessage = ""

	for (var/i = 1, i <= messageLen, i++)
		processedMessage += "<font size=[fontSize]>[copytext(message, i, i+1)]</font>"
		if (fontIncreasing)
			fontSize = min(fontSize+1, fontSizeMax)
			if (fontSize >= fontSizeMax)
				fontIncreasing = 0
		else
			fontSize = max(fontSize-1, fontSizeMin)
			if (fontSize <= fontSizeMin)
				fontIncreasing = 1

	for (var/mob/O in audience)
		O.show_message("<span class='game say'><span class='name'>[src]</span> beeps, \"[processedMessage]\"",2)

	return

#undef fontSizeMax
#undef fontSizeMin

/obj/machinery/bot/medbot/bullet_act(var/obj/projectile/P)
	..()
	if (src && (P && istype(P) && P.proj_data.damage_type == D_ENERGY))
		src.stunned += 5
		if (src.stunned > 15)
			src.stunned = 15
	return

/obj/machinery/bot/medbot/ex_act(severity)
	switch(severity)
		if(1.0)
			src.explode()
			return
		if(2.0)
			src.health -= 15
			if (src.health <= 0)
				src.explode()
			return
	return

/obj/machinery/bot/medbot/emp_act()
	..()
	if(!src.emagged && prob(75))
		src.emagged = 1
		src.visible_message("<span class='alert'><B>[src] buzzes oddly!</B></span>")
		src.on = 1
	else
		src.explode()
	return

/obj/machinery/bot/medbot/meteorhit()
	src.explode()
	return

/obj/machinery/bot/medbot/blob_act(var/power)
	if(prob(25 * power / 20))
		src.explode()
	return

/obj/machinery/bot/medbot/gib()
	return src.explode()

/obj/machinery/bot/medbot/explode()
	if(src.exploding) return
	src.exploding = 1
	src.on = 0
	for(var/mob/O in hearers(src, null))
		O.show_message("<span class='alert'><B>[src] blows apart!</B></span>", 1)
	var/turf/Tsec = get_turf(src)

	new /obj/item/storage/firstaid(Tsec)

	new /obj/item/device/prox_sensor(Tsec)

	new /obj/item/device/analyzer/healthanalyzer(Tsec)

	if(src.reagent_glass)
		src.reagent_glass.set_loc(Tsec)
		src.reagent_glass = null

	if (prob(50))
		new /obj/item/parts/robot_parts/arm/left(Tsec)

	elecflash(src, radius=1, power=3, exclude_center = 0)
	qdel(src)
	return

/obj/machinery/bot/medbot/Bumped(M as mob|obj)
	SPAWN_DBG(0)
		var/turf/T = get_turf(src)
		M:set_loc(T)

/*
 *	Medbot Assembly -- Can be made out of all three medkits.
 */

/obj/item/storage/firstaid/attackby(var/obj/item/parts/robot_parts/S, mob/user as mob)
	if (!istype(S, /obj/item/parts/robot_parts/arm/))
		if (src.contents.len >= 7)
			return
		if ((S.w_class >= 2 || istype(S, /obj/item/storage)))
			if (!istype(S,/obj/item/storage/pill_bottle))
				return
		..()
		return

	if (src.contents.len >= 1)
		boutput(user, "<span class='alert'>You need to empty [src] out first!</span>")
		return
	else
		var/obj/item/firstaid_arm_assembly/A = new /obj/item/firstaid_arm_assembly
		if (src.icon_state != "firstaid") // fart
			A.skin = src.icon_state // farto
/* all of this is kinda needlessly complicated imo
		if (istype(src, /obj/item/storage/firstaid/fire))
			A.skin = "ointment"
		else if (istype(src, /obj/item/storage/firstaid/toxin))
			A.skin = "tox"
		else if (istype(src, /obj/item/storage/firstaid/oxygen))
			A.skin = "o2"
		else if (istype(src, /obj/item/storage/firstaid/brain))
			A.skin = "red"
		else if (istype(src, /obj/item/storage/firstaid/brute))
			A.skin = "brute"
*/
		user.u_equip(S)
		user.put_in_hand_or_drop(A)
		boutput(user, "You add the robot arm to the first aid kit!")
		qdel(S)
		qdel(src)

/obj/item/firstaid_arm_assembly/attackby(obj/item/W as obj, mob/user as mob)
	if ((istype(W, /obj/item/device/analyzer/healthanalyzer)) && (!src.build_step))
		src.build_step++
		boutput(user, "You add the health sensor to [src]!")
		src.name = "First aid/robot arm/health analyzer assembly"
		src.overlays += "medibot-scanner"
		qdel(W)

	else if ((istype(W, /obj/item/device/prox_sensor)) && (src.build_step == 1))
		src.build_step++
		boutput(user, "You complete the Medibot! Beep boop.")
		var/obj/machinery/bot/medbot/S = new /obj/machinery/bot/medbot
		S.skin = src.skin
		S.set_loc(get_turf(src))
		S.name = src.created_name
		qdel(W)
		qdel(src)

	else if (istype(W, /obj/item/pen))
		var/t = input(user, "Enter new robot name", src.name, src.created_name) as null|text
		if (!t)
			return
		t = strip_html(replacetext(t, "'",""))
		t = copytext(t, 1, 45)
		if (!t)
			return
		if (!in_range(src, usr) && src.loc != usr)
			return

		src.created_name = t
