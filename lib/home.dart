import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lesson5/cat_show.dart';
import 'package:page_transition/page_transition.dart';
import 'show_list.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';




class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 16.0,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
      ),
    );
  }



  String _bannerID="";
  bool _bannerEnable=false;

  _getAdId(){
    var r=FirebaseFirestore.instance.collection("Ads").get();
    r.then((v) => {
      v.docs.forEach((e) {
        if(e['_bannerEnable']==true){
          _bannerID=e['_bannerID'];
          _bannerEnable=true;
        }else{
          setState(() {
            _bannerEnable=false;
          });
        }
      })
    });
  }


  // TODO: Add _bannerAd
  late BannerAd _bannerAd;

  // TODO: Add _isBannerAdReady
  bool _isBannerAdReady = false;

  _callBanner(){
    _bannerAd = BannerAd(
      adUnitId: _bannerID,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }


  @override
  void dispose() {
    // TODO: implement dispose
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  void initState() {

    _getAdId();
    // _callBanner();

    Timer(Duration(seconds: 3), () => {
      if(_bannerEnable){
        _callBanner()
      }
    });

    // TODO: implement initState
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        return exit(0);
        //Navigator.push(context, PageTransition(child: Home(), type: PageTransitionType.rightToLeft));

      },
      child: Scaffold(

              appBar: AppBar(
                title: Image.asset("images/funny-time.png", height: 70, fit: BoxFit.fitHeight,),
                backgroundColor: Colors.white,
                iconTheme: IconThemeData(
                    color: Colors.black
                ),
              ),
              drawer: Drawer(

              ),
              body: SafeArea(
                child: Stack(

                  children: [

                    Container(
                      child :_isBannerAdReady ? ShowWhenAds() : ShowWhenNoAds(),

                    ),

                    if (_isBannerAdReady)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: _bannerAd.size.width.toDouble(),
                          height: _bannerAd.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd),
                        ),
                      ),

                  ],
                ),
              )
          )

    );
  }
}


class ShowWhenAds extends StatefulWidget {
  const ShowWhenAds({Key? key}) : super(key: key);

  @override
  _ShowWhenAdsState createState() => _ShowWhenAdsState();
}

class _ShowWhenAdsState extends State<ShowWhenAds> {
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: Color.fromRGBO(230, 230, 230, 1),
                    width: 75
                )
            )
        ),
        padding: EdgeInsets.only(top: 10),
        child:  StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("Cats").snapshots(),
            builder: (context, s){
              if(s.hasData){
                var _data=s.data!.docs;
                return ListView.builder(
                    itemCount: _data.length,
                    itemBuilder: (_, i){
                      return Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(

                                // color: Colors.white,
                                child: Column(
                                  children: [
                                    Container(
                                        height: 30,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text("${_data[i]['_title']}", style: TextStyle(color: Color.fromRGBO(136, 0, 0, 0.7), fontSize: 16),),
                                            IconButton(
                                              onPressed: () {
                                                //_bannerAd.dispose();
                                                Navigator.of(context).push(PageTransition(
                                                    child: CatShow(data: _data[i]),
                                                    type: PageTransitionType.rightToLeft
                                                ));
                                              },
                                              icon: Icon(Icons.apps, size: 20, color: Color.fromRGBO(136, 0, 0, 0.7),),
                                            ),
                                          ],
                                        )
                                    ),
                                    Container(
                                        height: 160,
                                        child: Showlist(data:_data[i])
                                    )
                                  ],
                                ),
                              ),
                            ],
                          )
                      );
                    }
                );
              }else{
                return Container(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            }
        )
    );
  }
}

class ShowWhenNoAds extends StatefulWidget {
  const ShowWhenNoAds({Key? key}) : super(key: key);

  @override
  _ShowWhenNoAdsState createState() => _ShowWhenNoAdsState();
}

class _ShowWhenNoAdsState extends State<ShowWhenNoAds> {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 10),
        child:  StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("Cats").snapshots(),
            builder: (context, s){
              if(s.hasData){
                var _data=s.data!.docs;
                return ListView.builder(
                    itemCount: _data.length,
                    itemBuilder: (_, i){
                      return Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(

                                // color: Colors.white,
                                child: Column(
                                  children: [
                                    Container(
                                        height: 30,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text("${_data[i]['_title']}", style: TextStyle(color: Color.fromRGBO(136, 0, 0, 0.7), fontSize: 16),),
                                            IconButton(
                                              onPressed: () {
                                                //_bannerAd.dispose();
                                                Navigator.of(context).push(PageTransition(
                                                    child: CatShow(data: _data[i]),
                                                    type: PageTransitionType.rightToLeft
                                                ));
                                              },
                                              icon: Icon(Icons.apps, size: 20, color: Color.fromRGBO(136, 0, 0, 0.7),),
                                            ),
                                          ],
                                        )
                                    ),
                                    Container(
                                        height: 160,
                                        child: Showlist(data:_data[i])
                                    )
                                  ],
                                ),
                              ),
                            ],
                          )
                      );
                    }
                );
              }else{
                return Container(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            }
        )
    );
  }




}