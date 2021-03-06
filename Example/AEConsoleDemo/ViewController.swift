//
//  ViewController.swift
//  AEConsoleDemo
//
//  Created by Marko Tadic on 4/1/16.
//  Copyright © 2016 AE. All rights reserved.
//

import UIKit
import AEConsole

class ViewController: UIViewController {
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        aelog()
        generateLogLines(count: 100)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        aelog()
        generateLogLines(count: 200)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        aelog()
        generateLogLines(count: 300)
    }
    
    // MARK: - Actions

    @IBAction func didTapLogButton(sender: UIButton) {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        dispatch_async(queue) {
            self.generateLogLines(count: Int.random(max: 1000))
            dispatch_async(dispatch_get_main_queue(), {
                aelog(sender)
            })
        }
    }
    
    @IBAction func didTapToggleButton(sender: UIButton) {
        AEConsole.toggle()
    }
    
    // MARK: - Helpers
    
    func generateLogLines(count count: Int) {
        for i in 0...count {
            aelog("I'm just a log line #\(i).")
        }
    }
    
}

extension Int {
    static func random(min: Int = 0, max: Int = Int.max) -> Int {
        return Int(arc4random_uniform(UInt32((max - min) + 1))) + min
    }
}