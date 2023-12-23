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
@onready var button = $Button

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
				print("Piece owner: ",piece_owner, " Piece Type: ", piece_type)
				var piece_char = PIECE_CHARACTERS[piece_owner][piece_type]
				sfen += piece_char
		if empty_count > 0:
			sfen += str(empty_count)
			empty_count = 0

		if rank < board.boardSize.y - 1:
			sfen += "/"

	return sfen

func _on_button_pressed():
	print(get_sfen_notation())
