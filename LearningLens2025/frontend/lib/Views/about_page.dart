import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";

///
/// Template for views
/// Need to change the class name to the name based on the view you
/// are creating to include the constructor as well.
/// Need to change the class that extends State as well. Make sure
/// that the createState function returns the same name.
///
/// The CustomAppBar is already included, but you will need to update
/// the title string.
///
/// The content for the page begins in the children array. There is
/// a single text box as a place holder.
///
/// To add your view to the rest of the app, you will have to add it
/// to the dashboard.dart file. On line ~213, there is a List called
/// buttonData. You will need to update the 'onPressed' section with
/// your new template. You can see examples that Derek has already
/// done on other buttons.
///
class AboutPage extends StatefulWidget {
  AboutPage();

  @override
  State createState() {
    return _TemplateState();
  }
}

class _TemplateState extends State {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            title: 'About Learning Lens',
            onRefresh: () {
              // Add refresh logic here
            },
            userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
        body: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
              // Add Content here
              Padding(
                padding: EdgeInsets.all(16.0), // Adjust padding as needed
                child: Text(
                  'Learning Lens v3.0 by Team EduLense v2',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.0), // Adds left and right padding
                child: Text(
                  'Learning Lens is an application developed by students at the University of Maryland Global Campus '
                  'in the SWEN 670 Software Engineering Capstone course. It originated in the Fall 2024 student cohort '
                  'and was then further developed by the students of Spring 2025. Some features and ideas were also developed '
                  'from an application developed by Fall 2024 cohort team named EvaluAI. Additional features were incorporated '
                  'from an application developed by the Summer 2025 FocusEdAI team. The Fall 2025 team returned to the Spring '
                  '2025 Learning Lense application and built upon it with both new features and incorporating some of the '
                  'FocusEdAI team\'s work.\n\nLearning Lens was originally intended to be used by educators who teach students '
                  'who utilize Learning Management Systems (LMS) like Moodle and Google Classroom. The application allows '
                  'teachers to automatically generate quizzes, essay assignments, and lesson plans using various Artificial '
                  'Intelligence platforms. There are also added features for Individual Education Plans and advanced analytics. '
                  'Additional features as of Fall 2025 allow educators to create new, interactive assignments, such as '
                  'gamified experiences and scenario roleplay assignments using AI. Students can now log into the application to '
                  'complete these assignments and can use the tool for assistance on essay assignments. Student-to-AI interactions '
                  'are logged and are viewable by teachers. Enhanced grading tools expand the audience beyond K-12 to higher '
                  'education through grading tools for programming assignments. Additionally, AI-assisted actionable analytics help '
                  'drive course improvement, while rubric and feedback generation provide essential tools to educators. '
                  'Support for several LLMs, as well as locally downloaded LLM models, allows educators the to be flexible with their '
                  'chosen AI platform. This helps support the infrastructure and security requirements of a diverse set of users.\n\n'
                  'Fall 2025 Contributors Under Team Name "EduLense v2": Andreas Hochmuth, Cody White, Matthew McDaniel, '
                  'Ryan Appleby, Si Young Sung, Sneha Philip, and William Freeman\n\n'
                  'Summer 2025 FocusEdAI Application Contributors: Daouda Diabate, Medhanit Gashaw, Zaid Khalid, '
                  'Taylor Milton-Baker, Kelvin Nhim, Joshua Snavely, Josiah Weeks, and Savan Woods\n\n'
                  'Spring 2025 Contributors Under Team Name "EduLense": Nathaniel Boyd, Daniel Diep, Dinesh Ghimire, Andrew Hammes, '
                  'Dusty McKinnon, Derek Sappington, and Kevin Watts\n\n'
                  'Fall 2024 Contributors: Getinet Aga, Alexander Daugherty, Camille De Jesus, Desmond Herring, Jason Martin, '
                  'Teja Tammali, Adam Williams, Scott McGlynn, Safia Azhar, Joneice Butler, Anthony Ohiosikha, Daanish Siddiqui, '
                  'Conor Moore, and David Worthington\n\n'
                  'Summer 2024 Contributors: Eric Bennett, George Gaynor, Nicholas Jungmarker, Syrone Robinson, Marsha Sapp, '
                  'Henok Sibhatu, Tianming Zhu, Edward Shin, Jordan Gilberg, Mohammed Ghauri, Najwan Ismail, Stephen Buley, '
                  'Whitney Meulink, and William Crowdus\n\n'
                  'Spring 2024 Contributors: Tim Deering, Hemantha Adiga Madiyara, Colisian McLeod, Iriafen Ohiosikha, '
                  'Nick Patton, Kathryn Scearce, Malaika Shell, Rene Wong',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ])));
  }
}
