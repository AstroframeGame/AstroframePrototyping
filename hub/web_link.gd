extends Node
class_name WebLinkOpener

# invite to playtesting server
func discord():
	OS.shell_open("https://discord.gg/HREpgXceUW")

# invite to public prototyping github
func github():
	OS.shell_open("https://github.com/AstroframeGame/AstroframePrototyping")

# ships folder
func ships_folder():
	OS.shell_open(ProjectSettings.globalize_path("user://"))
