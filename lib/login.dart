import 'package:flutter/material.dart';
import 'package:fruit_chat/main.dart';
import 'package:provider/provider.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController();
  String usernameError = '';
  String passwordError = '';
  final TextEditingController _passwordController = TextEditingController();
  final _usernameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _validateInputs() {
    bool isUsernameValid = _usernameFormKey.currentState!.validate();
    bool isPasswordValid = _passwordFormKey.currentState!.validate();

    if (isUsernameValid && isPasswordValid) {
      return true;
    }
    if (!isUsernameValid) {
      setState(() {
        usernameError = '用户名不能为空';
      });
    } else {
      setState(() {
        usernameError = '';
      });
    }
    if (!isPasswordValid) {
      setState(() {
        passwordError = '密码不能为空';
      });
    } else {
      setState(() {
        passwordError = '';
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    var dataController = Provider.of<DataController>(context, listen: false);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          color: const Color.fromRGBO(251, 232, 218, 1.0),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.celebration_rounded,
                size: 100,
                color: Colors.orange,
              ),
              const Text('聊天室-版本1.1.5',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          const Align(
                              alignment: Alignment.centerLeft,
                              child:
                                  Text('用户名', style: TextStyle(fontSize: 18))),
                          Form(
                            key: _usernameFormKey,
                            child: TextFormField(
                              controller: _usernameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '用户名不能为空';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                errorText: usernameError,
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey.withOpacity(0.5))),
                              ),
                            ),
                          ),
                        ],
                      ))),
              const SizedBox(height: 20),
              Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          const Align(
                              alignment: Alignment.centerLeft,
                              child:
                                  Text('密码', style: TextStyle(fontSize: 18))),

                          Form(
                            key: _passwordFormKey,
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '密码不能为空';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                errorText: passwordError,
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey.withOpacity(0.5))),
                              ),
                            ),
                          ),
                        ],
                      ))),
              const SizedBox(height: 20),
              ElevatedButton(
                // clipBehavior: Clip.hardEdge,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(252, 140, 35, 1.0),
                    minimumSize: Size(screenWidth, 60),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                child: const Text('登录',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
                onPressed: () {
                  if (_validateInputs()) {
                    dataController.setName(_usernameController.text);
                    dataController.setPassword(_passwordController.text);
                    dataController.login();

                    _showLoadingDialog(context);
                    Future.delayed(const Duration(seconds: 2), () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showLoadingDialog(BuildContext context) {
  showDialog(
    barrierDismissible: false, // 设置为 false 以防止对话框外点击关闭
    context: context,
    builder: (BuildContext context) {
      return const AlertDialog(
        backgroundColor: Color.fromRGBO(249, 244, 220, 1),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(), // 加载指示器
            SizedBox(height: 20), // 间距
            Text('加载中，请稍候...',style: TextStyle(fontWeight: FontWeight.bold),),
          ],
        ),
      );
    },
  );
}
