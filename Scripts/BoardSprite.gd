extends Sprite2D

enum PieceType{
	King,
	Pawn,
	Lance,
	Knight,
	Silver,
	Gold,
	Bishop,
	Rook,
	PromotedPawn,
	PromotedLance,
	PromotedKnight,
	PromotedSilver,
	PromotedBishop,
	PromotedRook
}
enum Player{
	Sente,
	Gote
}

#Deubg
#var startingBoard = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1"
var startingBoard = "k3l4/9/4nb3/9/9/4G4/3K5/9/9 b 2R2N2rn 1"

@export var boardSize = Vector2(9, 9)
var lineSize = 8 #should be divisible by 4 for even lines
var squareSize = (texture.get_width()) / boardSize.x
var gridColor = Color(0,0,0)
var circleRadius = squareSize * 0.15
var circleColor = Color(0,0,0)
var selectedPiece = null
var xMargin = 25

var startX = squareSize / 2
var startY = squareSize / 2
var spacingX = squareSize
var spacingY = squareSize
var fontSize = 80
var fontColor = Color(0, 0, 0)
var font

var piecesOnBoard = []
var sentePiecesOnBoard = []
var gotePiecesOnBoard = []
var pieceData = [] #[pieceType, pieceOwner, pieceID]
var allMoves = []
var allMovesSente = []
var allMovesGote = []
var allMovesSenteIgnoreKing = []
var allMovesGoteIgnoreKing = []
var allMovesAfterCapture = []
var senteInCheck = false
var goteInCheck = false
var isPromoting = false
var playerTurn = Player.Sente
var turnCount = 1

var inHand = load("res://Scenes/in_hand.tscn")
var inHandSente = inHand.instantiate()
var inHandGote = inHand.instantiate()

var sfenManagerScript = load("res://Scenes/sfen_notation_manager.tscn")

signal turnStart(player)
signal turnEnd(player)

func _ready():
	board_setup()
	turnStart.connect(_on_turn_started)
	turnEnd.connect(_on_turn_ended)
	#await(get_tree().create_timer(.001).timeout)
	call_deferred("emit_signal","turnStart")
	#emit_signal("turnStart")
	#get_all_moves_for_player(Player.Sente,Vector2(1,7),Vector2(1,6))
	#get_all_moves_for_player(Player.Sente)
	#print(pieceData)
	#print(piecesOnBoard)

func _on_turn_started():
	#print("on turn start")
	#call_deferred("get_all_moves_for_player",Player.Sente,null,null,false,false)
	#call_deferred("get_all_moves_for_player",Player.Gote,null,null,false,false)
	call_deferred("get_all_moves_for_player",Player.Sente,null,null,true,true)
	call_deferred("get_all_moves_for_player",Player.Gote,null,null,true,true)
	
func _on_turn_ended():
	playerTurn = Player.Gote if playerTurn == Player.Sente else Player.Sente
	var king_pos = find_king(playerTurn)[0]
	var king_instance = instance_from_id(pieceData[piecesOnBoard.find(king_pos)][2])
	king_instance.check_attack_vectors(king_pos,playerTurn)
	#await(get_tree().create_timer(.001).timeout)
	for piece in get_tree().get_nodes_in_group("piece"):
		piece.constrained_moves.clear()
	call_deferred("emit_signal","turnStart")
	#emit_signal("turnStart")

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
	font = ThemeDB.fallback_font
	var char_size = font.get_string_size("1",HORIZONTAL_ALIGNMENT_CENTER,-1,fontSize)
	for x in range(boardSize.x):
		var number = str(boardSize.x - x)
		draw_string(font, Vector2(startX + (x * spacingX) - (char_size.x / 2), startY - spacingY / 2 - (spacingY / 10)), number, HORIZONTAL_ALIGNMENT_CENTER, -1, fontSize,fontColor)
	
	for y in range(boardSize.y):
		var number = str(y + 1)
		draw_string(font, Vector2(texture.get_width() + startX - (spacingX / 2) + (spacingX / 10), startY + (char_size.y / 4) +  (y * spacingY)), number, HORIZONTAL_ALIGNMENT_CENTER, -1, fontSize,fontColor)

func board_setup():
	get_parent().add_child.call_deferred(inHandSente)
	inHandSente.position = Vector2(texture.get_width() * scale.x,0)
	get_parent().add_child.call_deferred(inHandGote)
	inHandGote.position = Vector2(0,0)
	inHandGote.handOwner = Player.Gote
	
	var sfen_manager = sfenManagerScript.instantiate()
	add_child(sfen_manager)
	sfen_manager.scale *= 4
	sfen_manager.position = Vector2 (texture.get_width() + (xMargin * 6 * sfen_manager.scale.x),0)
	#lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1
	sfen_manager.create_board_from_sfen(startingBoard)

