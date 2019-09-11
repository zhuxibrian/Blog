---
title: ceph网络模块-AsyncMessenger组织结构
date: 2019-09-09 10:47:21
tags: [ceph]
---

<div id="content_views" class="markdown_views prism-atom-one-dark">
                    <!-- flowchart 箭头图标 勿删 -->
                    <svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
                        <path stroke-linecap="round" d="M5,0 0,2.5 5,5z" id="raphael-marker-block" style="-webkit-tap-highlight-color: rgba(0, 0, 0, 0);"></path>
                    </svg>
                                            <h2 id="ceph网络模块2-asyncmessenger数据结构分析"><a name="t0"></a>Ceph网络模块(2) - AsyncMessenger数据结构分析</h2>

<hr>

<p>本文主要介绍AsyncMessenger的代码框架结构和主要使用到的数据结构</p>

<p><img src="https://img-blog.csdn.net/20170108164803443?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="这里写图片描述" title=""></p>

<p>上图表示Ceph的AsyncMessenger模块中各个关键类之间的联系。在AsyncMessenger模块中用到的类主要有14个，下面逐一介绍每个类的作用，以及其中包含的主要成员变量和方法。</p>

<hr>

<h2 id="1-asyncmessenger类simplepolicymessenger类和messenger类"><a name="t1"></a>1、 AsyncMessenger类、SimplePolicyMessenger类和Messenger类</h2>

<p>AsyncMessenger类、SimplePolicyMessenger类和Messenger类三者是继承与被继承的关系，Messenger是一个抽象的消息管理器，其主要接口在派生类AsyncMessenger中实现，SimplePolicyMessenger类则是对消息管理器的一些连接的策略进行定义的设置，AsyncMessenger中定义和实现了消息管理器的相关成员变量以及方法。</p>

<p>一个AsyncMessenger实例的关键成员变量以及类方法如下表所示（包括该类继承的父类成员变量以及类方法）。AsyncMessenger包含一个WorkerPool对象、一个Processor实例，以及3个AsyncConnectionRef对象列表和1个ConnectionRef对象列表。</p>

<hr>

<p>AsyncMessenger类中的成员变量:</p>

<div class="table-box"><table class="table table-bordered table-striped table-condensed">
    <tbody><tr><td>成员变量名</td><td>返回值类型</td><td>描述</td></tr>
    <tr><td>*pool</td><td>WorkerPool</td><td>通过pool-&gt;get_worker()从线程池中获取工作线程来进行工作</td></tr>
    <tr><td>processor</td><td>Processor</td><td>Processor实例，主要用来监听连接，绑定socket，接受连接请求等，相当于AsyncMessenger的处理中心</td></tr>
    <tr><td>listen_sd</td><td>       int  </td><td>    定义的监听套接字</td></tr>
     <tr><td>conns</td><td>      ceph::unordered_map(entity_addr_t, AsyncConnectionRef) </td><td>地址和连接的map表，创建一个新的连接时将连接和和地址信息加入到这个map表中，在发送消息时先根据地址对这个map进行一次查找，如果找到了返回连接，如果没有找到创建一个新的连接。</td></tr>
    <tr><td>accepting_conns     </td><td>set(AsyncConnectionRef)      </td><td>接收连接的集合，这个集合主要存放那些已经接收的连接。</td></tr>
    <tr><td>deleted_conns</td><td>      set(AsyncConnectionRef)</td><td>已经关闭并且需要清理的连接的集合</td></tr>
    <tr><td>local_connection</td><td>ConnectionRef</td><td>本地连接的计数器</td></tr>
    <tr><td>did_bind</td><td> bool</td><td> 初始值为false，绑定地址后置为true，stop的时候再次置为false</td></tr>
</tbody></table></div>

<hr>

<p>AsynsMessenger类中的成员方法:</p>

