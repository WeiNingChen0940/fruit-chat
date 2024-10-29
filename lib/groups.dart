import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'chat.dart';
import 'main.dart';

class Groups extends StatefulWidget {
  const Groups({super.key});

  @override
  _GroupsState createState() => _GroupsState();
}

class _GroupsState extends State<Groups> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    var dataController = Provider.of<DataController>(context, listen: true);
    // 未读信息的显示
    String? newMessage = '';
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 10,
        shadowColor: Colors.black87,
        elevation: 7,
        backgroundColor: const Color.fromRGBO(252, 140, 35, 1),
        title: const Text('多人聊天', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
          itemCount: dataController.groups.length,
          itemBuilder: (context, index) {
            var msgKey = dataController.groups.elementAt(index)[1];
            if (dataController.chatRecords[msgKey]!.isNotEmpty) {
              newMessage = dataController.chatRecords[msgKey]?.last;
              bool isFile = newMessage!.endsWith('_file_');
              // 1_开头的消息是本人的，0_开头的消息是对方的
              bool isSelf = newMessage!.startsWith('1_');
              String replaceStr = isSelf ? '1_' : '0_';
              newMessage = newMessage?.replaceFirst(replaceStr, '');
              if (isFile) {
                int? lastIndex = newMessage?.lastIndexOf('_file_');
                newMessage =
                    newMessage?.replaceRange(lastIndex!, lastIndex + 6, '[文件]');
              }
            } else {
              newMessage = '暂无信息';
            }
            return Column(children: [
              InkWell(
                child: Row(
                  children: [
                    Card(
                      color: const Color.fromRGBO(252, 164, 4, 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      child: Container(
                          alignment: Alignment.center,
                          height: 50,
                          width: 50,
                          child: const Icon(
                            Icons.group,
                            color: Colors.white,
                            size: 30,
                          )),
                    ),
                    //###################
                    SizedBox(
                      height: 54,
                      width: screenWidth - 60,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dataController.groups.elementAt(index)[0],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(newMessage!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color: dataController.isRead[msgKey]!
                                      ? Colors.black
                                      : Colors.green))
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Chat(
                          title: dataController.groups.elementAt(index)[0],
                          chatIndex: index,
                          chatType: 'group',
                        ),
                      ));
                },
              ),
              Divider(
                indent: 10, // 左侧缩进距离
                endIndent: 10, // 右侧缩进距离
                height: 1, // 分割线的高度
                color: Colors.grey.shade300, // 分割线的颜色
              ),
            ]);
          }),
    );
  }
}
