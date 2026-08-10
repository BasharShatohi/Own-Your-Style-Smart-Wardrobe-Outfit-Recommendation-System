import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupportView extends GetView {
  const SupportView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support & Feedback')),
      body: const Center(
        child: Text('Support View', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
