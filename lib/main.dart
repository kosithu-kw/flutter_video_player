import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:page_transition/page_transition.dart';

import 'home.dart';

void main() async {
  Future<InitializationStatus> _initGoogleMobileAds() {
    // TODO: Initialize Google Mobile Ads SDK
    return MobileAds.instance.initialize();
  }

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MaterialApp(
      initialRoute: "/",
      routes: {
        '/':(context)=> Main(),
        '/home':(context)=> Home()
      },
    )
  );
}


class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  _MainState createState() => _MainState();
}



class _MainState extends State<Main> with TickerProviderStateMixin {

  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 5),
    vsync: this,
  )..repeat();
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.ease,
  );

  @override
  void initState() {
    // TODO: implement initState
    Timer(Duration(seconds: 5), ()=>{
        Navigator.of(context).push(PageTransition(child: Home(), type: PageTransitionType.leftToRight))
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
            child: Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child:  Center(
                    child: Image.asset("images/funny-time.png", width: 200,)
                  ),
                ),

                SizedBox(height: 50,),
                CircularProgressIndicator(
                  color: Colors.deepOrange,
                  backgroundColor: Color.fromRGBO(136, 0, 0, 1),
                )
              ],
            ),
            ),
        ),
      ),
    );
  }
}
