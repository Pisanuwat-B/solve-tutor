import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/models/user_model.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/feature/chat/models/chat_model.dart';
import 'package:solve_tutor/feature/chat/models/message.dart';
import 'package:solve_tutor/feature/chat/pages/chat_room_page.dart';
import 'package:solve_tutor/feature/chat/service/chat_provider.dart';
import 'package:solve_tutor/feature/order/model/order_class_model.dart';

class ChatOrderCard extends StatefulWidget {
  ChatOrderCard(this.chat, {super.key});
  ChatModel chat;
  @override
  State<ChatOrderCard> createState() => _ChatOrderCardState();
}

class _ChatOrderCardState extends State<ChatOrderCard> {
  Message? _message;
  RoleType me = RoleType.student;
  late AuthProvider auth;
  late ChatProvider chat;

  @override
  void initState() {
    super.initState();
    auth = Provider.of<AuthProvider>(context, listen: false);
    chat = Provider.of<ChatProvider>(context, listen: false);
    me = auth.user!.getRoleType();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      chat.init(auth: auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(5, 0, 5, 5),
      // color: Colors.blue.shade100,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
        child: FutureBuilder(
          future: chat.getOrderInfo(widget.chat.chatId ?? ""),
          builder: (context, snapshot1) {
            try {
              OrderClassModel? order;
              if (snapshot1.hasData) {
                order = OrderClassModel.fromJson(snapshot1.data!.data()!);
              }
              return FutureBuilder(
                future: chat.getTutorInfo("${order?.studentId ?? ""}"),
                builder: (context, snapshot2) {
                  UserModel? tutor;
                  if (snapshot1.hasData && snapshot2.hasData) {
                    tutor = UserModel.fromJson(snapshot2.data!.data()!);
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              chat: widget.chat,
                              order: order!,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Builder(builder: (context) {
                            if (tutor?.image == null) {
                              return const CircleAvatar(
                                child: Icon(CupertinoIcons.person),
                              );
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(500),
                              child: CachedNetworkImage(
                                width: 50,
                                height: 50,
                                imageUrl: tutor?.image ?? "",
                                errorWidget: (context, url, error) =>
                                    const CircleAvatar(
                                        child: Icon(CupertinoIcons.person)),
                              ),
                            );
                          }),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("class : ${order?.title}"),
                                StreamBuilder(
                                  stream: chat
                                      .getLastMessage(widget.chat.chatId ?? ""),
                                  builder: (context, snapshot) {
                                    final data = snapshot.data?.docs;
                                    final list = data
                                            ?.map((e) =>
                                                Message.fromJson(e.data()))
                                            .toList() ??
                                        [];
                                    if (list.isNotEmpty) _message = list[0];
                                    if (_message?.type == MessageType.image) {
                                      return const Text("รูปภาพ");
                                    }
                                    return Text("${_message?.msg ?? ""} ");
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Text("loading..");
                },
              );
            } catch (e) {
              return const Text("Errod Data..");
            }
          },
        ),
      ),
    );
  }
}
