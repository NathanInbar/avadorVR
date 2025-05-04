@tool
extends MeshInstance3D

@export var spawn_radius:float;

func _ready():
    DebugDraw3D.draw_sphere(position,spawn_radius);
