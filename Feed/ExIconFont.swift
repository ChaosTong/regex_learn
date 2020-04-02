//
//  ExIconFont.swift
//  Feed
//
//  Created by ChaosTong on 2020/4/2.
//  Copyright © 2020 ChaosTong. All rights reserved.
//

import Foundation
import UIKit

public extension UIFont {
    class func iconfont(ofSize: CGFloat) -> UIFont? {
        return UIFont(name: "iconfont", size: ofSize)
    }
}

public extension UIImage {
    convenience init?(text: Iconfont, fontSize: CGFloat = 16, imageSize: CGSize = CGSize(width: 16, height: 16), imageColor: UIColor = UIColor.black) {
        guard let iconfont = UIFont.iconfont(ofSize: fontSize) else {
            self.init()
            return nil
        }
        var imageRect = CGRect(origin: CGPoint.zero, size: imageSize)
        if __CGSizeEqualToSize(imageSize, CGSize.zero) {
            imageRect = CGRect(origin: CGPoint.zero, size: text.rawValue.size(withAttributes: [NSAttributedString.Key.font: iconfont]))
        }
        UIGraphicsBeginImageContextWithOptions(imageRect.size, false, UIScreen.main.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        text.rawValue.draw(in: imageRect, withAttributes: [NSAttributedString.Key.font : iconfont, NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: imageColor])
        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            self.init()
            return nil
        }
        self.init(cgImage: cgImage)
    }
}

public extension String {
    var icon: UIImage? {
        let link = UIImage(text: .link)
        let domain = self.RegularExpression(regex: "([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6}(?=/)")
        if domain.count != 1 { return link }
        let url = domain.first!
        // 搜索树, 二叉查找树
        if url.contains("weibo.com") || url.contains("sina.com.cn") {
            return UIImage(text: .weibo)
        } else if url.contains("githu.com") {
            return UIImage(text: .github)
        }
        print(domain.first!, self)
        return link
    }
}
