import 'package:flutter/material.dart';
import 'package:get/get.dart';


class HomeView extends GetView {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Welcome Home!', style: TextStyle(fontSize: 24))),
    );
  }
}
