---
title: Qt windows下关闭桌面
date: 2018-10-16 09:54:03
tags: [Qt]
categories: "Qt" #文章分類目錄 可以省略
---

在windows下隐藏桌面，可以先将注册表中 windows启动项改名，并将explorer进程关闭
```
// 隐藏桌面
QSettings settings("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon", QSettings::Registry64Format);
QString value = settings.value("Shell", "error").toString();//读
qDebug() << value << endl;
settings.setValue("Shell", "explorerHide.exe");//写

QProcess::startDetached("taskkill /im explorer.exe /f");

// 显示桌面
QSettings settings("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon", QSettings::Registry64Format);
QString value = settings.value("Shell", "error").toString();//读
qDebug() << value << endl;
settings.setValue("Shell", "explorer.exe");//写

QProcess::startDetached("C:\\Windows\\explorer.exe"); 
```
需要注意，32位程序修改注册表为wow6432node，如果想修改64位注册表，需要设置QSettings::Registry64Format。
QSettings::Registry64Format在qt5.2.1中不能使用，因此此代码需要在较高版本中运行，qt5.9.6测试通过。