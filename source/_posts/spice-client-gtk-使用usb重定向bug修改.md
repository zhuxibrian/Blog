---
title: spice-client-gtk 使用usb重定向bug修改
date: 2018-11-06 15:16:28
tags: [spice]
categories: "spice" #文章分類目錄 可以省略
---

spice-client-gtk在取消usb重定向时,程序会崩溃，今天在修改这个问题时，获得了“剑哥”的大力支持，在此鸣谢！！并且做下记录，以备查询。

在spice-client的usbredir channel中调用了glib的一个宏，传递了libusb的一个函数指针用于释放usb device内存：
```
// spice-client: channel-usbredir.c
        g_clear_pointer(&priv->device, libusb_unref_device);
```
```
// glib: gmem.h
typedef void            (*GDestroyNotify)       (gpointer       data);

#define g_clear_pointer(pp, destroy) \
  G_STMT_START {                                                               \
    G_STATIC_ASSERT (sizeof *(pp) == sizeof (gpointer));                       \
    /* Only one access, please */                                              \
    gpointer *_pp = (gpointer *) (pp);                                         \
    gpointer _p;                                                               \
    /* This assignment is needed to avoid a gcc warning */                     \
    GDestroyNotify _destroy = (GDestroyNotify) (destroy);                      \
                                                                               \
    _p = *_pp;                                                                 \
    if (_p) 								       \
      { 								       \
        *_pp = NULL;							       \
        _destroy (_p);                                                         \
      }                                                                        \
  } G_STMT_END
```
```
//libusb: core.c
#define API_EXPORTED LIBUSB_CALL DEFAULT_VISIBILITY

#if defined(_WIN32) || defined(__CYGWIN__) || defined(_WIN32_WCE)
#define LIBUSB_CALL WINAPI
#else
#define LIBUSB_CALL
#endif

#define WINAPI      FAR PASCAL
#define PASCAL          _pascal

void API_EXPORTED libusb_unref_device(libusb_device *dev) 
{
    ...
    free(dev);
}

```

在glib中，g_clear_pointer按照c的默认调用约定cdecl,而libusb中，如果是在windows下，libusb_unref_device调用约定声明为PASCAL也就是__stdcall，因此由于调用约定的不同，导致在出栈时，栈指针会偏移两次，因此造成堆栈错误，程序崩溃。

为了验证，修改代码如下：
```
// glib: gmem.h
typedef void            (__stdcall *GDestroyNotify_zx)       (gpointer       data);

#define g_clear_pointer_zx(pp, destroy) \
  G_STMT_START {                                                               \
    G_STATIC_ASSERT (sizeof *(pp) == sizeof (gpointer));                       \
    /* Only one access, please */                                              \
    gpointer *_pp = (gpointer *) (pp);                                         \
    gpointer _p;                                                               \
    /* This assignment is needed to avoid a gcc warning */                     \
    GDestroyNotify_zx _destroy = (GDestroyNotify_zx) (destroy);                      \
                                                                               \
    _p = *_pp;                                                                 \
    if (_p) 								       \
      { 								       \
        *_pp = NULL;							       \
        _destroy (_p);                                                         \
      }                                                                        \
  } G_STMT_END
```

```
// spice-client: channel-usbredir.c
        g_clear_pointer_zx(&priv->device, libusb_unref_device);
```
程序不再崩溃。

该问题也借鉴了 https://blog.csdn.net/sghdls/article/details/73693515 的内容


