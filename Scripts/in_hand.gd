extends Node2D

enum Player{
	Sente,
	Gote
}

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

var handOwner = Player.Sente
var piecesInHand = [0,0,0,0,0,0,0] #P,L,N,S,G,B,R

@onready var inHandPawn = inHandPiece.instantiate()
@onready var inHandLance = inHandPiece.instantiate()
@onready var inHandKnight = inHandPiece.instantiate()
@onready var inHandSilver = inHandPiece.instantiate()
@onready var inHandGold = inHandPiece.instantiate()
@onready var inHandBishop = inHandPiece.instantiate()
@onready var inHandRook = inHandPiece.instantiate()

@onready var board = get_parent()
@onready var boardSprite = board.get_node("BoardSprite")

var xMargin = 25
@onready var rectHeight = boardSprite.texture.get_height() * boardSprite.scale.y
@onready var rectWidth =  boardSprite.texture.get_height() * boardSprite.scale.x / 7
@onready var rect = Rect2(xMargin, 0,rectWidth,rectHeight)

var inHandPiece = load("res://Scenes/in_hand_piece.tscn")

func _ready():
	if handOwner == Player.Sente:
		add_child.call_deferred(inHandPawn)
		add_child.call_deferred(inHandLance)
		add_child.call_deferred(inHandKnight)
		add_child.call_deferred(inHandSilver)
		add_child.call_deferred(inHandGold)
		add_child.call_deferred(inHandBishop)
		add_child.call_deferred(inHandRook)
		inHandPawn.position = Vector2(xMargin + rectWidth / 2, rectWidth * 7 - rectWidth / 2)
		inHandPawn.pieceType = PieceType.Pawn
		inHandLance.position = Vector2(xMargin + rectWidth / 2, rectWidth * 6 - rectWidth / 2)
		inHandLance.pieceType = PieceType.Lance
		inHandKnight.position = Vector2(xMargin + rectWidth / 2, rectWidth * 5 - rectWidth / 2)
		inHandKnight.pieceType = PieceType.Knight
		inHandSilver.position = Vector2(xMargin + rectWidth / 2, rectWidth * 4 - rectWidth / 2)
		inHandSilver.pieceType = PieceType.Silver
		inHandGold.position = Vector2(xMargin + rectWidth / 2, rectWidth * 3 - rectWidth / 2)
		inHandGold.pieceType = PieceType.Gold
		inHandBishop.position = Vector2(xMargin + rectWidth / 2, rectWidth * 2 - rectWidth / 2)
		inHandBishop.pieceType = PieceType.Bishop
		inHandRook.position = Vector2(xMargin + rectWidth / 2, rectWidth * 1 - rectWidth / 2)
		inHandRook.pieceType = PieceType.Rook
	if handOwner == Player.Gote:
		add_child.call_deferred(inHandPawn)
		add_child.call_deferred(inHandLance)
		add_child.call_deferred(inHandKnight)
		add_child.call_deferred(inHandSilver)
		add_child.call_deferred(inHandGold)
		add_child.call_deferred(inHandBishop)
		add_child.call_deferred(inHandRook)
		inHandPawn.position = Vector2(-xMargin - rectWidth / 2, rectWidth * 1 - rectWidth / 2)
		inHandPawn.pieceType = PieceType.Pawn
		inHandPawn.pieceOwner = Player.Gote
		inHandLance.position = Vector2(-xMargin - rectWidth / 2, rectWidth * 2 - rectWidth / 2)
		inHandLance.pieceType = PieceType.Lance
		inHandLance.pieceOwner = Player.Gote
		inHandKnight.position = Vector2(-xMargin - rectWidth / 2, rectWidth * 3 - rectWidth / 2)
		inHandKnight.pieceType = PieceType.Knight
		inHandKnight.pieceOwner = Player.Gote
		inHandSilver.position = Vector2(-xMargin - rectWidth / 2, rectWidth * 4 - rectWidth / 2)
		inHandSilver.pieceType = PieceType.Silver
		inHandSilver.pieceOwner = Player.Gote
		inHandGold.position = Vector2(-xMargin - rectWidth / 2, rectWidth * 5 - rectWidth / 2)
		inHandGold.pieceType = PieceType.Gold
		inHandGold.pieceOwner = Player.Gote
		inHandBishop.position = Vector2(-xMargin - rectWidth / 2, rectWidth * 6 - rectWidth / 2)
		inHandBishop.pieceType = PieceType.Bishop
		inHandBishop.pieceOwner = Player.Gote
		inHandRook.position = Vector2(-xMargin - rectWidth / 2, rectWidth * 7 - rectWidth / 2)
		inHandRook.pieceType = PieceType.Rook
		inHandRook.pieceOwner = Player.Gote
		
	await(get_tree().create_timer(0).timeout)
	#update_in_hand()

func _draw():
	if handOwner == Player.Sente:
		draw_rect(Rect2(rect),boardSprite.gridColor,false,boardSprite.lineSize)
		for i in 7:
			draw_line(Vector2(xMargin,i * boardSprite.texture.get_height() * boardSprite.scale.x / 7), Vector2(rectWidth + xMargin,i * boardSprite.texture.get_height() * boardSprite.scale.x / 7),boardSprite.gridColor,boardSprite.lineSize)
	if handOwner == Player.Gote:
		draw_rect(Rect2(-xMargin, 0,-rectWidth,rectHeight),boardSprite.gridColor,false,boardSprite.lineSize)
		for i in 7:
			draw_line(Vector2(-xMargin,i * boardSprite.texture.get_height() * boardSprite.scale.x / 7), Vector2(-rectWidth - xMargin,i * boardSprite.texture.get_height() * boardSprite.scale.x / 7),boardSprite.gridColor,boardSprite.lineSize)

func update_in_hand(piece, amount):
	if piece == PieceType.Pawn:
		inHandPawn.pieceCount += amount
		inHandPawn.update_pieces()
	if piece == PieceType.Lance:
		inHandLance.pieceCount += amount
		inHandLance.update_pieces()
	if piece == PieceType.Knight:
		inHandKnight.pieceCount += amount
		inHandKnight.update_pieces()
	if piece == PieceType.Silver:
		inHandSilver.pieceCount += amount
		inHandSilver.update_pieces()
	if piece == PieceType.Gold:
		inHandGold.pieceCount += amount
		inHandGold.update_pieces()
	if piece == PieceType.Bishop:
		inHandBishop.pieceCount += amount
		inHandBishop.update_pieces()
	if piece == PieceType.Rook:
		inHandRook.pieceCount += amount
		inHandRook.update_pieces()
	if piece == -1:
		inHandPawn.pieceCount = amount
		inHandPawn.update_pieces()
		inHandLance.pieceCount = amount
		inHandLance.update_pieces()
		inHandKnight.pieceCount = amount
		inHandKnight.update_pieces()
		inHandSilver.pieceCount = amount
		inHandSilver.update_pieces()
		inHandGold.pieceCount = amount
		inHandGold.update_pieces()
		inHandBishop.pieceCount = amount
		inHandBishop.update_pieces()
		inHandRook.pieceCount = amount
		inHandRook.update_pieces()
