class_name SliceFeedbackAudio
extends RefCounted

## Deterministic project-authored PCM cues. Keeping the short electronic
## waveforms in source makes their origin and SFX routing auditable without
## introducing music, ambience or an external asset dependency.

const MIX_RATE := 22050
const AMPLITUDE := 0.22

const PROFILES := {
	SliceDeviceFeedbackState.EVENT_CORE_REPAIRED: {
		"duration": 0.18,
		"start_hz": 420.0,
		"end_hz": 620.0,
		"overtone": 0.22,
		"pulses": 1,
	},
	SliceDeviceFeedbackState.EVENT_CORE_CHARGED: {
		"duration": 0.22,
		"start_hz": 520.0,
		"end_hz": 920.0,
		"overtone": 0.28,
		"pulses": 1,
	},
	SliceDeviceFeedbackState.EVENT_CORE_SAMPLE_INSTALLED: {
		"duration": 0.24,
		"start_hz": 760.0,
		"end_hz": 560.0,
		"overtone": 0.38,
		"pulses": 2,
	},
	SliceDeviceFeedbackState.EVENT_REACTOR_POWER_LOST: {
		"duration": 0.16,
		"start_hz": 360.0,
		"end_hz": 170.0,
		"overtone": 0.18,
		"pulses": 1,
	},
	SliceDeviceFeedbackState.EVENT_REACTOR_STARTED: {
		"duration": 0.14,
		"start_hz": 330.0,
		"end_hz": 520.0,
		"overtone": 0.24,
		"pulses": 1,
	},
	SliceDeviceFeedbackState.EVENT_REACTOR_BLOCKED: {
		"duration": 0.20,
		"start_hz": 250.0,
		"end_hz": 190.0,
		"overtone": 0.32,
		"pulses": 2,
	},
	SliceDeviceFeedbackState.EVENT_DEVICE_POWER_LOST: {
		"duration": 0.15,
		"start_hz": 340.0,
		"end_hz": 155.0,
		"overtone": 0.20,
		"pulses": 1,
	},
	SliceDeviceFeedbackState.EVENT_DEVICE_RUNNING: {
		"duration": 0.13,
		"start_hz": 390.0,
		"end_hz": 610.0,
		"overtone": 0.20,
		"pulses": 1,
	},
	SliceDeviceFeedbackState.EVENT_DEVICE_BLOCKED: {
		"duration": 0.18,
		"start_hz": 235.0,
		"end_hz": 175.0,
		"overtone": 0.34,
		"pulses": 2,
	},
}


static func stream_for(event_id: StringName) -> AudioStreamWAV:
	if not PROFILES.has(event_id):
		return null
	var profile: Dictionary = PROFILES[event_id]
	var duration := float(profile["duration"])
	var sample_count := roundi(float(MIX_RATE) * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var progress := float(index) / float(sample_count - 1)
		var time_seconds := float(index) / float(MIX_RATE)
		var frequency_delta := (
			float(profile["end_hz"])
			- float(profile["start_hz"])
		)
		var phase := TAU * (
			float(profile["start_hz"]) * time_seconds
			+ 0.5 * frequency_delta * time_seconds * time_seconds / duration
		)
		var envelope := sin(PI * progress)
		var pulses := int(profile["pulses"])
		if pulses > 1:
			envelope *= 0.35 + 0.65 * maxf(
				0.0, sin(PI * float(pulses) * progress)
			)
		var carrier := sin(phase)
		var overtone := sin(phase * 2.0) * float(profile["overtone"])
		var sample := clampi(
			roundi((carrier + overtone) * envelope * AMPLITUDE * 32767.0),
			-32768,
			32767
		)
		data[index * 2] = sample & 0xff
		data[index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.resource_name = String(event_id)
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
