// pages/messages_list_page.dart
import 'package:care_connect_app/features/social/in-app-chat/pages/chat-page.dart';
import 'package:care_connect_app/widgets/default_app_header.dart';
import 'package:flutter/material.dart';

class MessagesListPage extends StatelessWidget {
  const MessagesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: DefaultAppHeader(),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(.1),
            margin: EdgeInsets.all(16),
            // decoration: BoxDecoration(
            //   color: Colors.red,
            //   borderRadius: BorderRadius.circular(25),
            // ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildMessageItem(
                  context,
                  'Dr. Sarah Chen',
                  'Primary Care Physician',
                  'How are you feeling today?',
                  '2:30 PM',
                  Colors.blue,
                  hasUnread: true,
                ),
                _buildMessageItem(
                  context,
                  'Nurse Maria',
                  'Registered Nurse',
                  'Your test results are ready',
                  '11:15 AM',
                  Colors.orange,
                ),
                _buildMessageItem(
                  context,
                  'CareConnect Support',
                  'Support Team',
                  'Thank you for contacting us',
                  'Yesterday',
                  Colors.red,
                ),
                // Add more placeholder items as needed
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
      BuildContext context,
      String name,
      String role,
      String lastMessage,
      String time,
      Color avatarColor, {
        bool hasUnread = false,
      }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              contactName: name,
              contactRole: role,
            ),
          ),
        );
      },
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(.01),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: avatarColor,
              radius: 24,
              child: Icon(Icons.person, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