<div class="table-box"><table class="table table-bordered table-striped table-condensed">
    <tbody><tr><td>成员方法名</td><td>返回值类型</td><td>描述</td></tr>
    <tr><td>bind (const entity_addr_t&amp; bind_addr)</td><td>int</td><td>绑定套接字，具体绑定过程是由Processor的bind()函数完成的</td></tr>
    <tr><td>start()</td><td>int</td><td>注册一个AsyncMessenger的实例后，启动这个实例，具体执行过程是WokerPool的start()函数完成的。</td></tr>
    <tr><td>wait()</td><td>void</td><td>等待停止的信号，如果收到停止的信息后，调用Processor的stop()函数，然后将did_bind置为false，最后删除建立的连接</td></tr>
    <tr><td>send_message (Message *m, const entity_inst_t&amp; dest)</td><td>int</td><td>加了一个锁，然后调用_send_message(m, dest)，将消息发送到目的地址</td></tr>
    <tr><td>get_connection (const entity_inst_t&amp; dest)</td><td>ConnectionRef</td><td>函数用来建立连接，判定是否为本地连接，否则再继续查找连接是否已经存在，如果不存在再创建一个连接</td></tr>
    <tr><td>ready()</td><td>void</td><td>注册的AsyncMessenger已经准备好了，启动事件处理中心，开始工作，启动工作线程</td></tr>
    <tr><td>create_connect(const entity_addr_t&amp; addr, int type)</td><td>AsyncConnectionRef</td><td>create一个连接并将其加到conns中</td></tr>
    <tr><td>submit_message(Message *m, AsyncConnectionRef con,const entity_addr_t&amp; dest_addr, int dest_type)</td><td>void</td><td>发送消息的时候会用到，根据目的地址判断需要发送消息的连接是否存在，以及连接是否是本地连接，如果是本地连接，直接对消息进行dispatch，如果连接不存在，需要根据消息类型创建新的连接</td></tr>
    <tr><td>_send_message(Message *m, const entity_inst_t&amp; dest)</td><td>int</td><td>从连接中查找目的地址，然后调用submit_message()发送消息</td></tr>
    <tr><td>add_accept(int sd)</td><td>AsyncConnectionRef</td><td>新建一个连接，然后将其加入到accepting_conns中</td></tr>

</tbody></table></div>

<hr>



<h2 id="2-processor类workerpool类和worker类"><a name="t2"></a>2、   Processor类、WorkerPool类和Worker类</h2>

<hr>

<ul>
<li><p>Processor类相当于AsyncMessenger模块中的一个处理器，AsyncMessenger需要完成的很多操作(start、ready、bind等)都是通过Processor来完成的。当Messenger完成地址绑定后，Processor启动，然后监听即将到来的连接。就是说AsyncMessenger模块的一些启动、绑定、就绪等操作是在Processor相应操作的基础上封装的。</p></li>
<li><p>Processor类定义了一个AsyncMessenger的对象，一个NetHandler的实例，一个Worker对象。</p></li>
</ul>

<p>Processor类的成员变量（方法）：</p>

<div class="table-box"><table class="table table-bordered table-striped table-condensed">
    <tbody><tr><td>成员变量（方法）名</td><td>返回值类型</td><td>描述</td></tr>
    <tr><td>*msgr</td><td>AsyncMessenger</td><td>AsyncMessenger的指针实例，用于调用AsyncMessenger中的成员变量(方法)，用的最多的还是绑定时获取的地址信息等。</td></tr>
    <tr><td>net</td><td>NetHandler</td><td>绑定套接字后将其设置为非阻塞，然后这是套接字选项。</td></tr>
    <tr><td>*worker</td><td>Worker</td><td>工作线程</td></tr>
    <tr><td>listen_sd</td><td>int</td><td>获取套接口描述字的值，非负表示套接字创建成功，-1表示出错</td></tr>
    <tr><td>nonce</td><td>uint64_t</td><td>构造函数中用于entity_addr_t的唯一标识ID</td></tr>
    <tr><td>bind(const entity_addr_t &amp;bind_addr, const set&amp; avoid_ports)</td><td>int</td><td>执行绑定套接字的具体过程</td></tr>
    <tr><td>start(Worker *w)</td><td>int</td><td>执行消息模块的start，具体就是启动线程，让其处于工作状态</td></tr>
    <tr><td>accept()</td><td>void</td><td>建立连接的过程，如果连接建立成功，则通过add_accept()函数将连接加入到accepting_conns集合中</td></tr>
    <tr><td>stop()</td><td>void</td><td>关闭套接字</td></tr>
    <tr><td>rebind(const set&amp; avoid_port)</td><td>int</td><td>如果第一次没有绑定成功或者其它原因导致的绑定失败，执行重新绑定</td></tr>
