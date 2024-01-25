extends Node2D

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

var pieceType: PieceType = PieceType.Pawn
var pieceOwner = Player.Sente
var pieceCount = 0
@onready var spriteNode = $Sprite2D

@onready var board = get_parent().get_parent()
@onready var boardSprite = board.get_node("BoardSprite")

var valid_moves = []
var pawns = []
var pawnsIndex = []
var pawnsRemovalIndex = []
@export var selected: bool = false
var squareHighlight = load("res://Scenes/square_highlight.tscn")
@onready var globalPieceScale = (boardSprite.texture.get_width() * boardSprite.scale.x) / (boardSprite.boardSize.x * spriteNode.texture.get_width())


func _ready():
	scale *= globalPieceScale
	#spriteNode.modulate = Color(1,1,1,0.5)
	var sprite_texture = null
	match pieceType:
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
	spriteNode.texture = sprite_texture
	if pieceOwner == Player.Gote:
		rotation_degrees += 180
	set_process_input(true)
	#await(get_tree().create_timer(0).timeout)
	update_pieces()

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and (pieceOwner == boardSprite.playerTurn and pieceCount > 0) and event.button_index == MOUSE_BUTTON_LEFT and boardSprite.isPromoting == false:
		if spriteNode.get_rect().has_point(to_local(event.position)):
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
				get_valid_moves()
				for move_pos in valid_moves:
					var highlight = squareHighlight.instantiate()
					add_child(highlight)
					highlight.currentPosition = move_pos
					highlight.global_position = board.position + Vector2(boardSprite.texture.get_width() * boardSprite.scale.x,0)
					if pieceOwner == Player.Sente:
						highlight.position.x -= highlight.currentPosition.x * highlight.texture.get_width() - highlight.texture.get_width()/2
						highlight.position.y += highlight.currentPosition.y * highlight.texture.get_width() - highlight.texture.get_height()/2
					if pieceOwner == Player.Gote:
						highlight.position.x += highlight.currentPosition.x * highlight.texture.get_width() - highlight.texture.get_width()/2
						highlight.position.y -= highlight.currentPosition.y * highlight.texture.get_width() - highlight.texture.get_height()/2

func get_valid_moves():
	pawns = []
	pawnsIndex = []
	pawnsRemovalIndex = []
	valid_moves = []

	for  x in range(1,boardSprite.boardSize.x + 1):
		for y in range(1,boardSprite.boardSize.y + 1):
			var pos = Vector2(x,y)
			if !pos in boardSprite.piecesOnBoard:
				valid_moves.append(pos)
	if (pieceType == PieceType.Pawn or pieceType == PieceType.Lance) and pieceOwner == Player.Sente:
		for i in valid_moves:
			if i[1] == 1:
				valid_moves.remove_at(valid_moves.find(i))
	if pieceType == PieceType.Pawn and pieceOwner == Player.Sente:
		get_all_pawn_ranks()
		for j in valid_moves:
			for k in pawns:
				if j[0] == k:
					pawnsRemovalIndex.append(j)
		for each in pawnsRemovalIndex:
			valid_moves.erase(each)
		var checkmate_king = check_pawn_drop_checkmate()
		if checkmate_king != null:
			valid_moves.remove_at(valid_moves.find(checkmate_king))
	if pieceType == PieceType.Knight and pieceOwner == Player.Sente:
		var new_valid_moves = []
		for i in valid_moves:
			if i.y > 2:
				new_valid_moves.append(i)
		valid_moves = new_valid_moves
	
	if (pieceType == PieceType.Pawn or pieceType == PieceType.Lance) and pieceOwner == Player.Gote:
		for i in valid_moves:
			if i[1] == 9:
				valid_moves.remove_at(valid_moves.find(i))
	if pieceType == PieceType.Pawn and pieceOwner == Player.Gote:
		get_all_pawn_ranks()
		for j in valid_moves:
			for k in pawns:
				if j[0] == k:
					pawnsRemovalIndex.append(j)
		for each in pawnsRemovalIndex:
			valid_moves.erase(each)
		var checkmate_king = check_pawn_drop_checkmate()
		if checkmate_king != null:
			valid_moves.remove_at(valid_moves.find(checkmate_king))
	if pieceType == PieceType.Knight and pieceOwner == Player.Gote:
		var new_valid_moves = []
		for i in valid_moves:
			if i.y < 8:
				new_valid_moves.append(i)
		valid_moves = new_valid_moves
	
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
	
