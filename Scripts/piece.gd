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

@export var currentPosition: Vector2
@export var selected: bool = false
var dragging: bool = false
var dragging_position: Vector2
var selectionColor = Color(0,1,0,0.5)
@onready var rectSize = Vector2(texture.get_width(),texture.get_height())

var valid_moves = []
var capture_squares = []
var squareHighlight = load("res://Scenes/square_highlight.tscn")


func _ready():
	scale *= globalPieceScale
	set_piece_type()
	snap_to_grid()
	if pieceOwner == Player.Gote:
		rotation_degrees += 180
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and (pieceOwner == boardSprite.playerTurn) and event.button_index == MOUSE_BUTTON_LEFT:
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
					deltaPosition.x *= -1 #this accounts for the sprite origin being on the left side of the board
					highlight.position -= deltaPosition
		queue_redraw()

func _draw():
	if selected:
		draw_rect(Rect2(Vector2(0,0) - rectSize/2,rectSize),selectionColor,true)
		draw_texture(texture,Vector2(-texture.get_width()/2,-texture.get_height()/2),modulate)

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

func get_valid_moves(coordinate):
	var move_direction
	var possibleMoves = []
	if pieceOwner == Player.Sente:
		move_direction = -1
	else:
		move_direction = 1
	
	if pieceType == PieceType.Pawn:
		possibleMoves.append(Vector2(coordinate.x,coordinate.y + move_direction))
		for moves in possibleMoves:
			if check_move_legality(moves):
				valid_moves.append(moves)
	if pieceType == PieceType.Lance:
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,0,move_direction)
	if pieceType == PieceType.Knight:
		possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y + move_direction * 2))
		possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y + move_direction * 2))
		for moves in possibleMoves:
			if check_move_legality(moves):
				valid_moves.append(moves)
	if pieceType == PieceType.Silver:
		possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y - move_direction))
		possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y - move_direction))
		for moves in possibleMoves:
			if check_move_legality(moves):
				valid_moves.append(moves)
	if pieceType == PieceType.Gold:
		possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y + move_direction))
		possibleMoves.append(Vector2(coordinate.x - move_direction,coordinate.y))
		possibleMoves.append(Vector2(coordinate.x + move_direction,coordinate.y))
		possibleMoves.append(Vector2(coordinate.x,coordinate.y - move_direction))
		for moves in possibleMoves:
			if check_move_legality(moves):
				valid_moves.append(moves)
	if pieceType == PieceType.Bishop:
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,-move_direction,move_direction)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,move_direction,move_direction)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,-move_direction,-move_direction)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,move_direction,-move_direction)
	if pieceType == PieceType.Rook:
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,0,-move_direction)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,move_direction,0)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,0,move_direction)
		check_horizontal_moves(valid_moves,coordinate.x,coordinate.y,-move_direction,0)
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
			if check_move_legality(moves):
				valid_moves.append(moves)

func check_move_legality(move):
	if !is_inside_board(move):
		return false
	if can_capture(move):
		return true
	if is_space_taken(move):
		return false
	return true

func is_inside_board(move):
	return(move.x > 0 and move.x <= boardSprite.boardSize.x and move.y > 0 and move.y <= boardSprite.boardSize.y)
		
func is_space_taken(move):
	return move in boardSprite.piecesOnBoard

func can_capture(move):
	if is_space_taken(move):
		if pieceOwner == Player.Sente:
			if move in boardSprite.gotePiecesOnBoard:
				return true
		if pieceOwner == Player.Gote:
			if move in boardSprite.sentePiecesOnBoard:
				return true
	return false

func check_horizontal_moves(valid_move, start_rank, start_file, delta_rank, delta_file):
	var target_rank = start_rank + delta_rank
	var target_file = start_file + delta_file
	while check_move_legality(Vector2(target_rank,target_file)):
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
		target_rank += delta_rank
		target_file += delta_file


func destroy_all_highlights():
	for child in get_children():
		#if child is square_highlight:
			child.queue_free()

func move_piece(rank,file):
	if can_capture(Vector2(rank,file)):
		capture_piece(rank,file)
	var indexToRemove = boardSprite.piecesOnBoard.find(currentPosition)
	boardSprite.piecesOnBoard.remove_at(indexToRemove) #remove the moving from position from the array
	boardSprite.pieceData.remove_at(indexToRemove)	#remove the moving from position from the array
	if pieceOwner == Player.Sente:
		boardSprite.sentePiecesOnBoard.remove_at(boardSprite.sentePiecesOnBoard.find(currentPosition)) #remove the moving from position from the array
	if pieceOwner == Player.Gote:
		boardSprite.gotePiecesOnBoard.remove_at(boardSprite.gotePiecesOnBoard.find(currentPosition)) #remove the moving from position from the array
	currentPosition = Vector2(rank,file)
	boardSprite.piecesOnBoard.append(currentPosition) #adds the moving to position to the array
	boardSprite.pieceData.append([pieceType,pieceOwner]) # adds the moving to data (piece type and owner) to the array
	if pieceOwner == Player.Sente:
		boardSprite.sentePiecesOnBoard.append(currentPosition)  # adds the moving to position into the array
	if pieceOwner == Player.Gote:
		boardSprite.gentePiecesOnBoard.append(currentPosition) # adds the moving to position into the array
	snap_to_grid()

func capture_piece(rank,file):
	var indexToRemove =  boardSprite.piecesOnBoard.find(Vector2(rank,file))
	var captured_id
	if pieceOwner == Player.Sente:
		add_piece_to_hand((boardSprite.pieceData[boardSprite.piecesOnBoard.find(Vector2(rank,file))]))
		captured_id = (boardSprite.pieceData[boardSprite.piecesOnBoard.find(Vector2(rank,file))])[2]
		boardSprite.gotePiecesOnBoard.remove_at(boardSprite.gotePiecesOnBoard.find(Vector2(rank,file)))
		boardSprite.piecesOnBoard.remove_at(indexToRemove)
		boardSprite.pieceData.remove_at(indexToRemove)
		
		instance_from_id(captured_id).queue_free()
		
	if pieceOwner == Player.Gote:
		add_piece_to_hand((boardSprite.pieceData[boardSprite.piecesOnBoard.find(Vector2(rank,file))]))
		captured_id = (boardSprite.pieceData[boardSprite.piecesOnBoard.find(Vector2(rank,file))])[2]
		boardSprite.sentePiecesOnBoard.remove_at(boardSprite.sentePiecesOnBoard.find(Vector2(rank,file)))
		boardSprite.piecesOnBoard.remove_at(indexToRemove)
		boardSprite.pieceData.remove_at(indexToRemove)
		
		instance_from_id(captured_id).queue_free()
		

func add_piece_to_hand(piece_data):
	print(piece_data)
