# PowerShell script to manage Windows service for OpenCode serve with mDNS

$serviceName = "OpenCodeServe"
$binaryPath = "opencode.exe"
$opencodeArgs = "serve --mdns --port 4096"
$action = "start"

foreach ($arg in $args) {
    if ($arg -eq "--stop") {
        $action = "stop"
    }
}

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Relaunching with elevated privileges..."
    $elevatedArgs = @()
    foreach ($arg in $args) {
        if ($arg -ne "--stop") {
            $elevatedArgs += $arg
        }
    }
    if ($action -eq "stop") {
        $elevatedArgs += "--stop"
    }
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"", $elevatedArgs -Verb RunAs
    exit
}

$existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($action -eq "stop") {
    if ($existingService) {
        Write-Host "Stopping and removing service $serviceName..."
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        sc.exe delete $serviceName | Out-Null
        Write-Host "OpenCode serve service removed"
    } else {
        Write-Host "Service $serviceName does not exist"
    }
 } else {
    if ($existingService) {
        Write-Host "Service $serviceName already exists"
        exit 0
    }

    sc.exe create $serviceName binPath= "$binaryPath $opencodeArgs" start= auto DisplayName= "OpenCode Serve with mDNS"
    sc.exe description $serviceName "OpenCode serve service with mDNS support"
    Start-Service -Name $serviceName

    Write-Host "OpenCode serve service installed and started with mDNS support"
}
