import asyncio
import random
import os
import websockets

import json

# group = {
#     'groupName': data['groupName'],
#     'groupNumber': f'{random.randint(10000000, 99999999)}',
#     'IPs': data['IPs'],
#     }

groups = []
# 格式：{群号：IPs}
IPsList = {}
contacts = []
chatBox = []
recycleBox = []
alive = {}
# 格式：{type，groupNumber，fromIP，toIPs，content} 每次被使用都会弹出接受者的IP，IPs为空时弹出本条信息
chatBox_group = []


# 接收格式：{type，fromIP，content}

async def add_contacts(websocket):
    client_ip = websocket.remote_address[0]
    temp = []
    for i in contacts:
        if i[1] != client_ip:
            temp.append(i)
    # print(temp)
    # print(client_ip)
    msg = {
        'type': 'add_contacts',
        'contacts': temp,
        'alive': alive
        }
    await websocket.send(json.dumps(msg))


async def add_groups(websocket):
    client_ip = websocket.remote_address[0]
    temp = []
    _IPsList = []
    for i in groups:
        if client_ip in i['IPs']:
            temp.append([i['groupName'], i['groupNumber']])
            _IPsList.append(i['IPs'])
    if len(temp) != 0:
        msg = {
            'type': 'add_groups',
            'groups': temp,
            # 下面未使用
            'IPsList': IPsList,
            }
        await websocket.send(json.dumps(msg))


# 处理这台服务器接收到信息
async def receive_message(websocket, path):
    client_ip = websocket.remote_address[0]
    while True:
        message = await websocket.recv()
        alive[client_ip] = True
        try:
            # 尝试解析收到的 JSON 消息
            data = json.loads(message)
            # print(f"Parsed JSON data: {data}")
            
            if data['type'] == 'login':
                if client_ip not in [i[1] for i in contacts]:
                    contacts.append([data['username'], client_ip])
                else:
                    for i in contacts:
                        if i[1] == client_ip:
                            i[0] = data['username']
                            break
                await add_contacts(websocket)
                msg = {
                    'type': 'login_back',
                    'contacts': contacts,
                    # 'groups': groups,
                    }
                await add_groups(websocket)
                await websocket.send(json.dumps(msg))
            elif data['type'] == 'send_contact':
                # 处理聊天消息
                data['type'] = 'receive_contact'
                data['content'] = '0' + data['content'][1:]
                data['fromIP'] = client_ip
                print(f"新的信息： from {client_ip} to {data['toIP']}: {data['content']}")
                chatBox.append(data)
            elif data['type'] == 'create_group':
                # 处理创建群组请求
                data['IPs'].append(client_ip)
                print(f"创建群组请求： {data}")
                group = {
                    'groupName': data['groupName'],
                    'groupNumber': f'{random.randint(10000000, 99999999)}',
                    'IPs': data['IPs'],
                    }
                IPsList[group['groupNumber']] = data['IPs']
                groups.append(group)
            elif data['type'] == 'send_group':
                print(f"新的群组信息： {data}")
                msg = {
                    'type': 'receive_group',
                    'groupNumber': data['groupNumber'],
                    'fromIP': client_ip,
                    'toIPs': IPsList[data['groupNumber']],
                    'content': '0' + data['content'][1:],
                    }
                # data['type'] = 'receive_group'
                # data['content'] = '0_' + data['content']
                # data['fromIP'] = client_ip
                chatBox_group.append(msg)
            elif data['type'] == 'send_file_contact':
                # data = {
                #     type,
                #     toIP,
                #     fileName,文件名的_file_后缀和0_前缀在客户端单独处理，不要直接修改文件名
                #     fileBytes,文件的二进制数据
                #     }
                # 客户端根据接收到文件的日期为文件添加唯一标识，并用
                data['type'] = 'receive_file_contact'
                data['fromIP'] = client_ip
                print(f"新的文件信息： from {client_ip} to {data['toIP']}: {data['fileName']}")
                current_directory = os.getcwd()
                file_path = f'{current_directory}\\files\\{data["fileName"]}'
                # 将接收到的文件字节数据进行写入
                try:
                    with open(file_path, 'wb') as file:
                        file.write(bytes(data['fileBytes']))
                    print(f"文件 {data['fileName']} 已成功保存")
                except Exception as e:
                    print(f"文件保存失败: {e}")
                
                chatBox.append(data)
            elif data['type'] == 'send_file_group':
                # data:fileName,fileBytes,groupNumber,type
                data['type'] = 'receive_file_group'
                data['fromIP'] = client_ip
                data['toIPs'] = IPsList[data['groupNumber']]
                current_directory = os.getcwd()
                file_path = f'{current_directory}\\files\\{data["fileName"]}'
                # 将接收到的文件字节数据进行写入
                try:
                    with open(file_path, 'wb') as file:
                        file.write(bytes(data['fileBytes']))
                    print(f"文件 {data['fileName']} 已成功保存")
                except Exception as e:
                    print(f"文件保存失败: {e}")
                    
                chatBox_group.append(data)
                
        
        
        
        except json.JSONDecodeError:
            print("收到的消息不是有效的 JSON 格式")


