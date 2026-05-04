extends Node2D

@export var sky_parallax: float = 0.7
@export var bg1_parallax: float = 0.4
@export var bg2_parallax: float = 0.6
@export var bgenv_parallax: float = 0.6

@onready var player: CharacterBody2D = $"../../Player"
@onready var sky: TileMapLayer = $SKY
@onready var bg1: TileMapLayer = $Background
@onready var bg2: TileMapLayer = $Background2
@onready var bg_env: TileMapLayer = $BackgroundEnv




func _process(delta):
	# SKY PARALLAX
	sky.global_position = sky_parallax * player.position
	
	# BACKGROUND PARALLAX
	bg1.position = bg1_parallax * player.position
	
	#BACKGROUND 2 PARALLAX
	bg2.position = bg2_parallax * player.position
	
	#BACKGROUNS TERRAIN PARALLAX
	bg_env.position = bgenv_parallax * player.position
	#global_position = sky_parallax * player.global_position
