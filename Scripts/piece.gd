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

@onready var board = get_parent()
@onready var boardSprite = board.get_node("BoardSprite")
@onready var globalPieceScale = (boardSprite.texture.get_width() * boardSprite.scale.x) / (boardSprite.boardSize.x * texture.get_width())
var sente_shader = preload("res://Shaders/piece.gdshader")
@onready var selection_highlight = $selection_highlight
@onready var moved_from_square_highlight = $moved_from_square_highlight
@onready var boardPosition = board.global_position

@export var pieceType = PieceType.Pawn
@export var pieceOwner = Player.Sente
@export var promoted: bool = false

@export var currentPosition: Vector2
@export var selected: bool = false
var dragging: bool = false
var dragging_position: Vector2
var selectionColor = Color(0,1,0,0.5)
@onready var rectSize = Vector2(texture.get_width(),texture.get_height())

var valid_moves = []
var constrained_moves = []
var threats = []

var confirmed_attack_vectors = []
var vertical_north = []
var diagonal_northeast = []
var horizontal_east = []
var diagonal_southeast = []
var vertical_south = []
var diagonal_southwest = []
var horizontal_west = []
var diagonal_northwest = []
var north = []
var northeast = []
var east = []
var southeast = []
var south = []
var southwest = []
var west = []
var northwest = []
var knighteast = []
var knightwest = []

var adjacentSquares = [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1),Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]
var squareHighlight = load("res://Scenes/square_highlight.tscn")
var promotionWindow = load("res://Scenes/promotion_window.tscn")

@export var move_sounds = [
	preload("res://Sounds/PieceSnap/shogisnap1.mp3"),
	preload("res://Sounds/PieceSnap/shogisnap2.mp3"),
	preload("res://Sounds/PieceSnap/shogisnap3.mp3"),
	preload("res://Sounds/PieceSnap/shogisnap4.mp3")
]
@onready var audio_player = $AudioStreamPlayer2D

func _ready():
	scale *= globalPieceScale
	set_piece_type()
	snap_to_grid()
	moved_from_square_highlight.visible = false
	if pieceOwner == Player.Gote:
		rotation_degrees += 180
	else:
		var sente_material = ShaderMaterial.new()
		sente_material.shader = sente_shader
		material = sente_material
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and (pieceOwner == boardSprite.playerTurn) and event.button_index == MOUSE_BUTTON_LEFT and boardSprite.isPromoting == false:
		if get_rect().has_point(to_local(event.position)):
			selected = !selected
			if !selected:
				valid_moves = []
				destroy_all_highlights()
				boardSprite.selectedPiece = null
			else:
				if boardSprite.selectedPiece != null:
					boardSprite.selectedPiece.destroy_all_highlights()
					boardSprite.selectedPiece.selected = false
					valid_moves = []
				boardSprite.selectedPiece = self
				get_valid_moves(currentPosition)
				for move_pos in valid_moves:
					var highlight = squareHighlight.instantiate()
					add_child(highlight)
					highlight.currentPosition = move_pos
					var deltaPosition = (currentPosition - highlight.currentPosition) * (highlight.texture.get_width())
					if pieceOwner == Player.Sente:
						deltaPosition.x *= -1 #this accounts for the sprite origin being on the left side of the board
					elif pieceOwner == Player.Gote:
						deltaPosition.y *= -1
					highlight.position -= deltaPosition
		queue_redraw()

func _draw():
	if selected:
		$selection_highlight.visible = true
	else:
		$selection_highlight.visible = false
	draw_texture(texture,Vector2(float(-texture.get_width())/2,float(-texture.get_height())/2),modulate)

func snap_to_grid():
	var posNotation:Vector2 = boardSprite.find_square_center(currentPosition.x,currentPosition.y)
	position = posNotation * boardSprite.scale