func check_pawn_drop_checkmate():
	var opponent
	var opponent_king
	if pieceOwner == Player.Sente:
		opponent = Player.Gote
	else:
		opponent = Player.Sente
	var move_direction
	if opponent == Player.Sente:
		move_direction = -1
	else:
		move_direction = 1
	
	for i in range(len(boardSprite.pieceData)):
		if boardSprite.pieceData[i][0] == PieceType.King and boardSprite.pieceData[i][1] == opponent:
			opponent_king = instance_from_id(boardSprite.pieceData[i][2])
			break
	var adjacent_squares = []
	var opponent_king_position = opponent_king.currentPosition
	var surronding_squares = [
	Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
	Vector2(-1,  0),               Vector2(1,  0),
	Vector2(-1,  1), Vector2(0,  1), Vector2(1,  1)]
	for square in surronding_squares:
		var adjacent_position = opponent_king_position + square
		if is_inside_board(adjacent_position):
			adjacent_squares.append(adjacent_position)
	var opponent_moves = get_all_moves_except_king_for_player()
	if pieceOwner == Player.Sente:
		for move in adjacent_squares:
			if move in opponent_moves:
				return
	else:
		for move in adjacent_squares:
			if move in opponent_moves:
				return
	return opponent_king_position + Vector2(0,move_direction)

func get_all_moves_except_king_for_player():
	var opponent
	var opponent_pieces_location = []
	var opponent_pieces = []
	var opponent_moves = []
	if pieceOwner == Player.Sente:
		opponent = Player.Gote
		opponent_pieces_location = boardSprite.gotePiecesOnBoard
	else:
		opponent = Player.Sente
		opponent_pieces_location = boardSprite.sentePiecesOnBoard
	
	for piece in opponent_pieces_location:
		var piece_index
		piece_index = boardSprite.piecesOnBoard.find(piece)
		if boardSprite.pieceData[piece_index][0] != 0:
			opponent_pieces.append(instance_from_id(boardSprite.pieceData[piece_index][2]))
	for piece in opponent_pieces:
		for move in piece.valid_moves:
			if move not in opponent_moves:
				opponent_moves.append(move)
	return opponent_moves
	

func get_all_pawn_ranks():
	if pieceOwner == Player.Sente:
		for i in boardSprite.pieceData:
			if i[0] == 1 and i[1] == 0:
				pawnsIndex.append(boardSprite.pieceData.find(i))
		for j in pawnsIndex:
			pawns.append(boardSprite.piecesOnBoard[j][0])
	if pieceOwner == Player.Gote:
		for i in boardSprite.pieceData:
			if i[0] == 1 and i[1] == 1:
				pawnsIndex.append(boardSprite.pieceData.find(i))
		for j in pawnsIndex:
			pawns.append(boardSprite.piecesOnBoard[j][0])

func destroy_all_highlights():
	for child in get_children():
		if child.is_in_group("highlights"):
			child.queue_free()

func drop_piece(file,rank):
	boardSprite.create_piece(pieceType, pieceOwner, Vector2(file,rank))
	destroy_all_highlights()
	if pieceOwner == Player.Sente:
		boardSprite.inHandSente.update_in_hand(pieceType,-1)
		boardSprite.call_deferred("emit_signal","turnEnd")
		#boardSprite.playerTurn = Player.Gote
		queue_redraw()
	elif pieceOwner == Player.Gote:
		boardSprite.inHandGote.update_in_hand(pieceType,-1)
		boardSprite.call_deferred("emit_signal","turnEnd")
		#boardSprite.playerTurn = Player.Sente
		queue_redraw()

func update_pieces():
	if pieceCount > 0:
		spriteNode.modulate = Color(1,1,1,1)
	elif pieceCount == 0:
		spriteNode.modulate = Color(1,1,1,0.3)

func is_inside_board(move):
	return(move.x > 0 and move.x <= boardSprite.boardSize.x and move.y > 0 and move.y <= boardSprite.boardSize.y)
