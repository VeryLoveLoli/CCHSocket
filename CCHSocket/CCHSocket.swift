//
//  CCHSocket.swift
//  CCHSocketDemo
//
//  Created by 韦烽传 on 16/5/19.
//  Copyright © 2016年 韦烽传. All rights reserved.
//

import Foundation

enum SocketConnectType {
    case TCP            ///< TCP
    case UDP            ///< UDP
}

class CCHSocket {
    
    ///IP
    var address_ip : String { return IP }
    ///端口
    var address_port : UInt16 { return PORT }
    ///连接类型（TCP/UDP）
    var connect_type : SocketConnectType { return TYPE }
    ///socket 状态
    var socket_status : Int32 { return fcntl(socket_id, F_GETFL, 0)}
    
    private var socket_id : Int32!
    private var IP : String!
    private var PORT : UInt16!
    private var TYPE : SocketConnectType!
    
    /**
     初始化 CCHSocket
     创建 socket
     绑定 地址
     
     - parameter ip:          IP 地址
     - parameter port:        端口
     - parameter connectType: socket 连接类型(SocketConnectType)
     
     - returns: CCHSocket
     */
    init (ip: String, port: UInt16, connectType:SocketConnectType) {
        
        IP = ip
        PORT = port
        TYPE = connectType
        
        if self.createSocket(TYPE) != -1 {
            
            self.bindAddress(IP, port: PORT)
        }
    }
    
    /**
     初始化 CCHSocket
     
     - parameter socketId: socket
     - parameter connectType: socket 连接类型(SocketConnectType)
     
     - returns: CCHSocket
     */
    init (socketId: Int32, connectType:SocketConnectType) {
        
        socket_id = socketId
        TYPE = connectType
        
        ///获取绑定的地址
        let address = Address.sockname(socketId)
        IP = address.ip
        PORT = address.port
    }
    
    /**
     创建 socket
     
     - parameter connectType: 连接类型 SocketConnectType
     
     - returns: socket_id
     */
    func createSocket(connectType:SocketConnectType) -> Int32 {
        
        switch connectType {
        case .TCP:
            socket_id = socket(AF_INET, SOCK_STREAM, 0)
        case .UDP:
            socket_id = socket(AF_INET, SOCK_DGRAM, 0)
        }
        
        if socket_id != -1 {
            
            print("创建 socket_id:\(socket_id) 成功")
        }
        else {
            
            print("创建 Socket 失败")
        }
        
        return socket_id
    }
    
    /**
     绑定地址
     
     - parameter ip:   IP 地址
     - parameter port: 端口
     
     - returns: 绑定状态
     */
    func bindAddress(ip: String, port: UInt16) -> Int32 {
        
        ///设置地址
        var addrress = Address.addressStringToSockaddr(IP, port: PORT)
        
        ///绑定地址
        let status = bind(socket_id, &(addrress), UInt32(strideofValue(addrress)));
        
        if status == 0 {
            
            ///获取绑定的地址
            var addr = sockaddr()
            var len = socklen_t.init(16)
            getsockname(socket_id, &addr, &len)
            let address = Address.sockaddrToAddressSring(addr)
            IP = address.ip
            PORT = address.port
            
            print("socket_id:\(socket_id) 绑定地址 \(IP):\(PORT) 成功")
        }
        else {
            
            print("socket_id:\(socket_id) 绑定地址 \(IP):\(PORT) 失败")
        }
        
        return status
    }
    
    /**
     关闭 socket
     
     - returns: 关闭状态
     */
    func closeSocket() -> Int32 {
        
        let status = close(socket_id)
        
        if status == 0 {
            
            print("关闭 socket_id:\(socket_id) 成功")
        }
        else {
            
            print("关闭 socket_id:\(socket_id) 失败")
        }
        
        return status
    }
}

class CCHSocketTCP : CCHSocket {
    
    /**
     初始化 CCHSocket
     创建 socket(TCP)
     绑定 本地地址
     
     - returns: CCHSocket
     */
    convenience init() {
        
        self.init(ip: "0.0.0.0", port: 0, connectType:.TCP)
    }
    
