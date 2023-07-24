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
	

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and (pieceOwner == boardSprite.playerTurn) and event.button_index == MOUSE_BUTTON_LEFT:
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
	if pieceType == PieceType.Knight and pieceOwner == Player.Sente:
		for i in valid_moves:
			if i[1] <= 2:
				valid_moves.remove_at(valid_moves.find(i))
	
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
	if pieceType == PieceType.Knight and pieceOwner == Player.Gote:
		for i in valid_moves:
			if i[1] >= 8:
				valid_moves.remove_at(valid_moves.find(i))
				
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
		boardSprite.playerTurn = Player.Gote
		queue_redraw()
	elif pieceOwner == Player.Gote:
		boardSprite.playerTurn = Player.Sente
		queue_redraw()
