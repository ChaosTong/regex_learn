//
//  ExRegex.swift
//  Feed
//
//  Created by ChaosTong on 2020/4/2.
//  Copyright © 2020 ChaosTong. All rights reserved.
//

import Foundation

public extension String {
    func RegularExpression(regex:String) -> [String] {
        do {
            let regex: NSRegularExpression = try NSRegularExpression(pattern: regex, options: [])
            let matches = regex.matches(in: self, options: [], range: NSMakeRange(0, self.count))
            
            var data:[String] = Array()
            for item in matches {
                let string = (self as NSString).substring(with: item.range)
                data.append(string)
            }
            return data
        }
        catch {
            return []
        }
    }
}
