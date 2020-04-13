//
//  ViewController.swift
//  Feed
//
//  Created by ChaosTong on 2020/3/30.
//  Copyright © 2020 ChaosTong. All rights reserved.
//

import UIKit
import MPITextKit
import YYImage

class ViewController: UIViewController {
    
    private let app = UIApplication.shared.delegate as! AppDelegate
    
    var dataSources: [(NSMutableAttributedString, CGFloat)] = [] {
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        caculateHeight(size.width)
        tableView.reloadData()
    }
    
    private func caculateHeight(_ width: CGFloat) {
        var temp: [(NSMutableAttributedString, CGFloat)] = []
        dataSources.forEach { (str, height) in
            temp.append((str, heightOfAttributedString(str, width - 15 * 2)))
        }
        dataSources = temp
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
                }
                m.text = replace(validateString: m.text, regex: "<a data-url.+? href=\"(.+?)\".+?</a>", content: "$1")
            }
            
            dataSources.append(matchesResultOfTitleMP(title: m.text))
        }
    }
    
    let KRegularMatcheHttpUrl = "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)" // 图标+描述 替换HTTP链接
    let KRegularMatcheTopic = "#[^#]+#"    // 话题匹配 #话题#
    let KRegularMatcheUser = "@[\\u4e00-\\u9fa5a-zA-Z0-9_-]*"  // @用户匹配
    let KRegularMatcheEmotion = "\\[[^ \\[\\]]+?\\]"   //表情匹配 [爱心]
    func matchesResultOfTitle(title: String) -> (attributedString: NSMutableAttributedString, height: CGFloat) {
        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string:title)
        
        //话题匹配
        let topicRanges = RegularExpressions(regex: KRegularMatcheTopic, validateString: attributedString.string)
        topicRanges.forEach { (str, range) in
            attributedString.addAttributes([NSAttributedString.Key.link: str], range: range)
        }
        
        //@用户匹配
        let userRanges = RegularExpressions(regex: KRegularMatcheUser, validateString: attributedString.string)
        userRanges.forEach { (str, range) in
            attributedString.addAttributes([NSAttributedString.Key.link: str], range: range)
        }
        
        var currentTitleRange = NSRange(location: 0, length:attributedString.length)
        let feed = RegularExpressions(regex: "feed://.+", validateString: title)
        feed.forEach { (str, range) in
            let attchimage = NSTextAttachment()
            attchimage.image = UIImage.init(text: .link)
            attchimage.bounds = CGRect.init(x: 0, y: -2, width: 16, height: 16)
            let replaceStr: NSMutableAttributedString = NSMutableAttributedString(attachment: attchimage)
            replaceStr.append(NSAttributedString.init(string: "全文"))
            replaceStr.addAttributes([NSAttributedString.Key.link: str], range: NSRange(location: 0, length:replaceStr.length))
            //注意：涉及到文本替换的 ，每替换一次，原有的富文本位置发生改变，下一轮替换的起点需要重新计算！
            let newLocation = range.location - (currentTitleRange.length - attributedString.length)
            //图标+描述 替换HTTP链接字符
            attributedString.replaceCharacters(in: NSRange(location: newLocation, length: range.length), with: replaceStr)
        }
        
        // 图标+网页title 替换链接
        currentTitleRange = NSRange(location: 0, length:attributedString.length)
        let urlRanges = RegularExpressions(regex: KRegularMatcheHttpUrl, validateString: title)
        urlRanges.forEach { (str, range) in
            let attchimage = NSTextAttachment()
            attchimage.image = str.icon
            attchimage.bounds = CGRect.init(x: 0, y: -2, width: 16, height: 16)
            let replaceStr : NSMutableAttributedString = NSMutableAttributedString(attachment: attchimage)
            if let linkTitle = app.urlDict[str] {
                if str.contains(".jpg") {
                    attchimage.image = UIImage(text: .picture)
                    replaceStr.append(NSAttributedString.init(string: "查看图片"))
                } else if linkTitle.contains("的微博视频") {
                    attchimage.image = UIImage(text: .video)
                    replaceStr.append(NSAttributedString.init(string: linkTitle))
                } else {
                    replaceStr.append(NSAttributedString.init(string: linkTitle))
                }
            } else {
                replaceStr.append(NSAttributedString.init(string: "网页链接"))
            }
            replaceStr.addAttributes([NSAttributedString.Key.link: str], range: NSRange(location: 0, length:replaceStr.length ))
            let newLocation = range.location - (currentTitleRange.length - attributedString.length)
            //图标+描述 替换HTTP链接字符
            attributedString.replaceCharacters(in: NSRange(location: newLocation, length: range.length), with: replaceStr)
        }
        
        //表情匹配
        let emotionRanges = RegularExpressions(regex: KRegularMatcheEmotion, validateString: attributedString.string)
        //经过上述的匹配替换后，此时富文本的范围
        currentTitleRange = NSRange(location: 0, length:attributedString.length)
        emotionRanges.forEach { (str, range) in
            //表情附件
            if let emoji = app.emojiDict.first(where: { "[\($0.name)]" == str }) {
                let attchimage: NSTextAttachment = NSTextAttachment()
                if emoji.filename.contains(".gif") {
                    attchimage.image = UIImage.gif(name: emoji.filename)
                } else {
                    attchimage.image = UIImage.init(named: emoji.filename)
                }
                attchimage.bounds = CGRect.init(x: 0, y: -2, width: 16, height: 16)
                let stringImage : NSAttributedString = NSAttributedString(attachment: attchimage)
                let newLocation = range.location - (currentTitleRange.length - attributedString.length)
                //图片替换表情文字
                attributedString.replaceCharacters(in: NSRange(location: newLocation, length: range.length), with: stringImage)
            }
        }
        
        //段落
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4 //行间距
        attributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location:0, length:attributedString.length))
        //元组
        let attributedStringHeight = (attributedString, heightOfAttributedString(attributedString))
        return attributedStringHeight
    }
    //计算富文本的高度
    func heightOfAttributedString(_ attributedString: NSAttributedString, _ width: CGFloat = UIScreen.main.bounds.size.width - 15 * 2) -> CGFloat {
        let height: CGFloat =  attributedString.boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height
        return ceil(height)
    }
    func matchesResultOfTitleMP(title: String) -> (attributedString: NSMutableAttributedString, height: CGFloat) {
        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string:title)
        
        //话题匹配
        let topicRanges = RegularExpressions(regex: KRegularMatcheTopic, validateString: attributedString.string)
        topicRanges.forEach { (str, range) in
            let link = MPITextLink(value: str as NSString)
            attributedString.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(red:0.27, green:0.56, blue:0.90, alpha:1.00), NSAttributedString.Key.MPILink: link], range: range)
        }

        //@用户匹配
        let userRanges = RegularExpressions(regex: KRegularMatcheUser, validateString: attributedString.string)
        userRanges.forEach { (str, range) in
            let link = MPITextLink(value: str as NSObjectProtocol)
            attributedString.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(red:0.27, green:0.56, blue:0.90, alpha:1.00), NSAttributedString.Key.MPILink: link], range: range)
        }
        
        var currentTitleRange = NSRange(location: 0, length:attributedString.length)
        let feed = RegularExpressions(regex: "feed://.+", validateString: title)
        feed.forEach { (str, range) in
            let attchimage = NSTextAttachment()
            attchimage.image = UIImage.init(text: .link)
            attchimage.bounds = CGRect.init(x: 0, y: -2, width: 16, height: 16)
            let replaceStr: NSMutableAttributedString = NSMutableAttributedString(attachment: attchimage)
            replaceStr.append(NSAttributedString.init(string: "全文"))
            let link = MPITextLink(value: str as NSObjectProtocol)
            replaceStr.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(red:0.27, green:0.56, blue:0.90, alpha:1.00), NSAttributedString.Key.MPILink: link], range: NSRange(location: 0, length:replaceStr.length))
            //注意：涉及到文本替换的 ，每替换一次，原有的富文本位置发生改变，下一轮替换的起点需要重新计算！
            let newLocation = range.location - (currentTitleRange.length - attributedString.length)
            //图标+描述 替换HTTP链接字符
            attributedString.replaceCharacters(in: NSRange(location: newLocation, length: range.length), with: replaceStr)
        }

        // 图标+网页title 替换链接
        currentTitleRange = NSRange(location: 0, length:attributedString.length)
        let urlRanges = RegularExpressions(regex: KRegularMatcheHttpUrl, validateString: title)
        urlRanges.forEach { (str, range) in
            let attchimage = NSTextAttachment()
            attchimage.image = str.icon
            attchimage.bounds = CGRect.init(x: 0, y: -2, width: 16, height: 16)
            let replaceStr : NSMutableAttributedString = NSMutableAttributedString(attachment: attchimage)
            if let linkTitle = app.urlDict[str] {
                if str.contains(".jpg") {
                    attchimage.image = UIImage(text: .picture)
                    replaceStr.append(NSAttributedString.init(string: "查看图片"))
                } else if linkTitle.contains("的微博视频") {
                    attchimage.image = UIImage(text: .video)
                    replaceStr.append(NSAttributedString.init(string: linkTitle))
                } else {
                    replaceStr.append(NSAttributedString.init(string: linkTitle))
                }
            } else {
                replaceStr.append(NSAttributedString.init(string: "网页链接"))
            }
            let link = MPITextLink(value: str as NSObjectProtocol)
            replaceStr.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(red:0.27, green:0.56, blue:0.90, alpha:1.00), NSAttributedString.Key.MPILink: link], range: NSRange(location: 0, length:replaceStr.length))
            let newLocation = range.location - (currentTitleRange.length - attributedString.length)
            //图标+描述 替换HTTP链接字符
            attributedString.replaceCharacters(in: NSRange(location: newLocation, length: range.length), with: replaceStr)
        }

        //表情匹配
        let emotionRanges = RegularExpressions(regex: KRegularMatcheEmotion, validateString: attributedString.string)
        //经过上述的匹配替换后，此时富文本的范围
        currentTitleRange = NSRange(location: 0, length:attributedString.length)
        var last: String? = nil
        emotionRanges.forEach { (str, range) in
            //表情附件
            if let emoji = app.emojiDict.first(where: { "[\($0.name)]" == str }) {
                let attchimage = MPITextAttachment.init()
                if emoji.filename.contains(".gif") {
                    let path = Bundle.main.url(forResource: "emoji_gif/\(emoji.filename)", withExtension: "")!
                    let data = try! Data.init(contentsOf: path)
                    let image = YYImage.init(data: data, scale: 2)
                    image?.preloadAllAnimatedImageFrames = true
                    let imageView = YYAnimatedImageView.init(image: image)
                    attchimage.content = imageView
                } else {
                    attchimage.content = UIImage.init(named: emoji.filename)
                }
                attchimage.bounds = CGRect.init(x: 0, y: 0, width: 16, height: 16)
                let stringImage: NSAttributedString = NSAttributedString(attachment: attchimage)
                let attachText = stringImage.mutableCopy() as! NSMutableAttributedString
                
                if last == str {
                    let entity = MPITextEntity(value: "\(str)-\(range.location)" as NSString)
                    attachText.addAttribute(.MPIEntity, value: entity, range: attachText.mpi_rangeOfAll())
                }
                last = str
                
                let newLocation = range.location - (currentTitleRange.length - attributedString.length)
                attributedString.replaceCharacters(in: NSRange(location: newLocation, length: range.length), with: attachText)
            }
        }
        
//        段落
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4 //行间距
        attributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location:0, length:attributedString.length))
        //元组
        let attributedStringHeight = (attributedString, heightOfAttributedString(attributedString))
        return attributedStringHeight
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
        cell.txt.attributedText = dataSources[indexPath.row].0
        cell.txt.numberOfLines = 0
        cell.txt.sizeToFit()
        cell.txt.delegate = self
        return cell
    }
}

extension ViewController: MPILabelDelegate {
    func label(_ label: MPILabel, highlightedTextAttributesWith link: MPITextLink, forAttributedText attributedText: NSAttributedString, in characterRange: NSRange) -> [AnyHashable : Any]? {
        let backgroud = MPITextBackground(fill: UIColor(red:0.15, green:0.79, blue:0.25, alpha:1.00), cornerRadius: 3)
        return [NSAttributedString.Key.MPIBackground: backgroud]
    }
    func label(_ label: MPILabel, didInteractWith link: MPITextLink, forAttributedText attributedText: NSAttributedString, in characterRange: NSRange, interaction: MPITextItemInteraction) {
        guard let link = link.value as? String else { return }
        print(link)
    }
}

//extension ViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return dataSources[indexPath.row].1
//    }
//}