</tbody></table></div>

<hr>

<ul>
<li><p>WorkerPool类是一个线程池，主要作用是创建worker线程，然后将其放入自己的worker容器中，每次创建worker线程的时候根据配置文件的参数ms_async_op_threads来指定worker线程的数量，创建是在WorkerPool的构造函数中进行的。</p></li>
<li><p>在WorkerPool类中定义了一个worker集合，用于存放worker线程，还定义了一个coreids，用户存放cpu id的集合，提供指定cpu运行单个线程的作用。在配置文件中有一个参数是ms_async_affinity_cores，将创建的worker绑定到指定的cpu core上。如果创建了2个线程，绑定的cpu core是0、1，默认的ms_async_affinity_cores值是空的，即使用全部的cpu资源，如果cpu的资源不够用的时候可以将worker指定cpu core。</p></li>
</ul>

<p>WorkerPool类的成员变量（方法）</p>

<div class="table-box"><table class="table table-bordered table-striped table-condensed">
   <tbody><tr><td>成员变量（方法）名</td><td>返回值类型</td><td>描述</td></tr>
   <tr><td>coreids</td><td>vector</td><td>用于存放CPU id的集合</td></tr>
   <tr><td>WorkerPool(CephContext *c)</td><td>构造函数</td><td>WorkerPool的构造函数，根据ms_async_op_threads的值创建相应数量的worker线程，同时完成worker和cpu core的绑定。</td></tr>
   <tr><td>start()</td><td>void</td><td>创建worker集合中的worker线程，启动线程开始工作</td></tr>
   <tr><td>*get_worker()</td><td>Worker</td><td>获取worker集合中的worker线程</td></tr>
   <tr><td>get_cpuid(int id)</td><td>int</td><td>获取cpu的id</td></tr>
   <tr><td>workers</td><td>Worker*</td><td>Worker线程的集合，WorkerPool在构造函数中创建的worker线程放入到这个集合中</td></tr>
</tbody></table></div>

<hr>

<ul>
<li>Worker类是具体的工作线程，Worker线程的主要工作是一个循环，调用epoll_wait获取需要处理的事件，用循环来处理这个事件，当外部有操作时，比如读取消息，注册一个回调类，创建一个文件事件，然后启动回调操作即可处理请求。消息模块启动时，用一个线程在Worker类中定义了一个WorkerPool对象，一个EventCenter的实例。</li>
</ul>

<p>Worker类的成员变量（方法）</p>

<div class="table-box"><table class="table table-bordered table-striped table-condensed">
   <tbody><tr><td>成员变量（方法）名</td><td>返回值类型</td><td>描述</td></tr>
   <tr><td>*pool</td><td>WorkerPool</td><td>WorkerPool的实例，在entry()函数中用于获取cpu的id</td></tr>
   <tr><td>done</td><td>bool</td><td>如果线程的工作完成置为true，否则false</td></tr>
   <tr><td>center</td><td>EventCenter</td><td>EventCenter的实例，在Worker的构造函数中执行EventCenter的初始化工作</td></tr>
   <tr><td>*entry()</td><td>void</td><td>工作线程的入口函数，启动一个while循环来执行事件的处理，在整个消息模块中就使用了这一个工作线程</td></tr>
   <tr><td>stop()</td><td>void</td><td>将done置为true，然后调用EventCenter的wakeup函数，即停止socket工作</td></tr>