func set_piece_type():
	var sprite_texture = null
	match pieceType:
		PieceType.King:
			sprite_texture = load("res://Images/Pieces/King.png")
		PieceType.Pawn:
			if promoted == false:
				sprite_texture = load("res://Images/Pieces/Pawn.png")
			elif promoted == true:
				sprite_texture = load("res://Images/Pieces/Promoted Pawn.png")
				pieceType = PieceType.PromotedPawn
				for piece in range(len(boardSprite.pieceData)):
					if get_instance_id() == boardSprite.pieceData[piece][2]:
						boardSprite.pieceData[piece] = [pieceType,boardSprite.pieceData[piece][1],boardSprite.pieceData[piece][2]]
						break
		PieceType.Lance:
			if promoted == false:
				sprite_texture = load("res://Images/Pieces/Lance.png")
			elif promoted == true:
				sprite_texture = load("res://Images/Pieces/Promoted Lance.png")
				pieceType = PieceType.PromotedLance
				for piece in range(len(boardSprite.pieceData)):
					if get_instance_id() == boardSprite.pieceData[piece][2]:
						boardSprite.pieceData[piece] = [pieceType,boardSprite.pieceData[piece][1],boardSprite.pieceData[piece][2]]
						break
		PieceType.Knight:
			if promoted == false:
				sprite_texture = load("res://Images/Pieces/Knight.png")
			elif promoted == true:
				sprite_texture = load("res://Images/Pieces/Promoted Knight.png")
				pieceType = PieceType.PromotedKnight
				for piece in range(len(boardSprite.pieceData)):
					if get_instance_id() == boardSprite.pieceData[piece][2]:
						boardSprite.pieceData[piece] = [pieceType,boardSprite.pieceData[piece][1],boardSprite.pieceData[piece][2]]
						break
		PieceType.Silver:
			if promoted == false:
				sprite_texture = load("res://Images/Pieces/Silver General.png")
			elif promoted == true:
				sprite_texture = load("res://Images/Pieces/Promoted Silver General.png")
				pieceType = PieceType.PromotedSilver
				for piece in range(len(boardSprite.pieceData)):
					if get_instance_id() == boardSprite.pieceData[piece][2]:
						boardSprite.pieceData[piece] = [pieceType,boardSprite.pieceData[piece][1],boardSprite.pieceData[piece][2]]
						break
		PieceType.Gold:
			sprite_texture = load("res://Images/Pieces/Gold General.png")
		PieceType.Bishop:
			if promoted == false:
				sprite_texture = load("res://Images/Pieces/Bishop.png")
			elif promoted == true:
				sprite_texture = load("res://Images/Pieces/Promoted Bishop.png")
				pieceType = PieceType.PromotedBishop
				for piece in range(len(boardSprite.pieceData)):
					if get_instance_id() == boardSprite.pieceData[piece][2]:
						boardSprite.pieceData[piece] = [pieceType,boardSprite.pieceData[piece][1],boardSprite.pieceData[piece][2]]
						break
		PieceType.Rook:
			if promoted == false:
				sprite_texture = load("res://Images/Pieces/Rook.png")
			elif promoted == true:
				sprite_texture = load("res://Images/Pieces/Promoted Rook.png")
				pieceType = PieceType.PromotedRook
				for piece in range(len(boardSprite.pieceData)):
					if get_instance_id() == boardSprite.pieceData[piece][2]:
						boardSprite.pieceData[piece] = [pieceType,boardSprite.pieceData[piece][1],boardSprite.pieceData[piece][2]]
						break
		_:
			sprite_texture = null
	texture = sprite_texture

