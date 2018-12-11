//
//  MyURLProtocol.swift
//  Created by jahan on 2018. 3. 3..
//  Copyright © 2018년 gmkApp. All rights reserved.
//

import Foundation
import UIKit

var requestCount = 0

class MyURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return false
    }
}