</tbody></table></div>

<hr>



<h2 id="3-asyncconnection类"><a name="t3"></a>3、   AsyncConnection类</h2>

<ul>
<li><p>AsyncConnection是整个Async消息模块的核心，连接的创建和删除、数据的读写指令、连接的重建、消息的处理等都是在这个类中进行的。本小节重点分析了其中的重要成员变量和24个成员函数。</p>

<p>AsyncConnection类的成员变量</p></li>
</ul>

<div class="table-box"><table class="table table-bordered table-striped table-condensed">
   <tbody><tr><td>成员变量名</td><td>返回值类型</td><td>描述</td></tr>
   <tr><td>*async_msgr</td><td>AsyncMessenger</td><td>AsyncMessenger对象，调用一些环境变量等</td></tr>
   <tr><td>out_q</td><td>map（int, list（pair（bufferlist, Message*）） ）</td><td>存放消息和消息map信息的数据结构</td></tr>
   <tr><td>sent</td><td>list（Message*）</td><td>存放那些需要发送的消息</td></tr>
   <tr><td>  local_messages</td><td>list（Message*）</td><td>存放本地传输的消息</td></tr>
   <tr><td>outcoming_bl</td><td>bufferlist</td><td>临时存放消息的bl</td></tr>
   <tr><td>read_handler</td><td>EventCallbackRef</td><td>处理读请求的回调指令</td></tr>
   <tr><td>write_handler</td><td>EventCallbackRef</td><td>处理写请求的回调指令</td></tr>
   <tr><td>connect_handler</td><td>EventCallbackRef</td><td>处理连接请求的回调指令</td></tr>
   <tr><td>local_deliver_handler</td><td>EventCallbackRef</td><td>处理本地连接请求的回调指令</td></tr>
   <tr><td>data_buf</td><td>bufferlist</td><td>存放数据的bl</td></tr>
   <tr><td>data_blp</td><td>bufferlist::iterator</td><td>data_buf的指针</td></tr>
   <tr><td>front, middle, data</td><td>bufferlist</td><td>头部，中间部分和数据部分</td></tr>
   <tr><td>connect_msg</td><td>ceph_msg_connect</td><td>消息连接</td></tr>
   <tr><td>net</td><td>NetHandler</td><td>NetHandler的实例，处理网络连接</td></tr>
   <tr><td>*center</td><td>EventCenter</td><td>EventCenter的对象，用来调用事件中心的操作</td></tr>
   <tr><td>*recv_buf</td><td>char</td><td>用于从套接字中接收消息的buf</td></tr>
</tbody></table></div>

<hr>

<p>AsyncConnection类的成员方法</p>

