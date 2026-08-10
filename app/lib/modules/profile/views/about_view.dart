import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutView extends GetView {
  const AboutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(
        child: Text('About View', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
