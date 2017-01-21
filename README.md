# CCHSocket
CCHSocket 是一个 swift 写的 socket 支持 TCP/UDP

## 版本
0.0.1

## cocoapods

pod 'CCHSocket'

## 用法

### TCP

###### server

启动服务端获取客户端

		///创建服务端
		let server = CCHSocketServer()
		
		///客户端操作
		var server_client_1 : CCHSocketClient?
		
		///监听客户端连接
        server.listeners { (client) in
            
            ///获取客户端
            server_client_1 ＝ client
            
            ///读取客户端数据
            server_client_1!.recvData({ (data, code) in
                
                if data != nil {
                    
                   	print(server_client_1!.connection_address)
                    print(String.init(data: data!, 
                    encoding: NSUTF8StringEncoding))
                }
            })
        }                   
 ```      ```
        
 发送数据到客户端
 
 
 		server_client_1!.sendData("发送的数据..."!.dataUsingEncoding(NSUTF8StringEncoding)!) { (status, code) in
            
            ///
        } 

###### client

		///创建客户端
		let client = CCHSocketClient()
        
        ///连接服务端
        client.connection(server.address_ip, port: server.address_port) { (status, code) in
            
            if status {
                
                client.recvData({ (data, code) in
                    
                    print(self.client.connection_address)
                    print(String.init(data: data!, encoding: NSUTF8StringEncoding))
                })
            }
        }
        
        ///发送数据到服务端
        client.sendData("发送的数据..."!.dataUsingEncoding(NSUTF8StringEncoding)!) { (status, code) in
            
        }

### UDP


		///创建UDP
		UDP = CCHSocketUDP()
		
		///读取数据
        UDP.recvfromData(1024) { (ip, port, data, code) in
            
            if data != nil {

                print("\(ip):\(port)")
                print(String.init(data: data!, encoding: NSUTF8StringEncoding))
            }
        }
        
        ///发送数据
        UDP.sendtoData(UDP.address_ip, port: UDP.address_port, data: "发送的数据..."!.dataUsingEncoding(NSUTF8StringEncoding)!) { (status, code) in
            
        }