func create_piece(piece_name,piece_owner,starting_position, promoted = false):
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
	if promoted:
		piece.promoted = true

func get_all_moves_for_player(player, simulatedMoveOrigin = null, simulatedMoveDestination = null, ignoreKing = false, includeDefendedSquares = false):
	var isSimulatedMove = simulatedMoveOrigin != null and simulatedMoveDestination != null
	var simulatedPiecesOnBoard = piecesOnBoard if isSimulatedMove else []
	var simulatedPieceData = pieceData if isSimulatedMove else []
	var simulatedMoves = []
	#[pieceType, pieceOwner, pieceID]
	
	if isSimulatedMove:
		var simulatedMoveIndex = simulatedPiecesOnBoard.find(simulatedMoveOrigin)
		var simulatedPieceDataValues = simulatedPieceData[simulatedMoveIndex]
		simulatedPiecesOnBoard.remove_at(simulatedMoveIndex)
		simulatedPieceData.remove_at(simulatedMoveIndex)
		simulatedPiecesOnBoard.append(simulatedMoveOrigin)
		simulatedPieceData.append(simulatedPieceDataValues)
	
	var pieceDataToCheck = simulatedPieceData if isSimulatedMove else pieceData
	
	allMoves = []
	var gamePieces = []
	for piece in pieceDataToCheck:
		if player == Player.Sente:
			if piece[1] == Player.Sente:
				gamePieces.append(piece)
				for j in gamePieces:
					if !isSimulatedMove:
						instance_from_id(j[2]).get_valid_moves(instance_from_id(j[2]).currentPosition,null,ignoreKing, includeDefendedSquares)
						for i in instance_from_id(j[2]).valid_moves:
							if !(i in allMoves):
								allMoves.append(i)
					else:
						simulatedMoves = instance_from_id(j[2]).get_valid_moves(simulatedMoveDestination, simulatedMoveOrigin)
						#if instance_from_id(j[2]).currentPosition == simulatedMoveOrigin:
							#print(simulatedMoves)
						for t in simulatedMoves:
							if !(t in allMoves):
								allMoves.append(t)
								#print(allMoves)
			allMovesSente = allMoves
			if ignoreKing:
				allMovesSenteIgnoreKing = allMoves
		elif player == Player.Gote:
			if piece[1] == Player.Gote:
				gamePieces.append(piece)
				for k in gamePieces:
					instance_from_id(k[2]).get_valid_moves(instance_from_id(k[2]).currentPosition, null, ignoreKing, includeDefendedSquares)
					for i in instance_from_id(k[2]).valid_moves:
						if !(i in allMoves):
							allMoves.append(i)
			allMovesGote = allMoves
			if ignoreKing:
				allMovesGoteIgnoreKing = allMoves
	#print("all moves in get all moves "+str(allMoves),player)
	#return allMoves
	#return simulatedAllMoves if isSimulatedMove else null

func get_all_moves_after_capture(player, capturePos):
	allMovesAfterCapture = []
	var gamePieces = []
	var _capturePieceIndex
	_capturePieceIndex = piecesOnBoard.find(capturePos)
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

func is_in_check(player):  #currently messes with king legal moves, needs rework.
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
		#print("Is in check? " + str(senteInCheck))
	
	if player == Player.Gote:
		get_all_moves_for_player(Player.Sente)
		kingPosition = find_king(Player.Gote)
		#print("Gote kingPos " + str(kingPosition))
		#print("all moves in is in check "+str(allMoves))
		if kingPosition[0] in allMoves:
			goteInCheck = true
		else:
			goteInCheck = false
		#print("Is in check? " + str(goteInCheck))

func clear_board():
	for piece in get_parent().get_children():
		#print(piece_scene.get_class())
		if piece.is_in_group("piece"):
			piece.queue_free()
	piecesOnBoard = []
	sentePiecesOnBoard = []
	gotePiecesOnBoard = []
	pieceData = []
	allMoves = []
	allMovesAfterCapture = []
	senteInCheck = false
	goteInCheck = false
	inHandSente.update_in_hand(-1,0)
	inHandGote.update_in_hand(-1,0)
	inHandSente.piecesInHand = [0,0,0,0,0,0,0]
	inHandGote.piecesInHand = [0,0,0,0,0,0,0]
