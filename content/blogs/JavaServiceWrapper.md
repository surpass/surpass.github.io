---
title: "Java Service Wrapper介绍与应用"
date: 2019-09-10T21:44:58+08:00
author: "Frank Li"
authorlink: "https://www.easyolap.cn/resume/"
translator: "李在超"
pubtype: "Talk"
featured: true
description: "Java Service Wrapper 顾名思义就是将java程序包装成系统程序，这样可以随着系统的运行而运行。换句话说 JSW可以将我们的java后台程序包装成一个后台服务运行。除此之外，JSW还可以在java程序挂掉以后自动拉起服务，相当于提供了一个守护进程。JSW主要目标就是，单点服务尽可能做到高可靠，程序挂了之后立马拉起，这样能够大大降低运维成本。"
tags: ["java服务","JSW","DevOps","运维","daemon","appassembler","maven"]
keywords: ["JSW","java service wrapper","daemon","mavne","DevOps"]
image: "/img/jsw-logo.jpg"
link: "https://wrapper.tanukisoftware.com/doc/english/download.jsp"
fact: "自动化运维工具"
summary: "Java Service Wrapper 顾名思义就是将java程序包装成系统程序，这样可以随着系统的运行而运行。换句话说 JSW可以将我们的java后台程序包装成一个后台服务运行。除此之外，JSW还可以在java程序挂掉以后自动拉起服务，相当于提供了一个守护进程。JSW主要目标就是，单点服务尽可能做到高可靠，程序挂了之后立马拉起，这样能够大大降低运维成本。"
weight: 400
sitemap:
  priority : 0.8
---

> 本文转载自：DevOps小站 官方网站，原文地址：https://www.easyolap.cn/blogs/JavaServiceWrapper 

# Java Service Wrapper 介绍与应用

## 1、概述
使用java开发程序，一般有web应用，后台服务应用，桌面应用：

web应用多数打成war包在web容器（如tomcat,jetty等）中运行
桌面应用一般打成jar包或exe文件运行
后台服务应用一般打成jar包，然后使用命令行（如java -jar xxx.jar）运行
前面两种运行方式在本文不作讨论，主要描述java开发的后台服务程序（如定时任务程序，文件处理，数据备份等）。

###1.1、为什么要用服务形式运行
若使用命令行方式运行java程序，把命令写成脚本（如bat脚本）运行即可，但命令行方式有其不方便之处，如命令行窗口不能关闭，关闭即停止，因此维护人员容易误操作（关闭窗口使程序停止）;若服务器宕机或其它原因，程序往往无法在服务器重启时自动启动。在windows下，很多程序都是以服务的形式运行，这也符合windows的管理。因此，建议使用服务形式运行，操作方便。

### 1.2、如何让java程序以服务形式运行
有几种方法可以让java程序以服务形式运行：

