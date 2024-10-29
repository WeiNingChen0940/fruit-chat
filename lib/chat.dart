import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;

import 'package:fruit_chat/main.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

class Chat extends StatefulWidget {
  final String title;
  final int chatIndex;

  // 联系人：contact，群聊：group
  final String chatType;

  const Chat(
      {super.key,
      required this.title,
      required this.chatIndex,
      required this.chatType});

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void sendMessage(
      {String msg = '1_hello world',
      required DataController dataController,
      required String msgKey}) {
    if (widget.chatType == 'contact') {
      dataController.sendContact(widget.chatIndex, msg);
    } else if (widget.chatType == 'group') {
      var members = dataController
          .groupMembers[dataController.groups[widget.chatIndex][1]];
      members?.add(dataController.name);
      dataController.sendGroup(widget.chatIndex, msg);
    }
    setState(() {
      dataController.chatRecords[msgKey]?.add(msg);
    });
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void sendFile(
      {required String fileName,
      required Uint8List fileBytes,
      required DataController dataController,
      required String msgKey}) {
    Future.delayed(const Duration(milliseconds: 700));
    if (widget.chatType == 'contact') {
      dataController.sendFileContact(widget.chatIndex, fileName, fileBytes);
    } else if (widget.chatType == 'group') {
      var members = dataController
          .groupMembers[dataController.groups[widget.chatIndex][1]];
      members?.add(dataController.name);
      dataController.sendFileGroup(widget.chatIndex, fileName, fileBytes);
    }
    setState(() {
      dataController.chatRecords[msgKey]?.add('1_${fileName}_file_');
    });
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void downloadFile({required String fileName}) {
    // Uint8List? fileBytes = dataController.fileRecords[msgKey]?[fileIndex];
    // if(fileBytes != null){
    // FilePicker.platform.saveFile(
    //   bytes: fileBytes,
    //   fileName: 'file_${fileIndex}.txt',
    // );
    // OpenFile.open(filePath)
    // }
    // 创建一个 Blob 对象
    // 创建一个指向 Blob 的 URL
    String url = 'http://172.16.91.233:5000/download/$fileName';

    // 创建一个下载链接
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click(); // 自动触发下载

    // 释放 URL 对象
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    var dataController = Provider.of<DataController>(context, listen: true);
    String msgKey = 'n';
    if (widget.chatType == 'contact') {
      msgKey = dataController.contacts[widget.chatIndex][1];
    } else if (widget.chatType == 'group') {
      msgKey = dataController.groups[widget.chatIndex][1];
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 10,
        shadowColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 7,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
          )
        ],
        backgroundColor: const Color.fromRGBO(252, 140, 35, 1),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text('聊天记录条数:${dataController.chatRecords[msgKey]?.length}'),
            Expanded(
              child: ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  itemCount: dataController.chatRecords[msgKey]?.length,
                  itemBuilder: (context, index) {
                    dataController.isRead[msgKey] = true;
                    bool isFile = (dataController.chatRecords[msgKey] ?? [])
                        .elementAt(index)
                        .endsWith('_file_');
                    // 1_开头的消息是本人的，0_开头的消息是对方的
                    bool isSelf = (dataController.chatRecords[msgKey] ?? [])
                        .elementAt(index)
                        .startsWith('1_');
                    String replaceStr = isSelf ? '1_' : '0_';
                    String msg = (dataController.chatRecords[msgKey] ?? [])
                        .elementAt(index)
                        .replaceFirst(replaceStr, '');
                    if (isFile) {
                      int lastIndex = msg.lastIndexOf('_file_');
                      msg = msg.replaceRange(lastIndex, lastIndex + 6, '');
                    }
                    return Align(
                        alignment: isSelf
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: isSelf
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (widget.chatType == 'group')
                              Card(
                                  color: isSelf
                                      ? const Color.fromRGBO(249, 236, 220, 1)
                                      : const Color.fromRGBO(249, 244, 120, 1),
                                  elevation: 1,
                                  margin: const EdgeInsets.only(
                                      top: 0, bottom: 0, left: 10, right: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Text(dataController.groupMembers[
                                            dataController
                                                .groups[widget.chatIndex][1]]!
                                        .elementAt(index)),
                                  )),
                            Card(
                              color: isSelf
                                  ? const Color.fromRGBO(249, 236, 220, 1)
                                  : const Color.fromRGBO(249, 244, 120, 1),
                              elevation: 5,
                              margin: const EdgeInsets.only(
                                  top: 3, bottom: 10, left: 10, right: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isFile && isSelf)
                                        IconButton(
                                            onPressed: () {},
                                            icon: const Icon(Icons.folder)),
                                      Text(
                                        softWrap: true,
                                        msg,
                                        style: const TextStyle(
                                            fontSize: 18, color: Colors.black),
                                      ),
                                      if (isFile && !isSelf)
                                        IconButton(
                                            onPressed: () {
                                              downloadFile(fileName: msg);
                                            },
                                            icon: const Icon(Icons.folder)),
                                    ]),
                              ),
                            ),
                          ],
                        ));
                  }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10),
        child: TextField(
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          minLines: 1,
          focusNode: _focusNode,
          onSubmitted:
              // 已弃置
              (String msg) {
            if (msg.trim().isNotEmpty) {
              sendMessage(
                  msg: '1_$msg',
                  dataController: dataController,
                  msgKey: msgKey);
              _textController.clear();
            }
            FocusScope.of(context).requestFocus(_focusNode);
          },
          controller: _textController,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: IconButton(
              tooltip: '发送文件',
              onPressed: () async {
                // 获取文件
                final result = await FilePicker.platform
                    .pickFiles(type: FileType.any, allowMultiple: false);

                if (result != null && result.files.isNotEmpty) {
                  final fileBytes = result.files.first.bytes;
                  final fileName = result.files.first.name;
                  print(fileName);
                  if (fileName.trim().isNotEmpty && fileBytes != null) {
                    sendFile(
                        fileName: fileName,
                        fileBytes: fileBytes,
                        dataController: dataController,
                        msgKey: msgKey);
                  }
                }
                // File file = File(result.files.single.path!);
              },
              icon: const Icon(
                Icons.add_circle_outline,
                size: 30,
              ),
            ),
            suffixIcon: IconButton(
                // highlightColor: Colors.blue.withOpacity(0.5),
                tooltip: '发送消息',
                icon: const Icon(
                  Icons.send,
                  size: 30,
                ),
                onPressed: () {
                  if (_textController.text.trim().isNotEmpty) {
                    sendMessage(
                        msg: '1_${_textController.text}',
                        dataController: dataController,
                        msgKey: msgKey);
                    _textController.clear();
                  }
                }),
            labelText: '请输入消息',
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
