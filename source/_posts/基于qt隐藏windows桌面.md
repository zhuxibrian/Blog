---
title: 基于qt隐藏windows桌面
date: 2018-12-24 09:26:57
tags: [qt]
---

基于qt隐藏windows桌面，需要修改windows注册表，将开机后自动启动桌面的注册表项指向其他程序，之后再终止windows explorer.exe，直接上代码
```
void ExplorerUtil::ShowExplorer()
{
    QSettings settings("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon", QSettings::Registry64Format);
    QString value = settings.value("Shell", "error").toString();
    qDebug() << value << endl;
    settings.setValue("Shell", "explorer.exe");

    QProcess::startDetached("C:\\Windows\\explorer.exe"); 
}

void ExplorerUtil::hideExplorer()
{
    QSettings settings("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon", QSettings::Registry64Format);
    QString value = settings.value("Shell", "error").toString();
    qDebug() << value << endl;
    settings.setValue("Shell", "explorerHide.exe");

    QProcess::startDetached("taskkill /im explorer.exe /f"); 
}

```