<div class="table-box"><table class="table table-bordered table-striped table-condensed">
   <tbody><tr><td>编号</td><td>成员方法名</td><td>返回值类型</td><td>描述</td></tr>
   <tr><td>1</td><td>do_sendmsg(struct msghdr &amp;msg, int len, bool more)</td><td>int</td><td>返回的是需要被发送的消息的长度</td></tr>
   <tr><td>2</td><td>try_send(bufferlist &amp;bl, bool send=true)</td><td>int</td><td>加上一个write_lock，然后调用_try_send来真正发送消息</td></tr>
   <tr><td>3</td><td>_try_send(bufferlist &amp;bl, bool send=true)</td><td>int</td><td>如果send的值为false，会将bl添加到send buffer中，这么做的目的是避免messenger线程外发生错误</td></tr>
   <tr><td>4</td><td>prepare_send_message(uint64_t features, Message *m, bufferlist &amp;bl)</td><td>void</td><td>将m中的数据encode和copy到bl中</td></tr>
   <tr><td>5</td><td>read_until(uint64_t needed, char *p)</td><td>int</td><td>循环读，调用read_bulk，如果r的值不为0，一直循环下去</td></tr>
   <tr><td>6</td><td>_process_connection()</td><td>int</td><td>处理连接，根据不同的state状态执行不同的操作，关键点是state的值不同</td></tr>
   <tr><td>7</td><td>_connect()</td><td>void</td><td>首先将STATE_CONNECTING的值赋给state，然后调用dispatch_event_external将read_handler事件添加到external_events集合中</td></tr>
   <tr><td>8</td><td>_stop()</td><td>void</td><td>注销连接，然后将STATE_CLOSED赋给state，关闭套接字，清理事件</td></tr>
   <tr><td>9</td><td>handle_connect_reply(ceph_msg_connect &amp;connect, ceph_msg_connect_reply &amp;r)</td><td>int</td><td>根据reply.tag值的不同执行不同的操作</td></tr>
   <tr><td>10</td><td>handle_connect_msg(ceph_msg_connect &amp;m, bufferlist &amp;aubl, bufferlist &amp;bl)</td><td>int</td><td>处理消息的连接，如果成功则接收这个连接</td></tr>
   <tr><td>11</td><td>discard_out_queue()</td><td>void</td><td>清除AsyncConnection的消息队列</td></tr>
   <tr><td>12</td><td>requeue_sent()</td><td>void</td><td>重新将send队列入队</td></tr>
   <tr><td>13</td><td>handle_ack(uint64_t seq)</td><td>void</td><td>处理确认信息，删除send队列中的message</td></tr>
   <tr><td>14</td><td>write_message(Message *m, bufferlist&amp; bl)</td><td>int</td><td>将消息写到complete_bl中，调用_try_send发送消息</td></tr>
   <tr><td>15</td><td>_reply_accept(char tag, ceph_msg_connect &amp;connect, ceph_msg_connect_reply &amp;replybufferlist authorizer_reply)</td><td>int</td><td>有一个bufferlist结构的reply_bl，调用try_send将reply_bl发送出去</td></tr>
   <tr><td>16</td><td>is_queued()</td><td>bool</td><td>判断是否入队列，主要是out_q和outcoming_bl这两个队列</td></tr>
   <tr><td>17</td><td>shutdown_socket()</td><td>void</td><td>关闭套接字</td></tr>
   <tr><td>18</td><td>connect(const entity_addr_t&amp; addr, int type)</td><td>void</td><td>在AsyncConnection第一次构造的时候使用，然后调用_connect()函数</td></tr>
   <tr><td>19</td><td>accept(int sd)</td><td>void</td><td>将state的值设置为STATE_ACCEPTING，然后调用create_file_event函数创建文件事件，调用dispatch_event_external函数将回调指令分发出去</td></tr>
   <tr><td>20</td><td>send_message(Message *m)</td><td>int</td><td>一般需要发送消息的时候都会调用这个函数进行具体的发送操作，在此之前已经完成了连接</td></tr>
   <tr><td>21</td><td>handle_write()</td><td>void</td><td>使用一个while循环调用write_message将data写入到m中</td></tr>
   <tr><td>22</td><td>process()</td><td>void</td><td>还是根据不同的state值做不同的处理</td></tr>
   <tr><td>23</td><td>local_deliver()</td><td>void</td><td>这个函数主要用来处理本地的消息传递</td></tr>
   <tr><td>24</td><td>cleanup_handler()</td><td>void</td><td>清理事件处理助手，将其重置</td></tr>

</tbody></table></div>

<hr>



<h2 id="4-eventcenter类和eventcallback类"><a name="t4"></a>4、   EventCenter类和EventCallback类</h2>

<ul>
<li>AsyncMessenger消息模块是基于epoll的事件驱动方式，取代了之间每个连接需要建立一个Pipe，然后创建两个线程，一个用来处理消息的接收，另一个用来处理消息的发送，其它操作也是借助线程的方式。不同于SimpleMessenger消息模块，AsyncMessenger消息模块使用了事件，所以需要一个处理事件的数据结构，即EventCenter，用一个线程专门用来循环处理，所有的操作都是通过回调函数来进行的，避免了大量线程的使用。在EventCenter定义了一个FileEvent的数据结构和一个TimeEvent的数据结构，大部分事件都是FileEvent。下面介绍EventCenter中的主要成员变量和方法。</li>
</ul>

