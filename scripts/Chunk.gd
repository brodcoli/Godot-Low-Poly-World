extends Spatial

onready var ocean_node = preload("res://scenes/Ocean.tscn")
onready var _mesh_instance = $Mesh

const _width = Constants.CHUNK_WIDTH
const _tri_width = Constants.TRI_WIDTH
const _width_for_vertices = _width + 1
const total_width = _width * _tri_width
var pos: Vector2
var global_pos: Vector2
#var offset: Vector3
onready var biome = Noise.get_biome(pos.x * total_width, pos.y * total_width)
#const level_of_detail = 0.25

var _surface_tool = SurfaceTool.new()
var _data_tool = MeshDataTool.new()
var _plane_array: ArrayMesh
var _start_time: int
var _has_vertex_below_water = false

var rng = RandomNumberGenerator.new()

func init(pos: Vector2):
	self.pos = pos
	self.global_pos = pos * total_width
	#self.offset = Vector3(total_width / 2, 0, total_width / 2)
	self.transform.origin = Vector3(global_pos.x, 0, global_pos.y)
	
func _create_subdivided_plane():
	var plane = PlaneMesh.new()
	plane.size = Vector2(_width, _width) * _tri_width
	plane.subdivide_width = _width# * level_of_detail
	plane.subdivide_depth = _width# * level_of_detail
	return plane
	
func _init_plane_array():
	_plane_array = _surface_tool.commit()
	
func _init_tools_and_plane_array():
	var plane = _create_subdivided_plane()
	_surface_tool.create_from(plane, 0)
	_init_plane_array()
	_data_tool.create_from_surface(_plane_array, 0)

func _init_collision():
	_mesh_instance.create_trimesh_collision()


func _init_mesh():
	_mesh_instance.mesh = ArrayMesh.new()
	
func _get_heightmap_vertices():
	var vertices = []
	
	for x in range(_width_for_vertices):
		for z in range(_width_for_vertices):
			var vertex = Vector3(x, 0, z) * _tri_width
			
			var pos = Vector2(vertex.x + global_pos.x, vertex.z + global_pos.y)
			vertex.y = Noise.get_terrain_noise(pos.x, pos.y)
			
			if vertex.y <= Constants.WATER_LEVEL:
				_has_vertex_below_water = true
	
			vertices.append(vertex)
			
	return vertices
	
func _calculate_respective_biome_faces_and_normals(vertices, biome_specific_vertices, biome_specific_normals):
	var w = _width_for_vertices
	
	for i in range(vertices.size()):
		if (i + 1) % w == 0 or i >= w * (w - 1):
			continue
			
		var avg_point_of_vertices = (vertices[i + w] + vertices[i + 1] + vertices[i]) / 3
		var pos = avg_point_of_vertices + Vector3(global_pos.x, 0, global_pos.y)
		var biome = Noise.get_biome(pos.x, pos.z)
		
		biome_specific_vertices[biome].push_back(vertices[i + w])
		biome_specific_vertices[biome].push_back(vertices[i + 1])
		biome_specific_vertices[biome].push_back(vertices[i])
		
		var n = (vertices[i] - vertices[i + w]).cross(vertices[i + 1] - vertices[i + w]).normalized()
		biome_specific_normals[biome].push_back(n)
		biome_specific_normals[biome].push_back(n)
		biome_specific_normals[biome].push_back(n)
		
		
		avg_point_of_vertices = (vertices[i + w] + vertices[i + w + 1] + vertices[i + 1]) / 3
		pos = avg_point_of_vertices + Vector3(global_pos.x, 0, global_pos.y)
		biome = Noise.get_biome(pos.x, pos.z)
		
		biome_specific_vertices[biome].push_back(vertices[i + w])
		biome_specific_vertices[biome].push_back(vertices[i + w + 1])
		biome_specific_vertices[biome].push_back(vertices[i + 1])
		
		n = (vertices[i + 1] - vertices[i + w]).cross(vertices[i + w + 1] - vertices[i + w]).normalized()
		biome_specific_normals[biome].push_back(n)
		biome_specific_normals[biome].push_back(n)
		biome_specific_normals[biome].push_back(n)
	
func _add_faces_and_materials_to_mesh(biome_specific_vertices, biome_specific_normals):
	var i = 0;
	for b in biome_specific_vertices:
		var verts = biome_specific_vertices[b]
		var norms = biome_specific_normals[b]
		if verts.size() == 0:
			continue
		
		var arrays = []
		arrays.resize(ArrayMesh.ARRAY_MAX)
		arrays[ArrayMesh.ARRAY_VERTEX] = PoolVector3Array(verts)
		arrays[ArrayMesh.ARRAY_NORMAL] = PoolVector3Array(norms)
	
		_mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var material = Biomes.dict[b].ground_material
		_mesh_instance.set_surface_material(i, material)
		i += 1
		
func _add_geometry_and_materials_to_mesh():
	var biome_specific_vertices = {}
	var biome_specific_normals = {}
	for biome in Biomes.dict:
		biome_specific_vertices[biome] = []
		biome_specific_normals[biome] = []
	
	_init_mesh()
	var vertices = _get_heightmap_vertices()
	_calculate_respective_biome_faces_and_normals(vertices, biome_specific_vertices, biome_specific_normals)
	_add_faces_and_materials_to_mesh(biome_specific_vertices, biome_specific_normals)
	
func _add_ocean_if_necessary():
	if _has_vertex_below_water:
		var ocean = ocean_node.instance()
		ocean.translation += Vector3(total_width / 2, 0, total_width / 2)
		ocean.translation.y = Constants.WATER_LEVEL
		add_child(ocean)
	
func _populate_decorations():
	var b = Biomes.dict[biome]
	if b.has_method("populate_decorations"):
		b.populate_decorations(self)
	
func _ready():
	rng.randomize()
		
	_add_geometry_and_materials_to_mesh()
	_add_ocean_if_necessary()
	_init_collision()
	_populate_decorations()
