import 'package:care_connect_app/widgets/app_bar_helper.dart';
import 'package:flutter/material.dart';

class PatientVirtualCheckIn extends StatelessWidget {
  const PatientVirtualCheckIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBarHelper.createAppBar(
          context,
          title: 'Patient Check-In',
        ),
        body: SafeArea(
            child: 
          Row(
           children: [
             Text("Placeholder")
           ], 
          )
        )
    );

  }
}
