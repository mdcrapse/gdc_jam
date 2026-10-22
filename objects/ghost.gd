extends Node3D

@export var animation: AnimationPlayer
@export var particles_trail: GPUParticles3D
@export var name_label: Label3D

func _process(dt):
	particles_trail.emitting = animation.current_animation == "walk"
