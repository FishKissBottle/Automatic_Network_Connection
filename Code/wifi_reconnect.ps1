$ssids = @("shnu 2", "shnu-mobile")  # 你可以在这里列出多个网络名称
$testHost = "10.210.96.1"

# 启动时做一次配置
foreach ($ssid in $ssids) {
    netsh wlan set profileparameter name="$ssid"  interface="Wi-Fi" ConnectionMode=auto useOneX=yes authMode=machineOrUser cacheUserData=yes ssoMode=preLogon | Out-Null
    netsh wlan set allowexplicitcreds allow=yes | Out-Null
    netsh wlan set profiletype name="$ssid" profiletype=all | Out-Null
}

# -n 1：发1次
# -w 3000：等待最多3000ms(3秒)
$pingOut = ping.exe -n 3 -w 3000 $testHost
$ok = ($pingOut | Select-String -Quiet "TTL=")   # 有TTL=基本就代表收到回包

if (-not $ok) {
    # 遍历网络进行连接尝试
    foreach ($ssid in $ssids) {
        Start-Sleep -Seconds 2
        netsh wlan connect name="$ssid" | Out-Null
        Start-Sleep -Seconds 3

        # 第二步：再检查一次是否恢复（按你原来的 3 秒 ping 逻辑也行）
        $pingOut2 = ping.exe -n 2 -w 3000 $testHost
        $ok2 = ($pingOut2 | Select-String -Quiet "TTL=")

        if ($ok2) {
            Write-Host "连接成功到网络：$ssid"
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