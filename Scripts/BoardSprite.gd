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

@export var boardSize = Vector2(9, 9)
var lineSize = 8 #should be divisible by 4 for even lines
var squareSize = (texture.get_width()) / boardSize.x
var gridColor = Color(0,0,0)
var circleRadius = squareSize * 0.15
var circleColor = Color(0,0,0)
var selectedPiece = null

var piecesOnBoard = []
var sentePiecesOnBoard = []
var gotePiecesOnBoard = []
var pieceData = [] #[pieceType, pieceOwner, pieceID]
var playerTurn = Player.Sente

func _ready():
	board_setup()
	print("PieceData: " + str(pieceData))

func find_square_center(file: int,rank: int) -> Vector2:
	var centerX = (10 - file) * squareSize - squareSize / 2
	var centerY = rank * squareSize - squareSize / 2
	return Vector2(centerX, centerY)

func draw_grid():
	for x in range(1, boardSize.x):
		var xPosition = x * squareSize
		draw_line(Vector2(xPosition, 0), Vector2(xPosition, squareSize * boardSize.x), gridColor, lineSize)
	for y in range(1, boardSize.y):
		var yPosition = y * squareSize
		draw_line(Vector2(0,yPosition), Vector2(squareSize * boardSize.y, yPosition), gridColor, lineSize)
	
	draw_circle(Vector2(squareSize*3,squareSize*3),circleRadius, circleColor)
	draw_circle(Vector2(squareSize*3,squareSize*6),circleRadius, circleColor)
	draw_circle(Vector2(squareSize*6,squareSize*3),circleRadius, circleColor)
	draw_circle(Vector2(squareSize*6,squareSize*6),circleRadius, circleColor)

func _draw():
	draw_grid()


func board_setup():
	create_piece(PieceType.Lance, Player.Sente, Vector2(1,9))
	create_piece(PieceType.Knight, Player.Sente, Vector2(2,9))
	create_piece(PieceType.Silver, Player.Sente, Vector2(3,9))
	create_piece(PieceType.Gold, Player.Sente, Vector2(4,9))
	create_piece(PieceType.King, Player.Sente, Vector2(5,9))
	create_piece(PieceType.Gold, Player.Sente, Vector2(6,9))
	create_piece(PieceType.Silver, Player.Sente, Vector2(7,9))
	create_piece(PieceType.Knight, Player.Sente, Vector2(8,9))
	create_piece(PieceType.Lance, Player.Sente, Vector2(9,9))
	create_piece(PieceType.Bishop, Player.Sente, Vector2(8,8))
	create_piece(PieceType.Rook, Player.Sente, Vector2(2,8))
	create_piece(PieceType.Pawn, Player.Sente, Vector2(1,7))
	create_piece(PieceType.Pawn, Player.Sente, Vector2(2,7))
	create_piece(PieceType.Pawn, Player.Sente, Vector2(3,7))
	create_piece(PieceType.Pawn, Player.Sente, Vector2(4,7))
	create_piece(PieceType.Pawn, Player.Sente, Vector2(5,7))
	create_piece(PieceType.Pawn, Player.Sente, Vector2(6,7))
	create_piece(PieceType.Pawn, Player.Sente, Vector2(7,7))
	create_piece(PieceType.Pawn, Player.Sente, Vector2(8,7))
	create_piece(PieceType.Pawn, Player.Sente, Vector2(9,7))
	
	create_piece(PieceType.Lance, Player.Gote, Vector2(1,1))
	create_piece(PieceType.Knight, Player.Gote, Vector2(2,1))
	create_piece(PieceType.Silver, Player.Gote, Vector2(3,1))
	create_piece(PieceType.Gold, Player.Gote, Vector2(4,1))
	create_piece(PieceType.King, Player.Gote, Vector2(5,1))
	create_piece(PieceType.Gold, Player.Gote, Vector2(6,1))
	create_piece(PieceType.Silver, Player.Gote, Vector2(7,1))
	create_piece(PieceType.Knight, Player.Gote, Vector2(8,1))
	create_piece(PieceType.Lance, Player.Gote, Vector2(9,1))
	create_piece(PieceType.Bishop, Player.Gote, Vector2(2,2))
	create_piece(PieceType.Rook, Player.Gote, Vector2(8,2))
	create_piece(PieceType.Pawn, Player.Gote, Vector2(1,3))
	create_piece(PieceType.Pawn, Player.Gote, Vector2(2,3))
	create_piece(PieceType.Pawn, Player.Gote, Vector2(3,3))
	create_piece(PieceType.Pawn, Player.Gote, Vector2(4,3))
	create_piece(PieceType.Pawn, Player.Gote, Vector2(5,3))
	create_piece(PieceType.Pawn, Player.Gote, Vector2(6,3))
	create_piece(PieceType.Pawn, Player.Gote, Vector2(7,3))
	create_piece(PieceType.Pawn, Player.Gote, Vector2(8,3))
	create_piece(PieceType.Pawn, Player.Gote, Vector2(9,3))

func create_piece(piece_name,piece_owner,starting_position):
	var piece_scene = load("res://Scenes/piece.tscn")
	var piece = piece_scene.instantiate()
	piece.pieceType = piece_name
	piece.pieceOwner = piece_owner
	piece.currentPosition = starting_position
	if piece.pieceOwner == Player.Sente:
		sentePiecesOnBoard.append(starting_position)
	else:
		gotePiecesOnBoard.append(starting_position)
	get_parent().add_child.call_deferred(piece)
	piecesOnBoard.append(starting_position)
	pieceData.append([piece.pieceType, piece.pieceOwner, piece.get_instance_id()])
