const fs = require("fs")
const os = require('os')

const http = require('http')

let jsonUrl = ""
let ttfUrl = ""
var argv = process.argv
if (argv.length == 3) {
    jsonUrl = `http://at.alicdn.com/t/${argv[2]}.json`
    ttfUrl = `http://at.alicdn.com/t/${argv[2]}.ttf`
} else {
    console.log("error - no download url e.g. font_1756345_gjri6xdau9")
    return
}

const json = fs.createWriteStream("iconfont.json");
http.get(jsonUrl, function(response) {
  response.pipe(json)
})

const ttf = fs.createWriteStream("./Feed/iconfont.ttf");
http.get(ttfUrl, function(response) {
  response.pipe(ttf)
})

setTimeout(writeFile, 1500)

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
//  Created by ChaosTong on ${current.split(',')[0]}.
//  Copyright © ${(current.split(',')[0]).split('/')[2]} ChaosTong. All rights reserved.
//
//  Auto generated
public enum Iconfont: String {
`
function writeFile() {
    let list = require('./iconfont.json')
    list.glyphs.forEach(i => {
        let line = `    case ${i.font_class} = \"\\u\{${i.unicode}\}\"\r\n`
        w_str += line
    })

    w_str += `}\r\n`
    var w_data = new Buffer.from(w_str)

    // fs.writeFile(__dirname + '/Iconfont.swift', w_data, {flag: 'a'}, function (err) {
    fs.writeFile('./Feed/IconFont.swift', w_data, function (err) {
        if(err) {
            console.error(err)
        } else {
           console.log('写入成功')
           trashHandle()
        }
    })
}

function trashHandle() {
    try {
      fs.unlinkSync('./iconfont.json')
      //file removed
    } catch(err) {
      console.error(err)
    }
}