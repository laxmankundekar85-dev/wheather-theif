## CampaignDatabase.gd
## Comprehensive, data-driven campaign database for all 55 levels in Weather Thief.
## Contains narrative briefings, objectives, enemy setups, boss configurations,
## required weather mechanics, rewards, and scene routing.
class_name CampaignDatabase

const REGIONS: Dictionary = {
	"region_1": {
		"id": "region_1",
		"name": "The Forgotten District",
		"element": "rain",
		"level_range": [1, 15],
		"theme_color": Color(0.25, 0.8, 1.0),
		"description": "Overgrown urban ruins and ancient water aqueducts under Shadow Vanguard siege."
	},
	"region_2": {
		"id": "region_2",
		"name": "The Frozen Mountains",
		"element": "snow",
		"level_range": [16, 25],
		"theme_color": Color(0.65, 0.9, 1.0),
		"description": "Perpetual snow blizzards and high-altitude cryo-laboratories commanded by Frostguard."
	},
	"region_3": {
		"id": "region_3",
		"name": "The Sky Islands",
		"element": "wind",
		"level_range": [26, 35],
		"theme_color": Color(0.35, 1.0, 0.8),
		"description": "Floating Aetherian cloud sanctuaries, updraft bridges, and aerial patrol fleets."
	},
	"region_4": {
		"id": "region_4",
		"name": "The Sunken Desert",
		"element": "sun",
		"level_range": [36, 45],
		"theme_color": Color(1.0, 0.85, 0.3),
		"description": "Golden sand dunes, subterranean solar laboratories, and heat-tempered monoliths."
	},
	"region_5": {
		"id": "region_5",
		"name": "The Storm Kingdom",
		"element": "thunder",
		"level_range": [46, 55],
		"theme_color": Color(0.85, 0.45, 1.0),
		"description": "The Eclipse Citadel fortress, dark lightning spires, and Sovereign Corvin's army."
	}
}

static var _levels_cache: Array[Dictionary] = []

static func get_all_levels() -> Array[Dictionary]:
	if _levels_cache.is_empty():
		_init_levels()
	return _levels_cache

static func get_level(level_idx: int) -> Dictionary:
	var list := get_all_levels()
	if level_idx >= 1 and level_idx <= list.size():
		return list[level_idx - 1]
	return {}

