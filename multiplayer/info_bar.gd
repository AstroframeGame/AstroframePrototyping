extends Label
class_name InfoBar

#region Indicator Text Info
var info_colors = {
	"green"  : Color("a2c067ff", 1.0),
	"yellow" : Color("ddd04aff", 1.0),
	"orange" : Color("f9c169ff", 1.0),
	"red"    : Color("c8695cff", 1.0),
	"off"    :  Color("white", 0.0)
}
var info_messages = {
	"STEAMINIT" : { "msg" : "Steam Initialized. Username is %s.", "color" : "green" },
	"FAILINIT" : { "msg" : "Steam failed to Initialize.", "color" : "red" },
	"HOSTLOBBY" : { "msg" : "Initializing Lobby...", "color" : "yellow" },
	"JOINLOBBY" : { "msg" : "Joining Lobby %d...",   "color" : "yellow" },
	"LOBBYCREATED" : { "msg" : "Lobby Created with PEER_ID( %d )!\nLobby ID copied to clipboard. Share the lobby ID with friends to play with them!",   "color" : "green" },
	"LOBBYJOINED"  : { "msg" : "Lobby %d Joined. Connecting Peer...",    "color" : "yellow" }, 	
	"HOSTLEFT"  : { "msg" : "Host Left! Returned to Menu",    "color" : "orange" },
	"PEERLEFT"  : { "msg" : "%s left...",    "color" : "orange" },
	"PEERJOIN"  : { "msg" : "PEER_ID( %d ) joined. Retrieving username...",  "color" : "yellow"},
	"USER"      : { "msg" : "%s synced!\nPlayers:\n[ %s ]", "color" : "green"},
	"ERASE" : { "msg" : "", "color" : "off" },
	"CUSTOM" : { }
}
#endregion

func write(code: String, args: Array = []):
	
	var message    = ""
	var text_color = info_colors.yellow
	var is_custom  = code == "CUSTOM"
	if is_custom:
		message    = args[0]
		text_color = info_colors[args[1]]
	elif code in info_messages.keys():
		message    = info_messages[code].msg
		text_color = info_colors[info_messages[code].color]
	
	if args.is_empty() or is_custom:
		text = message
	else:
		text = message % args
	
	if has_theme_color_override("font_color"):
		remove_theme_color_override("font_color")
	add_theme_color_override("font_color", text_color)
	
