extends Node2D
# singleton defines name

# maybe we use a pooling system?

func clear():
	for p in get_children():
		p.call_deferred("queue_free")
	# destroy all projectiles
