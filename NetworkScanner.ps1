param (
    [string]$target = "example.com",
    [switch]$stealth
)

function Random-Delay {
    $delay = Get-Random -Minimum 3 -Maximum 10
    Start-Sleep -Seconds $delay
}

$dnsInfo = Resolve-DnsName -Name $target -ErrorAction SilentlyContinue
if ($dnsInfo) {
    $ipAddress = $dnsInfo.IPAddress
    Write-Output "IP Address of ${target}: $ipAddress"
} else {
    Write-Output "Unable to resolve $target"
    exit
}

function Silent-Ping {
    try {
        Invoke-WebRequest -Uri "http://$target" -UseBasicParsing -TimeoutSec 5
        Write-Output "$target is ONLINE"
    } catch {
        Write-Output "$target appears OFFLINE"
    }
}

Silent-Ping

$ports = @(21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995, 1433, 1521, 3306, 3389, 8080)
foreach ($port in $ports) {
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $tcp.Connect($ipAddress, $port)
        Write-Output "Port $port is OPEN on $target"
    } catch {
        Write-Output "Port $port is CLOSED on $target"
    }
    $tcp.Close()

    if ($stealth) {
        Random-Delay
    }
}

$response = Invoke-RestMethod -Uri "http://ip-api.com/json/$ipAddress" -ErrorAction SilentlyContinue
Write-Output "Location: $($response.city), $($response.country) | ISP: $($response.isp)"

Write-Output "Scan Completed"
