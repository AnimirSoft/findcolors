import 'package:audioplayers/audioplayers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flippable_box/flippable_box.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math';

void main() => runApp(const MyApp());

// StatelessWidget 정적 UI
// StatefulWidget 동적 UI
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => CardFlipState();
}

class CardFlipState extends State<MyHomePage> {
  int lineCount = 4; // 한줄에 카드 갯수
  var numbars; // 전체 카드 넘버
  late List<bool> showFronts; // 전체 카드 뒤집기 여부
  int selectIndex = 0;
  int firstNumber = -1; // 첫번째 선택 카드 Index
  int secondNumber = -1;  // 두번째 선택 카드 Index
  int cardVerdictCount = 0; // 뒤집어진 카드 갯수
  bool buttonClickFlag = true;  // 버튼 클릭 가능여부
  int cardSize = 10;
  double cardPadding = 10;

  static AudioCache player = AudioCache();
  String soundPath = "sound.mp3";

  @override
  void initState(){
    super.initState();
    reSet();
  }

  // 시작 및 재시작
  void reSet(){
    // 숫자를 생성하고 shuffle 함
    numbars = List.generate(lineCount * lineCount, (index) => getNumber(index), growable: false);
    numbars.shuffle();
    numbars.shuffle();
    numbars.shuffle();

    showFronts = List.generate(lineCount * lineCount, (index) => false, growable: false);
    firstNumber = -1;
    secondNumber = -1;
    cardVerdictCount = 0;
    buttonClickFlag = true;
  }

  // 전체 배열에서 두번 반복한 숫자를 가져온다.
  // ex>  8 = (4 x 4) / 2
  // 8 을 두번 반복함
  int getNumber(int index){
    int num = index+1;
    if(num > (lineCount * 2)){
      num = num - (lineCount * 2);
    }
    return num;
  }

  // 카드를 배치한다.
  List<Widget> setCards(){
    return List.generate(lineCount * lineCount, (index) =>
        GestureDetector(
            onTap: () {
              // setState 는 StatefulWidget 에서 사용 하는 화면 갱신 Function
              setState((){
                // 1> 버튼클릭이 가능하며 뒤집혀있는경우
                if(buttonClickFlag && !showFronts[index]){
                  showFronts[index] = true;
                  selectIndex = index;
                  // 2> 판정하기 위한 첫번째, 두번재 카드 Index 를 담아 둔다.
                  if(firstNumber == -1){
                    firstNumber = index;
                  }else if(secondNumber == -1){
                    secondNumber = index;
                  }
                  print('selectFlag : ${index}');
                  //Fluttertoast.showToast(msg: '$firstNumber : ${numbars[index]}', gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT);
                  // 3> 두개다 선택이 되었을 경우
                  if(firstNumber != -1 && secondNumber != -1){
                    // 4> 버튼을 클릭하지 못하게 잠근다. sync
                    buttonClickFlag = false;

                    // 5> 판정
                    // 5_1> 선택카드가 같으면 정답카드 카운트를 올리고 선택카드를 초기화 시킨다.
                    // 5_2> 선택카드가 다를경우 다시 되돌리고 선택카드를 초기화 시킨다.
                    // 5_3> 정답카드 카운트가 전체 카드갯수 /2 만큼 도달할경우 게임 종료로 간주한다.
                    if(numbars[firstNumber] == numbars[secondNumber]){

                      //Fluttertoast.showToast(msg: '$firstNumber : ${numbars[index]}', gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT);
                      firstNumber = -1;
                      secondNumber = -1;
                      cardVerdictCount++;

                      player.play(soundPath);

                      if(cardVerdictCount == (lineCount * lineCount) / 2 ){
                        Fluttertoast.showToast(msg: 'Game Clear!!', gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_SHORT);
                      }else{
                        buttonClickFlag = true;
                      }

                    }else{
                      // 속도가 너무 빨라서 타이머를 이용해 0.5초 뒤에 실행하도록 하였음
                      Timer.periodic(const Duration(milliseconds: 500), (Timer timer) =>
                          setState(() {
                            showFronts[firstNumber] = false;
                            showFronts[secondNumber] = false;
                            firstNumber = -1;
                            secondNumber = -1;
                            timer.cancel();
                            buttonClickFlag = true;
                          })
                      );

                    }
                  }
                }
              });
            },

          // child: FlippableBox(
          //   front: renderCard(isBack: false, colorIndex: numbars[index]),
          //   back: renderCard(isBack: true, colorIndex: numbars[index]),
          //   isFlipped: showFronts[index],
          //   duration: 0.5,
          //   curve: Curves.easeOut,
          // ),
          
          child: Card(
              isFlipped: showFronts[index],
              front: renderCard(isBack: false, colorIndex: numbars[index]),
              back: renderCard(isBack: true, colorIndex: numbars[index])
          ),
            //AnimatedSwitcher를 이용하여 showFronts값에 따라서 앞면카드 또는 뒷면 카드가 보일수있게 한다.
            // child: AnimatedSwitcher(
            //   duration: const Duration(milliseconds: 500),
            //   transitionBuilder: transitionBuilder,
            //   child: showFronts[index] ? renderCard(isBack: true, colorIndex: numbars[index]) : renderCard(isBack: false, colorIndex: numbars[index]),
            // )
          //selectContainer(cardSelectFlags[i1 * lineCount + i2], i1, i2)
        )
    );
  }
  // Widget transitionBuilder(Widget widget, Animation<double> animation){
  //   // return TweenAnimationBuilder(
  //   //     tween: Tween<double>(begin: 0, end: showFronts[selectIndex] ? 180 : 0),
  //   //     duration: const Duration(milliseconds: 700),
  //   //     builder: (BuildContext context, double? value, Widget? child) {
  //   //       return RotationY(key: const ValueKey(false), child: child!, rotationY: value!);
  //   //     },
  //   // );
  // }
  // 카드 뒤집기 애니메이션
  // Widget transitionBuilder(Widget widget, Animation<double> animation){
  //   // Pi 부터 0 까지에 값을 애니메이션 시킨다.
  //   final rotate = Tween(begin: pi, end: 0).animate(animation);
  //
  //   return AnimatedBuilder(
  //       animation: rotate,
  //       child: widget,
  //       builder: (BuildContext context, Widget? widget){
  //
  //         final value = min(rotate.value, pi / 2);
  //         double tilt = ((animation.value - 0.5).abs() - 0.5) * 0.005;
  //
  //         print('${animation.value}');
  //
  //         tilt *= (animation.value <= 1) ? -1.0 : 1.0;
  //
  //         return Transform(
  //           transform: Matrix4.rotationY(value as double)..setEntry(3, 0, tilt),
  //           child: widget,
  //           alignment: Alignment.center,
  //         );
  //       });
  // }

