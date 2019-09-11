---
title: ceph网络模块-AsyncMessenger代码流程分析
date: 2019-09-10 15:15:42
tags: [ceph]
---

<div id="content_views" class="markdown_views prism-atom-one-dark">
                    <!-- flowchart 箭头图标 勿删 -->
                    <svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
                        <path stroke-linecap="round" d="M5,0 0,2.5 5,5z" id="raphael-marker-block" style="-webkit-tap-highlight-color: rgba(0, 0, 0, 0);"></path>
                    </svg>
                                            <h2 id="ceph网络模块3asyncmessenger代码流程分析"><a name="t0"></a>Ceph网络模块(3)——AsyncMessenger代码流程分析</h2>

<hr>



<h2 id="1消息模块的生命周期"><a name="t1"></a>1、消息模块的生命周期</h2>

<p><img src="https://img-blog.csdn.net/20170108191457078?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="消息模块的生命周期" title=""></p>

<p>如图所示以OSD为例描述了消息模块的生命周期，本文如果没有特殊说明均指的是OSD守护进程。在守护进程的main()函数中首先注册并创建了一个Messenger，然后对注册的Messenger进行绑定，绑定后开启消息模块进行工作，消息模块启动后即启动OSD的初始化，在OSD的初始化中让Messenger处于ready状态，即准备工作状态。当消息模块工作结束后处于wait状态，如果需要的话则删除注册的Messenger。这就是消息模块大致的生命周期，下面详细描述一下每个过程的操作。</p>

<p>OSD注册的Messenger实例列表</p>

<div class="table-box"><table class="table table-bordered table-striped table-condensed">
   <tbody><tr><td>编号</td><td>Messenger实例名称</td><td>作用</td></tr>
   <tr><td>1</td><td>*ms_public</td><td>用来处理OSD和Client之间的消息</td></tr>
   <tr><td>2</td><td>*ms_cluster</td><td>用来处理OSD和集群之间的消息</td></tr>
   <tr><td>3</td><td>*ms_hbclient</td><td>用来处理OSD和其它OSD保持心跳的消息</td></tr>
   <tr><td>4</td><td>*ms_hb_back_server</td><td>用来处理OSD接收心跳消息</td></tr>
   <tr><td>5</td><td>*ms_hb_front_server</td><td>用来处理OSD发送心跳消息</td></tr>
   <tr><td>6</td><td>*ms_objecter</td><td>用来处理OSD和Objecter之间的消息</td></tr>

</tbody></table></div>

<ol>
<li>系统根据不同的角色会启动相应的守护进程，如果分配的是OSD这个角色，则通过 ceph_osd.cc这个文件来启动守护进程，首先进入的是main()函数；</li>
<li>在main()函数中会对OSD需要的模块进行注册和初始化，我们主要分析消息模块。在main()函数中注册了6个Messenger的实例，如下表所示。Messenger是一个接口类，根据不同的需求对其进行实现，本文主要从AsyncMessenger来分析。</li>
<li>初始化消息模块后进行绑定。具体执行绑定的是调用AsyncMessenger的bind函数()，实例调用的参数是配置文件中的g_conf-&gt;public_addr和g_conf-&gt;cluster_addr等。AsyncMessenger的bind()函数执行的是Processor::bind()。在Processor的bind函数中真正完成了绑定，Processor的bind函数有两个参数，一个是addr，另一个是port。在Processor的bind函数中主要进行的操作有： <br>
1)  根据bind_addr得出socket的参数family； <br>
2)  创建socket，family参数根据步骤1)获取； <br>
3)  将socket设置为非阻塞； <br>
4)  绑定需要监听的端口； <br>
5)  获取绑定的socket的name； <br>
6)  监听端口。</li>
<li>开启消息模块。在步骤2中create了Messenger，还需要开启它的服务来工作，具体执行是由AsyncMessenger来执行，在create的时候new了一个AsyncMessenger。AsyncMessnger在start函数中调用WorkPool的start来具体执行AsyncMessenger的开启工作。</li>
<li>启动OSD，在这个之前有一个pre启动（int err = osd-&gt;pre_init()），在这个后面还有一个final启动（osd-&gt;final_init();）。执行OSD启动的是osd.cc文件中的init函数，调用Messenger的add_dispatcher_head()函数将响应的消息实例加入到dispatchers的链表中。在add_dispatcher_head()函数中如果是链表中的第一个元素，则执行ready函数。ready函数的具体执行是由AsyncMessenger的ready来实现，通过WorkerPool来获取worker，然后启动事件处理中心来处理事件。启动worker线程，并通知事件处理中心可以开始工作了，主要是事件的create和处理。这个时候AsyncMessenger的机制已经基本全部启动完成，可以进行正常的工作。</li>
<li>注册的Messenger进入wait状态。这个wait和我们平时理解的等待状态不同，wait主要执行的操作是完成清理工作，关闭所有的连接。</li>
<li>执行完wait操作后，删除之前注册的Messenger。</li>
</ol>

