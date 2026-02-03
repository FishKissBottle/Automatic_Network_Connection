# 0 说明

最近成功处理了一下断网和远程桌面（RDP）问题，趁着还有清晰的记忆，做一个笔记并浅浅分享一下。

# 1 场景概述

许多学校、公司使用的无线网络的安全类型都属于：WPA2 - 企业，这种类型会在Windows用户切换、RDP接管时出现断开连接的情况，也有时候因为网络波动出现断连的情况。但是诸如爬虫等自动化任务要求网络持续连接，因此，我们需要在网络断开连接时让其重新进行连接，从而避免担心任务因为网络断开而中断报错的情况。

# 2 通过任务计划解决断网

## 2.1 任务创建

简单来说，就是通过让计算机每隔一段时间（比如5分钟）查看去Ping某一地址（可以是网关、也可以是某个特定的网址），如果能够Ping通，就说明网络良好，如果Ping不通，就说明网络已断开，就执行重连程序。

Windows系统提供了“任务计划程序”能够为解决这一问题提供可行的路径。

以Windows11为例，我们可以：

- 右击开始图标→计算机管理→任务计划程序→创建任务

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/创建任务图示.png?raw=1" width="50%" alt="创建任务图示">
</p>

- 在常规下：
  - 设置任务的名称
  - 安全选项卡下：如果是需要通过远程桌面（RDP）来远程操控电脑的话，一定要选择“只在用户登录时运行”，如果选择了“不管用户是否登录都要运行”的话，就我个人的经验来看，会出现RDP一接管，被接管的计算机返回登录界面，网络直接断开的情况。

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/创建任务_常规_图示.png?raw=1" width="50%" alt="创建任务_常规_图示">
</p>

- 在触发器下：
  - 触发器是指：在什么情况下触发目标任务的执行，比如是要一开机就执行一次？还是每隔一段时间执行一次？等等。
  - 点击“新建”按钮，可以新创建一个触发器。
  - 这里可以定义与添加多个触发器，但是最重要的还是图中的第一个触发器，每隔一段时间检测网络是否连通，不连通的话出发任务。当然，也可以新建其他触发器，如图中就创建了一个在计算机启动时执行任务的触发器。

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/创建任务_触发器_图示拼接.png?raw=1" height="260" alt="创建任务_触发器_图示">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/创建任务_触发器_图示拼接2.png?raw=1" height="260" alt="创建任务_触发器_图示2">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/创建任务_触发器_图示拼接3.png?raw=1" height="260" alt="创建任务_触发器_图示3">
</p>

- 在操作下：
  - 操作是指：触发器决定执行任务之后，我们要告诉计算机做什么，在这里就是让它去检测网络是否连通，如果连通则什么也不做，如果不连通，那么重新连接指定的网络。

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/创建任务_操作_图示.png?raw=1" height="260" alt="创建任务_操作_图示">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/创建任务_操作_图示2.png?raw=1" height="260" alt="创建任务_操作_图示2">
</p>

- 在条件下：
  - 如果是笔记本电脑，可以选择将“只有在计算机使用交流电源时才启动此任务”取消勾选。

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/创建任务_条件_图示.png?raw=1" width="50%" alt="创建任务_条件_图示">
</p>

- 点击确定，即可完成任务的设定（有密码的可能还要输入密码才能完成）。

- 可以在“任务计划程序库”中查看到设置好的任务，可以右键，在弹出的选择框中选择是“启用”还是“禁用”等。设置为禁用的话，任务就不会被执行。

## 2.2 WiFi重连操作代码

在操作的流程中，我们使用wscript执行.vbs文件中的代码，在.vbs文件中我们又调用了.ps1文件的代码，.vbs与.ps1文件被存储在C盘Scripts文件夹下，路径与结构如图所示（直接创建.txt文件然后改后缀名就行）：

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/路径与结构图示.png?raw=1" width="50%" alt="路径与结构图示">
</p>

- run_hidden.vbs中的代码：

```
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\Scripts\wifi_reconnect.ps1""", 0, False
```

- wifi_reconnect.ps1中的代码:

```
$ssids = @("WiFi名称1", "WiFi名称2")  # 可以在这里列出多个网络名称
$testHost = "1.1.1.1"			# 输入Ping的地址，可以是网关或者某个网址

# 配置
foreach ($ssid in $ssids) {
    netsh wlan set profileparameter name="$ssid"  interface="Wi-Fi" ConnectionMode=auto useOneX=yes authMode=machineOrUser cacheUserData=yes ssoMode=preLogon | Out-Null
    netsh wlan set allowexplicitcreds allow=yes | Out-Null
    netsh wlan set profiletype name="$ssid" profiletype=all | Out-Null
}

# -w 3000：等待最多3000ms(3秒)
$pingOut = ping.exe -n 3 -w 3000 $testHost
$ok = ($pingOut | Select-String -Quiet "TTL=")   # 有TTL=基本就代表收到回包

if (-not $ok) {
    # 遍历列出的网络进行连接尝试
    foreach ($ssid in $ssids) {
        Start-Sleep -Seconds 2
        netsh wlan connect name="$ssid" | Out-Null
        Start-Sleep -Seconds 3

        # 第二步：再检查一次是否恢复（按你原来的 3 秒 ping 逻辑也行）
        $pingOut2 = ping.exe -n 2 -w 3000 $testHost
        $ok2 = ($pingOut2 | Select-String -Quiet "TTL=")

        if ($ok2) {
            Write-Host "连接成功到网络
            break  # 如果成功连接，跳出循环
        }
    }

    # 如果仍然没有连接上，则执行强制断开和重连
    if (-not $ok2) {
        netsh wlan disconnect | Out-Null
        Start-Sleep -Seconds 3
        foreach ($ssid in $ssids) {
            netsh wlan connect name="$ssid" | Out-Null
            Start-Sleep -Seconds 3
        }
    }
}
```

