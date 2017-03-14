---
title: 利用Github的Webhook进行静态网站的自动化部署
date: 2017-03-13 23:08:40
tags: [Git,Linux,Hexo]
categories: "Git" #文章分類目錄 可以省略
---

花了些时间，把blog自动化部署到了服务器，悲催的事情是，这篇文章快写完的时候出了意外，所有文档都丢了...重新手打...

<font color=#0099ff size=5 face="微软雅黑">原理</font>  

利用Github在仓库进行操作时，可以通过配置webhook向服务器发送请求，在服务器端接到请求后，使用脚本来自动进行git pull操作。

## 首先构建Node.js服务器代码 webhook.js  
首先安装github-webhook-handler的中间件，用npm install -g github-webhook-handler来全局安装  
```
var http = require('http')
var createHandler = require('github-webhook-handler')
var handler = createHandler({ path: '/', secret: 'root' })
// 上面的 secret 保持和 GitHub 后台设置的一致

function run_cmd(cmd, args, callback) {
  var spawn = require('child_process').spawn;
  var child = spawn(cmd, args);
  var resp = "";

  child.stdout.on('data', function(buffer) { resp += buffer.toString(); });
  child.stdout.on('end', function() { callback (resp) });
}

http.createServer(function (req, res) {
  handler(req, res, function (err) {
    res.statusCode = 404
    res.end('no such location')
  })
}).listen(7777)

handler.on('error', function (err) {
  console.error('Error:', err.message)
})

handler.on('push', function (event) {
  console.log('Received a push event for %s to %s',
    event.payload.repository.name,
    event.payload.ref);
    run_cmd('sh', ['./deploy.sh',event.payload.repository.name], function(text){ console.log(text) });
})  
```
其中:  
```
var handler = createHandler({ path: '/', secret: 'root' })
```
secret为在Github进行设置时的值。  

## 完成deploy.sh脚本
```
#!/bin/bash
 
WEB_PATH='/usr/hexo'
 
echo "Start deployment"
cd $WEB_PATH
echo "pulling source code..."
git pull origin master
echo "Finished."  
```
其中`WEB_PATH`为项目路径，根据实际项目位置，需要修改`WEB_PATH`值。  
另外如果是全新项目，需要在服务器上先clone要部署的项目。  

## 使用pm2后台运行webhook.js脚本  
网上比较多的是使用forever对node进行后台运行及监控，我这里使用pm2替代，pm2是为了改变forever一些缺陷而开发的。  
安装pm2：
```
npm install pm2 -g
```
运行webhook.js
```
pm2 start webhook.js
```  

## 进入Gtihub后台进行设置，添加webhook  
进入需要自动部署的项目的github地址，进入setting设置页面，点击左侧的`Webhooks & services`

![logo](Github-webhook-vps\2017-03-13_230427.jpg)
