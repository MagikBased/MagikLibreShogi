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

var sfen_char_to_piece_type = {
	"P": PieceType.Pawn, "L": PieceType.Lance, "N": PieceType.Knight, 
	"S": PieceType.Silver, "G": PieceType.Gold, "B": PieceType.Bishop, "R": PieceType.Rook,
	"p": PieceType.Pawn, "l": PieceType.Lance, "n": PieceType.Knight, 
	"s": PieceType.Silver, "g": PieceType.Gold, "b": PieceType.Bishop, "r": PieceType.Rook
}

@onready var board = get_parent()
@onready var button_get_sfen = $Button_get_sfen
@onready var lineEdit_sfen = $LineEdit_sfen
@onready var button_set_sfen = $Button_set_sfen
var regex = RegEx.new()

var pieceToIndex = {"P": 0, "L": 1, "N": 2, "S": 3, "G": 4, "B": 5, "R": 6, "p": 0, "l": 1, "n": 2, "s": 3, "g": 4, "b": 5, "r": 6}


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
				if instance_from_id(piece_data[2]).promoted:
					piece_char = "+" + piece_char
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
	sfen += " " + str(board.turnCount)
	return sfen

func create_board_from_sfen(sfen: String):
	var parts = sfen.split(" ")
	var board_state = parts[0]
	var player_turn = parts[1]
	var in_hand_pieces = parts[2]
	var turn_count = parts[3]
	
	regex.compile("([1-9]|\\+[plnsgkbrPLNSGKBR]|[plnsgkbrPLNSGKBR])")
	var matches = regex.search_all(board_state)
	
	var x = 0
	var y = 0
	for amatch in matches:
		var match_string = amatch.get_string()
		var is_promoted = match_string.begins_with("+")
		
		if is_promoted:
			match_string = match_string.substr(1)
			
		if match_string.is_valid_int():
			x += int(match_string)
		else:
			var piece_type = get_piece_type_from_symbol(match_string)
			var piece_owner
			if match_string == match_string.to_upper():
				piece_owner = Player.Sente
			else:
				piece_owner = Player.Gote
			board.create_piece(piece_type,piece_owner,Vector2(board.boardSize.x - x,y+1),is_promoted)
			x+=1
		if x > board.boardSize.x - 1:
			x = 0
			y += 1
	
	regex.compile("(\\d*[PLNSGKBRplnsgkbr])")
	var in_hand_matches = regex.search_all(in_hand_pieces)
	
	for amatch in in_hand_matches:
		var piece_string = amatch.get_string()
		var count = 1
		var piece_char
		
		if piece_string.length() > 1:
			count = int(piece_string.substr(0,piece_string.length() - 1))
			piece_char = piece_string[-1]
		else:
			piece_char = piece_string
		var piece_type = sfen_char_to_piece_type[piece_char]
		if piece_char == piece_char.to_upper():
			board.inHandSente.call_deferred("update_in_hand",piece_type,count)
			
		else:
			board.inHandGote.call_deferred("update_in_hand",piece_type,count)
	
	if player_turn == "b":
		board.playerTurn = Player.Sente
	elif player_turn =="w":
		board.playerTurn = Player.Gote
	
	board.turnCount = int(turn_count)
	

func get_hand_notation(count, piece_char):
	if count > 0:
		return str(count if count > 1 else "") + (piece_char)
	return ""

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

func _on_button_get_sfen_pressed():
	lineEdit_sfen.text = get_sfen_notation()

func _on_button_set_sfen_pressed():
	board.clear_board()
	create_board_from_sfen(lineEdit_sfen.text)
