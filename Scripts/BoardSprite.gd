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
var allMoves = []
var allMovesAfterCapture = []
var senteInCheck = false
var goteInCheck = false
var playerTurn = Player.Sente

var inHand = load("res://Scenes/in_hand.tscn")
var inHandSente = inHand.instantiate()
var inHandGote = inHand.instantiate()

func _ready():
	board_setup()
	#print(pieceData)
	await(get_tree().create_timer(1).timeout)
	get_all_moves_after_capture(Player.Sente, Vector2(5,3))
	#await(get_tree().create_timer(1).timeout)
	#get_all_moves_for_player(Player.Sente)
	

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
	
	#create_piece(PieceType.Rook, Player.Gote, Vector2(5,8))
	
	get_parent().add_child.call_deferred(inHandSente)
	inHandSente.position = Vector2(texture.get_width() * scale.x,0)
	get_parent().add_child.call_deferred(inHandGote)
	inHandGote.position = Vector2(0,0)
	inHandGote.handOwner = Player.Gote

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

func get_all_moves_for_player(player):
	allMoves = []
	var gamePieces = []
	for piece in pieceData:
		if player == Player.Sente:
			if piece[1] == Player.Sente:
				gamePieces.append(piece)
				for j in gamePieces:
					instance_from_id(j[2]).get_valid_moves(instance_from_id(j[2]).currentPosition)
					for i in instance_from_id(j[2]).valid_moves:
						if !(i in allMoves):
							allMoves.append(i)

		elif player == Player.Gote:
			if piece[1] == Player.Gote:
				gamePieces.append(piece)
				for k in gamePieces:
					instance_from_id(k[2]).get_valid_moves(instance_from_id(k[2]).currentPosition)
					for i in instance_from_id(k[2]).valid_moves:
						if !(i in allMoves):
							allMoves.append(i)
	#print("all moves in get all moves "+str(allMoves))

func get_all_moves_after_capture(player, capturePos):
	allMovesAfterCapture = []
	var gamePieces = []
	var capturePieceIndex
	capturePieceIndex = piecesOnBoard.find(capturePos)
	for piece in pieceData:
		if player == Player.Sente:
			if piece[1] == Player.Sente:
				gamePieces.append(piece)
				for j in gamePieces:
					instance_from_id(j[2]).get_valid_moves(instance_from_id(j[2]).currentPosition)
					for i in instance_from_id(j[2]).valid_moves:
						if !(i in allMoves):
							allMoves.append(i)
		elif player == Player.Gote:
			if piece[1] == Player.Gote:
				gamePieces.append(piece)
				for k in gamePieces:
					instance_from_id(k[2]).get_valid_moves(instance_from_id(k[2]).currentPosition)
					for i in instance_from_id(k[2]).valid_moves:
						if !(i in allMoves):
							allMoves.append(i)
	

func find_king(player):
	var kingPos = []
	var kingIndex
	for piece in pieceData:
		if player == Player.Sente and piece[1] == Player.Sente and piece[0] == PieceType.King:
			kingIndex = piece[2]
			kingPos.append(instance_from_id(kingIndex).currentPosition)
		if player == Player.Gote and piece[1] == Player.Gote and piece[0] == PieceType.King:
			kingIndex = piece[2]
			kingPos.append(instance_from_id(kingIndex).currentPosition)
	return kingPos

func is_in_check(player):
	var kingPosition = []
	if player == Player.Sente:
		get_all_moves_for_player(Player.Gote)
		kingPosition = find_king(Player.Sente)
		#print("Sente kingPos " + str(kingPosition))
		#print("all moves in is in check "+str(allMoves))
		if kingPosition[0] in allMoves:
			senteInCheck = true
		else:
			senteInCheck = false
	
	if player == Player.Gote:
		get_all_moves_for_player(Player.Sente)
		kingPosition = find_king(Player.Gote)
		#print("Gote kingPos " + str(kingPosition))
		#print("all moves in is in check "+str(allMoves))
		if kingPosition[0] in allMoves:
			goteInCheck = true
		else:
			goteInCheck = false