<hr>



<h2 id="2消息模块初始化"><a name="t2"></a>2、消息模块初始化</h2>

<p>Monitor/Client/OSD/MDSDaemon四个模块都有相应main()函数，分别在src文件夹目录下的ceph_mon.cc/ceph_fuse.cc/ceph_osd.cc/ceph_mds.cc源码文件中，在各自的main()函数中，各个模块根据需要注册一个或者多个Messenger（Messenger指针指向AsyncMessenger实例），然后在各自的init()初始化函数中调用add_dispatcher_head ()/add_dispatcher_tail ()函数来启动消息模块。消息模块的初始化流程如下图所示。</p>

<p><img src="https://img-blog.csdn.net/20170108192500388?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="消息模块初始化" title=""></p>

<p>上图表示了消息模块初始化时一些关键函数的调用流程，和代码流程大体上是一致的。下面以OSD为例来描述消息模块的初始化流程。</p>

<p>首先在mian()函数中执行启动当前节点需要的一些配置和初始化，其中包括了Messenger和Dispatcher的创建与注册，Monitor/Client/OSD/MDSDaemon都是Dispatcher的子类。Messenger::create()用来创建一个消息处理者Messenger，但实际上创建的是一个AsyncMessenger实例。在main()函数中调用AsyncMessenger::bind()为每一个AsyncMessenger绑定一个用于网络传输的IP地址。在OSD模块的初始化函数init()中，调用add_dispatcher_head()或者add_dispatcher_tail()函数，执行如下操作：</p>

<ul>
<li>将OSD创建的所有Dispatcher添加到Messenger中定义的dispatchers队里中；</li>
<li>调用AsyncMessenger::ready()启动AsyncMessenger。</li>
</ul>

<p>消息模块的初始化主要启动两个模块，一个是EventerCenter（事件中心），事件中心的启动流程在下面小节中详细描述。另一个启动的是AsyncMessenger，调用AsyncMessenger::ready()获取一个工作线程，然后执行Processor::start(Worker *w)进行具体的初始化工作。在EventCenter::create_file_event()中创建文件事件，调用EpollDriver::add_event()，执行epoll_ctl，启动向epoll注册事件，事件中心的EventCenter::process_events()在等待事件的产生。同时Processor::accept()也被执行来准备接收连接。至此，整个消息模块初始化完毕。</p>

<hr>



<h2 id="事件中心的启动"><a name="t3"></a>事件中心的启动</h2>

<p><img src="https://img-blog.csdn.net/20170108192902190?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="事件中心的启动" title=""></p>

<p>在AsyncMessenger网络模块中，采用事件驱动模型，在事件驱动模型中有一个事件处理中心用来处理注册的事件。本节主要描述事件中心（EventCenter）的初始化。 <br>
首先，在OSD守护进程中启动Messenger，由于Messenger是消息处理的一个接口，具体执行是由其子类来完成的，即AsyncMessenger::start()。AsyncMessenger执行启动时完成了工作线程池的启动——WorkerPool::start()，工作线程池根据配置参数ms_async_op_threads（默认值是2）创建对应数量的工作线程Worker。工作线程的作用就是处理事件，在工作线程中定义了一个事件中心EventCenter，事件的具体执行由EventCenter来完成，具体执行函数是EventCenter::process_events()，在函数中主要有以下三个操作：</p>

<ul>
<li>调用EpollDriver的event_wait()函数执行epoll_wait，即epoll的主循环，返回需要处理的事件数量，系统根据epoll_wait返回的值来处理事件；</li>
<li>用一个for循环来处理epoll_wait返回的事件，调用FileEvent *_get_file_event()函数创建一个文件事件，根据文件事件的mask判定操作是读还是写，然后调用相应的回调函数进行处理；</li>
<li>看一下外部事件容器中是否有事件需要处理，如果有，使用一个while循环来处理外部事件，具体处理过程还是调用事件的回调函数。</li>
</ul>

