tool
extends EditorPlugin

const AUTOLOAD_NAME := "SteamCloud"

func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/steam_cloud/cloud.gd")



func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
