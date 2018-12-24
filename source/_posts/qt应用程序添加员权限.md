---
title: qt应用程序添加员权限
date: 2018-12-24 09:30:49
tags: [qt]
---

1. 通过记事本新建文件，内容如下：
```
<?xml version='1.0' encoding='UTF-8' standalone='yes'?> 
<assembly xmlns='urn:schemas-microsoft-com:asm.v1' manifestVersion='1.0'> 
<trustInfo xmlns="urn:schemas-microsoft-com:asm.v3"> 
<security> 
<requestedPrivileges> 
<requestedExecutionLevel level='requireAdministrator' uiAccess='false' /> 
</requestedPrivileges> 
</security> 
</trustInfo> 
</assembly> 
```
命名为UAC.manifest，名字并不重要。

2. 通过记事本新建文件，内容为：
```
1 24 DISCARDABLE "UAC.manifest"
```

其中1代表资源编号，24-资源类型为RTMAINIFEST

该文件命名为uac.rc，名字也可以自己取。其中UAC.manifest只要与上文名字一致即可。

3. 将UAC.manifest和uac.rc放到需要添加管理员权限的工程目录下，也就是pro文件所在目录。


4. 在工程文件中追加一行RC_FILE = uac.rc

重新编译程序，程序右下角则出现需要管理员权限的盾牌图标.