<p>至此，AsyncMessenger和事件中心(EventCenter)都已经启动完毕并且完成了初始化，消息中心也已经进入了工作状态，等待事件的到来并处理。下一节描述消息的接收。</p>

<hr>



<h2 id="3消息的接收"><a name="t4"></a>3、消息的接收</h2>

<hr>



<h2 id="启动消息接收"><a name="t5"></a>启动消息接收</h2>

<p>在消息模块初始化中创建了一个线程，专门用来处理事件，具体来说是通过EventCenter::process_events()函数来执行的。消息模块启动时，EventCenter::process_events()的循环中没有事件来处理，直到Processor::start()函数执行EventCenter::create_file_event()来创建文件事件放入事件中心中去处理。消息的处理也是借由事件来进行的，在EventCenter定义了两个回调指针——read_cb和write_cb，专门用来处理消息的读和写，具体执行由回调子类来实现。当事件到达事件中心处理之前已经封装好了回调操作，根据回调操作执行具体的操作，比如AsyncConnection::process()处理读操作，AsyncConnection::handle_write()处理写操作。</p>

<p>下面主要讲述消息接收的过程。 <br>
<img src="https://img-blog.csdn.net/20170108193503050?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="消息接收启动过程" title=""></p>

<p>消息接收之前，事件中心已经启动了，也就是说启动了事件处理，这时候还没有事件放入到事件中心去处理，事件的产生是通过EventCenter::create_file_event()进行的，所以消息的接收也是以事件的形式操作的，然后调用相应的接收模块来接收消息。</p>

<p>在Processor::start()调用EventCenter::create_file_event()时传递了两个参数，一个是mask的值EVENT_READABLE，告诉事件中心处理消息的读，另一个是回调指针的实例C_processor_accept，事件中心本身不处理具体的操作，都是通过回调函数来处理的。EventCenter::create_file_event()接收事件操作是C_processor_accept实例。在EventCenter::create_file_event()函数中对mask进行判定，如果是EVENT_READABLE，调用相应的回调函数来处理事件，此时的回调类是C_processor_accept，执行的回调操作是接收连接，具体来说就是Processor::accept()，一方面调用标准socket函数accept接收连接，另一方面调用AsyncConnectionRef AsyncMessenger::add_accept()处理连接。AsyncMessenger::add_accept()处理请求时先创建了一个连接AsyncConnection，然后调用AsyncConnection的accept()来接收消息，先将state的值置为STATE_ACCEPTING，然后创建一个接收消息的事件让事件中心处理。事件的maks是EVENT_READABLE，回调操作是read_handler，如果这个时候创建事件这个操作被锁住了，则将消息读操作放入外部事件容器中，等到事件中心处理事件的函数解锁以后会去处理外部事件容器，也会继续处理消息的读操作。</p>

<p>下面主要描述消息的接收状态是如何工作的（STATE_ACCEPTING）。</p>

<hr>



<h2 id="消息接收初始工作流程"><a name="t6"></a>消息接收初始工作流程</h2>

<p><img src="https://img-blog.csdn.net/20170108193738238?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="消息接收初始工作流程" title=""></p>

<p>消息的处理有两个途径，一个是根据事件的mask判定事件是否为EVENT_READABLE，如果Yes将read_cb回调指针指向传入的回调操作，即read_handler。另一个处理途径是当前create_file_event()正在执行别的操作被锁住了，则通过dispatch_event_external()函数将回调操作read_handler放入external_events中，事件处理中心有一个循环在轮询external_events，一旦发现有回调操作放入，则调用相应的回调函数来处理。这两个途径最后都是通过执行read_handler的回调函数来完成消息的读操作。</p>

<p>read_handler的回调操作是调用AsyncConnection::process()处理。在process()中有一个switch操作，根据之前accept()接收的state的值找到相应的执行体，根据state的值进入AsyncConnection::_process_connection()处理。在_process_connection()中新建了一个bufferlist，把CEPH_BANNER添加到bl中，CEPH_BANNER是一个字符串，标识这个消息是ceph的数据。然后通过get_myaddr()获取一个Messenger实例的地址encode到bl中。接着将socket_addr也encode到bl中，调用try_send()执行消息的发送准备工作，try_send()函数执行完成后返回剩余没发送的消息字节的长度，如果返回的值为0，说明消息发送完毕，将stated的值置为STATE_ACCEPTING_WAIT_BANNER_ADDR，如果返回的值大于0，说明消息没有发送完成，将state的值置为STATE_WAIT_SEND。</p>