    /**
     初始化 CCHSocket
     创建 socket(TCP)
     绑定 地址
     
     - parameter ip:          IP 地址
     - parameter port:        端口
     - parameter connectType: socket 连接类型(SocketConnectType)
     
     - returns: CCHSocket
     */
    convenience init (ip: String, port: UInt16) {
        
        self.init(ip: ip, port: port, connectType:.TCP)
    }
}

class CCHSocketServer : CCHSocketTCP  {
    
    /**
     监听客户端连接(TCP)
     
     - parameter block: 客户端连接结果; client:客户端连接端
     */
    func listeners(block: (client: CCHSockClient)->Void ) -> Void {
        
        dispatch_async(CCHSocketQueue.concurrent_queue, {
            
            ///监听
            if listen(self.socket_id, INT32_MAX) == 0 {
                
                print("socket_id:\(self.socket_id) 开始监听")
                
                while self.socket_status >= 0 {
                    
                    var client_addr = sockaddr()
                    var client_len = socklen_t.init(16)
                    
                    ///接收客户端连接
                    let client_id = accept(self.socket_id, &client_addr, &client_len)
                    
                    if  client_id != -1 {
                        
                        let address = Address.sockaddrToAddressSring(client_addr)
                        print("socket_id:\(self.socket_id) 接收到 \(address.ip):\(address.port) 的连接")
                        
                        let client = CCHSockClient.init(socketId: client_id, connectType: self.TYPE)
                        
                        block(client: client)
                    }
                }
            }
            else {
                
                print("socket_id:\(self.socket_id) 监听失败")
            }
        })
    }
    
}

class CCHSockClient: CCHSocketTCP {
    
    /// 缓冲区大小
    var buffer_max_length = 1024
    /// 失败重复发送次数
    var repeat_number = 0
    /// 连接的地址
    var connection_address : (ip: String, port: UInt16) { return Address.peername(socket_id)}
    
    /**
     连接服务器(TCP)
     
     - parameter ip:   IP 地址
     - parameter port: 端口
     - parameter block: 连接结果; status:连接状态 true=成功,false=失败; code:connection()函数的返回值
     */
    func connection(ip: String, port: UInt16, block: (status:Bool, code:Int32)->Void) -> Void {
        
        dispatch_async(CCHSocketQueue.concurrent_queue) {
            
            ///设置服务器地址
            var addrress = Address.addressStringToSockaddr(ip, port: port);
            //链接服务器
            let status = connect(self.socket_id, &addrress, UInt32(strideofValue(addrress)))
            
            if status == 0 {
                
                let addr = Address.sockname(self.socket_id)
                self.IP = addr.ip
                self.PORT = addr.port
                
                print("socket_id:\(self.socket_id) 连接 \(ip):\(port) 成功")
            }
            else {
                
                print("socket_id:\(self.socket_id) 连接 \(ip):\(port) 失败")
            }
            
            block(status: status == 0, code: status)
        }
    }
    
    /**
     发送数据(TCP)
     
     - parameter data: 发送的数据 NSData
     - parameter block: 发送结果; status:发送状态true=成功,false=失败;  code:send()函数的返回值
     */
    func sendData(data: NSData, block: (status: Bool, code: Int)->Void) -> Void {
        
        dispatch_async(CCHSocketQueue.concurrent_queue) {
            
            var index = 0
            
            var repeat_index = 0
            
            var status = true
            
            var sendCode : Int
            
            repeat {
                
                let len = min(data.length - index, self.buffer_max_length)
                
                let d = data.subdataWithRange(NSRange(location: index, length: len))
                var bytes : [UInt8] = [UInt8](count: d.length, repeatedValue: 0x0)
                d.getBytes(&bytes, length: bytes.count)
                
                sendCode = send(self.socket_id, &bytes, len, 0)
                
                if sendCode == len {
                    
                    index += len
                    repeat_index = 0
                }
                else if repeat_index < self.repeat_number{
                    
                    repeat_index += 1
                }
                else {
                    
                    status = false
                    break
                }
                
            } while index < data.length
            
            dispatch_async(dispatch_get_main_queue(), {
                
                if status {
                    
                    print("发送成功")
                }
                else {
                    
                    print("发送失败")
                }
                
                block(status: status, code: sendCode)
            })
        }
    }
    