func get_valid_moves(coordinate, simulatedMoveOrigin = null, ignoreKing = false, getDefendedSquares = false):
	var isSimulatedMove = simulatedMoveOrigin != null
	var move_direction
	var possibleMoves = []
	valid_moves = []
	if pieceOwner == Player.Sente:
		move_direction = -1
	else:
		move_direction = 1
	
	if pieceType == PieceType.Pawn or pieceType == PieceType.PromotedPawn:
		possibleMoves.append(Vector2(coordinate.x,coordinate.y + move_direction))
		if promoted:
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y + move_direction))
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y + move_direction))
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y))
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y))
			possibleMoves.append(Vector2(coordinate.x,coordinate.y - move_direction))			
		for moves in possibleMoves:
			if check_move_legality(moves, null, ignoreKing, getDefendedSquares):
				valid_moves.append(moves)
	if pieceType == PieceType.Lance or pieceType == PieceType.PromotedLance:
		if !promoted:
			check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,0,move_direction, ignoreKing, getDefendedSquares)
		elif promoted:
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y + move_direction))
			possibleMoves.append(Vector2(coordinate.x,coordinate.y + move_direction))
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y + move_direction))
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y))
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y))
			possibleMoves.append(Vector2(coordinate.x,coordinate.y - move_direction))
		for moves in possibleMoves:
			if check_move_legality(moves, null, ignoreKing, getDefendedSquares):
				valid_moves.append(moves)
		#print(valid_moves)
	if pieceType == PieceType.Knight or pieceType == PieceType.PromotedKnight:
		if !promoted:
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y + move_direction * 2))
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y + move_direction * 2))
		elif promoted:
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y + move_direction))
			possibleMoves.append(Vector2(coordinate.x,coordinate.y + move_direction))
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y + move_direction))
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y))
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y))
			possibleMoves.append(Vector2(coordinate.x,coordinate.y - move_direction))
		for moves in possibleMoves:
			if check_move_legality(moves, null, ignoreKing, getDefendedSquares):
				valid_moves.append(moves)
	if pieceType == PieceType.Silver or pieceType == PieceType.PromotedSilver:
		possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y + move_direction))
		if !promoted:
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y - move_direction))
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y - move_direction))
		elif promoted:
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y))
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y))
			possibleMoves.append(Vector2(coordinate.x,coordinate.y - move_direction))
		for moves in possibleMoves:
			if check_move_legality(moves, null, ignoreKing, getDefendedSquares):
				valid_moves.append(moves)
	if pieceType == PieceType.Gold:
		possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y))
		possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y))
		possibleMoves.append(Vector2(coordinate.x,coordinate.y - move_direction))
		for moves in possibleMoves:
			if check_move_legality(moves, null, ignoreKing, getDefendedSquares):
				valid_moves.append(moves)
	if pieceType == PieceType.Bishop or pieceType == PieceType.PromotedBishop:
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,-move_direction,move_direction,ignoreKing, getDefendedSquares)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,move_direction,move_direction,ignoreKing, getDefendedSquares)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,-move_direction,-move_direction,ignoreKing, getDefendedSquares)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,move_direction,-move_direction,ignoreKing, getDefendedSquares)
			
		if promoted:
			possibleMoves.append(Vector2(coordinate.x,coordinate.y + move_direction))
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y))
			possibleMoves.append(Vector2(coordinate.x,coordinate.y - move_direction))
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y))
			for moves in possibleMoves:
				if check_move_legality(moves, null, ignoreKing, getDefendedSquares):
					valid_moves.append(moves)
	if pieceType == PieceType.Rook or pieceType == PieceType.PromotedRook:
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,0,-move_direction,ignoreKing, getDefendedSquares)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,move_direction,0,ignoreKing, getDefendedSquares)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,0,move_direction,ignoreKing, getDefendedSquares)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,-move_direction,0,ignoreKing, getDefendedSquares)
		if promoted:
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y + move_direction))
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y + move_direction))
			possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y - move_direction))
			possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y - move_direction))
			for moves in possibleMoves:
				if check_move_legality(moves, null, ignoreKing, getDefendedSquares):
					valid_moves.append(moves)
	if pieceType == PieceType.King:
		possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y))
		possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y))
		possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y - move_direction))
		possibleMoves.append(Vector2(coordinate.x,coordinate.y - move_direction))
		possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y - move_direction))
		for moves in possibleMoves:
			if check_move_legality(moves, null, ignoreKing, getDefendedSquares):
				valid_moves.append(moves)
		var opponent = Player.Gote if pieceOwner == Player.Sente else Player.Sente
		var attacking_spaces_from_opponent = boardSprite.allMovesGoteIgnoreKing if pieceOwner == Player.Sente else boardSprite.allMovesSenteIgnoreKing
		var opponentKingPosition = boardSprite.find_king(opponent)
		for direction in adjacentSquares:
			var adjacentSquare = opponentKingPosition[0] + direction
			if is_inside_board(adjacentSquare) and !(adjacentSquare in attacking_spaces_from_opponent):
				attacking_spaces_from_opponent.append(adjacentSquare)
		#print("attacking spaces: ",attacking_spaces_from_opponent)
		var safe_moves = []
		for move in valid_moves:
			if not move in attacking_spaces_from_opponent:
				safe_moves.append(move)
		valid_moves = safe_moves
		
	if !constrained_moves.is_empty():
		var valid_and_constrained_moves_intersection = []
		for move in valid_moves:
			if move in constrained_moves:
				valid_and_constrained_moves_intersection.append(move)
		valid_moves = valid_and_constrained_moves_intersection
	
	if pieceType != PieceType.King and boardSprite.current_player_king.confirmed_attack_vectors != [] and pieceOwner == boardSprite.playerTurn:
		var valid_and_constrained_moves_intersection = []
		for move in valid_moves:
			var move_is_in_each_vector = true
			for sub_array in boardSprite.current_player_king.confirmed_attack_vectors:
				if move not in sub_array:
					move_is_in_each_vector = false
					break
			if move_is_in_each_vector:
				valid_and_constrained_moves_intersection.append(move)
		valid_moves = valid_and_constrained_moves_intersection
	
	if isSimulatedMove:
		return valid_moves 

