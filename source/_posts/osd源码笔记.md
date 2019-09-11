---
title: osd源码笔记
date: 2019-09-06 13:55:53
tags: [ceph]
---
Ceph依据节点功能可以将节点划分为4种类型，分别是Client、OSD、Monitor和MDS。每个节点由Dispatcher（消息调度器）集合和Messenger（消息管理器）集合两部分组成。Dispatcher是消息的订阅者，对接收的消息进行处理或者将需要发送的消息移交给本节点Messenger，不同的节点类型和消息类型对应Dispatcher的类型也不同；Messenger是消息的发布者，能将Dispatcher移交的消息发布给其它节点的Messenger或者从其它节点的Messenger接收消息并将其移交给本节点的Dispatcher，实现不同节点之间的消息交互。一个节点根据需求会注册一个或者多个Messenger和多种不同类型的Dispatcher（每种类型一个）。


ceph osd的入口文件为src/ceph_osd.cc
## Messager 对象功能
1. *ms_public  
用来处理OSD和Client之间的消息

2. *ms_cluster  
用来处理OSD和集群之间的消息

3. *ms_hb_front_client  
用来向其它OSD发送心跳的消息

4. *ms_hb_back_client  
用来向其它OSD发送心跳的消息

5. *ms_hb_back_server  
用来接收其他OSD的心跳消息

6. *ms_hb_front_server  
用来接收其他OSD的心跳消息

7. *ms_objecter  
用来处理OSD和Objecter之间的消息