async def send_contact(websocket, path):
    client_ip = websocket.remote_address[0]
    while True:
        await asyncio.sleep(0.1)
        if len(chatBox) > 0:
            data = chatBox[-1]
            # if data['type'] == 'receive_contact':
            if data['toIP'] == client_ip and alive[data['toIP']]:
                # data = chatBox.pop()
                chatBox.pop()
                await websocket.send(json.dumps(data))
                print('信息已发送')
            elif not alive[data['toIP']]:
                # data = chatBox.pop()
                chatBox.pop()
                print('信息 ', data['content'], ' 已被回收，等待对方上线')
                recycleBox.append(data)
            
        temp = []
        for i in recycleBox:
            if i['toIP'] == client_ip and alive[client_ip]:
                # data = i
                # data['type'] = 'receive_contact'
                # data['content'] = '0' + data['content'][1:]
                await websocket.send(json.dumps(i))
                print('信息已发送')
                temp.append(i)
        for i in temp:
            recycleBox.remove(i)


async def send_group(websocket, path):
    client_ip = websocket.remote_address[0]
    while True:
        await asyncio.sleep(0.1)
        # if len(chatBox_group) > 0:
        temp = []
        for i in chatBox_group:
            if i['fromIP'] != client_ip:
                if client_ip in i['toIPs'] and alive[client_ip]:
                    # msg = {
                    #     'type': 'receive_group',
                    #     'groupNumber': i['groupNumber'],
                    #     'fromIP': i['fromIP'],
                    #     'content': i['content'],
                    #     }
                    await websocket.send(json.dumps(i))
                    print('信息已发送')
            i['toIPs'] = [j for j in i['toIPs'] if j != client_ip]
            if len(i['toIPs']) == 0:
                temp.append(i)
        for i in temp:
            chatBox_group.remove(i)


async def handle_connection(websocket, path):
    # await refresh_contacts(websocket)
    client_ip = websocket.remote_address[0]
    print(f"新的连接 from {client_ip}")
    
    try:
        await asyncio.gather(
            receive_message(websocket, path),
            send_contact(websocket, path),
            send_group(websocket, path),
            refreshChats(websocket, path),
            
            )
    except websockets.exceptions.ConnectionClosed:
        print(f"连接关闭： {client_ip}")
        # 处理连接关闭时的逻辑，比如从联系人列表中移除该用户
        # contacts[:] = [c for c in contacts if c[1] != client_ip]
        alive[client_ip] = False


async def refreshChats(websocket, path):
    while True:
        await asyncio.sleep(0.3)
        await add_contacts(websocket)
        await add_groups(websocket)


# 启动WebSocket服务器

start_server = websockets.serve(handle_connection, "172.16.91.233",
                                9999)

# 运行事件循环

asyncio.get_event_loop().run_until_complete(start_server)

asyncio.get_event_loop().run_forever()