> Java Service Wrapper:目前业界最知名、最成熟的解决方案，添加任何额外的代码即可使用。Yet Another Java Service Wrapper类似JSW的开源实现版本，不过官方支持不怎么好。
> Apache Commons Daemon:著名的Apache Commons工具包的成员，按规则添加启动程序，再编写脚本实现。
> 其它的:（如WinRun4J，Launch4j）未使用过，更多可参考java开源打包工具
> `


        本文主要讲解使用java service wrapper把java程序作为服务运行，它不需要添加任何代码，配置即可。


Java Service Wrapper 顾名思义就是将java程序包装成系统程序，这样可以随着系统的运行而运行。换句话说 JSW可以将我们的java后台程序包装成一个后台服务运行。除此之外，JSW还可以在java程序挂掉以后自动拉起服务，相当于提供了一个守护进程。JSW主要目标就是，单点服务尽可能做到高可靠，程序挂了之后立马拉起，这样能够大大降低运维成本。

　　JSW除了支持 Windows和Linux还支持其他平台，几乎包含了所有的系统环境，十分强大，JSW分为社区版和企业版，社区版开源并且免费，企业版收费但是功能更加强大！

　　特性：1、多平台支持,主支主流的服务器操作系统

　　　　　2、简单的安装步骤，即可将java程序当成后台进程方式运行

　　　　    3、提高Java服务可靠性，当服务挂了立马拉起

　　　　    4、无需编写脚本，灵活配置，可定制化JSW的配置和JVM的配置

　　　　    5、Log功能(针对Java标准控制台输出生成warpper.log)

　　上述内容说到，JSW可以充当我们的守护进程，当服务挂掉以后JSW能够自动拉起(RESTART)，当JVM hung时间过长时，也会将服务重启。

　　JSW两个概念：JSW守护和wrapper。守护进程用来守护我们的应用程序，挂掉后立马拉起。而wrapper实际上就是在我们的应用程序上包装了一层。JSW守护进程会开启一个ServerSocket监听端口（服务端）。而对于wrapper，内部会开启一个Socket（客户端）连接到守护进程的ServerSocket监听端口上。守护进程在wrapper连接上自己以后，就会定期地发送ping包给wrapper，wrapper收到以后，会返回一个包，告诉守护进程自己没问题，I'm ok ! 。若守护进程在一定时间内没有收到wrapper返回的包，则认定JVM（我们的应用程序）hang住了。

以CentOS(linux)系统为例,结合比较常用的maven工具进行打包与发布。

## 2. 下载Wrapper

Wrapper下载地址：http://wrapper.tanukisoftware.com/doc/english/download.jsp
Wrapper几乎支持所有的系统环境，目前最新版本为3.5.40，下载Linux x86 64bit版本。

## 3.示例程序

### 3.1生成启动脚本之前，需要有一个启动的类，示例如下：

```
package cn.easyolap.jsw; 

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class JSWServer {
    public static void main(String[] args) {
        SpringApplication.run(JSWServer.class, args);
    }
}
```

 

### 3.2生成可执行的启动脚本

```
<plugin>
	<groupId>org.codehaus.mojo</groupId>
	<artifactId>appassembler-maven-plugin</artifactId>
	<version>1.10</version>
	<executions>
        <execution>
            <phase>package</phase>
            <goals>
            <goal>generate-daemons</goal>
            <goal>assemble</goal>
            </goals>
            </execution>
    </executions>
	<configuration>
		<!-- 生成linux, windows两种平台的执行脚本 -->
		<platforms>
			<platform>windows</platform>
			<platform>unix</platform>
		</platforms>
		<!-- 根目录 -->
		<assembleDirectory>${project.build.directory}/dist</assembleDirectory>
		<preAssembleDirectory>src/layout</preAssembleDirectory>
		<!-- 打包的jar，以及maven依赖的jar放到这个目录里面 -->
		<repositoryName>lib</repositoryName>
		<!-- 可执行脚本的目录 -->
		<binFolder>bin</binFolder>
		<!-- 配置文件的目标目录 -->
		<configurationDirectory>conf</configurationDirectory>
		<!-- 拷贝配置文件到上面的目录中 -->
		<copyConfigurationDirectory>true</copyConfigurationDirectory>
		<!-- 从哪里拷贝配置文件 (默认src/main/config) -->
		<configurationSourceDirectory>src/main/resources</configurationSourceDirectory>
		<!-- lib目录中jar的存放规则，默认是${groupId}/${artifactId}的目录格式，flat表示直接把jar放到lib目录 -->
		<repositoryLayout>flat</repositoryLayout>
		<encoding>UTF-8</encoding>
		<logsDirectory>logs</logsDirectory>
		<tempDirectory>tmp</tempDirectory>
		<programs>
			<program>
				<id>mall</id>
				<!-- 启动类 -->
				<mainClass>cn.easyolap.jsw.JSWServer</mainClass>
				<jvmSettings>
					<extraArguments>
						<extraArgument>-server</extraArgument>
						<extraArgument>-Xmx2G</extraArgument>
						<extraArgument>-Xms2G</extraArgument>
					</extraArguments>
				</jvmSettings>
			</program>
		</programs>
	</configuration>
