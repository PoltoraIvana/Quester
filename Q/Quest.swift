//
//  Quest.swift
//  Q
//
//  Created by Ivan on 10/27/15.
//  Copyright © 2015 Ivan. All rights reserved.
//

import UIKit

class Quest: NSObject {
    
    var text: String
    
    var completed: Bool
    
    init(text: String) {
        self.text = text
        self.completed = false
    }

}
