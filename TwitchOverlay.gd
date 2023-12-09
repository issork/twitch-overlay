extends Control

const TOKEN_FILE : String = "user://token.json"

@export var client_id : String = "9x951o0nd03na7moohwetpjjtds0or"
@export var channel : String
@export var username : String

var id : TwitchIDConnection
var api : TwitchAPIConnection
var irc : TwitchIRCConnection
var eventsub : TwitchEventSubConnection

var cmd_handler : GIFTCommandHandler = GIFTCommandHandler.new()

var iconloader : TwitchIconDownloader

func _ready() -> void:
	get_window().mouse_passthrough = true
	get_window().always_on_top = true
	get_viewport().transparent_bg = true
	var token : UserAccessToken
	var scopes : Array = ["chat:read", "chat:edit", "moderator:read:followers", "channel:read:goals"]
	if (FileAccess.file_exists(TOKEN_FILE)):
		var file : FileAccess = FileAccess.open(TOKEN_FILE, FileAccess.READ)
		var data : Dictionary = JSON.parse_string(file.get_as_text())
		if (data["scope"] != scopes):
			token = await(get_new_token(scopes))
		else:
			token = UserAccessToken.new(data, data["client_id"])
	else:
		token = await(get_new_token(scopes))

	id = TwitchIDConnection.new(token)
	irc = TwitchIRCConnection.new(id)
	api = TwitchAPIConnection.new(id)
	iconloader = TwitchIconDownloader.new(api)
	get_tree().process_frame.connect(id.poll)

	if(!await(irc.connect_to_irc(username))):
		return
	irc.request_capabilities()
	irc.join_channel(channel)

	irc.chat_message.connect(put_chat)

	irc.chat_message.connect(cmd_handler.handle_command)
	irc.whisper_message.connect(cmd_handler.handle_command.bind(true))

	cmd_handler.add_command("gift", gift)

	eventsub = TwitchEventSubConnection.new(api)
	await(eventsub.connect_to_eventsub())
	eventsub.event.connect(on_event)
	var user_ids : Dictionary = await(api.get_users_by_name([username]))
	if (user_ids.has("data") && user_ids["data"].size() > 0):
		var user_id : String = user_ids["data"][0]["id"]
		var goals_data : Dictionary = await(api.get_creator_goals(user_id))
		
		var data : Dictionary = goals_data["data"][0]
		
		%StreamGoal.max_value = data["target_amount"]
		%StreamGoal.value = data["current_amount"]
		%StreamGoal/Label.text = "Followers: %d/%d" % [%StreamGoal.value, %StreamGoal.max_value]
		
		await(eventsub.subscribe_event("channel.follow", "2", {"broadcaster_user_id": user_id, "moderator_user_id": user_id}))
		await(eventsub.subscribe_event("channel.goal.progress", "1", {"broadcaster_user_id": user_id}))

func get_new_token(scopes : Array) -> UserAccessToken:
	var token : UserAccessToken
	var auth : ImplicitGrantFlow = ImplicitGrantFlow.new()
	get_tree().process_frame.connect(auth.poll)
	token = await(auth.login(client_id, scopes))
	if (token == null):
		return null
	var file : FileAccess = FileAccess.open(TOKEN_FILE, FileAccess.WRITE)
	var data : Dictionary = {}
	data["access_token"] = token.token
	data["scope"] = token.scopes
	data["client_id"] = token.last_client_id
	file.store_string(JSON.stringify(data))
	return token

func gift(cmd_info : CommandInfo) -> void:
	irc.chat("The GIFT library I created can be found here: https://github.com/issork/gift")

func on_event(type : String, data : Dictionary) -> void:
	match(type):
		"channel.follow":
			print("%s followed your channel!" % data["user_name"])
			%FollowNotification.show_notification("%s followed your channel!" % data["user_name"])
		"channel.goal.progress":
			%StreamGoal.max_value = data["target_amount"]
			%StreamGoal.value = data["current_amount"]
			%StreamGoal/Label.text = "Followers: %d/%d" % [%StreamGoal.value, %StreamGoal.max_value]

func send_message() -> void:
	irc.chat(%LineEdit.text)
	%LineEdit.text = ""

func put_chat(senderdata : SenderData, msg : String):
	var label : RichTextLabel = preload("res://ChatMessage.tscn").instantiate()
	var time = Time.get_time_dict_from_system()
	label.push_font_size(12)
	label.push_color(Color.WEB_GRAY)
	label.add_text("%02d:%02d " % [time["hour"], time["minute"]])
	label.pop()
	label.push_font_size(14)
	var badges : Array[Texture2D]
	for badge in senderdata.tags["badges"].split(",", false):
		label.add_image(await(iconloader.get_badge(badge, senderdata.tags["room-id"])), 0, 0, Color.WHITE, INLINE_ALIGNMENT_CENTER)
	label.push_bold()
	if (senderdata.tags["color"] != ""):
		label.push_color(Color(senderdata.tags["color"]))
	label.add_text(" %s" % senderdata.tags["display-name"])
	label.push_color(Color.WHITE)
	label.push_normal()
	label.add_text(": ")
	var locations : Array[EmoteLocation] = []
	if (senderdata.tags.has("emotes")):
		for emote in senderdata.tags["emotes"].split("/", false):
			var data : PackedStringArray = emote.split(":")
			for d in data[1].split(","):
				var start_end = d.split("-")
				locations.append(EmoteLocation.new(data[0], int(start_end[0]), int(start_end[1])))
	locations.sort_custom(Callable(EmoteLocation, "smaller"))
	for loc in locations:
		%Emotes.put_emote(await(iconloader.get_emote(loc.id, true, "3.0")))
	if (locations.is_empty()):
		label.add_text(msg)
	else:
		var offset = 0
		for loc in locations:
			label.add_text(msg.substr(offset, loc.start - offset))
			label.add_image(await(iconloader.get_emote(loc.id)), 0, 0, Color.WHITE, INLINE_ALIGNMENT_CENTER)
			offset = loc.end + 1
	%Messages.add_child(label)
	var old_msg : Control = %Messages.get_child(0)
	if (old_msg != null):
		while (!%Messages.get_global_rect().intersects(old_msg.get_global_rect())):
			old_msg.queue_free()

class EmoteLocation extends RefCounted:
	var id : String
	var start : int
	var end : int

	func _init(emote_id, start_idx, end_idx):
		self.id = emote_id
		self.start = start_idx
		self.end = end_idx

	static func smaller(a : EmoteLocation, b : EmoteLocation):
		return a.start < b.start