func check_move_legality(move, simulatedMoveOrigin = null, ignoreKing = false, getDefendedSquares = false):
	if !is_inside_board(move):
		return false
	if can_capture(move):
		return true

	if is_space_taken(move, simulatedMoveOrigin, ignoreKing):
		if getDefendedSquares and is_space_an_ally(move):
			return true
		return false

	return true

func is_inside_board(move):
	return(move.x > 0 and move.x <= boardSprite.boardSize.x and move.y > 0 and move.y <= boardSprite.boardSize.y)

func is_space_taken(move, simulatedMoveOrigin = null, ignoreKing = false):
	if simulatedMoveOrigin != null:
		var simulatedPiecesOnBoard = boardSprite.piecesOnBoard
		var simulatedMoveIndex = simulatedPiecesOnBoard.find(simulatedMoveOrigin)
		simulatedPiecesOnBoard.remove_at(simulatedMoveIndex)
		#simulatedPiecesOnBoard.append(move)
		return move in simulatedPiecesOnBoard
	else:
		if !ignoreKing:
			return move in boardSprite.piecesOnBoard
		else:
			if move in boardSprite.piecesOnBoard:
				var pieceIndex = boardSprite.piecesOnBoard.find(move)
				if boardSprite.pieceData[pieceIndex][0] != PieceType.King:
					return true
				else:
					return false
			else:
				return false

func is_space_an_ally(move):
	if move in boardSprite.piecesOnBoard:
		var pieceIndex = boardSprite.piecesOnBoard.find(move)
		var pieceID = boardSprite.pieceData[pieceIndex]
		if pieceID[1] == pieceOwner:
			return true
	return false

func can_capture(move):
	if is_space_taken(move,null,true):
		if pieceOwner == Player.Sente:
			if move in boardSprite.gotePiecesOnBoard:
				return true
		if pieceOwner == Player.Gote:
			if move in boardSprite.sentePiecesOnBoard:
				return true
	return false

func check_horizontal_moves(valid_move, start_rank, start_file, delta_rank, delta_file, ignoreKing = false, getDefendedSquares = false):
	var target_rank = start_rank + delta_rank
	var target_file = start_file + delta_file
	var first_ally_seen = false
	while check_move_legality(Vector2(target_rank,target_file), null, ignoreKing, getDefendedSquares):
		if first_ally_seen == false and is_space_an_ally(Vector2(target_rank,target_file)) and getDefendedSquares:
			first_ally_seen = true
			getDefendedSquares = false
			ignoreKing = false
			valid_move.append(Vector2(target_rank,target_file))
			break
		#print("legal move: ",check_move_legality(Vector2(target_rank,target_file), null, ignoreKing, getDefendedSquares)," currentsquare: ",Vector2(target_rank,target_file)," Get Defended Squares: ",getDefendedSquares)
		valid_move.append(Vector2(target_rank,target_file))
		if can_capture(Vector2 (target_rank,target_file)):
			break
		target_rank += delta_rank
		target_file += delta_file
#func check_diagonal_moves(valid_move, start_rank, start_file, delta_rank, delta_file):
	#var target_rank = start_rank + delta_rank
	#var target_file = start_file + delta_file
	#while check_move_legality(Vector2(target_rank,target_file)):
		#valid_move.append(Vector2(target_rank,target_file))
		#if can_capture(Vector2 (target_rank,target_file)):
			#break
		#target_rank += delta_rank
		#target_file += delta_file

func destroy_all_highlights():
	for child in get_children():
		if child.is_in_group("highlights"):
			child.queue_free()

