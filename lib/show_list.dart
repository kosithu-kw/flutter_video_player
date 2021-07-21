import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:page_transition/page_transition.dart';
import 'show_list.dart';
import 'player.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class Showlist extends StatefulWidget {
  final data;
  const Showlist({Key? key, required this.data}) : super(key: key);

  @override
  _ShowListState createState() => _ShowListState();
}

class _ShowListState extends State<Showlist> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    return   StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("Movies").where("_cat", isEqualTo: widget.data['_title']).snapshots(),
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
                                                      width: 150.0,
                                                      //height: 200.0,
                                                      child: Card(
                                                          child: ListTile(
                                                              onTap: () {
                                                                Navigator.of(context).push(PageTransition(
                                                                    child: Player(data: _data[i]),
                                                                    type: PageTransitionType.rightToLeft
                                                                ));
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


    );
  }
}

