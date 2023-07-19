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
@export var selected: bool = false
var dragging: bool = false
var dragging_position: Vector2
var selectionColor = Color(0,1,0,0.5)
@onready var rectSize = Vector2(texture.get_width(),texture.get_height())

func _ready():
	scale *= globalPieceScale
	set_piece_type()
	snap_to_grid()
	if pieceOwner == Player.Gote:
		rotation_degrees += 180
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if get_rect().has_point(to_local(event.position)):
			selected = !selected
			queue_redraw()

func _draw():
	if selected:
		draw_rect(Rect2(Vector2(0,0) - rectSize/2,rectSize),selectionColor,true)

func snap_to_grid():
	var posNotation:Vector2 = boardSprite.find_square_center(currentPosition.x,currentPosition.y)
	position = posNotation * boardSprite.scale

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