<p>启动消息的接收以后，消息的接收状态是STATE_ACCEPTING，在这个状态中对消息进行了一些简单的处理，然后将state的值置为STATE_ACCEPTING_WAIT_BANNER_ADDR。类似于TCP的三次握手过程。每个接收状态下消息模块都会对消息进行一些简单的处理操作，比如Open消息，读取其中的头部、中间部分、数据部分，最后读取数据等，下面主要介绍消息接收状态(state)的转换过程，由于每个状态下对消息进行了相应的处理，直到STATE_OPEN_MESSAGE_READ_FOOTER_AND_DISPATCH状态时消息接收完毕。</p>

<hr>



<h2 id="消息接收状态转换图"><a name="t7"></a>消息接收状态转换图</h2>

<p><img src="https://img-blog.csdn.net/20170108193937469?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="消息状态转换图" title=""></p>

<p>如图所示为消息的状态转换图，开始建立连接以后消息的接收状态是STATE_ACCEPTING，在STATE_ACCEPTING状态下将消息加上了CEPH_BANNER这个标识，然后调用try_send()发送出去，成功以后将state的值置为STATE_ACCEPTING_WAIT_BANNER_ADDR。</p>

<p>在STATE_ACCEPTING_WAIT_BANNER_ADDR状态下将CEPH_BANNER和peer_addr读取到state_buffer中，如果成功了将peer_addr加入到addr_bl，addr_bl是一个专门存放地址的链表。有一种可能是对端不清楚他们拥有哪些IP地址，因此需要将socket绑定绑定的IP地址告诉peer_addr，然后根据peer_addr的值调用set_peer_addr()函数建立连接，完成以后将state的值置为STATE_ACCEPTING_WAIT_CONNECT_MSG。</p>

<p>在STATE_ACCEPTING_WAIT_CONNECT_MSG状态下首先读取connect_msg到state_buffer中， <br>
connect_msg是消息连接使用的一种数据结构，里面有一些标识和认证信息。从连接中读出消息的标识后清除这些标识，然后将state的值置为STATE_ACCEPTING_WAIT_CONNECT_MSG_AUTH。</p>

<p>在STATE_ACCEPTING_WAIT_CONNECT_MSG_AUTH状态下首先还是读取消息中的认证信息，然后放到authorizer_bl中，authorizer_bl是一个专门存放标识的bufferlist。然后根据authorizer_bl和authorizer_reply的值调用handle_connect_msg来处理连接。</p>

<p>在AsyncConnection::handle_connect_msg()中首先根据peer_addr判断连接是否存在，如果连接是存在的可以进行后续的操作，对连接进行一些处理，然后调用AsyncConnection::_reply_accept()将回复信息发送给对端，发送信息的时候有一个flag，如果可以接受消息了则将CEPH_MSGR_TAG_SEQ作为flag回复，然后将state的值置为STATE_ACCEPTING_WAIT_SEQ。</p>

<p>在STATE_ACCEPTING_WAIT_SEQ状态下将确认信息读取到state_buffer中，然后根据确认信息对消息进行优先级的设置，如果是高优先级的消息先处理。最后将state的值置为STATE_ACCEPTING_READY，即可以接受消息了。</p>

<p>在STATE_ACCEPTING_READY状态下主要操作是打印accept完成的信息，然后将用于连接的数据结构connect_msg清空，最后把state的值置为STATE_OPEN。</p>

<p>在STATE_OPEN状态下首先读出标识信息tag，如果tag是CEPH_MSGR_TAG_MSG，即读取的是消息的标识，将state的值置为STATE_OPEN_MESSAGE_HEADER，否则进行一些其它的处理。</p>

<p>在STATE_OPEN_MESSAGE_HEADER状态下读出消息的头部，然后进行一些类似CRC的校验工作，如果收到的是坏的消息中断当前的操作，返回错误信息，如果没有问题，将state的值置为STATE_OPEN_MESSAGE_THROTTLE_MESSAGE，进行下一步的消息读取操作。</p>

