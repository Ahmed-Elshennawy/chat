import 'package:chat/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No message found.'));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Somthing went wrong...'));
        }
        final loadedMessages = snapshot.data!.docs;
        return ListView.builder(
            itemCount: loadedMessages.length,
            reverse: true,
            itemBuilder: (ctx, index) {
              final chatMessage = loadedMessages[index].data();
              final nextMessage = index + 1 < loadedMessages.length
                  ? loadedMessages[index + 1].data()
                  : null;
              final currentMessageUserId = chatMessage['userId'];
              final nextMessageUserId =
                  nextMessage != null ? nextMessage['userId'] : null;
              final bool nextUserIsSame =
                  nextMessageUserId == currentMessageUserId;
              if (nextUserIsSame) {
                return MessageBubble.next(
                  message: chatMessage['text'],
                  isMe: authUser.uid == currentMessageUserId,
                );
              } else {
                return MessageBubble.first(
                  userImage: chatMessage['image_url'],
                  username: chatMessage['username'],
                  message: chatMessage['text'],
                  isMe: authUser.uid == currentMessageUserId,
                );
              }
            });
      },
    );
  }
}
