
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(appBar: AppBar(title: const Text("Book Your Space",style: TextStyle(fontSize: 22,fontWeight:FontWeight.w600,)),
      scrolledUnderElevation: 0,
      forceMaterialTransparency: true,),
    body: const SingleChildScrollView(
      child: Column(children: [

      ],),
    ),
    );
  }
}