func move_piece(file,rank):
	var origin = currentPosition
	var destination = Vector2(file,rank)
	if can_capture(destination):
		capture_piece(file,rank)
	var indexToRemove = boardSprite.piecesOnBoard.find(currentPosition)
	boardSprite.piecesOnBoard.remove_at(indexToRemove) #remove the moving from position from the array
	boardSprite.pieceData.remove_at(indexToRemove)	#remove the moving from position from the array
	if pieceOwner == Player.Sente:
		boardSprite.sentePiecesOnBoard.remove_at(boardSprite.sentePiecesOnBoard.find(currentPosition)) #remove the moving from position from the array
	elif pieceOwner == Player.Gote:
		boardSprite.gotePiecesOnBoard.remove_at(boardSprite.gotePiecesOnBoard.find(currentPosition)) #remove the moving from position from the array
	currentPosition = destination
	boardSprite.piecesOnBoard.append(currentPosition) #adds the moving to position to the array
	boardSprite.pieceData.append([pieceType, pieceOwner, get_instance_id()]) # adds the moving to data (piece type and owner) to the array
	if pieceOwner == Player.Sente:
		boardSprite.sentePiecesOnBoard.append(currentPosition)  # adds the moving to position into the array
	elif pieceOwner == Player.Gote:
		boardSprite.gotePiecesOnBoard.append(currentPosition) # adds the moving to position into the array
	snap_to_grid()
	moved_from_square_highlight.moved_from = Vector2(file,rank)
	if can_promote(origin.y,destination.y):
		if (pieceOwner == Player.Sente and (((pieceType == PieceType.Pawn or pieceType == PieceType.Lance) and destination.y == 1) or (pieceType == PieceType.Knight and destination.y <= 2))) or (pieceOwner == Player.Gote and (((pieceType == PieceType.Pawn or pieceType == PieceType.Lance) and destination.y == 9) or (pieceType == PieceType.Knight and destination.y >= 8))):
			promoted = true
			set_piece_type()
			boardSprite.emit_signal("turnEnd")
		else:
			boardSprite.isPromoting = true
			var promotionPrompt = promotionWindow.instantiate()
			add_child(promotionPrompt)
			promotionPrompt.position.y += rectSize.y / 2
	else:
		boardSprite.emit_signal("turnEnd")
	if boardSprite.selectedPiece != null:
		boardSprite.selectedPiece = null
		destroy_all_highlights()
		selected = false
		valid_moves = []
	var random_index = randi() % 4 
	audio_player.stream = move_sounds[random_index]  # Set the randomly selected sound
	audio_player.play()
	queue_redraw()
	boardSprite.is_in_check(Player.Sente)
	boardSprite.is_in_check(Player.Gote)

func update_move_indicators():
	pass

func capture_piece(file,rank):
	var indexToRemove =  boardSprite.piecesOnBoard.find(Vector2(file,rank))
	var captured_id
	if pieceOwner == Player.Sente:
		add_piece_to_hand((boardSprite.pieceData[boardSprite.piecesOnBoard.find(Vector2(file,rank))]))
		captured_id = (boardSprite.pieceData[boardSprite.piecesOnBoard.find(Vector2(file,rank))])[2]
		boardSprite.gotePiecesOnBoard.remove_at(boardSprite.gotePiecesOnBoard.find(Vector2(file,rank)))
		boardSprite.piecesOnBoard.remove_at(indexToRemove)
		boardSprite.pieceData.remove_at(indexToRemove)
		
		instance_from_id(captured_id).queue_free()
		
	if pieceOwner == Player.Gote:
		add_piece_to_hand((boardSprite.pieceData[boardSprite.piecesOnBoard.find(Vector2(file,rank))]))
		captured_id = (boardSprite.pieceData[boardSprite.piecesOnBoard.find(Vector2(file,rank))])[2]
		boardSprite.sentePiecesOnBoard.remove_at(boardSprite.sentePiecesOnBoard.find(Vector2(file,rank)))
		boardSprite.piecesOnBoard.remove_at(indexToRemove)
		boardSprite.pieceData.remove_at(indexToRemove)
		
		instance_from_id(captured_id).queue_free()

func add_piece_to_hand(piece_data):
	if pieceOwner == Player.Sente: #check for piece owner
		if piece_data[0] == PieceType.Pawn or piece_data[0] == PieceType.PromotedPawn:
			boardSprite.inHandSente.update_in_hand(PieceType.Pawn,1)
		if piece_data[0] == PieceType.Lance or piece_data[0] == PieceType.PromotedLance:
			boardSprite.inHandSente.update_in_hand(PieceType.Lance,1)
		if piece_data[0] == PieceType.Knight or piece_data[0] == PieceType.PromotedKnight:
			boardSprite.inHandSente.update_in_hand(PieceType.Knight,1)
		if piece_data[0] == PieceType.Silver or piece_data[0] == PieceType.PromotedSilver:
			boardSprite.inHandSente.update_in_hand(PieceType.Silver,1)
		if piece_data[0] == PieceType.Gold:
			boardSprite.inHandSente.update_in_hand(PieceType.Gold,1)
		if piece_data[0] == PieceType.Bishop or piece_data[0] == PieceType.PromotedBishop:
			boardSprite.inHandSente.update_in_hand(PieceType.Bishop,1)
		if piece_data[0] == PieceType.Rook or piece_data[0] == PieceType.PromotedRook:
			boardSprite.inHandSente.update_in_hand(PieceType.Rook,1)
	if pieceOwner == Player.Gote:
		if piece_data[0] == PieceType.Pawn or piece_data[0] == PieceType.PromotedPawn:
			boardSprite.inHandGote.update_in_hand(PieceType.Pawn,1)
		if piece_data[0] == PieceType.Lance or piece_data[0] == PieceType.PromotedLance:
			boardSprite.inHandGote.update_in_hand(PieceType.Lance,1)
		if piece_data[0] == PieceType.Knight or piece_data[0] == PieceType.PromotedKnight:
			boardSprite.inHandGote.update_in_hand(PieceType.Knight,1)
		if piece_data[0] == PieceType.Silver or piece_data[0] == PieceType.PromotedSilver:
			boardSprite.inHandGote.update_in_hand(PieceType.Silver,1)
		if piece_data[0] == PieceType.Gold:
			boardSprite.inHandGote.update_in_hand(PieceType.Gold,1)
		if piece_data[0] == PieceType.Bishop or piece_data[0] == PieceType.PromotedBishop:
			boardSprite.inHandGote.update_in_hand(PieceType.Bishop,1)
		if piece_data[0] == PieceType.Rook or piece_data[0] == PieceType.PromotedRook:
			boardSprite.inHandGote.update_in_hand(PieceType.Rook,1)

