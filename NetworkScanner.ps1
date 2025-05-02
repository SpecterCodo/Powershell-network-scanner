param (
    [string]$target = "example.com",
    [switch]$stealth
)

function Random-Delay {
    Start-Sleep -Seconds (Get-Random -Minimum 3 -Maximum 10)
}

# Resolve DNS
try {
    $ipAddress = [System.Net.Dns]::GetHostAddresses($target) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1
    if (-not $ipAddress) { throw "No IPv4 address found" }
    Write-Output "✅ Target IP for ${target}: $ipAddress"
} catch {
    Write-Output "❌ Failed to resolve $target"
    exit
}

# Ports 1-1200 + 3389
$ports = @(1..1200) + 3389

# Reliable TCP port test
function Test-Port {
    param (
        [string]$ip,
        [int]$port,
        [int]$timeout = 1000
    )

    $client = New-Object System.Net.Sockets.TcpClient
    $async = $client.BeginConnect($ip, $port, $null, $null)
    $success = $async.AsyncWaitHandle.WaitOne($timeout, $false)

    if ($success -and $client.Connected) {
        $client.EndConnect($async)
        $client.Close()
        return $true
    } else {
        $client.Close()
        return $false
    }
}

Write-Output "`n🔍 Starting port scan on ${target}..."
foreach ($port in $ports) {
    $isOpen = Test-Port -ip $ipAddress.IPAddressToString -port $port
    if ($isOpen) {
        Write-Output "🟢 Port $port is OPEN"
    } else {
        Write-Output "🔴 Port $port is closed"
    }

    if ($stealth) {
        Random-Delay
    }
}

# Geolocation info
$response = Invoke-RestMethod -Uri "http://ip-api.com/json/$($ipAddress.IPAddressToString)" -ErrorAction SilentlyContinue
if ($response -and $response.status -eq "success") {
    Write-Output "`n🌍 Location: $($response.city), $($response.country) | ISP: $($response.isp)"
} else {
    Write-Output "⚠️ GeoIP lookup failed"
}

Write-Output "`n✅ Scan completed."
