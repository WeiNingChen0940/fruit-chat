import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fruit_chat/groups.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

// import 'chat.dart';
import 'chats.dart';
import 'login.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DataController with ChangeNotifier {
  bool _isLoggedIn = false;
  List<List<String>> contacts = [
    // ['张安', '172.16.91.233']
  ];
  List<List<String>> groups = [
    // ['测试群聊1', '12896543']
  ];
  Map<String, List<String>> chatRecords = {};

  // <群号，发送信息的IP的列表>
  Map<String, List<String>> groupMembers = {};

  // <msgKey,<index,fileBytes>>
  Map<String, Map<int, Uint8List>> fileRecords = {};
  Map<String, bool> isRead = {}; // 记录是否已读
  Map<String, bool> alive = {};
  String _name = 'user1';
  String _password = '123456';
  late WebSocketChannel _channel;
  late StreamSubscription _subscription;

  String get name => _name;

  void setName(String name) {
    _name = name;
  }

  void setPassword(String password) {
    _password = password;
  }

  void login() {
    print('登录');
    // 服务器地址可自由设置
    _channel = WebSocketChannel.connect(Uri.parse("ws://172.16.91.233:9999"));
    _subscription = _channel.stream.listen((message) {
      receive(message);
    },
        onDone: () {
          _reconnect();
        });
    var user = {'type': 'login', 'username': _name, 'password': _password};
    send(user);
  }

  int _retryCount = 0; // 连接重试计数器
  final int _maxRetries = 100; // 最大重试次数
  void _reconnect() {
    if (_retryCount < _maxRetries) {
      // 使用 Timer 实现每隔1秒尝试重新连接
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        // 尝试重新连接
        _retryCount++; // 增加重试计数
        print("尝试重新连接... 第 $_retryCount 次");
        reConnect();
        print('重连成功');

        // 连接成功后取消定时器
        if (_channel.closeCode == null) {
          timer.cancel();
          _retryCount = 0; // 重置重试计数
        }
      });
    } else {
      print("达到最大重试次数，停止重试");
    }
  }

  void reConnect() {
    _channel = WebSocketChannel.connect(Uri.parse("ws://172.16.91.233:9999"));
    _subscription = _channel.stream.listen((message) {
      receive(message);
    },
        onDone: () {
          _reconnect();
        });
    // var user = {'type': 'login', 'username': _name, 'password': _password};
    // send(user);
  }

  void receive(String message) {
    // 接收服务器发来的JSON格式的信息
    Map<String, dynamic> data;
    try {
      data = jsonDecode(message); // 把消息解析为JSON
    } catch (e) {
      print('解析JSON出错: $e');
      print('收到的消息: $message');
      return; // 如果解析失败，返回
    }
    if (data['type'] == 'login_back') {
      contacts = (data['contacts'] as List<dynamic>)
          .map((e) => List<String>.from(e))
          .toList();
      // print(data['contacts']);
      // print('length of contacts: ${contacts.length}');
      // print(data['groups']);
      // groups = (data['groups'] as List<dynamic>)
      //     .map((e) => List<String>.from(e))
      //     .toList();
      // print('length of groups: ${groups.length}');
      for (var contact in contacts) {
        chatRecords[contact[1]] = [];
        fileRecords[contact[1]] = {};
        isRead[contact[1]] = true;
      }
      // for (var group in groups) {
      //   chatRecords[group[1]] = [];
      //   isRead[group[1]] = true;
      //   groupMembers[group[1]] = [];
      // }
      _isLoggedIn = true;
      notifyListeners();
    }
    else if (data['type'] == 'add_contacts') {
      contacts = List<List<String>>.from(
          (data['contacts'] as Iterable).map((item) => List<String>.from(item))
      );
      for (var contact in contacts) {
        if (!chatRecords.containsKey(contact[1])) {
          chatRecords[contact[1]] = [];
          fileRecords[contact[1]] = {};
          isRead[contact[1]] = true;
        }
      }

      alive = Map<String, bool>.from(data['alive']);
      notifyListeners();
    }
    else if (data['type'] == 'add_groups') {
      // print('添加群聊信息');
      groups = List<List<String>>.from(
          (data['groups'] as Iterable).map((item) => List<String>.from(item))
      );
      for (var group in groups) {
        if (!chatRecords.containsKey(group[1])) {
          print('检测到群聊信息');
          chatRecords[group[1]] = [];
          fileRecords[group[1]] = {};
          isRead[group[1]] = true;
          groupMembers[group[1]] = [];
        }
      }
    }
    else if (data['type'] == 'receive_contact') {
      chatRecords[data['fromIP']]?.add(data['content']);
      isRead[data['fromIP']] = false;
      notifyListeners();
    }
    else if (data['type'] == 'receive_file_contact') {
      chatRecords[data['fromIP']]?.add("0_${data['fileName']}_file_");
      print('接收到文件消息: ${data['fileName']}');
      // int? len = chatRecords[data['fromIP']]?.length;
      // if (len != null) {
      //   // fileRecords[data['fromIP']]?[len] = data['fileBytes'];
      //   var intList = List<int>.from(
      //       (data['fileBytes'] as Iterable).map((e) => e as int));
      //       fileRecords[data['fromIP']]?[len] = Uint8List.fromList(intList);
      // }
      isRead[data['fromIP']] = false;
      notifyListeners();
    }
    else if (data['type'] == 'receive_group') {
      chatRecords[data['groupNumber']]?.add(data['content']);
      String name = '';
      for (var contact in contacts) {
        if (contact[1] == data['fromIP']) {
          name = contact[0];
          break;
          // print('接收到${data['fromIP']}发来的消息,名字是$name');
        }
      }
      groupMembers[data['groupNumber']]?.add(name);
      isRead[data['groupNumber']] = false;
      notifyListeners();
    }
    else if (data['type'] == 'receive_file_group') {
      chatRecords[data['groupNumber']]?.add("0_${data['fileName']}_file_");
      // int? len = chatRecords[data['groupNumber']]?.length;
      // if (len != null) {
      //   // fileRecords[data['groupNumber']]?[len] = data['fileBytes'];
      //   var intList = List<int>.from(
      //       (data['fileBytes'] as Iterable).map((e) => e as int));
      //   fileRecords[data['groupNumber']]?[len] = Uint8List.fromList(intList);
      // }
      String name = '';
      for (var contact in contacts) {
        if (contact[1] == data['fromIP']) {
          name = contact[0];
          break;
          // print('接收到${data['fromIP']}发来的消息,名字是$name');
        }
      }
      groupMembers[data['groupNumber']]?.add(name);
      isRead[data['groupNumber']] = false;
      notifyListeners();
    }
  }

  void send(Map<String, dynamic> message) {
    // 发送JSON格式的信息到服务器
    _channel.sink.add(jsonEncode(message));
  }

  void sendContact(int index, String msg) {
    var sendMsg = {
      'type': 'send_contact',
      'toIP': contacts[index][1],
      'content': msg
    };
    send(sendMsg);
  }

  void sendFileContact(int index, String fileName, Uint8List fileBytes) {
    var sendMsg = {
      'type': 'send_file_contact',
      'toIP': contacts[index][1],
      'fileName': fileName,
      'fileBytes': fileBytes
    };
    send(sendMsg);
  }

  void sendGroup(int index, String msg) {
    var sendMsg = {
      'type': 'send_group',
      'groupNumber': groups[index][1],
      'content': msg
    };
    send(sendMsg);
  }


  void sendFileGroup(int index, String fileName, Uint8List fileBytes) {
    var sendMsg = {
      'type': 'send_file_group',
      'groupNumber': groups[index][1],
      'fileName': fileName,
      'fileBytes': fileBytes
    };
    send(sendMsg);
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => DataController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '主页',
      theme: ThemeData(
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '开始聊天吧'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Provider
          .of<DataController>(context, listen: false)
          ._isLoggedIn) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Login()));
      }
    });
  }

  int _pagesIndex = 0;

  @override
  Widget build(BuildContext context) {
    // if(!Provider.of<DataController>(context)._isLoggedIn){
    //   Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //           builder: (context) =>
    //           const Login()));
    // }
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: const [
          Chats(),
          Groups(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
          shadowColor: Colors.black87,
          elevation: 7,
          surfaceTintColor: const Color.fromRGBO(251, 139, 5, 1),
          indicatorColor: const Color.fromRGBO(251, 139, 5, 0.5),
          selectedIndex: _pagesIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _pagesIndex = index;
              _pageController.jumpToPage(index);
            });
          },
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.person),
              label: '联系人',
            ),
            NavigationDestination(
              icon: Icon(Icons.group),
              label: '群聊',
            ),
          ]),

      // floatingActionButton: FloatingActionButton(
      //     onPressed: _add,
      //     tooltip: '添加联系人',
      //     child: const Icon(Icons.add),
      //   ),
    );
  }
}