- Tip1：为什么要嵌套两层进行调用？
  - 当然可以在针对“操作”的设置时直接使用powershell进行执行，如下图所示。但是这样的话，每隔五分钟在任务执行的时候会弹出一个powershell窗口闪一下，然后立刻退出，这非常影响使用体验，因此搭建两层嵌套着调用能避免这个问题。

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/Tips图示.png?raw=1" width="50%" alt="Tips图示">
</p>

```
-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Scripts\wifi_reconnect.ps1"
```

- Tip2：查看网关的方法
  - Win + R，输入ipconfig，将网关填入.ps1文件的$testHost中

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/ipconfig图示.png?raw=1" width="50%" alt="ipconfig图示">
</p>

# 3 WiFi属性设置

我们还要进入无限网络的属性进行相关设置，Windows11和Windows10的进入方式有所差异。

- Win11：点击右下角
  - 高级Wi-Fi网络属性→编辑

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/Wifi设置进入.png?raw=1" width="50%" alt="Wifi设置进入">
</p>

- Win10：控制面板→网络和Internet→查看网络状态和任务→WLAN(XXXX)→无线属性(W)

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/Wifi设置进入4.png?raw=1" width="50%" alt="Wifi设置进入4">
</p>

- 在弹出的“无线网络属性”中：
  - 在“连接”选项卡中，可以考虑勾选“当此网络在范围内时自动连接”以及“即使网络未广播其名称也连接（SSID）”。
  - 在“安全”选项卡中，需要勾选“每次登录时记住此连接的凭据”。
  - 点击“高级设置(D)”，在“802.1X设置”选项卡下，选择“用户或计算机身份验证”（“用户身份验证”也可），可以选择保存一下凭据（WiFi的账号和密码）。
  - 然后网络会被断开，重新连接一下即可（这次连接需要重新输入账号和密码）。

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/Wifi设置进入3.png?raw=1" height="260" alt="Wifi设置进入3">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/Wifi设置进入5.png?raw=1" height="260" alt="Wifi设置进入5">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/Wifi设置进入6.png?raw=1" height="260" alt="Wifi设置进入6">
</p>

# 4 远程桌面（RDP）

如果仅仅是做远程控制的话，Windows自带的远程桌面是一个很好用的免费工具，但是如果需要多个人在一台计算机上做协同的话，那还是建议下载ToDesk、向日葵等远程控制软件。但是远程桌面3389端口存在着漏洞，这也是使用RDP所需了解的风险。

## 4.1 开启远程桌面

- 需要注意的是貌似只有Window专业版才能开启远程桌面
- 进行远程控制以及被远程控制的电脑需均要通过：设置→系统→远程桌面，开启远程桌面功能

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/远程桌面_图示.png?raw=1" width="50%" alt="远程桌面_图示">
</p>

## 4.2 生成XXX.rfp文件

- Win + R，输入mstsc
- 需要输入被远程计算机的IP地址，可以开始远程控制，IP地址依然是通过ipconfig在查询。

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/远程桌面_图示2.png?raw=1" width="50%" alt="远程桌面_图示2">
</p>

- 可以根据网络情况以及需求等进行一些设置

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/远程桌面_图示3.png?raw=1" height="260" alt="远程桌面_图示3">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/远程桌面_图示4.png?raw=1" height="260" alt="远程桌面_图示4">
</p>

## 4.3 开机时自动选择开机账户并输入密码进行登录

上面有提到任务的触发器被设置为：“只在用户登录时运行”，因此对于设置了密码的用户，可以通过修改注册表的方式让计算机启动后自动选择账户，输入密码，并进行登录。

- Win + R，输入“regedit”，打开注册表
- 按以下路径找到：

```
计算机\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
```

- 新建（若已经存在则直接修改即可）3个字符串值
  - 第一个命名为AutoAdminLogon，并设置值为：1
  - 第二个命名为DefaultUserName，并设置值为：你的账户名
  - 第三个命名为DefaultPassWord，并设置值为：你的账户密码

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/自动登录_图示.png?raw=1" width="50%" alt="自动登录_图示">
</p>

- Tips：如果在触发器中额外添加了“启动时”进行执行的话，虽然被远程控制的计算机会在开机时候执行任务连上WiFi，但是一旦RDP进行接管，那么依然会出现网络断开的情况。

## 4.4 内网穿透

有些学校、公司的WiFi网络只有内网IP，不能在公网中进行传播，因此远程桌面无法基于ipconfig查询到的IP地址对处在内网环境中的计算机进行访问，因此需要做内网穿透，将内网IP映射到一个公网可访问的IP上，从而实现对内网服务的外网访问。

那么我比较懒，使用的是SakuraFrp，并非广子，真的在用。如果有友友有更好用的内网穿透技术，还麻烦推荐给我一下，不胜感激！SakuraFrp的使用教程还请查看他们的官网
φ(゜▽゜*)♪

<p align="center">
  <img src="https://github.com/FishKissBottle/Automatic_Network_Connection/blob/main/Pic/远程桌面_图示5.png?raw=1" width="50%" alt="远程桌面_图示5">
</p>
