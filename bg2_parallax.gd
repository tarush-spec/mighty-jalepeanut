extends Node2D

# parallax speed variables
@export var sky_parallax: float = 0.7
@export var bg1_parallax: float = 0.5
@export var bg2_parallax: float = 0.6
@export var bgenv_parallax: float = 0.6

# player
@onready var player: CharacterBody2D = $"../Player"


# tile map layer variables
@onready var sky: TileMapLayer = $sky
@onready var bg_1: TileMapLayer = $background1
@onready var bg_2: TileMapLayer = $background2
@onready var bgenv: TileMapLayer = $backgroundenv

# parallax process
func _process(delta):
	bg_1.global_position = player.global_position * bg1_parallax
	bg_2.global_position = player.global_position * bg2_parallax
	bgenv.global_position = player.global_position * bgenv_parallax
	sky.global_position = player.global_position * sky_parallax
