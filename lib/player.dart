import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lesson5/show_list.dart';
import 'package:page_transition/page_transition.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'home.dart';
import 'main.dart';

/// Homepage
class Player extends StatefulWidget {
  final data;
  Player({required this.data});
  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  late YoutubePlayerController _controller;
  late TextEditingController _idController;
  late TextEditingController _seekToController;

  late PlayerState _playerState;
  late YoutubeMetaData _videoMetaData;
  double _volume = 100;
  bool _muted = false;
  bool _isPlayerReady = false;

  @override
  void initState() {

    _getAdId();

    Timer(Duration(seconds: 1), () => {
      if(_interEnable && !_isInterstitialAdReady){
        _loadInterstitialAd()
      }
    });

    setState(() {
      _playNow=widget.data['_url'];
      _title=widget.data['_cat'];
    });

    _fetchData();


    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: _playNow,
      flags: const YoutubePlayerFlags(
        mute: false,
        autoPlay: true,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: false,
      ),
    )..addListener(listener);
    _idController = TextEditingController();
    _seekToController = TextEditingController();
    _videoMetaData = const YoutubeMetaData();
    _playerState = PlayerState.unknown;
  }

  void listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {
        _playerState = _controller.value.playerState;
        _videoMetaData = _controller.metadata;
      });
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _idController.dispose();
    _seekToController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  List<String> _movies=[];

  String _playNow="";
  String _title="";

  _fetchData(){
    var r= FirebaseFirestore.instance.collection("Movies").where("_cat", isEqualTo: widget.data['_cat']).get();
    r.then((value) => {
      value.docs.forEach((e) {
        _movies.add(e['_url']);
      })
    });
  }

  _callHome(){
    _controller.pause();
    Navigator.of(context).push(PageTransition(
        child: Home(),
        type: PageTransitionType.leftToRight
    ));
  }

  String _interID="";
  bool _interEnable=false;

  _getAdId(){
    var r=FirebaseFirestore.instance.collection("Ads").get();
    r.then((v) => {
      v.docs.forEach((e) {
        if(e['_interEnable']==true){
          _interID=e['_interID'];
          _interEnable=true;
        }else{
          setState(() {
            _interEnable=false;
          });
        }
      })
    });
  }


  int _clickMovie=0;

  void _setClickMovie(){
      if(_clickMovie ==3){
        if(_interEnable && _isInterstitialAdReady){
          _interstitialAd?.show();
        }
        setState(() {
          _clickMovie=0;
        });
      }else{
        setState(() {
          _clickMovie++;
        });
      }
  }

  // TODO: Add _interstitialAd
  InterstitialAd? _interstitialAd;

  // TODO: Add _isInterstitialAdReady
  bool _isInterstitialAdReady = false;

  // TODO: Implement _loadInterstitialAd()
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interID,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          this._interstitialAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
               // _callHome();
            },
          );

          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // The player forces portraitUp after exiting fullscreen. This overrides the behaviour.
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,

        onReady: () {
          _isPlayerReady = true;
        },
        onEnded: (data) {
          _controller
              .load(_movies[(_movies.indexOf(data.videoId) + 1) % _movies.length]);
          _setClickMovie();
          _showSnackBar('Next Video Started!');
          
        //Navigator.pop(context);

        },
      ),
      builder: (context, player) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: (){
                Navigator.pop(context);
            },
          ),

          title:  Text(
            "${_title}",
            style: TextStyle(color: Color.fromRGBO(136, 0, 0,1)),
          ),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(
              color: Colors.black
          ),

        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white,
          child: Icon(Icons.home, color: Color.fromRGBO(136,0,0,1),),
          onPressed: (){

              _callHome();

          },
        ),
        body: Column(

          children: [
            player,
            _space,
            Container(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Row(
                children: [
                  Icon(Icons.slideshow),
                  Flexible(

                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        strutStyle: StrutStyle(fontSize: 12.0),
                        text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            text: _videoMetaData.title),
                      ),
                    ),

                ],
              ),
            ),
            _space,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

                Container(
                  child: IconButton(
                    icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                    onPressed: _isPlayerReady
                        ? () {
                      _muted
                          ? _controller.unMute()
                          : _controller.mute();
                      setState(() {
                        _muted = !_muted;
                      });
                    }
                        : null,
                  ),
                ),

                Slider(
                  inactiveColor: Colors.transparent,
                  value: _volume,
                  min: 0.0,
                  max: 100.0,
                  divisions: 10,
                  label: '${(_volume).round()}',
                  onChanged: _isPlayerReady
                      ? (value) {
                    setState(() {
                      _volume = value;
                    });
                    _controller.setVolume(_volume.round());
                  }
                      : null,
                ),
                FullScreenButton(
                  controller: _controller,
                  color: Colors.black,
                ),

              ],
            ),
            _space,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: (){
                    if(_isPlayerReady){
                      _controller.load(_movies[
                      (_movies.indexOf(_controller.metadata.videoId) -
                          1) %
                          _movies.length]);
                    }else{
                      null;
                    }
                   _setClickMovie();
                  }

                ),
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: _isPlayerReady
                      ? () {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                    setState(() {});
                  }
                      : null,
                ),


                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed:(){
                    if(_isPlayerReady){
                      _controller.load(_movies[
                      (_movies.indexOf(_controller.metadata.videoId) +
                          1) %
                          _movies.length]);
                    }else{
                      null;
                    }
                    _setClickMovie();
                  }

                ),
              ],
            ),
            _space,
            _space,
            _space,
            _space,
            _space,
            Container(
              padding: EdgeInsets.only(top: 5, left: 5, right: 5),
              height: 200,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 20),
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add_check),
                        Text("Suggested for you", textAlign: TextAlign.start, style: TextStyle(fontSize: 20),),
                      ],
                    ),
                  ),
                  _space,
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("Movies").where("_cat", isEqualTo: widget.data['_cat']).snapshots(),
              builder: (context, s){
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                            height: 140,
                            child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _data.length,
                                itemBuilder: (context, i) {
                                  return Row(
                                    children: <Widget>[
                                      Container(
                                        padding: EdgeInsets.only(
                                            left: 1.0, right: 1.0, top: 1.0, bottom: 1.0),
                                        width: 180.0,
                                        //height: 200.0,
                                        child: Card(
                                            child: ListTile(
                                                onTap: () {
                                                  if(_isPlayerReady){
                                                     _controller.load(_data[i]['_url']);
                                                   }
                                                  _setClickMovie();
                                                  print(_clickMovie);
                                                },
                                                title: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        child: Center(
                                                          child: Image.network("https://img.youtube.com/vi/${_data[i]['_url']}/1.jpg",),
                                                        ),
                                                      ),
                                                      Flexible(
                                                        child: Center(
                                                          child: RichText(
                                                            overflow: TextOverflow.ellipsis,
                                                            strutStyle: StrutStyle(fontSize: 12.0),
                                                            text: TextSpan(
                                                                style: TextStyle(color: Colors.black),
                                                                text: _data[i]['_title']),
                                                          ),
                                                        ),
                                                      ),
                                                    ]
                                                )
                                            )
                                        ),
                                      )
                                    ],
                                  );
                                }
                            )
                        )
                      ],
                    ),


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
                ],
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _text(String title, String value) {
    return RichText(
      text: TextSpan(
        text: '$title : ',
        style: const TextStyle(
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor(PlayerState state) {
    switch (state) {
      case PlayerState.unknown:
        return Colors.grey[700]!;
      case PlayerState.unStarted:
        return Colors.pink;
      case PlayerState.ended:
        return Colors.red;
      case PlayerState.playing:
        return Colors.blueAccent;
      case PlayerState.paused:
        return Colors.orange;
      case PlayerState.buffering:
        return Colors.yellow;
      case PlayerState.cued:
        return Colors.blue[900]!;
      default:
        return Colors.blue;
    }
  }

  Widget get _space => const SizedBox(height: 10);



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
}