</plugin>
```

执行 mvn package  或mvn appassembler:assemble   

执行完成之后，在target/dist目录就有可执行脚本



### 3.3生成后台服务程序

```
<plugin>
	<groupId>org.codehaus.mojo</groupId>
	<artifactId>appassembler-maven-plugin</artifactId>
	<version>1.10</version>
	<configuration>
		<!-- 根目录 -->
		<assembleDirectory>${project.build.directory}/dist</assembleDirectory>
		<!-- 打包的jar，以及maven依赖的jar放到这个目录里面 -->
		<repositoryName>lib</repositoryName>
		<!-- 可执行脚本的目录 -->
		<binFolder>bin</binFolder>
		<!-- 配置文件的目标目录 -->
		<configurationDirectory>conf</configurationDirectory>
		<!-- 拷贝配置文件到上面的目录中 -->
		<copyConfigurationDirectory>true</copyConfigurationDirectory>
		<!-- 从哪里拷贝配置文件 (默认src/main/config) -->
		<configurationSourceDirectory>src/main/resources</configurationSourceDirectory>
		<!-- lib目录中jar的存放规则，默认是${groupId}/${artifactId}的目录格式，flat表示直接把jar放到lib目录 -->
		<repositoryLayout>flat</repositoryLayout>
		<encoding>UTF-8</encoding>
		<logsDirectory>logs</logsDirectory>
		<tempDirectory>tmp</tempDirectory>
		<daemons>
			<daemon>
				<id>beyond</id>
				<mainClass>cn.easyolap.jsw.JSWServer</mainClass>
				<platforms>
					<platform>jsw</platform>
				</platforms>
				<generatorConfigurations>
					<generatorConfiguration>
						<generator>jsw</generator>
						<includes>
							<include>linux-x86-32</include>
							<include>linux-x86-64</include>
							<include>windows-x86-32</include>
							<include>windows-x86-64</include>
						</includes>
						<configuration>
							<property>
								<name>configuration.directory.in.classpath.first</name>
								<value>conf</value>
							</property>
							<property>
								<name>wrapper.ping.timeout</name>
								<value>120</value>
							</property>
							<property>
								<name>set.default.REPO_DIR</name>
								<value>lib</value>
							</property>
							<property>
								<name>wrapper.logfile</name>
								<value>runtime/logs/wrapper.log</value>
							</property>
						</configuration>
					</generatorConfiguration>
				</generatorConfigurations>
				<jvmSettings>
					<!-- jvm参数 -->
					<systemProperties>
						<systemProperty>com.sun.management.jmxremote</systemProperty>
						<systemProperty>com.sun.management.jmxremote.port=1984</systemProperty>
						<systemProperty>com.sun.management.jmxremote.authenticate=false</systemProperty>
						<systemProperty>com.sun.management.jmxremote.ssl=false</systemProperty>
					</systemProperties>
				</jvmSettings>
			</daemon>
		</daemons>
	</configuration>
</plugin>
<plugin>
    <artifactId>maven-assembly-plugin</artifactId>
    <version>2.5.3</version>
    <configuration>
    	<finalName>beyond-${project.version}</finalName>
    	<descriptor>src/assembly.xml</descriptor>
    </configuration>
    <executions>
        <execution>
            <id>create-archive</id>
            <phase>package</phase>
            <goals>
            <goal>single</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

assembly.xml文件内容：

```
<assembly
	xmlns="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.3"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.3 http://maven.apache.org/xsd/assembly-1.1.3.xsd">
	<id>bin</id>
	<baseDirectory>beyond-server</baseDirectory>
	<formats>
		<format>tar.gz</format>
		<format>zip</format>
	</formats>
	<fileSets>
        <fileSet>
            <directory>${project.build.directory}/dist/jsw/antsdb/bin</directory>
            <outputDirectory>/bin</outputDirectory>
            <fileMode>0755</fileMode>
        </fileSet>
        <fileSet>
            <directory>${project.build.directory}/dist/jsw/beyond</directory>
            <outputDirectory>/</outputDirectory>
            <includes>
                <include>**</include>
            </includes>
        </fileSet>
	</fileSets>
</assembly>
```



执行mvn clean package 
执行完成之后，在target\beyond-0.1.0-bin.zip和beyond-0.1.0-bin.tar.gz目录里面就有后台运行的程序



## 4.解压后运行测试

 ./bin/beyond
Usage: ./beyond{ console | start | stop | restart | status | dump }