    /**
     读取数据(TCP)
     
     - parameter block: 读取到的结果; data:读取到的数据;    code:recv()函数的返回值
     */
    func recvData(block: (data: NSData?, code: Int)->Void) -> Void {
        
        dispatch_async(CCHSocketQueue.concurrent_queue, {
            
            var recvCode : Int
            repeat {
                
                var bytes : [UInt8] = [UInt8](count: self.buffer_max_length, repeatedValue: 0x0)
                
                recvCode = recv(self.socket_id, &bytes, self.buffer_max_length, 0)
                
                var data : NSData?
                
                if recvCode <= -1 {
                    
                    print("socket_id:\(self.socket_id) 读取失败")
                }
                else if (recvCode == 0) {
                    
                    print("socket_id:\(self.socket_id) 连接端已关闭")
                    
                    self.closeSocket()
                }
                else {
                    
                    data = NSData.init(bytes: bytes, length: recvCode)
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    block(data: data, code: recvCode)
                })
                
            } while recvCode > 0
        })
    }
}

class CCHSocketUDP: CCHSocket {
    
    /**
     初始化 CCHSocket
     创建 socket(TCP)
     绑定 本地地址
     
     - returns: CCHSocket
     */
    convenience init() {
        
        self.init(ip: "0.0.0.0", port: 0, connectType:.UDP)
    }
    
    /**
     初始化 CCHSocket
     创建 socket(UDP)
     绑定 地址
     
     - parameter ip:          IP 地址
     - parameter port:        端口
     - parameter connectType: socket 连接类型(SocketConnectType)
     
     - returns: CCHSocket
     */
    convenience init (ip: String, port: UInt16) {
        
        self.init(ip: ip, port: port, connectType:.UDP)
    }
    
    /**
     发送数据(UDP)
     
     - parameter ip:    IP 地址
     - parameter port:  端口
     - parameter data:  发送的数据 NSData
     - parameter block: 发送结果; status:发送状态true=成功,false=失败;  code:sendto()函数的返回值
     */
    func sendtoData(ip: String, port: UInt16, data: NSData, block: (status: Bool, code: Int)->Void) -> Void {
        
        dispatch_async(CCHSocketQueue.concurrent_queue) {
            
            var bytes : [UInt8] = [UInt8](count: data.length, repeatedValue: 0x0)
            data.getBytes(&bytes, length: bytes.count)
            
            var addr = Address.addressStringToSockaddr(ip, port: port)
            
            let sendCode = sendto(self.socket_id, &bytes, bytes.count, 0, &addr, UInt32(strideofValue(addr)))
            
            let status = sendCode > 0
            
            dispatch_async(dispatch_get_main_queue(), {
                
                if status {
                    
                    print("发送成功")
                }
                else {
                    
                    print("发送失败")
                }
                
                block(status: status, code: sendCode)
            })
        }
    }
    
    /**
     读取数据(UDP)
     
     - parameter length:    缓冲大小
     - parameter ip:        IP 地址
     - parameter port:      端口
     - parameter block:     读取到的结果; data:读取到的数据;    code:recvfrom()函数的返回值
     */
    func recvfromData(length: Int, block: (ip: String, port: UInt16, data: NSData?, code: Int)->Void) -> Void {
        
        dispatch_async(CCHSocketQueue.concurrent_queue, {
            
            var recvCode : Int
            
            repeat {
                
                var bytes : [UInt8] = [UInt8](count: length, repeatedValue: 0x0)
                
                var addr = sockaddr()
                var len = socklen_t.init(16)
                
                recvCode = recvfrom(self.socket_id, &bytes, length, 0, &addr, &len)
                
                let address = Address.sockaddrToAddressSring(addr)
                
                var data : NSData?
                
                if recvCode <= -1 {
                    
                    print("socket_id:\(self.socket_id) 读取失败")
                }
                else {
                    
                    let address = Address.sockaddrToAddressSring(addr)
                    print("socket_id:\(self.socket_id) 接收到 \(address.ip):\(address.port) 的数据")
                    
                    data = NSData.init(bytes: bytes, length: recvCode)
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    block(ip:address.ip, port: address.port, data: data, code: recvCode)
                })
                
            } while recvCode > 0
        })
    }
    
}

