//
//  ViewController.swift
//  SharedObjectsSwift
//
//  Created by Slava Vdovichenko on 11/3/15.
//  Copyright © 2015 The Midnight Coders, Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController, IRTMPClientDelegate, ISharedObjectListener {
    
    let serverUrl = "rtmp://10.0.1.62:1935/live"
    let soName = "table_so"
    
    var rtmpClient:RTMPClient?
    var sharedObject:IClientSharedObject?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DebLog.setIsActive(true)
       
        rtmpClient = RTMPClient.init(serverUrl)
        rtmpClient?.delegate = self
        rtmpClient?.connect()

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func connectSO() {
        
        if (sharedObject == nil) {
            print("connectSO SEND ----> getSharedObject")
            sharedObject = rtmpClient?.getSharedObject(soName, persistent: false, owner: self)
        }
        else {
            print("connectSO SEND ----> connect")
            sharedObject?.connect()
        }
    }
    
    func setAttributeSO() {
        let os = ["iOS":"Apple", "android":"Google"]
        sharedObject?.setAttributes(os)
    }

    // IRTMPClientDelegate Methods
    
    func connectedEvent() {
        print("<IRTMPClientDelegate> connectedEvent");
        
        connectSO()
    }
    
    func disconnectedEvent() {
        print("<IRTMPClientDelegate> disconnectedEvent)");        
    }
    
    func connectFailedEvent(code: Int32, description: String!) {
        print("<IRTMPClientDelegate> connectFailedEvent: \(code) = \(description)");
    }
    
    func resultReceived(call: IServiceCall!) {
        let method = call.getServiceMethodName()
        let args = call.getArguments()
        print("<IRTMPClientDelegate> resultReceived: \(method) = \(args)");
    }
    
    // ISharedObjectListener methods
    
    func onSharedObjectConnect(so: IClientSharedObject!) {
        print("<ISharedObjectListener> onSharedObjectConnect:[\(so.getName())]");
    }
    
    func onSharedObjectDisconnect(so: IClientSharedObject!) {
        print("<ISharedObjectListener> onSharedObjectDisconnect:[\(so.getName())]");
    }
    
    func onSharedObjectUpdate(so: IClientSharedObject!, withDictionary values: [NSObject : AnyObject]!) {
        print("<ISharedObjectListener> onSharedObjectUpdate:withDictionary: [\(values)]");
        
    }
    
    func onSharedObjectUpdate(so: IClientSharedObject!, withKey key: AnyObject!, andValue value: AnyObject!) {
        print("<ISharedObjectListener> onSharedObjectUpdate:withKey: \(key)[\(value)]");
        
    }
    
    func onSharedObjectDelete(so: IClientSharedObject!, withKey key: String!) {
        print("<ISharedObjectListener> onSharedObjectDelete: \(key)");
        
    }
    
    func onSharedObjectClear(so: IClientSharedObject!) {
        print("<ISharedObjectListener> onSharedObjectClear:[\(so.getName())]");
        
        setAttributeSO()
    }
    
    func onSharedObjectSend(so: IClientSharedObject!, withMethod method: String!, andParams parms: [AnyObject]!) {
        print("<ISharedObjectListener> onSharedObjectSend: \(method)[\(parms)]");
    }
}

