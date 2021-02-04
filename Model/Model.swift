//
//  Model.swift
//  RealmPerformance
//
//  Created by Outbank Dev on 04.02.21.
//

import RealmSwift

open class Model: Object {
    @objc open dynamic var id = UUID().uuidString
    @objc open dynamic var b: Bool = false
    
    open override class func indexedProperties() -> [String] {
        return ["id"]
    }
}
