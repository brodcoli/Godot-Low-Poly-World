extends MeshInstance

onready var _camera = get_node("..")

func _process(delta: float):
	self.mesh.surface_get_material(0).set_shader_param("camera_x", _camera.global_transform.origin.x)
	self.mesh.surface_get_material(0).set_shader_param("camera_y", _camera.global_transform.origin.y)
	self.mesh.surface_get_material(0).set_shader_param("camera_z", _camera.global_transform.origin.z)