func can_promote(start_rank: int ,end_rank: int):
	if promoted:
		return false
	var promotion_zone_sente = [int(1), int(2), int(3)]
	var promotion_zone_gote = [int(7), int(8), int(9)]

	if pieceType in [PieceType.Pawn, PieceType.Lance, PieceType.Knight, PieceType.Silver, PieceType.Bishop, PieceType.Rook]:
		if pieceOwner == Player.Sente and (start_rank in promotion_zone_sente or end_rank in promotion_zone_sente):
			return true
		elif pieceOwner == Player.Gote and (start_rank in promotion_zone_gote or end_rank in promotion_zone_gote):
			return true
	return false

func king_under_attack_vector(player):
	var king_position = boardSprite.find_king(player)
	var attack_vectors = {
		"horizontal": [],
		"diagonal": [],
		"adjacent": [],
		"knight": []
	}
	attack_vectors["horizontal"] = check_attack_vectors(king_position, player)

func check_attack_vectors(king_position, player):
	var move_direction
	threats = []
	if player == Player.Sente:
		move_direction = -1
	else:
		move_direction = 1
	threats += check_swinging_attack_vectors_directions_and_piece(king_position, Vector2(-move_direction,0),player, [PieceType.Rook, PieceType.PromotedRook])
	threats += check_swinging_attack_vectors_directions_and_piece(king_position, Vector2(move_direction,0),player, [PieceType.Rook, PieceType.PromotedRook])
	threats += check_swinging_attack_vectors_directions_and_piece(king_position, Vector2(0,move_direction),player, [PieceType.Rook, PieceType.PromotedRook, PieceType.Lance])
	threats += check_swinging_attack_vectors_directions_and_piece(king_position, Vector2(0,-move_direction),player, [PieceType.Rook, PieceType.PromotedRook])
	threats += check_swinging_attack_vectors_directions_and_piece(king_position, Vector2(-move_direction,move_direction),player, [PieceType.Bishop, PieceType.PromotedBishop])
	threats += check_swinging_attack_vectors_directions_and_piece(king_position, Vector2(move_direction,move_direction),player, [PieceType.Bishop, PieceType.PromotedBishop])
	threats += check_swinging_attack_vectors_directions_and_piece(king_position, Vector2(-move_direction,-move_direction),player, [PieceType.Bishop, PieceType.PromotedBishop])
	threats += check_swinging_attack_vectors_directions_and_piece(king_position, Vector2(move_direction,-move_direction),player, [PieceType.Bishop, PieceType.PromotedBishop])
	
	var has_attack_vector
	has_attack_vector = check_nonswinging_attack_vectors_directions_and_piece(king_position,Vector2(0,move_direction),player,[PieceType.Pawn, PieceType.Silver, PieceType.Gold, PieceType.PromotedPawn, PieceType.PromotedLance, PieceType.PromotedKnight, PieceType.PromotedSilver])
	if has_attack_vector != []:
		threats.append(has_attack_vector)
	
	has_attack_vector = check_nonswinging_attack_vectors_directions_and_piece(king_position,Vector2(move_direction,move_direction),player,[PieceType.Silver, PieceType.Gold, PieceType.PromotedPawn, PieceType.PromotedLance, PieceType.PromotedKnight, PieceType.PromotedSilver])
	if has_attack_vector != []:
		threats.append(has_attack_vector)
	
	has_attack_vector = check_nonswinging_attack_vectors_directions_and_piece(king_position,Vector2(move_direction,0),player,[PieceType.Gold, PieceType.PromotedPawn, PieceType.PromotedLance, PieceType.PromotedKnight, PieceType.PromotedSilver])
	if has_attack_vector != []:
		threats.append(has_attack_vector)
	
	has_attack_vector = check_nonswinging_attack_vectors_directions_and_piece(king_position,Vector2(move_direction,-move_direction),player,[PieceType.Silver])
	if has_attack_vector != []:
		threats.append(has_attack_vector)
	
	has_attack_vector = check_nonswinging_attack_vectors_directions_and_piece(king_position,Vector2(0,-move_direction),player,[PieceType.Gold, PieceType.PromotedPawn, PieceType.PromotedLance, PieceType.PromotedKnight, PieceType.PromotedSilver])
	if has_attack_vector != []:
		threats.append(has_attack_vector)
	
	has_attack_vector = check_nonswinging_attack_vectors_directions_and_piece(king_position,Vector2(-move_direction,-move_direction),player,[PieceType.Silver])
	if has_attack_vector != []:
		threats.append(has_attack_vector)
	
	has_attack_vector = check_nonswinging_attack_vectors_directions_and_piece(king_position,Vector2(-move_direction,0),player,[PieceType.Gold, PieceType.PromotedPawn, PieceType.PromotedLance, PieceType.PromotedKnight, PieceType.PromotedSilver])
	if has_attack_vector != []:
		threats.append(has_attack_vector)
	
	has_attack_vector = check_nonswinging_attack_vectors_directions_and_piece(king_position,Vector2(-move_direction,move_direction),player,[PieceType.Silver, PieceType.Gold, PieceType.PromotedPawn, PieceType.PromotedLance, PieceType.PromotedKnight, PieceType.PromotedSilver])
	if has_attack_vector != []:
		threats.append(has_attack_vector)
		
	has_attack_vector = check_nonswinging_attack_vectors_directions_and_piece(king_position,Vector2(move_direction,move_direction*2),player,[PieceType.Knight])
	if has_attack_vector != []:
		threats.append(has_attack_vector)
		
	has_attack_vector = check_nonswinging_attack_vectors_directions_and_piece(king_position,Vector2(-move_direction,move_direction*2),player,[PieceType.Knight])
	if has_attack_vector != []:
		threats.append(has_attack_vector)
	#print("Threats: " + str(threats),self)
	if vertical_north.size()  > 0:
		confirmed_attack_vectors.append(vertical_north)
	if diagonal_northeast.size() > 0:
		confirmed_attack_vectors.append(diagonal_northeast)
	if horizontal_east.size() > 0:
		confirmed_attack_vectors.append(horizontal_east)
	if diagonal_southeast.size() > 0:
		confirmed_attack_vectors.append(diagonal_southeast)
	if vertical_south.size() > 0:
		confirmed_attack_vectors.append(vertical_south)
	if diagonal_southwest.size() > 0:
		confirmed_attack_vectors.append(diagonal_southwest)
	if horizontal_west.size() > 0:
		confirmed_attack_vectors.append(horizontal_west)
	if diagonal_northwest.size() > 0:
		confirmed_attack_vectors.append(diagonal_northwest)
	if north != []:
		confirmed_attack_vectors.append(north)
	if northeast != []:
		confirmed_attack_vectors.append(northeast)
	if east != []:
		confirmed_attack_vectors.append(east)
	if southeast != []:
		confirmed_attack_vectors.append(southeast)
	if south != []:
		confirmed_attack_vectors.append(south)
	if southwest != []:
		confirmed_attack_vectors.append(southwest)
	if west != []:
		confirmed_attack_vectors.append(west)
	if northwest != []:
		confirmed_attack_vectors.append(northwest)
	if knighteast != []:
		confirmed_attack_vectors.append(knighteast)
	if knightwest != []:
		confirmed_attack_vectors.append(knightwest)
		
		#confirmed_attack_vectors.append(attack_vector)
	#print(confirmed_attack_vectors)
	if threats != []:
		return threats
	
