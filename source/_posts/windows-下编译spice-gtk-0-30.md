---
title: windows 下编译spice-gtk 0.30
date: 2018-10-16 08:39:09
tags: [mingw, spice]
categories: "spice" #文章分類目錄 可以省略
---


# Windows 下编译 spice-gtk 0.30
### MSYS2安装
见上篇文章 [windows下编译glib](/2018/10/15/windows下编译glib/)


### 下载解压
下载 spice-gtk 0.30 及 spice 0.13.1
解压后，将spice 0.13.1中的 spice-common文件夹复制到spice-gtk 0.30中

### 安装程序库
```
#使用pacman安装所需要的程序库
pacman -S mingw-w64-i686-glib2
pacman -S mingw-w64-i686-libtool
pacman -S mingw-w64-i686-python3
pacman -S mingw-w64-i686-python3-six
pacman -S mingw-w64-i686-spice-protocol
```

由于直接安装的openssl和gtk3版本过高，需要下载低版本[清华镜像软件站](https://mirrors.tuna.tsinghua.edu.cn/)
mingw-w64-i686-gtk3-3.16.4-2-any.pkg.tar.xz
mingw-w64-i686-openssl-1.0.2.h-1-any.pkg.tar.xz

```
pacman -U mingw-w64-i686-gtk3-3.16.4-2-any.pkg.tar.xz
pacman -U mingw-w64-i686-openssl-1.0.2.h-1-any.pkg.tar.xz
```

### 编译spice-gtk
```
./configure --with-gtk=3.0 
mingw32-make
mingw32-make install
```