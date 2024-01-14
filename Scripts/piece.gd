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
var adjacentSquares = [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1),Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]
var squareHighlight = load("res://Scenes/square_highlight.tscn")
var promotionWindow = load("res://Scenes/promotion_window.tscn")


func _ready():
	scale *= globalPieceScale
	set_piece_type()
	snap_to_grid()
	if pieceOwner == Player.Gote:
		rotation_degrees += 180
	else:
		var sente_material = ShaderMaterial.new()
		sente_material.shader = sente_shader
		material = sente_material
	set_process_input(true)
	if pieceType == PieceType.King and pieceOwner == Player.Sente:
		check_attack_vectors(currentPosition,pieceOwner)

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
		#draw_rect(Rect2(Vector2(0,0) - rectSize/2,rectSize),selectionColor,true)
	#var sente_shade = Color(0.8,0.8,0.8)
	#if pieceOwner == Player.Gote:
	draw_texture(texture,Vector2(float(-texture.get_width())/2,float(-texture.get_height())/2),modulate)
	#else:
		#draw_texture(texture,Vector2(float(-texture.get_width())/2,float(-texture.get_height())/2),sente_shade)

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
		PieceType.Lance:
			if promoted == false:
				sprite_texture = load("res://Images/Pieces/Lance.png")
			elif promoted == true:
				sprite_texture = load("res://Images/Pieces/Promoted Lance.png")
				pieceType = PieceType.PromotedLance
		PieceType.Knight:
			if promoted == false:
				sprite_texture = load("res://Images/Pieces/Knight.png")
			elif promoted == true:
				sprite_texture = load("res://Images/Pieces/Promoted Knight.png")
				pieceType = PieceType.PromotedKnight
		PieceType.Silver:
			if promoted == false:
				sprite_texture = load("res://Images/Pieces/Silver General.png")
			elif promoted == true:
				sprite_texture = load("res://Images/Pieces/Promoted Silver General.png")
				pieceType = PieceType.PromotedSilver
		PieceType.Gold:
			sprite_texture = load("res://Images/Pieces/Gold General.png")
		PieceType.Bishop:
			if promoted == false:
				sprite_texture = load("res://Images/Pieces/Bishop.png")
			elif promoted == true:
				sprite_texture = load("res://Images/Pieces/Promoted Bishop.png")
				pieceType = PieceType.PromotedBishop
		PieceType.Rook:
			if promoted == false:
				sprite_texture = load("res://Images/Pieces/Rook.png")
			elif promoted == true:
				sprite_texture = load("res://Images/Pieces/Promoted Rook.png")
				pieceType = PieceType.PromotedRook
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
	while check_move_legality(Vector2(target_rank,target_file), null, ignoreKing):
		valid_move.append(Vector2(target_rank,target_file))
		if can_capture(Vector2 (target_rank,target_file)):
			break
		target_rank += delta_rank
		target_file += delta_file
func check_diagonal_moves(valid_move, start_rank, start_file, delta_rank, delta_file):
	var target_rank = start_rank + delta_rank
	var target_file = start_file + delta_file
	while check_move_legality(Vector2(target_rank,target_file)):
		valid_move.append(Vector2(target_rank,target_file))
		if can_capture(Vector2 (target_rank,target_file)):
			break
		target_rank += delta_rank
		target_file += delta_file

func destroy_all_highlights():
	for child in get_children():
		if child.is_in_group("highlights"):
			child.queue_free()

func move_piece(file,rank):
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
	if can_promote(rank):
		if (pieceOwner == Player.Sente and (((pieceType == PieceType.Pawn or pieceType == PieceType.Lance) and rank == 1) or (pieceType == PieceType.Knight and rank <= 2))) or (pieceOwner == Player.Gote and (((pieceType == PieceType.Pawn or pieceType == PieceType.Lance) and rank == 9) or (pieceType == PieceType.Knight and rank >= 8))):
			promoted = true
			set_piece_type()
			boardSprite.emit_signal("turnEnd")
		else:
			boardSprite.isPromoting = true
			var promotionPrompt = promotionWindow.instantiate()
			#await(get_tree().create_timer(1).timeout)
			add_child(promotionPrompt)
			promotionPrompt.position.y += rectSize.y / 2
	else:
		boardSprite.emit_signal("turnEnd")
	if boardSprite.selectedPiece != null:
		boardSprite.selectedPiece = null
		destroy_all_highlights()
		selected = false
		valid_moves = []
	queue_redraw()
	boardSprite.is_in_check(Player.Sente)
	boardSprite.is_in_check(Player.Gote)

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

func can_promote(rank):
	if promoted == true:
		return false
	if pieceType == PieceType.Pawn or pieceType == PieceType.Lance or pieceType == PieceType.Knight or pieceType == PieceType.Silver or pieceType == PieceType.Bishop or pieceType == PieceType.Rook:
		if pieceOwner == Player.Sente and rank <= 3:
			return true
		elif pieceOwner == Player.Gote and rank >= 7:
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
	var threats = []
	var move_direction
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
	#print("Threats: " + str(threats),self)
	return threats
	
func check_swinging_attack_vectors_directions_and_piece(start_pos, direction,player, threatening_pieces):
	var threats = []
	var alliedPiecesInPath = []
	var currentSpace = start_pos + direction
	var opponent = Player.Gote if player == Player.Sente else Player.Sente
	
	var alliedPieceIndex
	var alliedPiece 
	
	var threatenedSpaces = []
	var spacesChecked = []
	
	while is_inside_board(currentSpace):
		spacesChecked.append(currentSpace)
		if boardSprite.piecesOnBoard.has(currentSpace):
			var pieceIndex = boardSprite.piecesOnBoard.find(currentSpace)
			if boardSprite.pieceData[pieceIndex][1] == player:
				alliedPiecesInPath.append(currentSpace)
				if alliedPiecesInPath.size() == 1:
					alliedPieceIndex = boardSprite.piecesOnBoard.find(currentSpace)
					alliedPiece = instance_from_id(boardSprite.pieceData[alliedPieceIndex][2])
				else:
					alliedPieceIndex = null
			elif boardSprite.pieceData[pieceIndex][1] == opponent:
				if boardSprite.pieceData[pieceIndex][0] in threatening_pieces:
					threats.append(currentSpace)
					threatenedSpaces = spacesChecked
					print("spaces checked ",spacesChecked)
					break
		currentSpace += direction
	if alliedPiecesInPath.size() == 1:
		if alliedPiece != null:
			for space in threatenedSpaces:
				alliedPiece.constrained_moves.append(space)
	#print("Threats: " + str(threats),self)
	return threats
