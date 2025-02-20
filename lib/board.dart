import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trtris/pixel.dart';
import 'package:trtris/values.dart';
import 'package:trtris/piece.dart';

//create board

List<List<Tetromino?>> gameBoard = List.generate(colLength, (i) => List.generate(rowLength,(j)=>null ,),);

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  
  //current tetris piece
  Piece currentPiece = Piece(type: Tetromino.T); //First piece to fall

  //current score
  int currentScore=0;

  //gameover status
  bool gameOver=false;

  @override
  void initState() {
    super.initState();

    // start game when app starts
    startGame();
  }

  void startGame(){
    currentPiece.initializePiece();

    //frame refresh rate
    Duration frameRate = const Duration(milliseconds: 200); //Pieces speed (200 = fast)
    gameLoop(frameRate);

  }
  //game loop
  void gameLoop(Duration frameRate){
    Timer.periodic(
      frameRate,
      (timer) {
        setState(() {

          //clear lines
          clearLines();

          //check landing
          checkLanding();

          //check if game is over
          if(gameOver==true){
            timer.cancel();
            showGameOverDialog();
          }



          //move current piece down
          currentPiece.movePiece(Direction.down);
        });
      },
    );
  }
  //game over message
  void showGameOverDialog(){
    showDialog(context: context, builder: (context)=>AlertDialog(
      title: Text('Game Over'),
      content: Text('Your score is: $currentScore'),
      actions: [
        TextButton(onPressed: (){
          //reset the game
          resetGame();
          
          //Game over message
          Navigator.pop(context);
        }, child: Text('Play again'))
      ],
    ),
    );
  }

  //reset game
  void resetGame(){
    //clear the board
    gameBoard= List.generate(colLength, (i) => List.generate(rowLength,(j)=>null ,),);

    //new game
    gameOver=false;
    currentScore=0;

    //create new piece
    createNewPiece();

    //play again
    startGame();
  }

  //check ofr collision in a future position 
  //return true --> there is a collision 
  //return false --> there is no colission 
  bool checkCollision(Direction direction){
    //loop through each position of the current piece
    for (int i=0; i<currentPiece.position.length; i++){
      //calculate the row and the column of the current position 
      int row =(currentPiece.position[i] / rowLength).floor();
      int col =currentPiece.position[i] % rowLength;

      //adjust the row and col base on the direction
      if(direction == Direction.left) {
        col -=1;
      } else if (direction == Direction.right){
        col +=1;
      } else if (direction == Direction.down){
        row += 1;
      }

      //check if the piece is out of bounds (either too low or too far to the left or right)
      if(row >= colLength || col<0 || col>= rowLength){
        return true;
      }
      //check collisions with other landed pieces
      if(row>= 0 && gameBoard [row][col]!=null){
        return true;
      }

    }
    //if no collisions are detected, return false
    return false;
  } 
  
void checkLanding() {
    // if going down is occupied or landed on other pieces
    if (checkCollision(Direction.down) || checkLanded()) {
      // mark position as occupied on the game board
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;  

        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }

      // once landed, create the next piece
      createNewPiece();
    }
  }

  bool checkLanded() {
    // loop through each position of the current piece
    for (int i = 0; i < currentPiece.position.length; i++) {
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      // check if the cell below is already occupied
      if (row + 1 < colLength && row >= 0 && gameBoard[row + 1][col] != null) {
        return true; // collision with a landed piece
      }
    }

    return false; // no collision with landed pieces
  }

  void createNewPiece(){
    //create a random object to generate random tetromino types
    Random rand = Random();

    // create a new piece with random  type
    Tetromino randomType = Tetromino.values[rand.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();

    if(isGameOver()){
      gameOver=true;
    }
  }

  //move left
  void moveLeft(){
    //make sure the move is valid before moving there
    if(!checkCollision(Direction.left)){
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }

  }

  //move right
  void moveRight(){
    //make sure the move is valid before moving there
    if(!checkCollision(Direction.right)){
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }

  }

  //rotatepiece
  void rotatePiece(){
    setState(() {
      currentPiece.rotatePiece();
    });

  }
  //clear lines
  void clearLines(){
    //step1: Loop through each row of the game board, from bottom to top
    for (int row = colLength -1; row >= 0; row--){
      //step 2: initialize a variable to track if the row is full
      bool rowIsFull = true;

      //step3: check if the row is full 
      for (int col=0; col < rowLength; col++){
        //if theres an emptycolumn, set rowIsFull to false and break the loop
        if(gameBoard[row][col]==null){
          rowIsFull = false;
          break;
        }
      }
      //step4: if the row is full, clear the row and shift rows down
      if (rowIsFull){
        //step5: move all rows above the cleared row down by one position
        for(int r = row; r>0; r--){
          //copy the above row to the current row 
          gameBoard[r] =List.from(gameBoard[r-1]);
        }
        //step6: set the top row to empty 
        gameBoard[0]= List.generate(row, (index) =>null);

        //step7: increase the score
        currentScore++;
      }
    }
  }

  //gameover
  bool isGameOver(){
    //check if any columns in the top row are filled
    for(int col=0; col<rowLength; col++){
      if(gameBoard[0][col] != null){
        return true;
      }
    }

    //if the top row is empty
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [

          //GAME GRID
          Expanded(
            child: GridView.builder(itemCount: rowLength*colLength, physics: const NeverScrollableScrollPhysics(),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: rowLength), itemBuilder: (context, index){
              
              //get row and col of each index
              int row=(index/rowLength).floor();
              int col =index % rowLength;
              //current piece
              if (currentPiece.position.contains(index)){
                return Pixel(
                color: currentPiece.color, 
                );
              } 
              //landed pieces
              else if (gameBoard[row][col]!= null){
                final Tetromino? tetrominoType = gameBoard[row][col];
                return Pixel(color: tetrominoColors[tetrominoType]);
            
              }
              //blank pixel
              else {
                return Pixel(
                  color: Colors.grey[900], 
                );
              }
            },
            ),
          ),

          //score
          Text('Score: $currentScore',
          style: TextStyle(color:Colors.white),
          
          ),
          
          //GAME CONTROLS
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
              //left
              IconButton(
              onPressed: moveLeft, 
              color:Colors.white,
              icon: Icon(Icons.arrow_back),
              ),
            
              //rotate
              IconButton(
              onPressed: rotatePiece,
              color:Colors.white, 
              icon: Icon(Icons.rotate_right),
              ),
            
              //right
              IconButton(
              onPressed: moveRight, 
              color:Colors.white,
              icon: Icon(Icons.arrow_forward),
              ),
            ],
            ),
          )
        ],
      ),
    );
  }
}