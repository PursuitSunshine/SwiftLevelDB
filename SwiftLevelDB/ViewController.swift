//
//  ViewController.swift
//  SwiftLevelDB
//
//  Created by Cherish on 2021/12/6.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .cyan
        print("成功展示首页")
        let db = try! LevelDB.open(db: "Cherish")
        print("成功打开数据库")
        db.putCodable(true, forKey: "bool")
        print(db.getCodable(forKey: "bool", type: Bool.self) ?? false)
        let allKeys = db.keys()
        for item in allKeys {
            print(String(data: item as! Data, encoding: .utf8)!)
        }
        
    }


    
}

