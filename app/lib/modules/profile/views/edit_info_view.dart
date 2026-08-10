import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditInfoView extends GetView {
  const EditInfoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Information')),
      body: const Center(
        child: Text('Edit Information View', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
