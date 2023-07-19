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
enum Player{
	Sente,
	Gote
}

@onready var board = get_parent()
@onready var boardSprite = board.get_node("BoardSprite")
@onready var globalPieceScale = (boardSprite.texture.get_width() * boardSprite.scale.x) / (boardSprite.boardSize.x * texture.get_width())
@onready var boardPosition = board.global_position

@export var pieceType = PieceType.Pawn
@export var pieceOwner = Player.Sente
@export var promoted: bool = false

@export var currentPosition: Vector2 = Vector2(1,9)
var selected: bool = false
var dragging: bool = false
var dragging_position: Vector2

func _ready():
	scale *= globalPieceScale
	set_piece_type()
	snap_to_grid()
	if pieceOwner == Player.Gote:
		rotation_degrees += 180

func snap_to_grid():
	var posNotation:Vector2 = boardSprite.find_square_center(currentPosition.x,currentPosition.y)
	position = posNotation * boardSprite.scale
	#print(posNotation)
	#print(to_global(posNotation))
	#print("piece position " + str(position))

func set_piece_type():
	var sprite_texture = null
	match pieceType:
		PieceType.King:
			sprite_texture = load("res://Images/Pieces/King.png")
		PieceType.Pawn:
			sprite_texture = load("res://Images/Pieces/Pawn.png")
		PieceType.Lance:
			sprite_texture = load("res://Images/Pieces/Lance.png")
		PieceType.Knight:
			sprite_texture = load("res://Images/Pieces/Knight.png")
		PieceType.Silver:
			sprite_texture = load("res://Images/Pieces/Silver General.png")
		PieceType.Gold:
			sprite_texture = load("res://Images/Pieces/Gold General.png")
		PieceType.Bishop:
			sprite_texture = load("res://Images/Pieces/Bishop.png")
		PieceType.Rook:
			sprite_texture = load("res://Images/Pieces/Rook.png")
		_:
			sprite_texture = null
	texture = sprite_texture

func _input(_event):
	pass


