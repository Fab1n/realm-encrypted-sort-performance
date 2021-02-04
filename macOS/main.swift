//
//  main.swift
//  macOS
//
//  Created by Outbank Dev on 04.02.21.
//

import Foundation

while true {
    print("What do you want to do? (generate|test-sort|exit)")
    let string = readLine()
    
    switch string {
    case "test-sort":
        fetchResults()
    case "generate":
        deleteDB()
        generateData()
    case "exit":
        exit(0)
    default:
        print(#"Option not availabe! Type "generate|test-sort|exit"#)
    }
}