<div class="table-box"><table class="table table-bordered table-striped table-condensed">
   <tbody><tr><td>成员变量（方法）名</td><td>返回值类型</td><td>描述</td></tr>
   <tr><td>FileEvent</td><td>struct</td><td>文件事件类</td></tr>
   <tr><td>TimeEvent</td><td>struct</td><td>时间事件类</td></tr>
   <tr><td>external_events</td><td>deque(EventCallbackRef)</td><td>用于存放外部事件的队列</td></tr>
   <tr><td>*file_events</td><td>FileEvent</td><td>FileEvent的实例</td></tr>
   <tr><td>*driver</td><td>EventDriver</td><td>EventDriver的实例</td></tr>
   <tr><td>time_events</td><td>map(utime_t, list(TimeEvent))</td><td>事件事件的容器</td></tr>
   <tr><td>net</td><td>  NetHandler</td><td>NetHandler的实例</td></tr>
   <tr><td>process_time_events()</td><td>int</td><td>处理时间事件</td></tr>
   <tr><td>*_get_file_event(int fd)</td><td>FileEvent</td><td>获取文件事件</td></tr>
   <tr><td>init(int nevent)</td><td>int</td><td>根据不同的宏创建不同的事件处理器；调用create_file_event创建事件。</td></tr>
   <tr><td> create_file_event(int fd, int mask, EventCallbackRef ctxt)</td><td>int</td><td>根据fd和mask创建文件事件，调用add_event函数将创建的事件加入到事件处理器中去处理</td></tr>
   <tr><td>create_time_event(uint64_t milliseconds, EventCallbackRef ctxt)</td><td>uint64_t</td><td>创建time event，然后将其加入到time_events中</td></tr>
   <tr><td>delete_file_event(int fd, int mask)</td><td>void</td><td>删除file event</td></tr>
   <tr><td>delete_time_event(uint64_t id)</td><td>void</td><td>删除time event</td></tr>
   <tr><td>process_events(int timeout_microseconds)</td><td>int</td><td>如果事件是read_cb或者write_cb则调用相应的回调函数来进行处理（由do_request函数来完成）；如果不是这两种事件，则将external_events队列中的事件取出放入cur_process中，调用一个while一个循环来处理。</td></tr>
   <tr><td>dispatch_event_external(EventCallbackRef e)</td><td>void</td><td>将创建的外部事件放入external_events队列中</td></tr>

</tbody></table></div>

<ul>
<li>EventCallback是一个接口类，根据操作不同会定义其子类，使用方式用一个虚函数do_request()来回调处理不同的事件，具体的处理是在do_request()中进行的。</li>
</ul>

<hr>



<h2 id="5-eventdriver类epolldriver类kqueuedriver类和selectdriver类"><a name="t5"></a>5、   EventDriver类、EpollDriver类、KqueueDriver类和SelectDriver类</h2>

<ul>
<li>事件中心相当于一个事件处理的容器，它本身并不真正去处理事件，通过回调函数的方式来完成事件的处理。同样，如何获取需要处理的事件也不是事件中心来完成的，它只负责处理，具体对需要处理的事件的获取是通过EventDriver来完成的，EventDriver是一个接口类，其实现主要是由EpollDriver、KqueueDriver和SelectDriver三个类操作的。Ceph支持多种操作系统的使用，如果使用的是Linux操作系统，使用EpollDriver，如果是BSD，使用KqueueDriver，如果都不是的情况下再使用SelectDriver(系统定义为最坏状况下)。事件驱动的执行主要依赖于epoll的方式，其中主要有三个函数：epoll_create(在epoll文件系统建立了个file节点，并开辟epoll自己的内核高速cache区，建立红黑树，分配好想要的size的内存对象，建立一个list链表，用于存储准备就绪的事件)； epoll_ctl(把要监听的socket放到对应的红黑树上，给内核中断处理程序注册一个回调函数，通知内核，如果这个句柄的数据到了，就把它放到就绪列表)；epoll_wait(观察就绪列表里面有没有数据，并进行提取和清空就绪列表，非常高效)。由于本项目运行在Linux中，所以下面以EpollDriver为例对Ceph的底层事件驱动进行描述。</li>
</ul>

