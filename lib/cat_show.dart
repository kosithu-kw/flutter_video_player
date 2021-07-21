import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lesson5/main.dart';
import 'package:page_transition/page_transition.dart';
import 'home.dart';
import 'show_list.dart';
import 'player.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class CatShow extends StatefulWidget {
  final data;
  const CatShow({Key? key, required this.data}) : super(key: key);

  @override
  _CatShowState createState() => _CatShowState();
}

class _CatShowState extends State<CatShow> {

  String _bannerID="";
  bool _bannerEnable=false;

  _getAdId(){
    var r=FirebaseFirestore.instance.collection("Ads").get();
    r.then((v) => {
      v.docs.forEach((e) {
          if(e['_bannerEnableTwo']==true){
            _bannerID=e['_bannerIDTwo'];
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


    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: (){
                  Navigator.push(context, PageTransition(child: Home(), type: PageTransitionType.leftToRight));
                },
              ),
              title: Text(widget.data['_title'], style: TextStyle( color:  Color.fromRGBO(136, 0, 0, 1)),),
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(
                  color: Colors.black
              ),
            ),

            body: SafeArea(
              child: Stack(
                children: [
                  Container(
                    child: _isBannerAdReady ? ShowWhenAds(title: widget.data['_title']) : ShowWhanNoAds(title: widget.data['_title'])

                  ),

                  if (_isBannerAdReady)
                    Container(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: _bannerAd.size.width.toDouble(),
                          height: _bannerAd.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd),
                        ),
                      ),
                    )
                ],
              ),
            )

        ),
    );
  }
}


class ShowWhanNoAds extends StatefulWidget {
  final title;
  const ShowWhanNoAds({Key? key, required this.title}) : super(key: key);

  @override
  _ShowWhanNoAdsState createState() => _ShowWhanNoAdsState();
}

class _ShowWhanNoAdsState extends State<ShowWhanNoAds> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("Movies").where("_cat", isEqualTo: widget.title).snapshots(),
        builder: (context, AsyncSnapshot s){
          if(s.hasError){
            return Container(
              child: Center(
                child: Text("${s.error}"),
              ),
            );
          }else if(s.hasData){
            var _data=s.data!.docs;
            return Padding(
              padding: EdgeInsets.all(5),
              child: GridView.builder(
                  itemCount: _data.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemBuilder: (_, i){
                    return InkWell(
                      onTap: (){
                        Navigator.of(context).push(PageTransition(
                            child: Player(data: _data[i]),
                            type: PageTransitionType.rightToLeft
                        ));
                      },
                      child: Container(
                        padding: EdgeInsets.only(left: 1.0, right: 1.0, top: 1.0, bottom: 1.0),
                        child: Card(
                          child: Container(
                            padding: EdgeInsets.only(left: 3, right: 3, top:  3),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    child: Center(
                                      child: Image.network("https://img.youtube.com/vi/${_data[i]['_url']}/1.jpg",),
                                    ),
                                  ),
                                  Container(
                                    // padding: EdgeInsets.all(10),
                                      child: Flexible(
                                        child: Center(
                                          child: RichText(
                                            overflow: TextOverflow.ellipsis,
                                            strutStyle: StrutStyle(fontSize: 12.0),
                                            text: TextSpan(
                                                style: TextStyle(color: Colors.black),
                                                text: _data[i]['_title']),
                                          ),
                                        ),
                                      )
                                  ),
                                ]
                            ),
                          ),
                        ),
                      ),
                    );
                  }
              ),

            );
          }else{
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}



class ShowWhenAds extends StatefulWidget {
  final title;
  const ShowWhenAds({Key? key, required this.title}) : super(key: key);

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
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("Movies").where("_cat", isEqualTo: widget.title).snapshots(),
        builder: (context, AsyncSnapshot s){
          if(s.hasError){
            return Container(
              child: Center(
                child: Text("${s.error}"),
              ),
            );
          }else if(s.hasData){
            var _data=s.data!.docs;
            return Padding(
              padding: EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 5),
              child: GridView.builder(
                  itemCount: _data.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemBuilder: (_, i){
                    return InkWell(
                      onTap: (){
                        Navigator.of(context).push(PageTransition(
                            child: Player(data: _data[i]),
                            type: PageTransitionType.rightToLeft
                        ));
                      },
                      child: Container(
                        padding: EdgeInsets.only(left: 1.0, right: 1.0, top: 1.0, bottom: 1.0),
                        child: Card(
                          child: Container(
                            padding: EdgeInsets.only(left: 3, right: 3, top:  3),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    child: Center(
                                      child: Image.network("https://img.youtube.com/vi/${_data[i]['_url']}/1.jpg",),
                                    ),
                                  ),
                                  Container(
                                    // padding: EdgeInsets.all(10),
                                      child: Flexible(
                                        child: Center(
                                          child: RichText(
                                            overflow: TextOverflow.ellipsis,
                                            strutStyle: StrutStyle(fontSize: 12.0),
                                            text: TextSpan(
                                                style: TextStyle(color: Colors.black),
                                                text: _data[i]['_title']),
                                          ),
                                        ),
                                      )
                                  ),
                                ]
                            ),
                          ),
                        ),
                      ),
                    );
                  }
              ),

            );
          }else{
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );

  }
}

