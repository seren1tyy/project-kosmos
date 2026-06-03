extends Node3D

var rotation_speed: float = 0.3

func _process(delta: float):
	#rotate_y(rotation_speed * delta)
	# Лёгкое "парение" вверх-вниз
	position.y = 0.2 + sin(Time.get_ticks_msec() * 0.001) * 0.05
