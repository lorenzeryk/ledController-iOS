//
//  ContentView.swift
//  ledController
//
//  Created by Eryk Lorenz on 5/8/23.
//

import SwiftUI

struct ContentView: View {
    let awsManager = AWSManager()
    var body: some View {
        VStack {
            Button("Test Update") {
                let jsonObject: [String:Any] = [
                    "state": [
                        "desired": [
                            "mode": "testVal",
                            "color": [
                                "red": 40,
                                "blue": 30,
                                "green": 20
                            ]
                        ]
                    ]
                ]
                
                let data = try? JSONSerialization.data(withJSONObject: jsonObject)
                let str = String(data: data!, encoding: .utf8)
                awsManager.publishMessage(message: str!, topic: "$aws/things/ledControllerThing/shadow/name/ledControllerShadow/update")
            }
            Button("Test Get") {
                awsManager.publishMessage(message: "", topic: "$aws/things/ledControllerThing/shadow/name/ledControllerShadow/get")
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
