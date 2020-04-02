const fs = require("fs")
const os = require('os')
const list = require(`${os.homedir()}/Downloads/font/iconfont.json`)

const options = {
    timeZone: 'Asia/Shanghai',
    hour12: false,
    year: 'numeric', month: 'numeric', day: 'numeric',
    hour: 'numeric', minute: 'numeric', second: 'numeric',
},
formatter = new Intl.DateTimeFormat([], options)
formatter.format(new Date())
let current = (new Date()).toLocaleString([], options)

var w_str = `//
//  IconFont.swift
//  Feed
//
//  Created by ChaosTong on ${current.split(' ')[0]}.
//  Copyright © ${(current.split(' ')[0]).split('/')[0]} ChaosTong. All rights reserved.
//

public enum Iconfont: String {
`

list.glyphs.forEach(i => {
    let line = `    case ${i.font_class} = \"\\u\{${i.unicode}\}\"\r\n`
    w_str += line
})

w_str += `}\r\n`
var w_data = new Buffer.from(w_str)

// fs.writeFile(__dirname + '/Iconfont.swift', w_data, {flag: 'a'}, function (err) {
fs.writeFile(`${os.homedir()}/Developer/Feed/Feed/IconFont.swift`, w_data, function (err) {
    if(err) {
        console.error(err)
    } else {
       console.log('写入成功')
    }
})