//
//  DatabaseManager.swift
//  RealmPerformance
//
//  Created by Outbank Dev on 29.01.21.
//

import RealmSwift
import os.log

func appMigration(_ migration: Migration, oldSchemaVersion: UInt64) {

}

let dbName = "database.realm"
let documents = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
let dbURL = (try! FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: documents, create: true)).appendingPathComponent("database.realm")
let encryptionKey: Data = {
    return Data(repeating: 7, count: 64)
}()

var config: Realm.Configuration {
    print("dbURL \(dbURL)")
    return .init(fileURL: dbURL, encryptionKey: encryptionKey, schemaVersion: 1, migrationBlock: appMigration, shouldCompactOnLaunch: { (Double($1) / Double($0)) < 0.5 })
}

let realm: Realm = {
    return try! Realm(configuration: config)
}()

func deleteDB() {
    let files = (try? FileManager.default.contentsOfDirectory(at: dbURL.deletingLastPathComponent(), includingPropertiesForKeys: nil)) ?? []
    
    for f in files {
        if f.lastPathComponent.contains(dbName) {
            try? FileManager.default.removeItem(at: f)
        }
    }
}

func generateData() {
    let r = realm
    
    try! r.write {
        r.deleteAll()
        
        for _ in 0..<1_000_000 {
            let m = Model()
            r.add(m)
        }
    }
}

func fetchResults() {
    
    let logger = OSLog(subsystem: "outbank", category: "tx performance")
    os_signpost(.begin, log: logger, name: "whole process")

    os_signpost(.begin, log: logger, name: "creating the realm")
    let r = realm
    os_signpost(.end, log: logger, name: "creating the realm")
    
    os_signpost(.begin, log: logger, name: "init results")
    let txs = r.objects(Model.self)
        .sorted(by: [
            SortDescriptor(keyPath: "b", ascending: false),
            SortDescriptor(keyPath: "id", ascending: false)
        ])
    os_signpost(.end, log: logger, name: "init results")

    os_signpost(.begin, log: logger, name: "count")
    let count = txs.count
    print(count)
    os_signpost(.end, log: logger, name: "count")
    
    os_signpost(.begin, log: logger, name: "getting a few elements")
    for _ in 0...10 {
        _ = txs.randomElement()
    }
    os_signpost(.end, log: logger, name: "getting a few elements")
    
    os_signpost(.end, log: logger, name: "whole process")
}
