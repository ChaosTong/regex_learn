//
//  ViewController.swift
//  Feed
//
//  Created by ChaosTong on 2020/3/30.
//  Copyright © 2020 ChaosTong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private let app = UIApplication.shared.delegate as! AppDelegate
    
    var dataSources: [NSMutableAttributedString] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var links: [[String]] = []

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        
    }

    private func loadData() {
        if let url = Bundle.main.url(forResource: "feed", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                prepareData(try decoder.decode([FeedModel].self, from: data))
            } catch {
                print("error:\(error)")
            }
        }
    }
    
    private func prepareData(_ models: [FeedModel]) {
        /// 数据过滤规则
        /// 1. 去 br 替换成 \n
        /// 2. 去 style
        /// 3. 去 class
        /// 4. 表情链接替换 [doge]
        /// 5. 去链接前的 icon
        /// 6. 带链接的话题 转 #topic#
        /// 7. 带链接的超话转 #topic[超话]#
        /// 8. 带链接 @ 转 普通@
        /// 9. 长微博全文链接 替换
        /// 10. http/https 链接替换
        ///
        models.forEach {
            var m = FeedModel.init(text: replace(validateString: $0.text, regex: "<br />", content: "\n"))
            m.text = replace(validateString: m.text, regex: " style=('|\")(.*?)('|\")", content: "")
            m.text = replace(validateString: m.text, regex: " class=('|\")(.*?)('|\")", content: "")
            m.text = replace(validateString: m.text, regex: "<span><img alt=\\[(.+?)\\].+?</span>", content: "[$1]")
            m.text = replace(validateString: m.text, regex: "<span><img .+?</span>", content: "")
            let topicReg = "<a  href=\"https://m.weibo.cn/search+.*?>([\\s\\S]*?)<span>(.+?)</span></a>"
            let topics: [String] = RegularExpression(regex: topicReg, validateString: m.text)
            if topics.count == 1 {
                m.text = replace(validateString: m.text, regex: topicReg, content: "$2")
            }
            let superTopicReg = "<a  href=('|\")https://m.weibo.cn/p/index+.*?>([\\s\\S]*?)<span>(.+?)</span></a>"
            let superTopics: [String] = RegularExpression(regex: superTopicReg, validateString: m.text)
            if superTopics.count == 1 {
                m.text = replace(validateString: m.text, regex: superTopicReg, content: "#$2[超话]#")
            }
            m.text = replace(validateString: m.text, regex: "<a href='/n.+?>(.+?)</a>", content: "$1")
            
            m.text = replace(validateString: m.text, regex: "<a href=('|\")(.+?)('|\")>全文</a>", content: "feed:/$2")
            
            let linkReg = "<a data-url.+? href=('|\").+?</a>"
            let links: [String] = RegularExpression(regex: linkReg, validateString: m.text)
            
            if links.count > 0 {
                links.forEach { (i) in
                    let title = replace(validateString: RegularExpression(regex: "<span>.+?</span>", validateString: i).first!, regex: "<span\\s*[^>]*>(.*?)<\\/span>", content: "$1")
                    let url = replace(validateString: i, regex: "<a.+?href=\"(.+?)\".+?></a>", content: "$1")
                    app.urlDict[url] = title
                    m.text = replace(validateString: m.text, regex: linkReg, content: url)
                }
            }
            
            let text: NSMutableAttributedString = NSMutableAttributedString.init(string: m.text)
            /// 话题 表情 @ http/https feed://
            let topicss = RegularExpressions(regex: "#[^#]+#", validateString: m.text)
            
            let emos = RegularExpressions(regex: "(\\[[0-9a-zA-Z\\u4e00-\\u9fa5]+\\])", validateString: m.text)
            
            let ats = RegularExpressions(regex: "@[\\u4e00-\\u9fa5a-zA-Z0-9_-]{2,30}", validateString: m.text)
            
            let urls = RegularExpressions(regex: "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)", validateString: m.text)
            
            let feed = RegularExpressions(regex: "feed://.+", validateString: m.text)
            
            ats.forEach { (str, range) in
                text.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.red], range: range)
            }
            topicss.forEach { (str, range) in
                text.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.green], range: range)
            }
            print("before-----", text.length)
            emos.reversed().forEach { (str, range) in
                let attach = NSTextAttachment.init(image: UIImage(named: "panda")!)
                attach.bounds = CGRect(x: 0, y: 0, width: 18, height: 18)
                let icon = NSAttributedString.init(attachment: attach)
                text.replaceCharacters(in: range, with: icon)
            }
            print("after-----", text.length)
//            urls.reversed().forEach { (str, range) in
//                if let title = app.urlDict[str] {
//                    let t = NSAttributedString.init(string: title)
//                    text.replaceCharacters(in: range, with: t)
//                }
//            }
            
            dataSources.append(text)
            print("")
        }
    }
    
    /// 字符串的替换
    ///
    /// - Parameters:
    ///   - validateString: 匹配对象
    ///   - regex: 匹配规则
    ///   - content: 替换内容
    /// - Returns: 结果
    private func replace(validateString:String,regex:String,content:String) -> String {
        do {
            let RE = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let modified = RE.stringByReplacingMatches(in: validateString, options: .reportProgress, range: NSRange(location: 0, length: validateString.count), withTemplate: content)
            return modified
        }
        catch {
            return validateString
        }
       
    }
    
    /// 正则匹配
    ///
    /// - Parameters:
    ///   - regex: 匹配规则
    ///   - validateString: 匹配对test象
    /// - Returns: 返回结果
    private func RegularExpression(regex:String,validateString:String) -> [String]{
        do {
            let regex: NSRegularExpression = try NSRegularExpression(pattern: regex, options: [])
            let matches = regex.matches(in: validateString, options: [], range: NSMakeRange(0, validateString.count))
            
            var data:[String] = Array()
            for item in matches {
                let string = (validateString as NSString).substring(with: item.range)
                data.append(string)
            }
            
            return data
        }
        catch {
            return []
        }
    }
    
    private func RegularExpressions(regex:String,validateString:String) -> [(String, NSRange)]{
        do {
            let regex: NSRegularExpression = try NSRegularExpression(pattern: regex, options: [])
            let matches = regex.matches(in: validateString, options: [], range: NSMakeRange(0, validateString.count))
            
            var data:[(String, NSRange)] = Array()
            for item in matches {
                let string = (validateString as NSString).substring(with: item.range)
                data.append((string, item.range))
            }
            
            return data
        }
        catch {
            return []
        }
    }
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSources.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! TextCell
        cell.txt.attributedText  = dataSources[indexPath.row]
        return cell
    }
}
