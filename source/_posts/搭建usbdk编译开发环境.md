---
title: 搭建usbdk编译开发环境
date: 2018-11-01 17:05:39
tags: [mingw, spice]
categories: "spice" #文章分類目錄 可以省略
---

#搭建编译usbdk及libusb环境

* 搭建编译usbdk环境（win7下）
1. 安装vs2015，安装时注意安装vc++ 及 windows sdk选项
2. 安装windows sdk&#160;&#160; https://go.microsoft.com/fwlink/p/?LinkID=845298
 安装    wdk10&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160; https://go.microsoft.com/fwlink/p/?LinkID=845980

 3. 下载usbdk，**注意解决方案配置要设置为 win7 Debug_NoSign**

 4. 编译后，进入编译目录 UsbDk_Package，使用```UsbDkController.exe -i```进行驱动安装
 5. 需要将UsbDkHelper.dll复制到spicy.exe路径下

 * libusb编译选项
```
mingw32-configure –enable-usbdk –enable-debug-log
```



