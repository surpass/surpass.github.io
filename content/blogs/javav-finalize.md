---
title: "java finalize在高并发应用中安全删除文件的应用"
date: 2019-08-08T21:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "java finalize gc 垃圾回收 安全删除文件"
tags: ["java","finalize","GC"]
keywords: ["java","finalize","GC"]
image: "/img/java.jpg"
link: "https://java.oracle.com"
fact: "java应用笔记"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/javav-finalize

java finalize在高并发应用中安全删除文件的应用


1. finalize的作用


finalize()是Object的protected方法，子类可以覆盖该方法以实现资源清理工作，GC在回收对象之前调用该方法。
finalize()与C++中的析构函数不是对应的。C++中的析构函数调用的时机是确定的（对象离开作用域或delete掉），但Java中的finalize的调用具有不确定性
不建议用finalize方法完成“非内存资源”的清理工作，但建议用于：① 清理本地对象(通过JNI创建的对象)；② 作为确保某些非内存资源(如Socket、文件等)释放的一个补充：在finalize方法中显式调用其他资源释放方法。其原因可见下文[finalize的问题]
2. finalize的问题
一些与finalize相关的方法，由于一些致命的缺陷，已经被废弃了，如System.runFinalizersOnExit()方法、Runtime.runFinalizersOnExit()方法
System.gc()与System.runFinalization()方法增加了finalize方法执行的机会，但不可盲目依赖它们
Java语言规范并不保证finalize方法会被及时地执行、而且根本不会保证它们会被执行
finalize方法可能会带来性能问题。因为JVM通常在单独的低优先级线程中完成finalize的执行
对象再生问题：finalize方法中，可将待回收对象赋值给GC Roots可达的对象引用，从而达到对象再生的目的
finalize方法至多由GC执行一次(用户当然可以手动调用对象的finalize方法，但并不影响GC对finalize的行为)
3. finalize的执行过程(生命周期)

(1) 首先，大致描述一下finalize流程：当对象变成(GC Roots)不可达时，GC会判断该对象是否覆盖了finalize方法，若未覆盖，则直接将其回收。否则，若对象未执行过finalize方法，将其放入F-Queue队列，由一低优先级线程执行该队列中对象的finalize方法。执行finalize方法完毕后，GC会再次判断该对象是否可达，若不可达，则进行回收，否则，对象“复活”。
(2) 具体的finalize流程：
对象可由两种状态，涉及到两类状态空间，一是终结状态空间 F = {unfinalized, finalizable, finalized}；二是可达状态空间 R = {reachable, finalizer-reachable, unreachable}。各状态含义如下：
unfinalized: 新建对象会先进入此状态，GC并未准备执行其finalize方法，因为该对象是可达的
finalizable: 表示GC可对该对象执行finalize方法，GC已检测到该对象不可达。正如前面所述，GC通过F-Queue队列和一专用线程完成finalize的执行
finalized: 表示GC已经对该对象执行过finalize方法
reachable: 表示GC Roots引用可达
finalizer-reachable(f-reachable)：表示不是reachable，但可通过某个finalizable对象可达
unreachable：对象不可通过上面两种途径可达


示例伪代码：

```

```

public class ParquetFile {
//部分属性略

private int refCnt = 1;//引用计数器

 	public synchronized void addRefCoun() {
        refCnt = refCnt + 1;
    }
    
    public synchronized void subRefCoun() {
        refCnt = refCnt - 1;
    }
    
    public synchronized int getRefCoun() {
       return refCnt;
    }


	@Override
	public void finalize() {
	       //在此删除文件
	}
}

```

```

public class GcTest{
在此只是测试用，在多线程应用中当文件没有被引用时即引用计数器为0时，系统GC时即会调用对象的finalize()方法，实现安全的删除文件。
     public static void main(String[] args) throws Exception {
         ParquetFile fileRef = new ParquetFile("test.par");
         ParquetFileManager.getInstance().addRef(fileRef);
         //someint proce code
         

         ParquetFileManager.getInstance().removeRef("test.par")
         
         System.gc();  
         Thread.sleep(5000);
     }

}
```