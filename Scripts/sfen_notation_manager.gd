extends Node2D


enum Player {
	Sente,
	Gote
}

enum PieceType {
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

const PIECE_CHARACTERS = {
	Player.Sente: {
		PieceType.King: "K",
		PieceType.Pawn: "P",
		PieceType.Lance: "L",
		PieceType.Knight: "N",
		PieceType.Silver: "S",
		PieceType.Gold: "G",
		PieceType.Bishop: "B",
		PieceType.Rook: "R",
		PieceType.PromotedPawn: "+P",
		PieceType.PromotedLance: "+L",
		PieceType.PromotedKnight: "+N",
		PieceType.PromotedSilver: "+S",
		PieceType.PromotedBishop: "+B",
		PieceType.PromotedRook: "+R"
	},
	Player.Gote: {
		PieceType.King: "k",
		PieceType.Pawn: "p",
		PieceType.Lance: "l",
		PieceType.Knight: "n",
		PieceType.Silver: "s",
		PieceType.Gold: "g",
		PieceType.Bishop: "b",
		PieceType.Rook: "r",
		PieceType.PromotedPawn: "+p",
		PieceType.PromotedLance: "+l",
		PieceType.PromotedKnight: "+n",
		PieceType.PromotedSilver: "+s",
		PieceType.PromotedBishop: "+b",
		PieceType.PromotedRook: "+r"
	}
}

@onready var board = get_parent()
@onready var button_get_sfen = $Button_get_sfen
@onready var lineEdit_sfen = $LineEdit_sfen
@onready var button_set_sfen = $Button_set_sfen
var regex = RegEx.new()

func _ready():
	pass

func get_sfen_notation():
	var sfen = ""
	var empty_count = 0
	for rank in range(0, board.boardSize.y):
		for file in range(board.boardSize.x - 1, -1, -1):
			var currentPosition = Vector2(file+1, rank+1)
			var piece_id = board.piecesOnBoard.find(currentPosition)
			if piece_id == -1:  
				empty_count += 1
			else:
				if empty_count > 0:
					sfen += str(empty_count)
					empty_count = 0

				var piece_data = board.pieceData[piece_id]
				var piece_owner = piece_data[1]
				var piece_type = piece_data[0]
				var piece_char = PIECE_CHARACTERS[piece_owner][piece_type]
				sfen += piece_char
		if empty_count > 0:
			sfen += str(empty_count)
			empty_count = 0

		if rank < board.boardSize.y - 1:
			sfen += "/"
	sfen += " "
	
	if board.playerTurn == 0:
		sfen += "b"
	else:
		sfen += "w"
	
	sfen += " "
	var senteHand = ""
	senteHand += get_hand_notation(board.inHandSente.inHandPawn.pieceCount, "P")
	senteHand += get_hand_notation(board.inHandSente.inHandLance.pieceCount, "L")
	senteHand += get_hand_notation(board.inHandSente.inHandKnight.pieceCount, "N")
	senteHand += get_hand_notation(board.inHandSente.inHandSilver.pieceCount, "S")
	senteHand += get_hand_notation(board.inHandSente.inHandGold.pieceCount, "G")
	senteHand += get_hand_notation(board.inHandSente.inHandBishop.pieceCount, "B")
	senteHand += get_hand_notation(board.inHandSente.inHandRook.pieceCount, "R")
	var goteHand = ""
	goteHand += get_hand_notation(board.inHandGote.inHandPawn.pieceCount, "p")
	goteHand += get_hand_notation(board.inHandGote.inHandLance.pieceCount, "l")
	goteHand += get_hand_notation(board.inHandGote.inHandKnight.pieceCount, "n")
	goteHand += get_hand_notation(board.inHandGote.inHandSilver.pieceCount, "s")
	goteHand += get_hand_notation(board.inHandGote.inHandGold.pieceCount, "g")
	goteHand += get_hand_notation(board.inHandGote.inHandBishop.pieceCount, "b")
	goteHand += get_hand_notation(board.inHandGote.inHandRook.pieceCount, "r")
	
	if senteHand == "" and goteHand == "":
		sfen += "-"
	else:
		sfen += senteHand
		sfen += goteHand

	return sfen

func get_hand_notation(count, piece_char):
	if count > 0:
		return str(count if count > 1 else "") + (piece_char)
	return ""

func _on_button_get_sfen_pressed():
	lineEdit_sfen.text = get_sfen_notation()

func _on_button_set_sfen_pressed():
	board.clear_board()
	create_board_from_sfen(lineEdit_sfen.text)
	
func create_board_from_sfen(sfen: String):
	var parts = sfen.split(" ")
	var board_state = parts[0]
	
	regex.compile("([1-9]|[plnsgkbrPLNSGKBR])")
	var matches = regex.search_all(board_state)
	
	var x = 0
	var y = 0
	for amatch in matches:
		var match_string = amatch.get_string()
		print(match_string)
		if match_string.is_valid_int():
			x += int(match_string)
		else:
			var piece_type = get_piece_type_from_symbol(match_string)
			var piece_owner
			if amatch.get_string() == match_string.to_upper():
				piece_owner = Player.Sente
			else:
				piece_owner = Player.Gote
			board.create_piece(piece_type,piece_owner,Vector2(board.boardSize.x - x,y+1))
			x+=1
		if x > board.boardSize.x - 1:
			x = 0
			y += 1
			
func get_piece_type_from_symbol(symbol: String) -> int:
	symbol = symbol.to_upper()
	match symbol:
		"K":
			return PieceType.King
		"R":
			return PieceType.Rook
		"B":
			return PieceType.Bishop
		"G":
			return PieceType.Gold
		"S":
			return PieceType.Silver
		"N":
			return PieceType.Knight
		"L":
			return PieceType.Lance
		"P":
			return PieceType.Pawn
		_:
			print("Unknown piece symbol: ", symbol)
			return -1
