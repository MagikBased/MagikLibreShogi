extends Sprite2D

@export var boardSize = Vector2(9, 9)
var lineSize = 8 #should be divisible by 4 for even lines
var squareSize = (texture.get_width()) / boardSize.x
var gridColor = Color(0,0,0) # Change this to set the color of the grid lines
var circleRadius = squareSize * 0.15
var circleColor = Color(0,0,0)
	
func _ready():
	pass

func draw_grid():
	for x in range(1, boardSize.x):
		var xPosition = x * squareSize
		draw_line(Vector2(xPosition, 0), Vector2(xPosition, squareSize * boardSize.x), gridColor, lineSize)
	for y in range(1, boardSize.y):
		var yPosition = y * squareSize
		draw_line(Vector2(0,yPosition), Vector2(squareSize * boardSize.y, yPosition), gridColor, lineSize)
	print(squareSize)
	draw_circle(Vector2(squareSize*3,squareSize*3),circleRadius, circleColor)
	draw_circle(Vector2(squareSize*3,squareSize*6),circleRadius, circleColor)
	draw_circle(Vector2(squareSize*6,squareSize*3),circleRadius, circleColor)
	draw_circle(Vector2(squareSize*6,squareSize*6),circleRadius, circleColor)
	
func _draw():
	draw_grid()
