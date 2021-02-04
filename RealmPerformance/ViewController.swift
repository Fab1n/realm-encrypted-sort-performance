//
//  ViewController.swift
//  RealmPerformance
//
//  Created by Outbank Dev on 28.01.21.
//

import UIKit
import RealmSwift
import os.log

class ViewController: UIViewController {
    @IBAction func generateData() {
        deleteDB()
        RealmPerformance.generateData()
    }
    
    @IBAction func fetchResults() {
        RealmPerformance.fetchResults()
    }
}

