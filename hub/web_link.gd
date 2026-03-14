extends Node
class_name WebLinkOpener

# invite to playtesting server
func discord():
	OS.shell_open("https://discord.gg/HREpgXceUW")

func instagram():
	OS.shell_open("https://www.instagram.com/astroframegame/")

# invite to public prototyping github
func github():
	OS.shell_open("https://github.com/AstroframeGame/AstroframePrototyping")

# ships folderS
func ships_folder():
	OS.shell_open(ProjectSettings.globalize_path("user://"))
