#!/usr/bin/env pwsh

param(
    [string]$Action = "start"
)

$ServiceName = "OpenCode"
$ServiceDisplayName = "OpenCode Serve with mDNS"

$OpencodePath = Get-Command opencode -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $OpencodePath) {
    Write-Error "opencode binary not found in PATH"
    exit 1
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges. Restarting with elevated permissions..."
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" $Action" -Verb RunAs
    exit
}

function Install-OpenCodeService {
    $ExecutablePath = "`"$OpencodePath`" serve --mdns --port 4096"
    
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        Write-Host "Service '$ServiceName' already exists. Stopping and removing..."
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        sc.exe delete $ServiceName | Out-Null
        Start-Sleep -Seconds 2
    }
    
    New-Service -Name $ServiceName -BinaryPathName $ExecutablePath -DisplayName $ServiceDisplayName -StartupType Automatic | Out-Null
    Start-Service -Name $ServiceName
    Write-Host "OpenCode serve service installed and started with mDNS support"
}

function Remove-OpenCodeService {
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        sc.exe delete $ServiceName | Out-Null
        Write-Host "OpenCode serve service removed"
    } else {
        Write-Host "Service '$ServiceName' not found"
    }
}

switch ($Action.ToLower()) {
    "start" {
        Install-OpenCodeService
    }
    "stop" {
        Remove-OpenCodeService
    }
    default {
        Write-Error "Unknown action: $Action. Use 'start' or 'stop'."
        exit 1
    }
}