func check_nonswinging_attack_vectors_directions_and_piece(start_pos, direction, player, threatening_pieces):
	var king_threats = []
	var opponent = Player.Gote if player == Player.Sente else Player.Sente
	var currentSpace = start_pos + direction
	var move_direction
	if player == Player.Sente:
		move_direction = -1
	else:
		move_direction = 1
	
	if !is_inside_board(currentSpace):
		return []
	if boardSprite.piecesOnBoard.has(currentSpace):
			var pieceIndex = boardSprite.piecesOnBoard.find(currentSpace)
			if boardSprite.pieceData[pieceIndex][1] == opponent and boardSprite.pieceData[pieceIndex][0] in threatening_pieces:
				king_threats.append(currentSpace)
	if direction == Vector2(0,move_direction) and king_threats != []:
		north.append(currentSpace)
	if direction == Vector2(move_direction,move_direction)and king_threats != []:
		northeast.append(currentSpace)
	if direction == Vector2(move_direction,0) and king_threats != []:
		east.append(currentSpace)
	if direction == Vector2(move_direction,-move_direction)and king_threats != []:
		southeast.append(currentSpace)
	if direction == Vector2(0,-move_direction) and king_threats != []:
		south.append(currentSpace)
	if direction == Vector2(-move_direction,-move_direction) and king_threats != []:
		southwest.append(currentSpace)
	if direction == Vector2(-move_direction,0) and king_threats != []:
		west.append(currentSpace)
	if direction == Vector2(-move_direction,move_direction) and king_threats != []:
		northwest.append(currentSpace)
	if direction == Vector2(move_direction,move_direction*2) and king_threats != []:
		knighteast.append(currentSpace)
	if direction == Vector2(-move_direction,move_direction*2) and king_threats != []:
		knightwest.append(currentSpace)
	#print(currentSpace)
	
	return king_threats

