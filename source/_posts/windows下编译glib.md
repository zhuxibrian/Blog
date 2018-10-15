---
title: windows下编译glib
date: 2018-10-15 16:05:07
tags: [mingw, spice]
categories: "spice" #文章分類目錄 可以省略
---

&#160; &#160; &#160; &#160;在windows下编译glib需要使用msys2进行编译：
## 1. msys2安装：
http://www.msys2.org/ 
启动Mingw-w64 32bit

## 2. 修改pacman源：
修改msys2安装目录下的\etc\pacman.d文件夹里面的3个mirrorlist.*文件，文件最前面添加
```
[repo-ck]							
Server = https://mirrors.tuna.tsinghua.edu.cn/repo-ck/$arch
```

输入 pacman -Syu                      #同步源，并更新系统 

## 3. 安装依赖库
```
# 安装依赖库和必须的工具
pacman --needed --noconfirm -S automake autoconf make libtool unzip glib2-devel intltool pcre-devel   \
            mingw-w64-x86_64-toolchain mingw-w64-x86_64-pcre

# 可选工具用于生成文档
#pacman --needed --noconfirm -S gtk-doc
```

## 4. 下载编译glib
```
# 从github上下载2.54.3版本的源码
wget https://github.com/GNOME/glib/archive/2.58.1.zip -O glib-2.58.1.zip
# 源码解压缩
unzip glib-2.58.1.zip || exit -1
```

###编译
```
cd glib-2.54.3
./autogen.sh --prefix=/your/install/path
# 编译并安装到prefix指定的位置
mingw32-make
mingw32-make install -j8
```

在MSYS2下编译用的是MinGW编译器，生成的导入库(import library)都后缀是.dll.a，MSVC怎么使用呢？其实MinGW生成的import library,MSVC是可以直接用的，直接添加到msvc工程就可以。 