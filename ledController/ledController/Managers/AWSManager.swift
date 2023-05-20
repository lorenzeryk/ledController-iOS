//
//  AWSManager.swift
//  ledController
//
//  Created by Eryk Lorenz on 5/8/23.
//

import Foundation
import AWSCore
import AWSIoT

class AWSManager {
    var clientID: String
    
    init() {
        clientID = ""
        initializeConnectionToAWS()
    }
    
    private func initializeConnectionToAWS() {
        let credentials = AWSCognitoCredentialsProvider(regionType: .USEast2, identityPoolId: Secrets.identity_pool)
        let config = AWSServiceConfiguration(region: .USEast2, credentialsProvider: credentials)
        
        AWSIoT.register(with: config!, forKey: "kAWSIoT")
        
        let endpoint = AWSEndpoint(urlString: Secrets.AWS_Endpoint)
        let iotDataConfig = AWSServiceConfiguration(region: .USEast2, endpoint: endpoint, credentialsProvider: credentials)
        
        AWSIoTDataManager.register(with: iotDataConfig!, forKey: "kDataManager")
        
        connectToAWSIoT()
    }
    
    private func getClientID() async -> String {
        let fetchClientID = Task { () -> String in
            let credentials = AWSCognitoCredentialsProvider(regionType: .USEast2, identityPoolId: Secrets.identity_pool)
            
            let id = credentials.getIdentityId()
            return id.result! as String
        }
        
        do {
            return try await fetchClientID.result.get()
        } catch {
            return ""
        }
    }
    
    private func connectToAWSIoT() {
        func mqttEventCallback(_ status: AWSIoTMQTTStatus ) {
            switch status {
            case .connecting: print("Connecting to AWS IoT")
            case .connected:
                print("Connected to AWS IoT")
                subscribeToTopics()
            case .connectionError: print("AWS IoT connection error")
            case .connectionRefused: print("AWS IoT connection refused")
            case .protocolError: print("AWS IoT protocol error")
            case .disconnected: print("AWS IoT disconnected")
            case .unknown: print("AWS IoT unknown state")
            default: print("Error - unknown MQTT state")
            }
        }
        
        Task.init {
            if (clientID == "") {
                clientID = await getClientID()
            }
            // Ensure connection gets performed background thread (so as not to block the UI)
            DispatchQueue.global(qos: .background).async {
                do {
                    let dataManager = AWSIoTDataManager(forKey: "kDataManager")
                    dataManager.connectUsingWebSocket(withClientId: self.clientID,
                                                      cleanSession: true,
                                                      statusCallback: mqttEventCallback)
                    
                } catch {
                    print("Error, failed to connect to device gateway => \(error)")
                }
            }
        }
    }
    
    func publishMessage(message: String, topic: String) {
        let dataManager = AWSIoTDataManager(forKey: "kDataManager")
        dataManager.publishString(message, onTopic: topic, qoS: .messageDeliveryAttemptedAtLeastOnce)
    }
    
    func subscribeToTopics() {
        func messageReceived(payload: Data) {
            print("Message Received")
            let message = String(data: payload, encoding: .utf8)
            print(message)
        }
        
        let dataManager = AWSIoTDataManager(forKey: "kDataManager")
        let topicArray = ["get/accepted", "get/rejected", "update/accepted", "update/rejected"]
        
        for topic in topicArray {
            dataManager.subscribe(toTopic: "$aws/things/ledControllerThing/shadow/name/ledControllerShadow/\(topic)", qoS: .messageDeliveryAttemptedAtLeastOnce, messageCallback: messageReceived)
        }
    }
}