func check_swinging_attack_vectors_directions_and_piece(start_pos, direction, player, threatening_pieces):
	var king_threats = []
	var alliedPiecesInPath = []
	var currentSpace = start_pos + direction
	var opponent = Player.Gote if player == Player.Sente else Player.Sente
	var alliedPieceIndex
	var alliedPiece 
	var threatenedSpaces = []
	var spacesChecked = []
	var isBlocked = false 
	#print(boardSprite.playerTurn)
	#print(start_pos, direction, player)
	while is_inside_board(currentSpace):
		spacesChecked.append(currentSpace)
		if boardSprite.piecesOnBoard.has(currentSpace):
			var pieceIndex = boardSprite.piecesOnBoard.find(currentSpace)
			var found_piece_owner = boardSprite.pieceData[pieceIndex][1]
			if found_piece_owner == player:
				# An allied piece is found, it blocks the attack
				alliedPiecesInPath.append(currentSpace)
				print("current space: ",currentSpace)
				if alliedPiecesInPath.size() == 1:
					alliedPieceIndex = boardSprite.piecesOnBoard.find(currentSpace)
					alliedPiece = instance_from_id(boardSprite.pieceData[alliedPieceIndex][2])
					#print("current space ",currentSpace)
					#print("Allied piece position:", alliedPiece.currentPosition)
				else:
					alliedPieceIndex = null
				isBlocked = true 
				break
			elif found_piece_owner == opponent:
				if boardSprite.pieceData[pieceIndex][0] in threatening_pieces:
					if not isBlocked:
						king_threats.append(currentSpace)
						threatenedSpaces = spacesChecked
					break
		currentSpace += direction
	if alliedPiecesInPath.size() == 1 and not isBlocked:
		if alliedPiece != null:
			for space in threatenedSpaces:
				alliedPiece.constrained_moves.append(space)
	if not isBlocked:
		if direction == Vector2(0, -1) and king_threats != []:
			vertical_north = spacesChecked
		if direction == Vector2(1, -1) and king_threats != []:
			diagonal_northeast = spacesChecked
		if direction == Vector2(1, 0) and king_threats != []:
			horizontal_east = spacesChecked
		if direction == Vector2(1, 1) and king_threats != []:
			diagonal_southeast = spacesChecked
		if direction == Vector2(0, 1) and king_threats != []:
			vertical_south = spacesChecked
		if direction == Vector2(-1, 1) and king_threats != []:
			diagonal_southwest = spacesChecked
		if direction == Vector2(-1, 0) and king_threats != []:
			horizontal_west = spacesChecked
		if direction == Vector2(-1, -1) and king_threats != []:
			diagonal_northwest = spacesChecked
	
	return king_threats


func clear_attack_vectors():
	confirmed_attack_vectors = []
	vertical_north = []
	diagonal_northeast = []
	horizontal_east = []
	diagonal_southeast = []
	vertical_south = []
	diagonal_southwest = []
	horizontal_west = []
	diagonal_northwest = []
	north = []
	northeast = []
	east = []
	southeast = []
	south = []
	southwest = []
	west = []
	northwest = []
	knighteast = []
	knightwest = []
	#print("attack vectors cleared")
	#print(boardSprite.current_player_king.confirmed_attack_vectors)

func deferred_print(value):
	print(value)
