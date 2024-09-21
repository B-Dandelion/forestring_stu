import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String teacher;
  final int pw;

  UserModel({
    required this.id,
    required this.teacher,
    required this.pw,
});
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'], teacher: json['teacher'], pw: json['pw']);
  }
}

class GetData extends StatefulWidget {
  const GetData({Key?key}) : super(key: key);

  @override
  State<GetData> createState() => _GetData();
}

class _GetData extends State<GetData> {

  String teacher = '';
  final int pw = 0;
  final int Time = 0;
  final String Week = '';

  getUser() async {
    var result = await FirebaseFirestore.instance.collection('student').doc('진민경').get();
    return result.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: getUser(),
          builder: (context, snapshot) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  teacher = (snapshot.data as Map)['teacher'],
                  Text((snapshot.data as Map)['teacher']),
                ],
              )
            );
          })
    );
  }
}