  // bool 에 따라 카드 뒷면과 앞면을 보여준다.
  renderCard({
    bool isBack = true,
    var colorIndex = 0,
    var text = '0'
  }) {

    if(isBack) {
      return Container(
        key: const ValueKey(0),
        color: selectColor(colorIndex),
        width: setSize(cardSize),
        height: setSize(cardSize),
        child: setNumberText(text),
      );
    }else{
      return Container(
        key: const ValueKey(1),
        color: Colors.grey,
        width: setSize(cardSize),
        height: setSize(cardSize),
        child: setNumberText(text),
      );
    }
  }

  setNumberText(String number){
    if(number != '0') {
      return Text(number);
    } else {
      return const SizedBox();
    }
  }

  Color selectColor(int index) {
    var color;
    switch (index) {
      case 0: color = Colors.pink; break;
      case 1: color =  Colors.lightGreenAccent; break;
      case 2: color =  Colors.blue; break;
      case 3: color =  Colors.orange; break;
      case 4: color =  Colors.green; break;
      case 5: color =  Colors.lime; break;
      case 6: color =  Colors.teal; break;
      case 7:  color =  Colors.red; break;
      case 8:  color =  Colors.deepPurple; break;
    }
    return color;
  }

  double setSize(int size){
    return (MediaQuery.of(context).size.width / 100) * size;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            SizedBox(
              width: 200,
              height: 80,
              child: TextButton(
                onPressed: (){
                  setState(() {
                    reSet();
                  });
                },
                child: const Text('ReStart!'),
              ),
            ),
            Center(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(cardPadding),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width,
                child: GridView.count(
                    padding: EdgeInsets.all(cardPadding),
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: setCards()
                ),
              ),
            ),
          ],
        )
    );
  }
}

class Card extends StatelessWidget {
  final bool isFlipped;
  final Container front;
  final Container back;

  const Card({Key? key, required this.isFlipped, required this.front, required this.back}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.0, end: isFlipped ? 180.0 : 0.0),
      builder: (BuildContext context, double value, Widget? child) {
        var content = value >= 90 ? back : front;
        return RotationY(
            rotationY: value,
            key: const ValueKey(false),
            child: content
        );
      },
    );
  }
}

class RotationY extends StatelessWidget {
  static const double degress2Radians = pi / 180;
  late Widget child;
  late double rotationY;
  late double rotationX;
  RotationY({required Key key, required this.child, this.rotationY = 0, this.rotationX = 0}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Transform(transform: Matrix4.identity()
    ..setEntry(3, 2, 0.003)
    ..rotateY(rotationY * degress2Radians)
    ..rotateX(rotationX * degress2Radians),
    alignment: Alignment.center,
    child: child);
  }
}


