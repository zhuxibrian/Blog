---
title: ceph网络模块-网络模块基本结构
date: 2019-09-09 09:39:33
tags: [ceph]
---

<div id="content_views" class="markdown_views prism-atom-one-dark">
                    <!-- flowchart 箭头图标 勿删 -->
                    <svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
                        <path stroke-linecap="round" d="M5,0 0,2.5 5,5z" id="raphael-marker-block" style="-webkit-tap-highlight-color: rgba(0, 0, 0, 0);"></path>
                    </svg>
                                            <h2 id="ceph网络模块基本结构">Ceph网络模块基本结构</h2>

<hr>

<p>本文基于Jewel版本对Ceph的网络模块进行分析，主要针对AsyncMessenger的方式。</p>

<p><img src="https://img-blog.csdn.net/20170108162515604?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="这里写图片描述" title=""></p>

<ul>
<li><p>Ceph依据节点功能可以将节点划分为4种类型，分别是Client、OSD、Monitor和MDS。每个节点由Dispatcher（消息调度器）集合和Messenger（消息管理器）集合两部分组成。Dispatcher是消息的订阅者，对接收的消息进行处理或者将需要发送的消息移交给本节点Messenger，不同的节点类型和消息类型对应Dispatcher的类型也不同；Messenger是消息的发布者，能将Dispatcher移交的消息发布给其它节点的Messenger或者从其它节点的Messenger接收消息并将其移交给本节点的Dispatcher，实现不同节点之间的消息交互。一个节点根据需求会注册一个或者多个Messenger和多种不同类型的Dispatcher（每种类型一个）。</p></li>
<li><p>以osd类型的节点为例，一个osd节点会创建6个Messenger来管理消息，每个Messenger的用途不一样。比如ms_public主要用于osd和client之间的消息交互，ms_cluster用于osd节点之间的消息交互等等。一个osd节点还会创建3种类型的Dispatcher来处理该节点消息，分别为HeartbeatDispatcher类型，OSD类型和Objecter类型的，其中OSD类型的Dispatcher可以处理部分osd节点的消息。</p></li>
</ul>                                    </div>


版权声明：本文为CSDN博主「hequan_hust」的原创文章，遵循 CC 4.0 BY-SA 版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/zhq5515/article/details/53026451