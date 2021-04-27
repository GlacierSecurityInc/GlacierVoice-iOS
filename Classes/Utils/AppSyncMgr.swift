//
//  AppSyncMgr.swift
//  Copyright © 2020 Glacier Security. All rights reserved.

import Foundation
import AWSAppSync

@objc open class AppSyncMgr: NSObject
{
    var appSyncClient: AWSAppSyncClient?
    
    @objc override public init() {
        super.init()
        appSyncClient = self.getAppSync()
    }
    
    fileprivate func getAppSync() -> AWSAppSyncClient? {
        if let client = appSyncClient {
            return client
        }
        
        do {
            // You can choose the directory in which AppSync stores its persistent cache databases
            let cacheConfiguration = try AWSAppSyncCacheConfiguration()
            
            // AppSync configuration & client initialization
            let appSyncServiceConfig = try AWSAppSyncServiceConfig()
            let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncServiceConfig: appSyncServiceConfig,
                                                                  cacheConfiguration: cacheConfiguration)
            appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
            // Set id as the cache key for objects. See architecture section for details
            appSyncClient?.apolloClient?.cacheKeyForObject = { $0["id"] }
        } catch {
            print("Error initializing appsync client. \(error)")
        }
        return appSyncClient
    }
    
    @objc public func getUserInfo(username: String, org: String, completion:@escaping (GlacierUser?) -> Void)  {
        guard let client = appSyncClient else {
            completion(nil)
            return
        }
        
        let gquery = GetGlacierUsersQuery(organization: org, username: username)
        
        client.fetch(query: gquery)  { (result, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
                completion(nil)
            }
            //let org = result?.data?.getGlacierUsers?.organization,
            if let pw = result?.data?.getGlacierUsers?.glacierpwd,
                let user = result?.data?.getGlacierUsers?.messengerId,
                let ext = result?.data?.getGlacierUsers?.extensionVoiceserver,
                let display = result?.data?.getGlacierUsers?.userName{
                let lowerorg = org.lowercased()
                let guser = GlacierUser(username: user, voiceext: ext, password: pw, org: lowerorg, displayname: display)
                completion(guser)
            } else {
                completion(nil)
            }
        }
    }
}

@objc public class GlacierUser:NSObject {
    @objc public let username:String
    @objc public let voiceext:String
    @objc public let password:String
    @objc public var organization:String?
    @objc public var displayName:String?
    
    @objc public init(username:String, voiceext:String, password:String, org:String, displayname:String) {
        self.username = username
        self.voiceext = voiceext
        self.password = password
        self.organization = org
        self.displayName = displayname
    }
}
