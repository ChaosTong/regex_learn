const fs = require('fs')
const os = require('os')


function parse() {
	try {  
	    var data = fs.readFileSync('weiboicon.txt', 'utf8')
	} catch(e) {
	    console.log('Error:', e.stack)
	}
	let str = '['
	str += data.toString()

	var reg = /<li.+?title="(.+?)(" suda).+?<img src="\/\/(.+?)"><\/li>/g

	var res = str.replace(reg, '{"name": "$1", "url": "http://$3"},')
	var w_data = new Buffer.from(res)


	fs.writeFile(`${os.homedir()}/Downloads/weiboicon.json`, w_data, function (err) {
	    if(err) {
	        console.error(err)
	    } else {
	       console.log('写入成功')
	    }
	})
}

function addFilename() {
	let list = require("./weiboicon.json")

	list.forEach(i => {
		let filename = i.url.replace(/(.*\/)*([^.]+)/ig, '$2')
		i.filename = filename
	})

	fs.writeFile(`${os.homedir()}/Downloads/weiboicon.json`, JSON.stringify(list), function (err) {
	    if(err) {
	        console.error(err)
	    } else {
	       console.log('写入成功')
	    }
	})
}
// parse()
addFilename()

// let list = require("./weiboicon.json")
// var str = ''
// list.forEach(i => {
// 	// console.log(i.url)
// 	str += `[${i.name}]`
// })

// console.log(str)

