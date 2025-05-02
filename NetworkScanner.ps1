param (
    [string]$target = "example.com",
    [switch]$stealth
)

function Random-Delay {
    $delay = Get-Random -Minimum 3 -Maximum 10
    Start-Sleep -Seconds $delay
}

# Resolve target to IPv4 address
$dnsInfo = Resolve-DnsName -Name $target -ErrorAction SilentlyContinue
$ipAddress = ($dnsInfo | Where-Object { $_.IPAddress -match '^\d{1,3}(\.\d{1,3}){3}$' }).IPAddress

if (-not $ipAddress) {
    Write-Output "❌ Unable to resolve a valid IPv4 address for $target"
    exit
} else {
    Write-Output "✅ IP Address of $target: $ipAddress"
}

# Check if host is online
function Silent-Ping {
    try {
        $response = Invoke-WebRequest -Uri "http://$target" -Method Head -TimeoutSec 5 -UseBasicParsing
        Write-Output "✅ $target is ONLINE"
    } catch {
        Write-Output "⚠️ $target appears OFFLINE"
    }
}

Silent-Ping

# Port scan with timeout and optional delay
$ports = @(1..1400 + 3389)
foreach ($port in $ports) {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $async = $tcp.BeginConnect($ipAddress, $port, $null, $null)
    $success = $async.AsyncWaitHandle.WaitOne(1000, $false)  # 1-second timeout

    if ($success -and $tcp.Connected) {
        Write-Output "🟢 Port $port is OPEN on $target"
    } else {
        Write-Output "🔴 Port $port is CLOSED on $target"
    }

    $tcp.Close()

    if ($stealth) {
        Random-Delay
    }
}

# Geolocation lookup
$response = Invoke-RestMethod -Uri "http://ip-api.com/json/$ipAddress" -ErrorAction SilentlyContinue
if ($response -and $response.status -eq "success") {
    Write-Output "🌍 Location: $($response.city), $($response.country) | ISP: $($response.isp)"
} else {
    Write-Output "⚠️ Geolocation lookup failed or was rate-limited"
}

Write-Output "✅ Scan Completed"