<p>EpollDriver的成员变量（方法）</p>

<div class="table-box"><table class="table table-bordered table-striped table-condensed">
   <tbody><tr><td>成员变量（方法）名</td><td>返回值类型</td><td>描述</td></tr>
   <tr><td>epfd</td><td>int</td><td>epoll的文件描述符</td></tr>
   <tr><td>*events</td><td>struct epoll_event</td><td>epoll_event的一个对象</td></tr>
   <tr><td>size</td><td>int</td><td>在执行初始化时获取文件数量</td></tr>
   <tr><td>init(int nevent)</td><td>int</td><td>执行EpollDriver的初始化，主要是调用epoll_create，建立epoll对象</td></tr>
   <tr><td>add_event(int fd, int cur_mask, int add_mask)</td><td>int</td><td>根据事件的mask执行不同的操作，如果是EVENT_READABLE，表示对应的文件描述符可读，如果是EVENT_WRITABLE，表示文件描述符可写，然后调用epoll_ctl添加事件</td></tr>
   <tr><td>del_event(int fd, int cur_mask, int del_mask)</td><td>int</td><td>调用epoll_ctl执行事件的修改或者删除</td></tr>
   <tr><td>resize_events(int newsize)</td><td>int</td><td>清空事件数量</td></tr>
   <tr><td>event_wait(vector &amp;fired_events, struct timeval *tp)</td><td>int</td><td>调用epoll_wait循环处理事件</td></tr>
</tbody></table></div>

<hr>



<h2 id="6nethandler类"><a name="t6"></a>6、NetHandler类</h2>

<ul>
<li>NetHandler是AsyncMessenger模块中用于网络处理的类，其中定义了6个关键成员方法，其中的NetHandler::generic_connect()是每个连接都需要使用到的，创建socket、将socket设置为非阻塞、设置socket选项等都是经常使用的方法，下表对其详细分析。</li>
</ul>

<div class="table-box"><table class="table table-bordered table-striped table-condensed">
   <tbody><tr><td>成员方法名</td><td>返回值类型</td><td>描述</td></tr>
   <tr><td>create_socket(int domain, bool reuse_addr=false)</td><td>int</td><td>创建socket</td></tr>
   <tr><td>generic_connect(const entity_addr_t&amp; addr, bool nonblock)</td><td>int</td><td>通信双方通过该函数产生连接，首先调用create_socket()创建一个socket，然后将创建的socket设置为非阻塞，完成以后调用系统socket:: connect()建立连接</td></tr>
   <tr><td>set_nonblock(int sd)</td><td>int</td><td>将Socket设置为非阻塞的</td></tr>
   <tr><td>set_socket_options(int sd)</td><td>void</td><td>调用系统的socket::setsockopt函数，设置套接字的一些关键选项</td></tr>
   <tr><td>connect(const entity_addr_t &amp;addr)</td><td>int</td><td>对NetHandler::generic_connect()进行了一个简单的封装</td></tr>
   <tr><td>nonblock_connect(const entity_addr_t &amp;addr)</td><td>int</td><td>接口函数，设置非阻塞的连接</td></tr>

</tbody></table></div>

<hr>

<p>上文描述了AsyncMessenger基本数据结构及框架，下一章描述代码流程。</p>                                    </div>


版权声明：本文为CSDN博主「hequan_hust」的原创文章，遵循 CC 4.0 BY-SA 版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/zhq5515/article/details/54234893
