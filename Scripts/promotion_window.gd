extends Sprite2D

enum PieceType{
	King,
	Pawn,
	Lance,
	Knight,
	Silver,
	Gold,
	Bishop,
	Rook
}

var parentNode = get_parent() #unused?
var sprite_texture = null
var sprite_texture_promoted = null
@onready var selectPromote: Area2D = $Area2D_promote
@onready var selectStay: Area2D = $Area2D_stay

func _ready():
	set_process_input(true)
	match get_parent().pieceType:
		PieceType.Pawn:
			sprite_texture = load("res://Images/Pieces/Pawn.png")
			sprite_texture_promoted = load("res://Images/Pieces/Promoted Pawn.png")
		PieceType.Lance:
			sprite_texture = load("res://Images/Pieces/Lance.png")
			sprite_texture_promoted = load("res://Images/Pieces/Promoted Lance.png")
		PieceType.Knight:
			sprite_texture = load("res://Images/Pieces/Knight.png")
			sprite_texture_promoted = load("res://Images/Pieces/Promoted Knight.png")
		PieceType.Silver:
			sprite_texture = load("res://Images/Pieces/Silver General.png")
			sprite_texture_promoted = load("res://Images/Pieces/Promoted Silver General.png")
		PieceType.Bishop:
			sprite_texture = load("res://Images/Pieces/Bishop.png")
			sprite_texture_promoted = load("res://Images/Pieces/Promoted Bishop.png")
		PieceType.Rook:
			sprite_texture = load("res://Images/Pieces/Rook.png")
			sprite_texture_promoted = load("res://Images/Pieces/Promoted Rook.png")
		_:
			sprite_texture = null

func _draw():
	draw_texture(sprite_texture_promoted,Vector2(float(-texture.get_width())/2,float(-texture.get_height())/2),modulate)
	draw_texture(sprite_texture,Vector2(float(-texture.get_width())/2,float(texture.get_height()) / 2 - float(texture.get_height())/2),modulate)

func selected_promote(selection):
	if selection:
		get_parent().promoted = true
		get_parent().set_piece_type()
	get_parent().boardSprite.isPromoting = false
	queue_free()

