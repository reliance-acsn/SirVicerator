<# 
Sir Vicerator - v1.0

Author: Thomas Beeney

Sir Vicerator is a service over-privilege enumeration script to enumerate services running as system on Windows Hosts.  
It retrieves service data and puts raw output to csv format. Then checks the output for commonly overly permissive services
which if compromised could be used to gain further privilege on the host.

The tool can be used in offensive engagements for post compromise audit and evidence collection and by system administrators looking to harden their environment.

#>


<# Display the Banner#>
Write-Host "`n`n`n 
       _____       _   ___                  __          
      / __(_)___  | | / (_)______ _______ _/ /____  ____ 
      _\ \/ / __/ | |/ / / __/ -_) __/ _ /  __/ _ \/ __/
     /___/_/_/    |___/_/\__/\__/_/  \_,_/\__/\___/_/



       @Relianceacsn
       Serious about Technology, Passionate about People `n`n` 

" ; 
<# Stop on error#>
$ErrorActionPreference = "Stop"

$err = 0
$path = ''

function Setup{

<#Prompt user for inputs#>

Write-Host '[*] Input unique identifier for this Instance. (if required)' -Foregroundcolor Yellow ;
$uid = Read-Host

<# Setup an output directory #>

$script:path = "$env:HomeDrive$env:HomePath\sirvicerator\$uid"
If(!(test-path $path))
   {
    New-Item -ItemType Directory -Force -Path $path | Out-Null ;
   } #end if
If (!(test-path $path\raw))
    {
    New-Item -ItemType Directory -Force -Path $path\raw | Out-Null ;
    } #end if
   <#Check if hosts.txt exists#>
Write-Host "[*] Checking for hosts.txt in $env:HomeDrive$env:HomePath" -ForegroundColor Yellow

if (Test-Path $env:HomeDrive$env:HomePath\hosts.txt) {
    
    Write-Host "[+] hosts.txt found" -ForegroundColor Green

    }
    else {
    Write-Host "[-] hosts.txt not found in $env:HomeDrive$env:HomePath" -ForegroundColor Red
    Write-Host "[*] Creating hosts.txt in $env:HomeDrive$env:HomePath and populating with localhost" -ForegroundColor Yellow
    Write-Host "[+] Testing localhost ONLY" -ForegroundColor Green
    New-Item -Path $env:HomeDrive$env:HomePath\hosts.txt -Value localhost | Out-Null
    }
    

}

Setup;


function Collect {


    <# Code to run #>

    foreach($line in Get-Content $env:HomeDrive$env:HomePath\hosts.txt) #Iterate through your ips file
        { 
            <#Test Connectivity before we attempt to extract services#>
		if (Test-Connection -Cn $line -BufferSize 16 -Count 1 -ea 0 -Quiet)
		{
                <# Print status to console for progress #>
			Write-Host "[*] Collecting Services From: $line" -ForegroundColor Yellow;
			
			try
			{
				
                <# Get services which are running as System #>				
				Get-WmiObject -ComputerName $line "Win32_Service" -Filter "StartName='localSystem'" |
				
                <# grab the required columns and import the Path which isnt a default attribute through the expression #>
				select @{ Label = "Host"; Expression = { $line } }, DisplayName, startname, @{ Name = "Path"; Expression = { $_.PathName }  } | Where { $_.Path -notmatch "WINDOWS" } |
				
                <# Exports the results for each server #>
				Export-Csv -NoTypeInformation -Path $path\raw\$line-services.csv
				
                <# Print status to the console for progress #>
				Write-Host "[+] Finished Collecting Service Data From Host $line" -Foregroundcolor Green;
				
				echo $path\raw\$line-services.csv | Out-File $path\files.txt -Append
			}
			catch
			{
				Write-Host "[-] Something went wrong collecting host data" -Foregroundcolor Red;
                $ErrorLog = "$path\Errors.txt"
                echo "Error $line : " $Error[0].Exception | Out-File $ErrorLog -Append
                $script:err = 1
			}
		} #end if
		Else
		{
            <# Catch an error if the host couldnt be reached (prevents powershell hanging while attemtping to connect to dead hosts)#>
			Write-Host "[x] Could not connect to host $line" -ForegroundColor Red;
		}
	} #end foreach

    Write-Host "[*] Finished Hosts!" -ForegroundColor Yellow;
}

Collect;

<# Print the Risks #>
Write-Host "`n`n`n[*] Issues:" -ForegroundColor Magenta;

<# These two lists need to be ordered the same as it draws the index ID of the array to marry the Search term to the Service Name#>

$SearchTerm = @(
'sqlservr.exe'
'tomcat\d.exe'
'jbosssvc.exe'
'appServService.exe'
'mysqld.exe'
'httpd.exe'
'pg_ctl.exe'
'fbserver.exe'
'mongod.exe'
)

$ServiceName = @(
'Microsoft SQL Database Server'
'Apache Tomcat Web Server'
'JBoss Server'
'GlassFish Web Server'
'MySQL Database Server'
'Apache Web Server'
'Postgres SQL Database Server'
'FireBird Database Server'
'MongoDB Database Server'
)

<#function to reduce code #>

function SearchIssues
{
try{
	$i = -1    
	foreach($term in $SearchTerm){
        try{
        
            foreach ($f in Get-Content $path\files.txt){
                $issue = $null
                <# Import the CSV file of services for each host, Find the string within the files, convert the results back to CSV, Output them to a csv file without type information, then convert the results back so they display on the screen nicely... Phew! #>
                $issue = @(Import-CSV $f | Where { $_.Path -match $term }  | ConvertTo-Csv -NoTypeInformation | Tee-Object -Append -File $path\Temp.csv | ConvertFrom-Csv)
                $issueArray += $issue          
            }  #end for each
            $i++  
            if($issueArray -ne $null){
            Write-Host -Foregroundcolor Yellow "`n[*] "$ServiceName[$i]" Services:"
            $issueArray | Format-Table -Autosize
            $issueArray = $null
            } else {}
         }
         catch{
         }
    }
}
catch{
    Write-Host -ForegroundColor Red "[-] No Hosts were contacted."
    }
}

SearchIssues;

function TidyUp {
    <# Tidy up files.txt and Temp.csv#>
    if (!(Test-Path $path\files.txt)){ }
    Else {
    Remove-Item -Path $path\files.txt
    }
    if (!(Test-Path $path\Temp.csv)){ } 
    else {
    Remove-Item -Path $path\Temp.csv
    }
 }

 function OperationComplete{
    <# Remove  Header rows from temp csv file and output as Results.csv#>

    if (!(Test-Path $path\Temp.csv)){
    Write-Host -Foregroundcolor Green "[+] No Issues Identified `n";
    } else {
    Import-Csv $path\Temp.csv | Where { $_.Host -notmatch "Host" } | Export-CSV -NoTypeInformation -Path $path\Results.csv

    <# Print Operation Complete and advise user of raw data location#>
    Write-Host -Foregroundcolor Magenta "[*] Operation Success: "
    
    Write-Host -Foregroundcolor Cyan "[+] Results are stored in $($path)Results.csv`n"
    Write-Host -Foregroundcolor Cyan "[INFO] The above Results are commonly exploited to gain elevation of privlege; Check RAW data for all potentially over-privileged services `n"

    }
        Write-Host -Foregroundcolor Green "[+] Raw data is stored in $($path)raw Directory.`n"
    if ($err -eq 1){ 
    Write-Host -Foregroundcolor Yellow "[WARN] One or more errors occured while collecting host data. `n[WARN] Check $($path)Errors.txt for detailed Error Log."
    } else {}
    TidyUp;
}

OperationComplete;
