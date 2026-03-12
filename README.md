# CSVM（CncfStack Virtual Machine）

CSVM（CncfStack Virtual Machine） 是一个基于容器模拟的虚拟机，能够实现类似虚拟机的使用体验。

## 核心特点

- 容器支持systemd 服务管理

## 快速开始

通过 docker 命令可以快速启动 csvm 虚拟机容器

```
docker run -itd \
  --name csvm \
  --hostname csvm \
  --privileged \
  -v /lib/modules:/lib/modules:ro \
  -v csvm-storage:/var \
  -p 10022:22 \
  registry.cncfstack.com/cncfstack/csvm:v0.1.2-bookworm
```

启动成功后，可以通过如下命令进入容器

```
docker exec -it csvm bash
```


## 默认安装的软件包

| 软件包名称 | 功能解释 |
| :--- | :--- |
| **systemd** | 系统和服务管理器，负责系统初始化、服务管理、日志记录等，是现代 Linux 发行版的核心组件 |
| **dbus** | 进程间通信（IPC）系统，允许应用程序之间进行通信和服务调用，是桌面环境和系统服务的基础 |
| **mount** | 用于挂载文件系统的工具，包含在 `util-linux` 包中 |
| **udev** | 设备管理器，动态管理 `/dev` 目录中的设备节点，处理设备的热插拔事件 |
| **kmod** | 用于管理 Linux 内核模块的工具集（如 `lsmod`、`modprobe`、`rmmod` 等） |
| **conntrack** | 连接跟踪工具，用于查看和管理 netfilter 的连接跟踪表 |
| **iptables** | 用户空间工具，用于配置 Linux 内核中的网络包过滤规则（防火墙） |
| **iproute2** | 网络配置工具集（如 `ip`、`tc`、`ss` 等），现代替代 `net-tools` 的网络管理套件 |
| **ethtool** | 用于查询和修改网卡参数的工具，支持查看和调整网络接口的硬件设置 |
| **libseccomp2** | seccomp（安全计算模式）库，用于限制进程可使用的系统调用，增强容器安全性 |
| **bash** | GNU Bourne Again SHell，是 Linux 系统中最常用的命令行解释器 |
| **ca-certificates** | 包含 CA 证书的包，用于验证 SSL/TLS 连接的可信性 |
| **curl** | 命令行工具和库，用于通过 URL 传输数据，支持多种协议（HTTP、FTP 等） |
| **openssl** | 强大的加密工具包，提供 SSL/TLS 协议实现和各种加密算法 |
| **wget** | 非交互式网络下载工具，支持 HTTP、HTTPS、FTP 协议的文件下载 |
| **telnet** | Telnet 客户端，用于远程登录（不安全，建议仅在调试时使用） |
| **gnupg** | GNU Privacy Guard，用于加密、签名和管理密钥的开源实现 |
| **hostname** | 用于查看或设置系统主机名的工具（包含在 `hostname` 包中） |
| **lsb-release** | 显示 Linux 标准基础（LSB）信息的工具，用于识别发行版版本 |
| **sudo** | 允许普通用户以超级用户权限执行命令的工具 |
| **build-essential** | 元包，包含编译软件所需的工具链（gcc、g++、make、dpkg-dev 等） |
| **util-linux** | 包含多种系统实用工具的标准包（如 `mount`、`fdisk`、`kill`、`dmesg` 等） |
| **vim** | 功能强大的文本编辑器，Vi 的改进版，支持语法高亮和插件扩展 |
| **nano** | 简单易用的命令行文本编辑器，适合初学者 |
| **file** | 用于识别文件类型的工具，通过检查文件特征而非扩展名 |
| **unzip** | 用于解压 ZIP 格式压缩文件的工具 |
| **less** | 分页查看工具，支持向前/向后浏览文本文件，比 `more` 功能更强大 |
| **lz4** | 极快的无损压缩算法及其工具，常用于需要高速压缩的场景 |
| **dnsutils** | DNS 诊断工具集（如 `dig`、`nslookup`、`nsupdate`），用于查询 DNS 记录 |
| **lsof** | 列出当前系统打开的文件和进程的工具，用于诊断文件占用问题 |
| **net-tools** | 传统网络工具集（如 `ifconfig`、`route`、`netstat`、`arp`） |
| **iputils-ping** | 提供 `ping` 命令的包，用于测试网络连通性 |
| **openssh-server** | OpenSSH 服务端，允许通过 SSH 协议安全远程登录系统 |
| **git** | 分布式版本控制系统，用于代码管理和协作开发 |
| **python3** | Python 3 解释器，用于运行和开发 Python 程序 |
| **jq** | 命令行 JSON 处理工具，用于解析、过滤和格式化 JSON 数据 |
| **cron** | 定时任务管理工具，用于执行计划任务 |

