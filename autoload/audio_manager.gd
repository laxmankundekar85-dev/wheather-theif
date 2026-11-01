## AudioManager.gd
## Global autoload for managing music and sound effects with volume control
## and procedural sound synthesis (no external audio files required).
extends Node

var music_volume: float = 0.8
var sfx_volume: float = 1.0

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool_size: int = 12

var _generated_sounds: Dictionary = {}

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	for i in range(_sfx_pool_size):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)

	# Generate all procedural game sounds
	_generate_all_sfx()
	print("[AudioManager] Initialized with %d SFX players and %d procedural sounds." % [_sfx_pool_size, _generated_sounds.size()])

# ─── Sound Playback API ───────────────────────────────────────────────────────

func play_sound(sound_name: String) -> void:
	if sound_name in _generated_sounds:
		play_sfx(_generated_sounds[sound_name])
	else:
		print("[AudioManager] Sound not found: ", sound_name)

func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = linear_to_db(sfx_volume)
			p.play()
			return
	# If all busy, reuse first player
	if _sfx_players.size() > 0:
		_sfx_players[0].stream = stream
		_sfx_players[0].volume_db = linear_to_db(sfx_volume)
		_sfx_players[0].play()

func play_music(stream: AudioStream, fade_in: float = 0.5) -> void:
	if _music_player.playing and _music_player.stream == stream:
		return
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(0.0)
	_music_player.play()
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", linear_to_db(music_volume), fade_in)

func stop_music(fade_out: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", linear_to_db(0.0), fade_out)
	tween.tween_callback(_music_player.stop)

func set_music_volume(vol: float) -> void:
	music_volume = clamp(vol, 0.0, 1.0)
	if _music_player:
		_music_player.volume_db = linear_to_db(music_volume)
	if AudioServer.get_bus_index("Music") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clamp(vol, 0.0, 1.0)
	for p in _sfx_players:
		p.volume_db = linear_to_db(sfx_volume)
	if AudioServer.get_bus_index("SFX") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))

# ─── Procedural Audio Synthesis ───────────────────────────────────────────────

func _generate_all_sfx() -> void:
	_generated_sounds["jump"] = _synth_tone_slide(180.0, 360.0, 0.14, 0.4, 0)
	_generated_sounds["land"] = _synth_noise(0.08, 0.35, 120.0)
	_generated_sounds["collect"] = _synth_arpeggio([523.25, 659.25, 783.99, 1046.50], 0.06, 0.45)
	_generated_sounds["weather_rain"] = _synth_rain_burst(0.6, 0.4)
	_generated_sounds["weather_snow"] = _synth_frost_chime(0.5, 0.4)
	_generated_sounds["weather_wind"] = _synth_wind_gust(0.7, 0.4)
	_generated_sounds["weather_sun"] = _synth_sun_radiance(0.6, 0.45)
	_generated_sounds["damage"] = _synth_damage_hit(0.2, 0.5)
	_generated_sounds["enemy_defeat"] = _synth_tone_slide(350.0, 90.0, 0.22, 0.5, 1)
	_generated_sounds["stomp"] = _synth_tone_slide(420.0, 180.0, 0.12, 0.5, 0)
	_generated_sounds["checkpoint"] = _synth_arpeggio([440.0, 554.37, 659.25, 880.0], 0.09, 0.5)
	_generated_sounds["button_click"] = _synth_tone_slide(400.0, 600.0, 0.04, 0.25, 0)
	_generated_sounds["puzzle_solve"] = _synth_arpeggio([392.0, 523.25, 659.25, 783.99, 1046.5], 0.08, 0.5)
	_generated_sounds["heart_pickup"] = _synth_arpeggio([587.33, 880.0], 0.08, 0.4)
	_generated_sounds["sword_swing"] = _synth_wind_gust(0.18, 0.3)
	_generated_sounds["dash"] = _synth_wind_gust(0.24, 0.35)
	_generated_sounds["hit"] = _synth_damage_hit(0.15, 0.45)
	
	# Third-Person Shooter Audio
	_generated_sounds["rifle_shoot"] = _synth_gunshot(0.22, 0.55, 230.0)
	_generated_sounds["rifle_shoot_silenced"] = _synth_gunshot(0.12, 0.32, 110.0)
	_generated_sounds["smg_shoot"] = _synth_gunshot(0.12, 0.42, 340.0)
	_generated_sounds["shotgun_blast"] = _synth_gunshot(0.40, 0.75, 120.0)
	_generated_sounds["sniper_fire"] = _synth_gunshot(0.48, 0.85, 95.0)
	_generated_sounds["carbine_burst"] = _synth_gunshot(0.24, 0.50, 460.0)
	_generated_sounds["bullet_impact"] = _synth_bullet_impact(0.12, 0.4)
	_generated_sounds["hitmarker"] = _synth_tone_slide(1800.0, 1600.0, 0.035, 0.3, 0)
	_generated_sounds["headshot_ding"] = _synth_arpeggio([1200.0, 2400.0], 0.045, 0.5)
	_generated_sounds["reload_start"] = _synth_reload_slide(0.25, 0.38)
	_generated_sounds["reload_finish"] = _synth_tone_slide(400.0, 750.0, 0.08, 0.42, 1)
	_generated_sounds["dry_fire_click"] = _synth_tone_slide(950.0, 600.0, 0.03, 0.35, 0)
	_generated_sounds["ability_cast"] = _synth_arpeggio([440.0, 660.0, 880.0], 0.06, 0.45)
	_generated_sounds["bullet_whiz"] = _synth_wind_gust(0.16, 0.30)