static func get_levels_for_region(region_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lvl in get_all_levels():
		if lvl.get("region_id") == region_id:
			result.append(lvl)
	return result

static func _init_levels() -> void:
	_levels_cache.clear()

	# -------------------------------------------------------------
	# REGION 1: THE FORGOTTEN DISTRICT (Levels 1 - 15)
	# -------------------------------------------------------------
	_add_level(1, "lvl_01_forgotten_district", "region_1", "The Forgotten District",
		"Infiltrate the overgrown district, eliminate Vanguard scouts, and reclaim the Rain Siphon.",
		"Vanguard Overseer Vane has locked down the ancient water aqueduct with heavy enforcers.",
		"Neutralize Vanguard operatives and overload the Rain Siphon [Q].",
		"Complete mission with over 80% accuracy.",
		"res://scenes/levels/verdantia_combat_outpost.tscn",
		"ELIMINATION", "rain", 5, "Vanguard Overseer", 1500, 250, "Snow Magic",
		[
			{"speaker": "Lyra", "text": "Kael, we've infiltrated Verdantia! The Shadow Vanguard has established fortifications across the Ancient Market and Fortress."},
			{"speaker": "Kael", "text": "I can feel the rain energy being siphoned away. Let's take out their patrols."}
		]
	)

	_add_level(2, "lvl_02_broken_signal", "region_1", "Broken Signal",
		"Investigate the mysterious transmission tower deep within the overgrown market ruins.",
		"A distress beacon was intercepted. Vanguard technicians are attempting to jam resistance frequencies.",
		"Destroy 3 signal jammers and eliminate the technical squad.",
		"Destroy all jammers in under 2 minutes.",
		"res://scenes/levels/campaign/level_02.tscn",
		"SABOTAGE", "rain", 4, "", 1600, 260, "",
		[
			{"speaker": "Lyra", "text": "The signal frequency is breaking up! The Vanguard deployed radio jamming pylons around the market square."},
			{"speaker": "Kael", "text": "If we disable those pylons, we can pinpoint where the survivors are hiding."}
		]
	)

	_add_level(3, "lvl_03_missing_voices", "region_1", "Missing Voices",
		"Search abandoned residential buildings and rescue captured civilians.",
		"Civilian scouts have been rounded up near the old temple square. Intervene before they are relocated.",
		"Rescue 3 captive scouts and defeat the guarding squad.",
		"Take no health damage (shields only).",
		"res://scenes/levels/campaign/level_03.tscn",
		"RESCUE", "rain", 5, "", 1700, 275, "",
		[
			{"speaker": "Lyra", "text": "There are life signs locked in cages near the temple square! Vanguard guards are standing watch."},
			{"speaker": "Kael", "text": "Cover me while I breach their defensive perimeter and release the captives."}
		]
	)

	_add_level(4, "lvl_04_enemy_outpost", "region_1", "Enemy Outpost",
		"Assault the forward fortified Vanguard outpost and eliminate the garrison commander.",
		"The forward bunker is coordinating patrols across the entire district sector.",
		"Clear the fortified bunker and defeat Vanguard Lieutenant Knox.",
		"Defeat the commander with a critical headshot.",
		"res://scenes/levels/campaign/level_04.tscn",
		"ELIMINATION", "rain", 6, "Lieutenant Knox", 1850, 300, "",
		[
			{"speaker": "Lyra", "text": "Knox is heavily armored and uses thermal suppressive fire from the bunker roof!"},
			{"speaker": "Kael", "text": "I'll use the side tunnels to flank his position and strike."}
		]
	)

	_add_level(5, "lvl_05_broken_extraction", "region_1", "Broken Extraction",
		"Disrupt the Eclipse Order's primary rain ether extraction refinery.",
		"Refinery pumps are siphoning celestial rain moisture directly into transport cells.",
		"Overload 3 cooling conduits and defeat the heavy refinery defenders.",
		"Trigger conduit overloads using Rain Magic [Q].",
		"res://scenes/levels/campaign/level_05.tscn",
		"SABOTAGE", "rain", 6, "", 2000, 320, "",
		[
			{"speaker": "Lyra", "text": "Look at the sheer volume of water being condensed! Their pumps are stressing the atmosphere!"},
			{"speaker": "Kael", "text": "Overloading these coolant valves will shut down the whole complex."}
		]
	)

	_add_level(6, "lvl_06_hidden_resistance", "region_1", "The Hidden Resistance",
		"Find the surviving resistance group and establish secure contact.",
		"Resistance leader Marcus is holding out in the catacombs under the district square.",
		"Locate the catacomb entrance and defeat the Vanguard search party.",
		"Complete mission in under 180 seconds.",
		"res://scenes/levels/campaign/level_06.tscn",
		"RECON_INVESTIGATION", "rain", 5, "", 2100, 340, "",
		[
			{"speaker": "Lyra", "text": "Marcus left an encrypted cipher on the ancient stone arches. Follow the marked trail."},
			{"speaker": "Kael", "text": "Vanguard patrols are sweeping the area. We need to move quietly and decisively."}
		]
	)

	_add_level(7, "lvl_07_city_under_watch", "region_1", "A City Under Watch",
		"Destroy enemy surveillance equipment and security watchtowers.",
		"Vanguard automated sensory relays are scanning all movement through the upper market.",
		"Destroy 4 surveillance sensor towers and eliminate marksmen.",
		"Eliminate all marksmen using precision sniper fire.",
		"res://scenes/levels/campaign/level_07.tscn",
		"SABOTAGE", "rain", 6, "", 2200, 350, "",
		[
			{"speaker": "Lyra", "text": "Those thermal sensor towers have locked down the entire street! Take them out from range."},
			{"speaker": "Kael", "text": "Aim for the glowing power cells at the base of each tower."}
		]
	)

	_add_level(8, "lvl_08_prison_block", "region_1", "The Prison Block",
		"Rescue captured civilians and weather researchers from the detention compound.",
		"The Eclipse Order has gathered district elders to force-extract their knowledge of the weather siphons.",
		"Breach the holding cells and eliminate the prison warden squad.",
		"Rescue all civilians without losing shield.",
		"res://scenes/levels/campaign/level_08.tscn",
		"RESCUE", "rain", 6, "Detention Warden", 2300, 370, "",
		[
			{"speaker": "Lyra", "text": "Elder Bramble and his apprentices are in the center holding block! Don't let the warden harm them!"},
			{"speaker": "Kael", "text": "They won't get past me. Breach and clear!"}
		]
	)

	_add_level(9, "lvl_09_silent_market", "region_1", "Silent Market",
		"Infiltrate an enemy weapons depot and confiscate Eclipse armaments.",
		"A cache of high-velocity kinetic rifles is being prepared for shipment to the frontlines.",
		"Infiltrate the market depot and secure 3 weapon crates.",
		"Neutralize 3 enemies without alerting the entire squad.",
		"res://scenes/levels/campaign/level_09.tscn",
		"STEALTH", "rain", 5, "", 2400, 380, "Viper SMG Upgrade",
		[
			{"speaker": "Lyra", "text": "The depot is stacked with military weapon crates. If we secure them, the resistance can arm itself."},
			{"speaker": "Kael", "text": "Staying in the shadows until I have a clean firing angle."}
		]
	)

	_add_level(10, "lvl_10_vanguard_hunt", "region_1", "The Vanguard Hunt",
		"Track and eliminate Vanguard Commander Brand.",
		"Commander Brand has taken personal command of the counter-offensive in the district.",
		"Track Brand to the old amphitheater and defeat him.",
		"Defeat Brand in under 90 seconds.",
		"res://scenes/levels/campaign/level_10.tscn",
		"BOSS_HUNT", "rain", 6, "Commander Brand", 2550, 400, "",
		[
			{"speaker": "Lyra", "text": "Brand is a ruthless tactician. He coordinates crossfire from multiple elevated barricades."},
			{"speaker": "Kael", "text": "His reign of terror in Verdantia ends today."}
		]
	)

	_add_level(11, "lvl_11_beneath_fortress", "region_1", "Beneath the Fortress",
		"Explore an underground facility and discover hidden evidence of the Weather Collapse.",
		"Subterranean tunnels beneath the fortress contain ancient archives and experimental notes.",
		"Collect 3 archive data tablets and clear security automatons.",
		"Discover all 3 archive tablets.",
		"res://scenes/levels/campaign/level_11.tscn",
		"RECON_INVESTIGATION", "rain", 5, "", 2650, 420, "",
		[
			{"speaker": "Lyra", "text": "These archives predate the Great Weather Collapse! Corvin was studying how to siphon all four elements simultaneously!"},
			{"speaker": "Kael", "text": "Then he didn't just cause an accident... he broke the sky deliberately."}
		]
	)

	_add_level(12, "lvl_12_missing_researcher", "region_1", "The Missing Researcher",
		"Find the scientist responsible for the Rain experiments and escort her to safety.",
		"Dr. Elena fled the Eclipse Order after realizing their true catastrophic ambitions.",
		"Locate Dr. Elena and protect her from pursuing hit squads.",
		"Keep Elena's protection barrier above 75%.",
		"res://scenes/levels/campaign/level_12.tscn",
		"ESCORT", "rain", 6, "", 2800, 440, "",
		[
			{"speaker": "Lyra", "text": "Dr. Elena is pinned down in the ruined observatory! Vanguard enforcers are closing in!"},
			{"speaker": "Kael", "text": "Hold on, Doctor! We're breaking through their lines!"}
		]
	)

	_add_level(13, "lvl_13_extraction_convoy", "region_1", "The Extraction Convoy",
		"Intercept and destroy a moving enemy supply convoy.",
		"A heavily armored convoy is transporting refined rain ether toward the mountain gate.",
		"Destroy the convoy transports and neutralize the armored escort.",
		"Destroy the lead transport with Rain Infused fire.",
		"res://scenes/levels/campaign/level_13.tscn",
		"CONVOY_INTERCEPT", "rain", 6, "", 2900, 460, "",
		[
			{"speaker": "Lyra", "text": "The convoy is on the main aqueduct road! If it reaches the mountain pass, the ether is gone!"},
			{"speaker": "Kael", "text": "Targeting their engine blocks. Let's stop them in their tracks."}
		]
	)

	_add_level(14, "lvl_14_siege_old_district", "region_1", "Siege of the Old District",
		"Defend the resistance headquarters against multiple hostile enemy waves.",
		"Vanguard forces have launched a massive retaliatory siege to crush the district rebellion.",
		"Survive 3 enemy assault waves and protect the command gate.",
		"Defeat 12 enemies during the siege.",
		"res://scenes/levels/campaign/level_14.tscn",
		"DEFENSE", "rain", 8, "Assault Captain", 3100, 500, "",
		[
			{"speaker": "Lyra", "text": "Here they come! Vanguard shock troopers breaching the northern courtyard!"},
			{"speaker": "Kael", "text": "Stand firm! We hold this district for the people!"}
		]
	)

	_add_level(15, "lvl_15_rain_guardian", "region_1", "The Rain Guardian",
		"Defeat the major regional boss: The Corrupted Siphon Colossus.",
		"High Magus Corvin has infused a massive mechanical dreadnought with stolen Rain ether.",
		"Defeat the Rain Guardian Colossus and restore Verdantia's rainfall.",
		"Defeat the boss without falling below 30% health.",
		"res://scenes/levels/campaign/level_15.tscn",
		"BOSS_HUNT", "rain", 7, "Rain Guardian Colossus", 3500, 600, "Primal Rain Mastery",
		[
			{"speaker": "Lyra", "text": "Look at the size of that machine! It's radiating pure concentrated rain ether!"},
			{"speaker": "Kael", "text": "Target its power exhaust manifolds! Bring the Colossus down!"}
		]
	)

	# -------------------------------------------------------------
	# REGION 2: THE FROZEN MOUNTAINS (Levels 16 - 25)
	# -------------------------------------------------------------
	_add_level(16, "lvl_16_beyond_snowline", "region_2", "Beyond the Snowline",
		"Ascend the steep mountain trail and reach the highland snow settlement.",
		"The Frostguard has established perimeter checkpoints along the narrow mountain ridges.",
		"Clear mountain trail barricades and defeat the Frostguard scouts.",
		"Complete ascent in under 2 minutes.",
		"res://scenes/levels/campaign/level_16.tscn",
		"ELIMINATION", "snow", 5, "", 2500, 350, "",
		[
			{"speaker": "Lyra", "text": "We've passed the snowline, Kael! The wind is howling and the cold is biting."},
			{"speaker": "Kael", "text": "Frostguard scouts have fortified the upper switchbacks. We push upward."}
		]
	)

	_add_level(17, "lvl_17_whiteout", "region_2", "Whiteout",
		"Survive the blinding blizzard and locate a safe route through the ice fields.",
		"A severe snowstorm has knocked out optical sensors. Snipers roam the ridges.",
		"Navigate through the storm lanterns and eliminate hidden snipers.",
		"Score 4 headshot eliminations in the snowstorm.",
		"res://scenes/levels/campaign/level_17.tscn",
		"STEALTH", "snow", 6, "", 2600, 370, "",
		[
			{"speaker": "Lyra", "text": "Visibility is near zero! Follow the pulse markers on your tactical HUD!"},
			{"speaker": "Kael", "text": "Movement at ten o'clock. Snipers on the ice cliffs."}
		]
	)

	_add_level(18, "lvl_18_frozen_outpost", "region_2", "The Frozen Outpost",
		"Destroy the Frostguard radar outpost tracking resistance movements.",
		"A forward radar dish is relaying all resistance coordinates to the main fortress.",
		"Overload 3 radar generators and defeat the outpost garrison.",
		"Overload all generators using Snow Magic [E].",
		"res://scenes/levels/campaign/level_18.tscn",
		"SABOTAGE", "snow", 6, "", 2750, 390, "",
		[
			{"speaker": "Lyra", "text": "That radar dish is relaying our every step. Disable its power generators!"},
			{"speaker": "Kael", "text": "Setting charges on the cryo-batteries now."}
		]
	)

	_add_level(19, "lvl_19_prisoners_of_ice", "region_2", "Prisoners of Ice",
		"Rescue captured mountain researchers locked in sub-zero cryo-pods.",
		"Frostguard scientists are conducting forced stasis experiments on abducted villagers.",
		"Deactivate 3 stasis containment pods and neutralize the research guards.",
		"Rescue all researchers in under 150 seconds.",
		"res://scenes/levels/campaign/level_19.tscn",
		"RESCUE", "snow", 6, "", 2900, 410, "",
		[
			{"speaker": "Lyra", "text": "Their body temperatures are dropping dangerously! We must thaw the containment pods immediately!"},
			{"speaker": "Kael", "text": "Overriding the pod locks. Clear out the guards!"}
		]
	)

	_add_level(20, "lvl_20_frostguard_hunt", "region_2", "The Frostguard Hunt",
		"Track and eliminate Frostguard Commander Varek's field marshal.",
		"Marshal Torvald has taken command of the ridge defenses with heavy cryo-cannons.",
		"Defeat Marshal Torvald and secure the ice canyon pass.",
		"Defeat Torvald without getting frozen.",
		"res://scenes/levels/campaign/level_20.tscn",
		"BOSS_HUNT", "snow", 6, "Marshal Torvald", 3050, 430, "",
		[
			{"speaker": "Lyra", "text": "Torvald's cryo-cannon fires freezing bursts! Evade when you see the charging arc!"},
			{"speaker": "Kael", "text": "I'll use my combat slide to stay out of his direct firing cone."}
		]
	)

	_add_level(21, "lvl_21_ice_caverns", "region_2", "The Ice Caverns",
		"Explore the glacial caverns and uncover the ancient Snow Fragment shrine.",
		"Crystalline ice caverns run deep into the mountain, holding ancient elemental artifacts.",
		"Traverse the glacial chasm and recover the Glacial Core fragment.",
		"Break 4 ice barriers using elemental attacks.",
		"res://scenes/levels/campaign/level_21.tscn",
		"RECON_INVESTIGATION", "snow", 5, "", 3200, 450, "",
		[
			{"speaker": "Lyra", "text": "The temperature here is absolute zero. The pure Snow Fragment is nearby!"},
			{"speaker": "Kael", "text": "Ancient ice barriers block the shrine. My infused shots can shatter them."}
		]
	)

	_add_level(22, "lvl_22_broken_lift", "region_2", "The Broken Lift",
		"Repair and defend the mountain funicular transport lift to reach Frosthold.",
		"The high-altitude freight lift has been sabotaged to isolate the upper peak.",
		"Restore power to 2 lift turbines and defend the platform against ambushes.",
		"Keep the lift mechanism integrity above 80%.",
		"res://scenes/levels/campaign/level_22.tscn",
		"DEFENSE", "snow", 7, "", 3350, 470, "",
		[
			{"speaker": "Lyra", "text": "Power restored to the lift cables! Enemies dropping in from the cliffs above!"},
			{"speaker": "Kael", "text": "Hold the platform edge! Don't let them cut the cables!"}
		]
	)

	_add_level(23, "lvl_23_frozen_convoy", "region_2", "The Frozen Convoy",
		"Stop the Frostguard heavy supply crawler moving across the ice shelf.",
		"The crawler carries heavy cryogenic munitions for the citadel siege engine.",
		"Disable the crawler tracks and defeat the heavy escort.",
		"Destroy the crawler in under 2 minutes.",
		"res://scenes/levels/campaign/level_23.tscn",
		"CONVOY_INTERCEPT", "snow", 7, "", 3500, 490, "",
		[
			{"speaker": "Lyra", "text": "The crawler is plowing through the snowbank! Heavy enforcers guarding the rear!"},
			{"speaker": "Kael", "text": "Concentrated fire on their left tread module!"}
		]
	)

	_add_level(24, "lvl_24_assault_frosthold", "region_2", "Assault on Frosthold",
		"Infiltrate the outer ramparts of Frosthold Fortress.",
		"The massive fortress commands the gateway to the Sky Islands.",
		"Breach the fortress courtyard and eliminate the elite defense echelon.",
		"Score 5 headshots on garrison guards.",
		"res://scenes/levels/campaign/level_24.tscn",
		"ELIMINATION", "snow", 7, "", 3700, 520, "",
		[
			{"speaker": "Lyra", "text": "The outer gate has fallen! Frostguard heavy troopers holding the courtyard barricades!"},
			{"speaker": "Kael", "text": "Take cover behind the stone pillars and advance in rhythm."}
		]
	)

	_add_level(25, "lvl_25_frostguard_captain", "region_2", "The Frostguard Captain",
		"Defeat the major regional boss: Frostguard Captain Varek.",
		"Varek wields a dual-barrel cryo lance and controls the master mountain Siphon.",
		"Defeat Captain Varek and claim the Sky Island Ascension Key.",
		"Overload Varek's shield using combined Rain and Snow attacks.",
		"res://scenes/levels/campaign/level_25.tscn",
		"BOSS_HUNT", "snow", 7, "Captain Varek", 4200, 650, "Sky Ascension Key",
		[
			{"speaker": "Lyra", "text": "Captain Varek is charging his cryogenic shield! Shatter his defenses, Kael!"},
			{"speaker": "Kael", "text": "Your frozen reign ends here, Varek! For the people of the peaks!"}
		]
	)

	# -------------------------------------------------------------
	# REGION 3: THE SKY ISLANDS (Levels 26 - 35)
	# -------------------------------------------------------------
	_add_level(26, "lvl_26_sky_passage", "region_3", "The Sky Passage",
		"Ascend through the cloud gateway and reach the floating island archipelago.",
		"Ancient gravitational siphons keep these massive landmasses aloft in the stratosphere.",
		"Activate 2 gravitational updraft nodes and defeat the aerial guards.",
		"Complete the ascent without falling into updrafts.",
		"res://scenes/levels/campaign/level_26.tscn",
		"ELIMINATION", "wind", 5, "", 3200, 450, "",
		[
			{"speaker": "Lyra", "text": "We've broken through the cloud ceiling! Miles of floating islands stretching to the horizon!"},
			{"speaker": "Kael", "text": "The wind currents are intense. Watch your step on the fractured ledges."}
		]
	)

	_add_level(27, "lvl_27_broken_bridges", "region_3", "Broken Bridges",
		"Restore ancient kinetic skybridges connecting the outer sanctuaries.",
		"Eclipse engineers destroyed the light bridges to prevent resistance crossings.",
		"Align 3 kinetic bridge prisms and eliminate aerial marksmen.",
		"Align all 3 prisms in under 140 seconds.",
		"res://scenes/levels/campaign/level_27.tscn",
		"SABOTAGE", "wind", 6, "", 3350, 470, "",
		[
			{"speaker": "Lyra", "text": "Those crystalline prisms focus the wind currents into solid light bridges! Realign them!"},
			{"speaker": "Kael", "text": "Aligning first prism. Marksmen firing from the opposite tower!"}
		]
	)

	_add_level(28, "lvl_28_wind_hunters", "region_3", "The Wind Hunters",
		"Eliminate elite Eclipse aerial skirmishers patrolling the cloud deck.",
		"Fast-moving Wind Hunters use jet-assisted glider rigs to harass grounded forces.",
		"Eliminate 7 aerial skirmishers across the archipelago.",
		"Defeat 3 skirmishers while in mid-air.",
		"res://scenes/levels/campaign/level_28.tscn",
		"ELIMINATION", "wind", 7, "", 3500, 490, "",
		[
			{"speaker": "Lyra", "text": "Wind Hunters inbound at high speed! They dive from above cloud cover!"},
			{"speaker": "Kael", "text": "Track their flight trajectory and fire as they bank."}
		]
	)

	_add_level(29, "lvl_29_temple_echoes", "region_3", "Temple of Echoes",
		"Investigate the sacred Temple of Echoes and decode the Aetherian glyphs.",
		"The temple holds the harmonic frequencies required to stabilize atmospheric wind currents.",
		"Decode 3 sonic resonance glyphs and defeat temple intruders.",
		"Solve glyph resonance in under 2 minutes.",
		"res://scenes/levels/campaign/level_29.tscn",
		"RECON_INVESTIGATION", "wind", 6, "", 3650, 510, "",
		[
			{"speaker": "Lyra", "text": "Listen to the harmonic wind whistling through the marble columns! The temple is speaking!"},
			{"speaker": "Kael", "text": "Harmonizing my ether core with the sanctuary altar."}
		]
	)

	_add_level(30, "lvl_30_lost_navigator", "region_3", "The Lost Navigator",
		"Rescue Master Navigator Zephyr stranded on a fractured floating outcrop.",
		"Zephyr is the last living pilot capable of navigating the high storm maelstrom.",
		"Rescue Navigator Zephyr and hold off enemy airborne reinforcements.",
		"Keep Zephyr safe without taking direct hit.",
		"res://scenes/levels/campaign/level_30.tscn",
		"RESCUE", "wind", 6, "", 3800, 530, "",
		[
			{"speaker": "Lyra", "text": "Zephyr is trapped on that collapsing island! His airskiff has been disabled!"},
			{"speaker": "Kael", "text": "Deploying Wind Gust [F] to clear the gap! Hang on, Zephyr!"}
		]
	)

	_add_level(31, "lvl_31_above_clouds", "region_3", "Above the Clouds",
		"Ascend to the highest island plateau and capture the Eclipse watchtower.",
		"The high watchtower commands line of sight over the entire eastern sky realm.",
		"Assault the watchtower summit and defeat the tower commander.",
		"Complete summit assault in under 160 seconds.",
		"res://scenes/levels/campaign/level_31.tscn",
		"ELIMINATION", "wind", 6, "Tower Commander", 3950, 550, "",
		[
			{"speaker": "Lyra", "text": "The wind pressure up here is tremendous! Use Wind Gust [F] for kinetic speed boosts!"},
			{"speaker": "Kael", "text": "Pushing up the grand marble staircase! Clear the flanks!"}
		]
	)

	_add_level(32, "lvl_32_storm_beacons", "region_3", "The Storm Beacons",
		"Disable 3 dark storm guidance beacons drawing unnatural lightning.",
		"The Eclipse Order is artificially summoning thunderclouds to shield their operations.",
		"Deactivate 3 storm beacon pylons and neutralize guardian drones.",
		"Deactivate beacons using Wind Magic [F].",
		"res://scenes/levels/campaign/level_32.tscn",
		"SABOTAGE", "wind", 7, "", 4100, 570, "",
		[
			{"speaker": "Lyra", "text": "Those beacon pylons are drawing ionic lightning from miles away! Purge their capacitors!"},
			{"speaker": "Kael", "text": "Reversing capacitor flow with an ether blast."}
		]
	)

	_add_level(33, "lvl_33_fallen_sanctuary", "region_3", "The Fallen Sanctuary",
		"Defend the ancient sky sanctuary against an intense three-phase aerial drop.",
		"Eclipse gunships are deploying squads directly onto the sacred altar platform.",
		"Repel 3 waves of airborne drop troops and protect the relic altar.",
		"Defeat 14 enemies during the assault.",
		"res://scenes/levels/campaign/level_33.tscn",
		"DEFENSE", "wind", 8, "", 4300, 600, "",
		[
			{"speaker": "Lyra", "text": "Gunships dropping enforcers right on top of our position! Form a defensive perimeter!"},
			{"speaker": "Kael", "text": "We hold this sacred ground! None shall pass!"}
		]
	)

	_add_level(34, "lvl_34_wind_fragment", "region_3", "The Wind Fragment",
		"Extract the primal Wind Fragment from the heart of the Grand Cloud Spire.",
		"The fragment is locked within a vortex of compressed atmospheric pressure.",
		"Stabilize 3 vortex dampeners and defeat the vortex guardians.",
		"Complete stabilization with over 85% accuracy.",
		"res://scenes/levels/campaign/level_34.tscn",
		"RECON_INVESTIGATION", "wind", 6, "", 4500, 630, "",
		[
			{"speaker": "Lyra", "text": "The Wind Fragment is spinning at supersonic speed! Dampen the kinetic field!"},
			{"speaker": "Kael", "text": "Syncing my ether pulse with the vortex frequency."}
		]
	)

	_add_level(35, "lvl_35_sky_warden", "region_3", "The Sky Warden",
		"Defeat the major regional boss: High Warden Zephyrus.",
		"Zephyrus commands an armored aerial dreadnought with kinetic wind cannons.",
		"Defeat High Warden Zephyrus and secure the Sunken Desert navigation chart.",
		"Defeat Zephyrus in under 3 minutes.",
		"res://scenes/levels/campaign/level_35.tscn",
		"BOSS_HUNT", "wind", 7, "High Warden Zephyrus", 5000, 750, "Wind Mastery & Desert Chart",
		[
			{"speaker": "Lyra", "text": "Zephyrus has taken flight in his kinetic combat chassis! Dodge his dive-bombing runs!"},
			{"speaker": "Kael", "text": "When he lands to vent heat, unleash full automatic fire!"}
		]
	)

	# -------------------------------------------------------------
	# REGION 4: THE SUNKEN DESERT (Levels 36 - 45)
	# -------------------------------------------------------------
	_add_level(36, "lvl_36_into_dunes", "region_4", "Into the Dunes",
		"Cross the scorching desert frontier and locate the buried ruins entrance.",
		"Intense heat waves and shifting sands hide ancient solar installations.",
		"Traverse the desert dunes and eliminate sand scout patrols.",
		"Complete the desert crossing without running out of stamina.",
		"res://scenes/levels/campaign/level_36.tscn",
		"ELIMINATION", "sun", 5, "", 3800, 520, "",
		[
			{"speaker": "Lyra", "text": "Welcome to the Sunken Desert, Kael! The heat is searing, but solar energy is potent here."},
			{"speaker": "Kael", "text": "I spot sand patrols guarding an ancient stone arch ahead."}
		]
	)

	_add_level(37, "lvl_37_buried_secrets", "region_4", "Buried Secrets",
		"Excavate and unlock the subterranean entrance to the ancient Sunken City.",
		"Centuries of desert sandstorms have buried the colossal stone gates.",
		"Uncover 3 solar reflection lenses and defeat the desert excavation squad.",
		"Uncover all 3 lenses in under 150 seconds.",
		"res://scenes/levels/campaign/level_37.tscn",
		"SABOTAGE", "sun", 6, "", 4000, 540, "",
		[
			{"speaker": "Lyra", "text": "Those solar lenses concentrate sunlight into the gate mechanism! Align them to burn through the sand!"},
			{"speaker": "Kael", "text": "First lens aligned. The beam is melting the sand buildup!"}
		]
	)

	_add_level(38, "lvl_38_scorpion_base", "region_4", "The Scorpion Base",
		"Destroy the Eclipse forward outpost: Scorpion Base.",
		"The base is harvesting raw solar ether from subterranean thermal vents.",
		"Destroy 3 thermal extractors and defeat Base Commander Thorne.",
		"Defeat Commander Thorne with Sun Radiance [C].",
		"res://scenes/levels/campaign/level_38.tscn",
		"SABOTAGE", "sun", 6, "Commander Thorne", 4200, 570, "",
		[
			{"speaker": "Lyra", "text": "Scorpion Base is pumping raw solar energy! Overload their extractor valves!"},
			{"speaker": "Kael", "text": "Commander Thorne is moving in with flame-shielded enforcers!"}
		]
	)

	_add_level(39, "lvl_39_beneath_sand", "region_4", "Beneath the Sand",
		"Navigate the subterranean ruins of the Sunken Metropolis.",
		"Vast cavernous halls buried beneath the desert house ancient technological wonders.",
		"Navigate through the subterranean labyrinth and eliminate security patrols.",
		"Score 4 critical headshots in low-light conditions.",
		"res://scenes/levels/campaign/level_39.tscn",
		"STEALTH", "sun", 6, "", 4400, 600, "",
		[
			{"speaker": "Lyra", "text": "We are walking beneath millions of tons of sand. These ancient pillars have held for millennia."},
			{"speaker": "Kael", "text": "Vanguard patrols are using flashlights down the main colonnade. Flanking left."}
		]
	)

	_add_level(40, "lvl_40_lost_caravan", "region_4", "The Lost Caravan",
		"Find and rescue missing nomad merchants captured by desert raiders.",
		"The nomads possess rare crystal keys that unlock the deepest solar vaults.",
		"Rescue 3 nomad leaders and eliminate the captor squad.",
		"Rescue all nomads without letting any cage take damage.",
		"res://scenes/levels/campaign/level_40.tscn",
		"RESCUE", "sun", 6, "", 4600, 620, "",
		[
			{"speaker": "Lyra", "text": "The nomad merchants are caged in the amphitheater! Break their chains!"},
			{"speaker": "Kael", "text": "Target the lock switches while keeping the guards suppressed!"}
		]
	)

	_add_level(41, "lvl_41_solar_laboratory", "region_4", "The Solar Laboratory",
		"Infiltrate the Eclipse clandestine laboratory experimenting with Sun energy.",
		"Scientists are attempting to synthesize an artificial miniature sun to incinerate resistance bases.",
		"Shut down 3 containment rings and download experimental telemetry.",
		"Shut down containment before the overload timer hits 0.",
		"res://scenes/levels/campaign/level_41.tscn",
		"SABOTAGE", "sun", 7, "", 4800, 650, "",
		[
			{"speaker": "Lyra", "text": "They are trying to birth a synthetic sun! The radiation levels are off the charts!"},
			{"speaker": "Kael", "text": "Purging containment rings! Stand back!"}
		]
	)

	_add_level(42, "lvl_42_sandstorm_siege", "region_4", "The Sandstorm Siege",
		"Survive a massive desert ambush amidst a raging dust hurricane.",
		"Eclipse forces have triggered a seismic sandstorm to bury Kael alive.",
		"Survive 3 waves of heavy assault troops in low visibility.",
		"Survive with at least 50% shield remaining.",
		"res://scenes/levels/campaign/level_42.tscn",
		"SURVIVAL", "sun", 8, "", 5000, 680, "",
		[
			{"speaker": "Lyra", "text": "Seismic sandstorm incoming! Keep moving or the dunes will swallow you!"},
			{"speaker": "Kael", "text": "Enemies attacking from all directions! Watch your compass radar!"}
		]
	)

	_add_level(43, "lvl_43_temple_of_light", "region_4", "The Temple of Light",
		"Recover the Solar Keystone from the high altar of the Temple of Light.",
		"The keystone acts as the focusing crystal for all solar ether in the hemisphere.",
		"Navigate the light beam reflection puzzle and secure the Solar Keystone.",
		"Solve the reflection beam puzzle in under 120 seconds.",
		"res://scenes/levels/campaign/level_43.tscn",
		"RECON_INVESTIGATION", "sun", 6, "", 5200, 710, "",
		[
			{"speaker": "Lyra", "text": "Align the solar mirrors toward the central obelisk to unlock the vault!"},
			{"speaker": "Kael", "text": "The beam is focusing! Keystone vault is opening!"}
		]
	)

	_add_level(44, "lvl_44_sun_fragment", "region_4", "The Sun Fragment",
		"Stop the Eclipse extraction drill and claim the pure Sun Fragment.",
		"A colossal thermal excavator is boring directly into the primal solar core.",
		"Destroy 3 excavator coolant pipes and defeat the heavy defense line.",
		"Destroy pipes using Sun Radiance [C].",
		"res://scenes/levels/campaign/level_44.tscn",
		"SABOTAGE", "sun", 7, "", 5500, 750, "",
		[
			{"speaker": "Lyra", "text": "The mega-drill is reaching critical depth! Rupture its hydraulic lines!"},
			{"speaker": "Kael", "text": "Firing concentrated solar rounds into the drill housing!"}
		]
	)

	_add_level(45, "lvl_45_sunbreaker", "region_4", "The Sunbreaker",
		"Defeat the major regional boss: Sunbreaker Commander Solon.",
		"Solon is clad in impenetrable solar-forged plate and wields a solar rail-cannon.",
		"Defeat Sunbreaker Commander Solon and unlock the Storm Kingdom portal.",
		"Defeat Solon in under 2 minutes and 30 seconds.",
		"res://scenes/levels/campaign/level_45.tscn",
		"BOSS_HUNT", "sun", 7, "Commander Solon", 6000, 850, "Sun Mastery & Storm Key",
		[
			{"speaker": "Lyra", "text": "Solon's armor absorbs kinetic energy! Use combined Snow and Water to cool his plating!"},
			{"speaker": "Kael", "text": "His defenses are breaking! Now take him down!"}
		]
	)

	# -------------------------------------------------------------
	# REGION 5: THE STORM KINGDOM (Levels 46 - 55)
	# -------------------------------------------------------------
	_add_level(46, "lvl_46_final_frontier", "region_5", "The Final Frontier",
		"Breach the outer perimeter of the perpetual storm barrier.",
		"Gigantic lightning arches and electromagnetic storms guard the entrance to Corvin's domain.",
		"Destroy 3 perimeter ion towers and defeat the storm vanguard.",
		"Complete perimeter breach in under 130 seconds.",
		"res://scenes/levels/campaign/level_46.tscn",
		"ELIMINATION", "thunder", 6, "", 5000, 700, "",
		[
			{"speaker": "Lyra", "text": "We are crossing into the Storm Kingdom! The atmospheric pressure is unprecedented!"},
			{"speaker": "Kael", "text": "Ion towers are discharging into the ground. Clearing the vanguard guards."}
		]
	)

	_add_level(47, "lvl_47_outer_wall", "region_5", "The Outer Wall",
		"Break through the massive fortified outer battlements of the Eclipse Citadel.",
		"Heavy automated turrets and armored shock troopers guard the main gate.",
		"Sabotage the gate power grid and eliminate the battlement defenders.",
		"Defeat 6 enemies using headshots.",
		"res://scenes/levels/campaign/level_47.tscn",
		"SABOTAGE", "thunder", 7, "", 5200, 730, "",
		[
			{"speaker": "Lyra", "text": "The outer wall is fifty feet of reinforced dark steel! Destroy the gate generators!"},
			{"speaker": "Kael", "text": "Charges planted on generator conduits! Detonating!"}
		]
	)

	_add_level(48, "lvl_48_silent_infiltration", "region_5", "The Silent Infiltration",
		"Infiltrate the Eclipse inner complex through the high-voltage maintenance conduits.",
		"Stealth is paramount to bypass the inner automated defense grid.",
		"Infiltrate the power sub-station without triggering the master alarm.",
		"Eliminate 4 patrolling guards with silenced headshots.",
		"res://scenes/levels/campaign/level_48.tscn",
		"STEALTH", "thunder", 6, "", 5400, 760, "",
		[
			{"speaker": "Lyra", "text": "Move between the electrical pulses. If you trip the sensor beams, the garrison alerts."},
			{"speaker": "Kael", "text": "Understood. Silently disabling the inner relay."}
		]
	)

	_add_level(49, "lvl_49_captive_alliance", "region_5", "The Captive Alliance",
		"Rescue imprisoned resistance leaders from the Citadel high-security dungeon.",
		"Allies captured throughout the campaign are scheduled for ether execution.",
		"Free 4 alliance commanders and defeat the elite inquisitor unit.",
		"Keep all rescued allies above 80% health during extraction.",
		"res://scenes/levels/campaign/level_49.tscn",
		"RESCUE", "thunder", 7, "Chief Inquisitor", 5700, 800, "",
		[
			{"speaker": "Lyra", "text": "Marcus, Dr. Elena, and Zephyr are all in the high security block! Breach the doors!"},
			{"speaker": "Kael", "text": "You're safe now, friends. Take our spare weapons and fall back!"}
		]
	)

	_add_level(50, "lvl_50_four_temples", "region_5", "The Four Temples",
		"Simultaneously calibrate the four elemental weather conduits in the Citadel Plaza.",
		"The siphons for Rain, Snow, Wind, and Sun must be synchronized to break Corvin's shield.",
		"Activate all 4 elemental pedestals: Rain [Q], Snow [E], Wind [F], Sun [C].",
		"Activate all 4 pedestals in under 90 seconds.",
		"res://scenes/levels/campaign/level_50.tscn",
		"SABOTAGE", "thunder", 8, "", 6000, 850, "",
		[
			{"speaker": "Lyra", "text": "All four elemental powers are resonating! Rain, Snow, Wind, and Sun! Align the pedestals!"},
			{"speaker": "Kael", "text": "Channels opening! Corvin's citadel shield is collapsing!"}
		]
	)

	_add_level(51, "lvl_51_eclipse_army", "region_5", "The Eclipse Army",
		"Survive a full-scale battle against the entire mobilized Eclipse legion.",
		"Corvin has unleashed his personal honor guard in a desperate bid to crush Kael.",
		"Eliminate 16 elite legionnaires and survive the onslaught.",
		"Defeat 5 enemies with Storm Burst Ultimate [G].",
		"res://scenes/levels/campaign/level_51.tscn",
		"SURVIVAL", "thunder", 10, "Legion General", 6500, 900, "",
		[
			{"speaker": "Lyra", "text": "It's an entire army! Enforcers, snipers, and shock troopers from all sides!"},
			{"speaker": "Kael", "text": "We've fought across four regions to reach this moment! I will not fall!"}
		]
	)

	_add_level(52, "lvl_52_betrayal", "region_5", "The Betrayal",
		"Confront the Eclipse double agent who orchestrated the initial weather siphon leak.",
		"Intel reveals that High Councilor Malakar secretly betrayed the realm to Corvin.",
		"Defeat Malakar and recover the master command cipher.",
		"Defeat Malakar in under 120 seconds.",
		"res://scenes/levels/campaign/level_52.tscn",
		"BOSS_HUNT", "thunder", 7, "Councilor Malakar", 7000, 950, "",
		[
			{"speaker": "Lyra", "text": "Malakar! You sold out your own people for promise of ether immortality!"},
			{"speaker": "Kael", "text": "No more lies, Malakar. Pay for your treason."}
		]
	)

	_add_level(53, "lvl_53_citadel_assault", "region_5", "The Citadel Assault",
		"Breach the Grand Spire of the Eclipse Citadel.",
		"The inner sanctum is heavily barricaded with void-infused barriers.",
		"Fight your way up the Grand Spire and eliminate the Sovereign's personal guard.",
		"Maintain over 85% accuracy during the assault.",
		"res://scenes/levels/campaign/level_53.tscn",
		"ELIMINATION", "thunder", 8, "", 7500, 1000, "",
		[
			{"speaker": "Lyra", "text": "The Grand Spire elevator is active! We're ascending to Corvin's throne room!"},
			{"speaker": "Kael", "text": "Check weapons. Refill magazines. This is the final ascent."}
		]
	)

	_add_level(54, "lvl_54_last_weather_fragment", "region_5", "The Last Weather Fragment",
		"Reclaim the Master Celestial Core powering Corvin's doomsday weapon.",
		"The Core contains the primordial balance of the entire atmospheric biosphere.",
		"Shatter the void containment matrix and absorb the Master Core.",
		"Absorb the Core before void instability exceeds 100%.",
		"res://scenes/levels/campaign/level_54.tscn",
		"RECON_INVESTIGATION", "thunder", 7, "", 8000, 1100, "",
		[
			{"speaker": "Lyra", "text": "The Master Celestial Core is destabilizing! Corvin is trying to tear the sky apart!"},
			{"speaker": "Kael", "text": "Absorbing the core into my ether reserve! The power of all four skies is unified!"}
		]
	)

	_add_level(55, "lvl_55_eclipse_sovereign", "region_5", "The Eclipse Sovereign",
		"Defeat the ultimate mastermind: High Magus Eclipse Sovereign Corvin and restore the skies.",
		"Corvin wields a stolen fusion of all four primal elements and void magic atop the Citadel Pinnacle.",
		"Defeat Eclipse Sovereign Corvin and unleash Storm Burst Ultimate [G] at the Master Spire.",
		"Defeat Corvin without dying once.",
		"res://scenes/levels/campaign/level_55.tscn",
		"BOSS_HUNT", "thunder", 8, "Eclipse Sovereign Corvin", 10000, 2000, "Supreme Weather Mastery & Campaign Victory",
		[
			{"speaker": "Corvin", "text": "You are too late, Kael! The old skies were weak! In their place, I shall forge a permanent eclipse!"},
			{"speaker": "Kael", "text": "The weather belongs to the earth and its people, Corvin. Your eclipse ends NOW!"},
			{"speaker": "Lyra", "text": "Unleash everything you have, Kael! For Verdantia! For the skies!"}
		]
	)

static func _add_level(
	idx: int,
	lvl_id: String,
	reg_id: String,
	lvl_title: String,
	lvl_desc: String,
	brief: String,
	main_obj: String,
	opt_obj: String,
	scn_path: String,
	m_type: String,
	weather: String,
	enemies: int,
	boss: String,
	xp: int,
	shards: int,
	unlock: String,
	dialogue: Array
) -> void:
	_levels_cache.append({
		"index": idx,
		"level_id": lvl_id,
		"mission_id": "mission_%02d" % idx,
		"region_id": reg_id,
		"name": lvl_title,
		"description": lvl_desc,
		"briefing": brief,
		"main_objective": main_obj,
		"optional_objective": opt_obj,
		"scene": scn_path,
		"mission_type": m_type,
		"element": weather,
		"required_kills": enemies,
		"boss": boss,
		"reward_xp": xp,
		"reward_shards": shards,
		"unlocked_weather": unlock,
		"intro_dialogue": dialogue
	})