<p>在STATE_OPEN_MESSAGE_THROTTLE_MESSAGE中对消息进行判断，如果阻塞了则创建一个时间的事件来等待处理，如果正常状态则将state的值置为STATE_OPEN_MESSAGE_THROTTLE_BYTES。</p>

<p>在STATE_OPEN_MESSAGE_THROTTLE_BYTES状态下计算一下当前收到的消息头部的操作，然后加上时间戳，最后将state的值置为STATE_OPEN_MESSAGE_READ_FRONT。</p>

<p>在STATE_OPEN_MESSAGE_READ_FRONT状态下调用read_until()函数将消息的头部（不同于之前的头部校验信息，这个是数据的front部分）读到front中，front是在AsyncConnection中定义的一个bufferlist的结构，专门用于存放消息的头部。完成以后将state的值置为STATE_OPEN_MESSAGE_READ_MIDDLE。</p>

<p>在STATE_OPEN_MESSAGE_READ_MIDDLE状态下和读取头部数据一样，调用read_until()函数将消息的中间部分读取到middle中，middle也是在AsyncConnection中定义的一个bufferlist的结构，专门用于存放消息的中间部分。完成以后将state的值置为STATE_OPEN_MESSAGE_READ_DATA_PREPARE。</p>

<p>在STATE_OPEN_MESSAGE_READ_DATA_PREPARE状态下进行的是读取消息数据部分的准备工作，比如判断接收消息中数据部分的数据结构是不是足够容纳数据，如果现有的申请的接收数据的结构的空间大小不能容纳数据，则重新申请空间大小给其使用，如果可以则不用操作，最后将state的值置为STATE_OPEN_MESSAGE_READ_DATA，真正接收消息中的数据部分。</p>

<p>在STATE_OPEN_MESSAGE_READ_DATA状态下用一个while循环来读取消息携带的数据，直到消息中没有数据可读才跳出循环，在循环中将消息读取到data中，data是在AsyncConnection中定义的一个bufferlist的结构，专门用于存放消息的数据部分。如果一次没有读完则终端当前的操作，等待下一次继续读取数据，最后将将state的值置为STATE_OPEN_MESSAGE_READ_FOOTER_AND_DISPATCH，准备读取消息的尾部然后将消息分发出去。</p>

<p>在STATE_OPEN_MESSAGE_READ_FOOTER_AND_DISPATCH状态下主要读取消息的尾部，然后对读取到的消息进行处理后分发出去让注册的Dispatcher来处理，关于接收到的消息是如何处理的在下一节中主要分析。</p>

<hr>



<h2 id="4消息的处理"><a name="t8"></a>4、消息的处理</h2>

<p><img src="https://img-blog.csdn.net/20170108194250537?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="消息的处理" title=""></p>

<p>如图所示，本小节主要描述消息的处理。经过一系列的状态变换，消息通信的接受端读出了消息中的包含的信息，但是读出的数据大都放在bufferlist中，如果将接收到的消息分发出去，Dispatcher无法处理bufferlist中的数据，因此需要一个将bufferlist中的数据封装成消息Message的过程。然后将封装的Message发送给Dispatcher处理。</p>

<p>在STATE_OPEN_MESSAGE_READ_FOOTER_AND_DISPATCH状态下首先是从消息中读出尾部footer，然后将之前读取到的current_header、front、middle、data一起封装成消息，执行过程是调用Message *decode_message()来完成的，在函数中首先进行CRC校验，如果没有问题根据header中的type定义该类型的消息实例，然后调用Message::set_header()将header封装到消息实例中，调用Message::set_footer()将fooer封装到消息实例中，调用Message:: set_payload()将front封装到消息实例中，调用Message:: set_middle()将middle封装到消息实例中，调用Message:: set_data()将data封装到消息实例中，至此完成了消息的封装，下一步就可以将封装好的消息分发出去了。</p>

<p>封装完消息以后调用Message::set_connection()将当前的连接添加到消息的连接中，然后执行Messenger::ms_fast_preprocess()对消息的分发进行一个预处理，具体执行时注册的Dispatcher来操作的，比如OSD。</p>

<p>预处理完成以后对当前的消息进行一个判断，即当前的消息是不是需要快速派送的消息，如果需要快速派送，调用Messenger::ms_fast_dispatch()，从fast_dispatchers链表中选择注册的Dispatcher，对消息进行快速派发。如果不需要快速派发则调用正常派送流程，调用事件中心创建一个派送消息的事件，创建事件的时候新建一个消息派送类的实例。EventCenter中有一个线程在循环等待处理放入事件中心的事件，当发现需要派送消息时调用消息派送类的回调函数来执行消息的具体派送，函数是Messenger::ms_deliver_dispatch()，Messenger从dispatchers链表中选择注册的Dispatcher对消息进行普通派发。</p>