func _create_wav(samples: PackedByteArray, sample_rate: int = 22050) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = samples
	return wav

func _synth_tone_slide(start_freq: float, end_freq: float, duration: float, volume: float, waveform: int = 0) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var freq: float = lerp(start_freq, end_freq, t)
		phase += (TAU * freq) / float(rate)

		var env := (1.0 - t) * volume
		var s := 0.0
		if waveform == 0:
			s = sin(phase)
		elif waveform == 1:
			s = 1.0 if sin(phase) > 0.0 else -1.0 # square
		else:
			s = fmod(phase / TAU, 1.0) * 2.0 - 1.0 # saw

		var sample_val := int(clamp(s * env, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_val)

	return _create_wav(bytes, rate)

func _synth_arpeggio(frequencies: Array, note_duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var total_notes := frequencies.size()
	var total_samples := int(total_notes * note_duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	var note_samples := int(note_duration * rate)
	var phase := 0.0

	for n in range(total_notes):
		var freq: float = frequencies[n]
		for i in range(note_samples):
			var global_idx := n * note_samples + i
			var t := float(i) / float(note_samples)
			phase += (TAU * freq) / float(rate)
			var env := (1.0 - t * 0.7) * volume
			var s := sin(phase) + 0.3 * sin(phase * 2.0)
			var sample_val := int(clamp(s * env, -1.0, 1.0) * 32767.0)
			bytes.encode_s16(global_idx * 2, sample_val)

	return _create_wav(bytes, rate)

func _synth_noise(duration: float, volume: float, _lp_freq: float = 200.0) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	var last := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := (1.0 - t) * volume
		var white := randf_range(-1.0, 1.0)
		last += (white - last) * 0.15 # Simple lowpass
		var sample_val := int(clamp(last * env, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_val)

	return _create_wav(bytes, rate)

func _synth_rain_burst(duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	var lp := 0.0
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI) * volume
		var white := randf_range(-1.0, 1.0)
		lp += (white - lp) * 0.2
		phase += (TAU * 440.0) / float(rate)
		var s := lp * 0.7 + sin(phase) * 0.3
		var sample_val := int(clamp(s * env, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_val)

	return _create_wav(bytes, rate)

func _synth_frost_chime(duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	var phase1 := 0.0
	var phase2 := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := (1.0 - t) * volume
		phase1 += (TAU * 1318.5) / float(rate) # E6
		phase2 += (TAU * 1760.0) / float(rate) # A6
		var s := 0.6 * sin(phase1) + 0.4 * sin(phase2)
		var sample_val := int(clamp(s * env, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_val)

	return _create_wav(bytes, rate)

func _synth_wind_gust(duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI) * volume
		var white := randf_range(-1.0, 1.0)
		var filter_cutoff := 0.05 + 0.15 * sin(t * PI)
		lp += (white - lp) * filter_cutoff
		var sample_val := int(clamp(lp * env * 2.0, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_val)

	return _create_wav(bytes, rate)

func _synth_sun_radiance(duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	var phase1 := 0.0
	var phase2 := 0.0
	var phase3 := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI) * volume
		phase1 += (TAU * 523.25) / float(rate) # C5
		phase2 += (TAU * 659.25) / float(rate) # E5
		phase3 += (TAU * 783.99) / float(rate) # G5
		var s := 0.4 * sin(phase1) + 0.35 * sin(phase2) + 0.25 * sin(phase3)
		var sample_val := int(clamp(s * env, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_val)

	return _create_wav(bytes, rate)

func _synth_damage_hit(duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := (1.0 - t) * volume
		var freq: float = lerp(180.0, 40.0, t)
		phase += (TAU * freq) / float(rate)
		var s := (1.0 if sin(phase) > 0.0 else -1.0) * 0.7 + randf_range(-0.3, 0.3)
		var sample_val := int(clamp(s * env, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_val)

	return _create_wav(bytes, rate)

func _synth_gunshot(duration: float, volume: float, base_pitch: float = 220.0) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	var phase := 0.0
	var last_noise := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := exp(-t * 16.0) * volume
		var freq: float = lerp(base_pitch, 45.0, min(1.0, t * 4.0))
		phase += (TAU * freq) / float(rate)

		var white := randf_range(-1.0, 1.0)
		last_noise += (white - last_noise) * 0.45
		var punch := sin(phase) * 0.6 + last_noise * 0.75
		var sample_val := int(clamp(punch * env, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_val)

	return _create_wav(bytes, rate)

func _synth_bullet_impact(duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := exp(-t * 22.0) * volume
		var freq: float = lerp(850.0, 120.0, t)
		phase += (TAU * freq) / float(rate)
		var s := (sin(phase) * 0.5 + randf_range(-0.5, 0.5)) * env
		var sample_val := int(clamp(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_val)

	return _create_wav(bytes, rate)

func _synth_reload_slide(duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)

	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(t * PI) * volume
		var freq: float = lerp(350.0, 520.0, t)
		phase += (TAU * freq) / float(rate)
		var s := (sin(phase) * 0.4 + randf_range(-0.3, 0.3)) * env
		var sample_val := int(clamp(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_val)

	return _create_wav(bytes, rate)
