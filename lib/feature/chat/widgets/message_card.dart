import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:gallery_saver_updated/gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/feature/chat/models/chat_model.dart';
import 'package:solve_tutor/feature/chat/models/message.dart';
import 'package:solve_tutor/feature/chat/service/chat_provider.dart';
import 'package:solve_tutor/widgets/date_until.dart';
import 'package:solve_tutor/widgets/dialogs.dart';
import 'package:solve_tutor/widgets/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

// for showing single message details
class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.chat, required this.message});
  final ChatModel chat;
  final Message message;
  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  late AuthProvider auth;
  late ChatProvider chat;
  double border = 10;
  @override
  void initState() {
    super.initState();
    auth = Provider.of<AuthProvider>(context, listen: false);
    chat = Provider.of<ChatProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      chat.init(auth: auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMe = chat.auth?.uid == widget.message.fromId;
    return InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        // onLongPress: () async {
        //   FocusScope.of(context).unfocus();
        //   await Future.delayed(const Duration(milliseconds: 500));
        //   _showBottomSheet(isMe);
        // },
        child: isMe ? _greenMessage() : _blueMessage());
  }

  // sender or another user message
  Widget _blueMessage() {
    //update last read message if sender and receiver are different
    if (widget.message.read.isEmpty) {
      chat.updateMessageReadStatus(widget.chat.chatId ?? "", widget.message);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //message content
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(builder: (context) {
                if (widget.message.type == MessageType.image) {
                  return Container(
                    constraints:
                        const BoxConstraints(maxWidth: 200, maxHeight: 200),
                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CachedNetworkImage(
                        imageUrl: widget.message.msg,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image, size: 70),
                      ),
                    ),
                  );
                }
                return Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    decoration: BoxDecoration(
                        color: greyColor2,
                        border: Border.all(color: backgroundColor),
                        //making borders curved
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(border),
                            topRight: Radius.circular(border),
                            bottomRight: Radius.circular(border))),
                    child: Linkify(
                      onOpen: (link) async {
                        if (!await launchUrl(Uri.parse(link.url))) {
                          throw Exception('Could not launch ${link.url}');
                        }
                      },
                      text: widget.message.msg,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      linkStyle: TextStyle(color: Colors.blue),
                    ));
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                child: Text(
                  MyDateUtil.getFormattedTime(
                      context: context, time: widget.message.sent),
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),

        //message time
        // Padding(
        //   padding: EdgeInsets.only(right: Sizer(context).w * .04),
        //   child: Text(
        //     MyDateUtil.getFormattedTime(
        //         context: context, time: widget.message.sent),
        //     style: const TextStyle(fontSize: 13, color: Colors.black54),
        //   ),
        // ),
      ],
    );
  }

  // our or user message
  Widget _greenMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Row(
        //   children: [
        //     SizedBox(width: Sizer(context).w * .04),
        //     if (widget.message.read.isNotEmpty)
        //       const Icon(Icons.done_all_rounded, color: Colors.blue, size: 20),
        //     const SizedBox(width: 2),
        //     Text(
        //       MyDateUtil.getFormattedTime(
        //           context: context, time: widget.message.sent),
        //       style: const TextStyle(fontSize: 13, color: Colors.black54),
        //     ),
        //   ],
        // ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Builder(builder: (context) {
                if (widget.message.type == MessageType.image) {
                  return Container(
                    constraints:
                        const BoxConstraints(maxWidth: 200, maxHeight: 200),
                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CachedNetworkImage(
                        imageUrl: widget.message.msg,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image, size: 70),
                      ),
                    ),
                  );
                }
                return Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.8),
                        border: Border.all(color: primaryColor),
                        //making borders curved
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(border),
                            topRight: Radius.circular(border),
                            bottomLeft: Radius.circular(border))),
                    child: Linkify(
                      onOpen: (link) async {
                        if (!await launchUrl(Uri.parse(link.url))) {
                          throw Exception('Could not launch ${link.url}');
                        }
                      },
                      text: widget.message.msg,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      linkStyle: TextStyle(color: Colors.blue),
                    ));
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(width: Sizer(context).w * .04),
                    Builder(builder: (context) {
                      if (widget.message.read.isNotEmpty) {
                        return const Icon(
                          Icons.done_all_rounded,
                          color: primaryColor,
                          size: 20,
                        );
                      }
                      return const SizedBox(width: 0);
                    }),
                    const SizedBox(width: 2),
                    Text(
                      MyDateUtil.getFormattedTime(
                          context: context, time: widget.message.sent),
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // bottom sheet for modifying message details
  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              margin: EdgeInsets.symmetric(
                  vertical: Sizer(context).h * .015,
                  horizontal: Sizer(context).w * .4),
              decoration: BoxDecoration(
                  color: Colors.grey, borderRadius: BorderRadius.circular(8)),
            ),
            widget.message.type == MessageType.text
                ? _OptionItem(
                    icon: const Icon(Icons.copy_all_rounded,
                        color: Colors.blue, size: 26),
                    name: 'Copy Text',
                    onTap: () async {
                      await Clipboard.setData(
                              ClipboardData(text: widget.message.msg))
                          .then((value) {
                        Navigator.pop(context);
                        Dialogs.showSnackbar(context, 'Text Copied!');
                      });
                    })
                : _OptionItem(
                    icon: const Icon(Icons.download_rounded,
                        color: Colors.blue, size: 26),
                    name: 'Save Image',
                    onTap: () async {
                      try {
                        log('Image Url: ${widget.message.msg}');
                        await GallerySaver.saveImage(widget.message.msg,
                                albumName: 'We Chat')
                            .then((success) {
                          //for hiding bottom sheet
                          Navigator.pop(context);
                          if (success != null && success) {
                            Dialogs.showSnackbar(
                                context, 'Image Successfully Saved!');
                          }
                        });
                      } catch (e) {
                        log('ErrorWhileSavingImg: $e');
                      }
                    }),
            if (isMe)
              Divider(
                color: Colors.black54,
                endIndent: Sizer(context).w * .04,
                indent: Sizer(context).w * .04,
              ),
            if (widget.message.type == MessageType.text && isMe)
              _OptionItem(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 26),
                  name: 'Edit Message',
                  onTap: () {
                    Navigator.pop(context);
                    _showMessageUpdateDialog();
                  }),
            if (isMe)
              _OptionItem(
                  icon: const Icon(Icons.delete_forever,
                      color: Colors.red, size: 26),
                  name: 'Delete Message',
                  onTap: () async {
                    // await chat.deleteMessage(widget.message).then((value) {
                    //   Navigator.pop(context);
                    // });
                  }),
            Divider(
              color: Colors.black54,
              endIndent: Sizer(context).w * .04,
              indent: Sizer(context).w * .04,
            ),
            _OptionItem(
                icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                name:
                    'Sent At: ${MyDateUtil.getMessageTime(context: context, time: widget.message.sent)}',
                onTap: () {}),
            _OptionItem(
                icon: const Icon(Icons.remove_red_eye, color: Colors.green),
                name: widget.message.read.isEmpty
                    ? 'Read At: Not seen yet'
                    : 'Read At: ${MyDateUtil.getMessageTime(context: context, time: widget.message.read)}',
                onTap: () {}),
          ],
        );
      },
    );
  }

  void _showMessageUpdateDialog() {
    String updatedMsg = widget.message.msg;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(
                    Icons.message,
                    color: Colors.blue,
                    size: 28,
                  ),
                  Text(' Update Message')
                ],
              ),
              content: TextFormField(
                initialValue: updatedMsg,
                maxLines: null,
                onChanged: (value) => updatedMsg = value,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),
              actions: [
                MaterialButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    )),
                MaterialButton(
                    onPressed: () {
                      // Navigator.pop(context);
                      // chat.updateMessage(widget.message, updatedMsg);
                    },
                    child: const Text(
                      'Update',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ))
              ],
            ));
  }
}

//custom options card (for copy, edit, delete, etc.)
class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: EdgeInsets.only(
              left: Sizer(context).w * .05,
              top: Sizer(context).h * .015,
              bottom: Sizer(context).h * .015),
          child: Row(children: [
            icon,
            Flexible(
                child: Text('    $name',
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        letterSpacing: 0.5)))
          ]),
        ));
  }
}
