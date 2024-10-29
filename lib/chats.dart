import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'chat.dart';
import 'main.dart';

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  _ChatsState createState() => _ChatsState();
}

class _ChatsState extends State<Chats> with SingleTickerProviderStateMixin {
  bool _isSelecting = false;
  bool _isAllSelected = false;
  int _selectedNum = 0;
  final List<bool> _isSelectedList = List<bool>.filled(100, false);
  int _listLength = 5;

  void _add() {
    setState(() {
      _isSelecting = !_isSelecting;
      for (int i = 0; i < _listLength; i++) {
        _isSelectedList[i] = false;
      }
      _isAllSelected = false;
      _selectedNum = 0;
    });
  }

  void _selectAll() {
    setState(() {
      for (int i = 0; i < _listLength; i++) {
        _isSelectedList[i] = true;
      }
      _isAllSelected = true;
      _selectedNum = _listLength;
    });
  }

  void _deselect() {
    setState(() {
      for (int i = 0; i < _isSelectedList.length; i++) {
        _isSelectedList[i] = false;
      }
      _isAllSelected = false;
      _selectedNum = 0;
    });
  }

  @override
  void initState() {
    super.initState();
  }

// TODO:https://pub.dev/packages/auto_animated
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    var dataController = Provider.of<DataController>(context, listen: true);
    // 未读信息的显示
    String? newMessage = '';

    _listLength = dataController.contacts.length;
    //todo:后面的刷新需要重新构建一遍_isSelectedList
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 10,
        shadowColor: Colors.black87,
        elevation: 7,
        actions: [
          if (!_isSelecting)
            IconButton(
              onPressed: _add,
              tooltip: '添加群组',
              icon: const Icon(Icons.add),
              color: Colors.white,
            )
          else
            IconButton(
              onPressed: _isAllSelected ? _deselect : _selectAll,
              tooltip: _isAllSelected ? '取消全选' : '全选',
              icon: Icon(_isAllSelected ? Icons.deselect : Icons.select_all),
              color: Colors.white,
            ),
          if (_isSelecting)
            IconButton(
              onPressed: _add,
              tooltip: '取消选择',
              icon: const Icon(Icons.close),
              color: Colors.white,
            ),
        ],
        backgroundColor: const Color.fromRGBO(252, 140, 35, 1),
        title: const Text('开始聊天吧', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
          itemCount: dataController.contacts.length,
          itemBuilder: (context, index) {
            var msgKey = dataController.contacts.elementAt(index)[1];

            if (dataController.chatRecords[msgKey]!.isNotEmpty) {
              newMessage = dataController.chatRecords[msgKey]?.last;
              bool isFile = newMessage!.endsWith('_file_');
              // 1_开头的消息是本人的，0_开头的消息是对方的
              bool isSelf = newMessage!.startsWith('1_');
              String replaceStr = isSelf ? '1_' : '0_';
              newMessage = newMessage?.replaceFirst(replaceStr, '');
              if (isFile) {
                int? lastIndex = newMessage?.lastIndexOf('_file_');
                newMessage = newMessage?.replaceRange(lastIndex!, lastIndex + 6, '[文件]');
              }
            } else {
              newMessage = '暂无信息';
            }
            bool? isAlive = dataController
                .alive[dataController.contacts.elementAt(index)[1]];
            isAlive ??= false;
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
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          )),
                    ),
                    SizedBox(
                      height: 54,
                      width: screenWidth - 100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dataController.contacts.elementAt(index)[0],
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isAlive ? Colors.black : Colors.grey)),

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
                    //###################
                    const Spacer(),
                    if (_isSelecting)
                      Checkbox(
                        value: _isSelectedList[index],
                        onChanged: (bool? value) {
                          setState(() {
                            _isSelectedList[index] = !_isSelectedList[index];
                            if (_isSelectedList[index]) {
                              _selectedNum++;
                              if (_selectedNum == _listLength) {
                                _isAllSelected = true;
                              }
                            } else {
                              _selectedNum--;
                              _isAllSelected = false;
                            }
                          });
                        },
                      ),
                  ],
                ),
                onTap: () {
                  if (!_isSelecting) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Chat(
                            title: dataController.contacts.elementAt(index)[0],
                            chatIndex: index,
                            chatType: 'contact',
                          ),
                        ));
                  } else {
                    setState(() {
                      _isSelectedList[index] = !_isSelectedList[index];
                      if (_isSelectedList[index]) {
                        _selectedNum++;
                        if (_selectedNum == _listLength) {
                          _isAllSelected = true;
                        }
                      } else {
                        _selectedNum--;
                        _isAllSelected = false;
                      }
                      // print(_selectedNum);
                      // print(_isAllSelected);
                    });
                  }
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
      floatingActionButton: _isSelecting
          ? FloatingActionButton(
              onPressed: () {
                //TODO: 实现群组创建功能
                List<int> selectedIndexList = [];
                for (int i = 0; i < _isSelectedList.length; i++) {
                  if (_isSelectedList[i]) {
                    selectedIndexList.add(i);
                  }
                }
                List<String> IPs = [];
                for (int i = 0; i < selectedIndexList.length; i++) {
                  IPs.add(dataController.contacts.elementAt(selectedIndexList[i])[1]);
                }
                String groupName = '我的群组';
                showDialog(context: context, builder: (context){
                  final TextEditingController nameController = TextEditingController();
                  return AlertDialog(
                    title: const Text('请输入群聊的名字'),
                    content: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: '请输入群聊的名字'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: (){
                          setState(() {
                            _isSelecting = false;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: (){
                          if(nameController.text.isNotEmpty) {
                            groupName = nameController.text;
                          }
                          var msg = {
                            'type': 'create_group',
                            'groupName': groupName,
                            'IPs': IPs,
                          };
                          dataController.send(msg);
                          setState(() {
                            _isSelecting = false;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  );
                });

              },
              tooltip: '确定',
              backgroundColor: const Color.fromRGBO(252, 140, 35, 1),
              child: const Icon(Icons.check, color: Colors.white),
            )
          : null,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }
}