<hr>



<h2 id="消息的发送"><a name="t9"></a>消息的发送</h2>

<p>如图下图所示为消息发送的基本流程。首先注册的Messenger调用send_message()发送消息，由于Messenger是一个抽象类，具体执行是由AsyncMessenger::send_message()来完成的。在AsyncMessenger::send_message()函数中加入一个Mutex::Locker后调用AsyncMessenger::_send_message()根据目的地址发送消息m。在AsyncMessenger::_send_message()中先寻找创建的连接conn，然后通过conn调用AsyncMessenger::submit_message()来提交消息，在函数中根据之前寻找的conn建立了连接。接着调用AsyncConnection::send_message()发送消息，但是现在消息的形式是Message，如果通过网络进行发送出去，需要一个转换，即将Message转换成网络层可以识别的bufferlist的形式，这个过程是通过AsyncConnection::write_message()来完成的，将消息放到sent这个专门存放消息的链表中，标识哪些是需要发送的消息，然后取出m的header、footer以及数据部分等放入complete_bl中，complete_bl是一个bufferlist，调用AsyncConnection::_try_send()把complete_bl中携带的数据发送出去。bufferlist中的数据并不能直接发送出去，需要将数据放到msghdr这个数据结构中，msghdr是系统提供的一个数据结构，专门用来存放通过套接字发送的信息。然后调用AsyncConnection::do_sendmsg()执行消息的具体发送操作，在函数中有一个循环操作，调用系统函数socket:: sendmsg()发送消息。</p>

<p><img src="https://img-blog.csdn.net/20170108194528085?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="消息发送的基本流程" title=""></p>

<p>上述流程为消息发送的大体脉络流程，下面详细描述消息发送的各个过程。 <br>
如图下图1所示，在AsyncMessenger::_send_message()函数中首先判断传入的目的地址是否为空，如果是空的删除当前消息，返回错误信息，如果是正常的根据目的地址调用AsyncConnectionRef _lookup_conn()寻找连接，即在ceph::unordered_map（entity_addr_t, AsyncConnectionRef） conns中根据目的地址进行定位，如果找到了立即返回conns中的AsyncConnection。然后调用AsyncMessenger::submit_message()执行消息的提交。首先判断连接是否是之前已经建立的，如果是的直接调用AsyncConnection::send_message()函数执行消息的发送。如果连接不存在，判断消息所需的连接是否是本地连接，如果是本地连接直接调用本地连接实例的AsyncConnection::send_message()函数来发送消息。如果连接不是已经存在的，并且消息的连接不是本地连接，需要根据消息发送的目的地址和连接的类型创建一个新的连接，然后用这个新的连接调用AsyncConnection::send_message()函数发送消息。</p>

<p>在AsyncConnection::send_message()函数中准备消息的发送过程如图下图2所示。首先判断消息的连接是否本地连接，如果是本地连接将消息放到local_messages链表中，然后直接调用AsyncConnection::local_deliver()，在函数中对local_messages进行一个判断，如果是空的结束本地传送，否则从local_messages链表中取出消息，设置一下当前的连接状态，设置接收的时间戳等信息，然后判断消息是需要快速派送还是正常途径派送，根据判断的结果执行相应的操作。如果不是本地消息，对消息进行判断是否需要快速派送，如果是快速派送的消息执行AsyncConnection::prepare_send_message()，将消息中的数据添加到bufferlist中。如果正常派送的消息，判断是否需要对消息进行一个处理，处理也是通过AsyncConnection::prepare_send_message()执行的，消息处理完成后调用AsyncConnection::write_message()进行写消息。</p>

<p>图1： <br>
<img src="https://img-blog.csdn.net/20170108194757044?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="建立连接过程" title=""></p>

<p>图2： <br>
<img src="https://img-blog.csdn.net/20170108194904718?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvemhxNTUxNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="这里写图片描述" title=""></p>

<hr>

<p>本文完。</p>                                    </div>


版权声明：本文为CSDN博主「hequan_hust」的原创文章，遵循 CC 4.0 BY-SA 版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/zhq5515/article/details/54236198