/// 队列
struct CCHSocketQueue {
    
    /// 串行队列
    static let serial_queue = dispatch_queue_create("cch_scoket_serial_queue", DISPATCH_QUEUE_SERIAL)
    /// 并行队列
    static let concurrent_queue = dispatch_queue_create("cch_scoket_concurrent_queue", DISPATCH_QUEUE_CONCURRENT)
    /// 任务组
    static let group = dispatch_group_create()
}

/// 地址
class Address {
    
    class func addressStringToSockaddr(ip: String, port: UInt16) -> sockaddr
    {
        var address = sockaddr()
        memset(&address, 0, strideofValue(address))
        address.sa_len = UInt8(strideofValue(address))
        address.sa_family = UInt8(AF_INET)
        address.sa_data = self.data(ip, port: port)
        
        return address
    }
    
    class func sockaddrToAddressSring(addr: sockaddr) -> (ip: String, port: UInt16)
    {
        return self.data(addr.sa_data)
    }
    
    class func data(addr: String, port: UInt16) -> (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8)
    {
        var x0 : Int = (Int(port) & 0b1111111100000000) >> 8
        var x1 : Int = (Int(port) & 0b0000000011111111)
        
        x0 = x0 > 127 ? x0 - 256 : x0
        x1 = x1 > 127 ? x1 - 256 : x1
        
        var array = [Int8].init(count: 4, repeatedValue: 0)
        
        var i = 0
        
        for value in addr.componentsSeparatedByString(".") {
            
            if (UInt8(value) != nil) {
                
                array[i] = UInt8(value)!.int8()
            }
            
            i += 1
        }
        
        return (Int8(x0), Int8(x1),                                 /// 端口号
            array[0], array[1], array[2], array[3],                 /// IP地址
            0, 0, 0, 0, 0, 0, 0, 0)                                 /// 对齐
    }
    
    class func data(data: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8)) -> (ip:String, port:UInt16)
    {
        var x0 = Int(data.0)
        var x1 = Int(data.1)
        
        x0 = (x0 < 0 ? x0 + 256 : x0) * 256
        x1 = x1 < 0 ? x1 + 256 : x1
        
        return ("\(data.2.uint8()).\(data.3.uint8()).\(data.4.uint8()).\(data.5.uint8())", UInt16(x0 + x1))
    }
    
    class func sockname(socket_id: Int32) -> (ip: String, port: UInt16) {
    
        var addr = sockaddr()
        var len = socklen_t.init(16)
        getsockname(socket_id, &addr, &len)
        let address = Address.sockaddrToAddressSring(addr)
        
        return address
    }
    
    class func peername(socket_id: Int32) -> (ip: String, port: UInt16) {
    
        var addr = sockaddr()
        var len = socklen_t.init(16)
        getpeername(socket_id, &addr, &len)
        let address = Address.sockaddrToAddressSring(addr)
        
        return address
    }
    
    class func hostnameToIP(host: String) -> String? {
        
        var ip : String?
        
        let data = host.dataUsingEncoding(NSUTF8StringEncoding)
        
        if data != nil {
            
            var bytes = [Int8].init(count: data!.length, repeatedValue: 0x0)
            data!.getBytes(&bytes, length: bytes.count)
            
            let hostname = gethostbyname(&bytes)
            
            if hostname != nil {
                
                var h = hostent()
                memcpy(&h, hostname, strideofValue(h))
                
                if h.h_addr_list != nil {
                    
                    var addr = in_addr()
                    memcpy(&addr, h.h_addr_list[0], strideofValue(addr))
                    
                    ip = String.fromCString(inet_ntoa(addr))
                }
            }
        }
        
        return ip
    }
}

extension UInt8 {
    
    func int8() -> Int8 {
        
        if self > 127 {
            
            return Int8(Int(self) - 256)
        }
        
        return Int8(self)
    }
}

extension Int8 {

    func uint8() -> UInt8 {
        
        if self < 0 {
            
            return UInt8(Int(self) + 256)
        }
        
        return UInt8(self)
    }
}