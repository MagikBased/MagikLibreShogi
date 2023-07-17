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

#var boardScale = $Board.BoardSprite.squareSize
var globalPieceScale = 1

@export var pieceType = PieceType.Pawn
@export var pieceOwner = Player.Sente
@export var promoted: bool = false

var selected: bool = false

func _ready():
	scale *= globalPieceScale
	set_piece_type()
	if pieceOwner == Player.Gote:
		rotation_degrees += 180
		
func set_piece_type():
	pass

