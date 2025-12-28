extends Area3D

func _on_body_entered(body: Node3D) -> void:
		# التأكد أن الذي دخل المنطقة هو اللاعب
	if body.name == "Player":
		# تحديث موقع الحفظ في سكربت اللاعب
		body.last_checkpoint_position = global_transform.origin
		print("Checkpoint reached!")
