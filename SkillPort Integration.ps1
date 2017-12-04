$Logfile = "SkillPort Integration" + $StartTime + ".log"
$ResFile = "SkillPort Integration" + $StartTime + ".result.csv"

function LogWrite
{
   Param ([string]$logstring)
   Add-content $Logfile -value $logstring
}

function ResWrite
{
   Param ([string]$resstring)
   Add-content $ResFile -value $resstring
}
################################################################################################
############################## UD_SubmitReport #################################################

############################################### 
#                      Run                    #
###############################################

$start_time1 = $(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Write-Host "Start Time:" $start_time1
LogWrite "$(Get-Date) Starting..."
ResWrite "FilePath;StartTime;EndTime;ExitResult"
Start-Sleep -Seconds 1

$start_time = $(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Write-Host "Start Time:" $start_time "UD_SubmitReport"
LogWrite "$(Get-Date) Starting...UD_SubmitReport"


[xml]$SOAP = @"
<soapenv:Envelope xmlns:olsa="http:/.......services/olsa_v1_0/" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
   <soapenv:Header>
      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
         <wsu:Timestamp wsu:Id="TS-12346235678qwertyu3234">
            <wsu:Created>2017-11-29T17:20:09.993Z</wsu:Created>
            <wsu:Expires>2017-11-29T17:26:09.993Z</wsu:Expires>
         </wsu:Timestamp>
         <wsse:UsernameToken wsu:Id="UsernameToken-23we4675784542">
            <wsse:Username>XXX</wsse:Username>
            <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">ksdhfclFSYdhfhg1sdk=</wsse:Password>
            <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">ksdhfclFSYdhfhg1sdk==</wsse:Nonce>
            <wsu:Created>2017-11-29T17:20:05.561Z</wsu:Created>
         </wsse:UsernameToken>
      </wsse:Security>
   </soapenv:Header>
   <soapenv:Body>
      <olsa:SubmitReportRequest>
         <olsa:customerId>XXX</olsa:customerId>
         <olsa:report>YYY</olsa:report>
         <olsa:reportFormat>CSV</olsa:reportFormat>
         <olsa:scopingUserId>ZZZ</olsa:scopingUserId>
         <olsa:language>en_US</olsa:language>
         <olsa:duration>2</olsa:duration>
         <olsa:reportParameters>
            <olsa:item>
               <olsa:key>display_options</olsa:key>
               <olsa:value>default</olsa:value>
            </olsa:item>
         </olsa:reportParameters>
      </olsa:SubmitReportRequest>
   </soapenv:Body>
</soapenv:Envelope>
"@

$URL = "https:/.....services/Olsa?WSDL"
$header = @{SOAPAction = "http:/.....services/olsa_v1_0/UD_SubmitReport"}

####### created - expires dates

$startDateUT = $(Get-Date).ToUniversalTime() 
$startDateTS = $startDateUT.AddSeconds(4)
$endDate = $startDateTS.AddMinutes(2)

$idstart  = $startDateTS.tostring("yyyy-MM-ddTHH`:mm`:ss`.fffZ")
$utstart = $startDateUT.tostring("yyyy-MM-ddTHH`:mm`:ss`.fffZ")
$idend = $endDate.tostring("yyyy-MM-ddTHH`:mm`:ss`.fffZ")


############## CreatePasswordDigest

$nonce =1..16 | % {Get-Random -Maximum 250}
$nonce64 = [convert]::ToBase64String($nonce)
$pass = "YYY"

function CreatePasswordDigest
([byte[]] $non, [string] $createdTime, [string] $password)
{
    $enc = [system.Text.Encoding]::UTF8
    $time = $enc.GetBytes($createdTime)
    $pwd = $enc.GetBytes($password)

    $operand = $non+$time+$pwd

    $sha1Hasher = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
    $hashedDataBytes = $sha1Hasher.ComputeHash($operand)
    return [Convert]::ToBase64String($hashedDataBytes)
}

############ change XML
$SOAP.Envelope.Header.Security.Timestamp.Created = $idstart
$SOAP.Envelope.Header.Security.Timestamp.Expires = $idend
$SOAP.Envelope.Header.Security.UsernameToken.Created = $utstart
$SOAP.Envelope.Header.Security.Timestamp.id = $([guid]::NewGuid()).toString(
$SOAP.Envelope.Header.Security.UsernameToken.Id = $([guid]::NewGuid()).toString()
$SOAP.Envelope.Header.Security.UsernameToken.Nonce.InnerText = $nonce64
$SOAP.Envelope.Header.Security.UsernameToken.Password.InnerText = CreatePasswordDigest $nonce $utstart $pass

[xml]$result = Invoke-WebRequest -Uri $url -Body $SOAP -Method POST -ContentType "text/xml" -Headers $header

$reportID = $result.Envelope.Body.HandleResponse.handle

$end_time = $(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Write-Host "End Time:" $end_time "UD_SubmitReport"
LogWrite "reportID $reportID"
LogWrite "$(Get-Date) Ending...UD_SubmitReport"
ResWrite "UD_SubmitReport;$start_time;$end_time"

$end_time1 = $(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Write-Host "End Time:" $end_time1
$TimeDiff = New-TimeSpan $start_time1 $end_time1
    $Diff = "{0:G}" -f $TimeDiff
    $Diff = $Diff.ToString()
    $Diff = $Diff.Substring(0,$Diff.IndexOf('.'))
    Write-Host "Time taken (D:HH:MM:SS):" $Diff

LogWrite "$(Get-Date) Ending..."

