//
//  ViewController.swift
//  CCHSocketDemo
//
//  Created by 韦烽传 on 16/5/19.
//  Copyright © 2016年 韦烽传. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    ///服务端
    var server : CCHSocketServer!
    ///客户连接端
    var server_1 : CCHSocketClient!
    ///客户端
    var client : CCHSocketClient!
    
    var UDP_1 : CCHSocketUDP!
    var UDP_2 : CCHSocketUDP!
    
    
    @IBOutlet weak var server_text: UITextField!
    
    @IBOutlet weak var client_text: UITextField!
    
    @IBOutlet weak var udp_1_text: UITextField!
    
    @IBOutlet weak var udp_2_text: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        /***TCP***/
        
        server = CCHSocketServer()
        server.listeners { (client) in
            
            self.server_1 = client
            ///读取客户端数据
            self.server_1.recvData({ (data, code) in
                
                if data != nil {
                    
                    print(client.connection_address)
                    print(String.init(data: data!, encoding: NSUTF8StringEncoding))
                }
            })
        }
        
        client = CCHSocketClient()
        
        ///连接服务端
        client.connection(server.address_ip, port: server.address_port) { (status, code) in
            
            if status {
                
                self.client.recvData({ (data, code) in
                    
                    print(self.client.connection_address)
                    print(String.init(data: data!, encoding: NSUTF8StringEncoding))
                })
            }
        }
        
        
        /***UDP***/
        
        UDP_1 = CCHSocketUDP()
        UDP_1.recvfromData(1024*10) { (ip, port, data, code) in
            
            if data != nil {

                print("\(ip):\(port)")
                print(String.init(data: data!, encoding: NSUTF8StringEncoding))
            }
        }
        
        UDP_2 = CCHSocketUDP()
        UDP_2.recvfromData(1024*10) { (ip, port, data, code) in
            
            if data != nil {
                
                print("\(ip):\(port)")
                print(String.init(data: data!, encoding: NSUTF8StringEncoding))
            }
        }
        
    }
    
    
    
    @IBAction func serverSend(sender: UIButton) {
        
        server_1.sendData(server_text.text!.dataUsingEncoding(NSUTF8StringEncoding)!) { (status, code) in
            
        }
    }

    @IBAction func clientSend(sender: UIButton) {
        
        client.sendData(client_text.text!.dataUsingEncoding(NSUTF8StringEncoding)!) { (status, code) in
            
        }
    }
    
    @IBAction func udp1Send(sender: UIButton) {
        
        UDP_1.sendtoData(UDP_2.address_ip, port: UDP_2.address_port, data: udp_1_text.text!.dataUsingEncoding(NSUTF8StringEncoding)!) { (status, code) in
            
        }
    }
    
    @IBAction func udp2Send(sender: UIButton) {
        
        UDP_2.sendtoData(UDP_1.address_ip, port: UDP_1.address_port, data: udp_2_text.text!.dataUsingEncoding(NSUTF8StringEncoding)!) { (status, code) in
            
        }
    }
    
    

}

