# CX Infrastructure Pre-Flight Check Script - Simplified
# Windows PowerShell script to run infrastructure checks

param(
    [Parameter(Mandatory=$false)]
    [switch]$Summary
)

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogDir = Join-Path $ScriptDir "logs"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path $LogDir "preflight_$Timestamp.log"

# Create logs directory
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Logging function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - [$Level] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry
}

# Display header
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "CX Infrastructure Pre-Flight Check" -ForegroundColor Blue
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Yellow
Write-Host "Log file: $LogFile" -ForegroundColor Yellow
Write-Host ""

# Server definitions
$Servers = @(
    @{ Name = "cx-llm-01"; IP = "192.168.10.29"; Type = "Chat Models (RTX 4070 Ti SUPER)" },
    @{ Name = "cx-llm-02"; IP = "192.168.10.28"; Type = "Instruct Models (RTX 5060 Ti)" },
    @{ Name = "cx-orc"; IP = "192.168.10.31"; Type = "Embedding Models (RTX 5060 Ti)" }
)

Write-Log "Testing connectivity to all CX AI servers..."

# Test connectivity first
Write-Host "📡 CONNECTIVITY CHECK:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

$ConnectivityResults = @()
foreach ($Server in $Servers) {
    Write-Host "Testing $($Server.Name) ($($Server.IP))..." -ForegroundColor Yellow -NoNewline
    
    $ConnTest = Test-NetConnection -ComputerName $Server.IP -Port 22 -WarningAction SilentlyContinue
    $Status = if ($ConnTest.TcpTestSucceeded) { "✅ Connected" } else { "❌ Failed" }
    
    Write-Host " $Status" -ForegroundColor $(if ($ConnTest.TcpTestSucceeded) { "Green" } else { "Red" })
    Write-Host "  Purpose: $($Server.Type)" -ForegroundColor Gray
    
    $ConnectivityResults += [PSCustomObject]@{
        Name = $Server.Name
        IP = $Server.IP
        Type = $Server.Type
        Connected = $ConnTest.TcpTestSucceeded
    }
    
    Write-Log "$($Server.Name) ($($Server.IP)): $Status"
}

Write-Host ""

# Run detailed checks on accessible servers
Write-Host "🔍 DETAILED SERVER CHECKS:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

foreach ($Server in $ConnectivityResults) {
    if ($Server.Connected) {
        Write-Host "`n📍 Checking $($Server.Name) ($($Server.IP))..." -ForegroundColor Yellow
        Write-Log "Starting detailed check of $($Server.Name)"
        
        # Define checks to run
        $Checks = @{
            "System Info" = "uname -a 2>/dev/null; echo"
            "NVIDIA Driver" = "nvidia-smi --version 2>/dev/null | head -1; echo"
            "GPU Info" = "nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null; echo"
            "CUDA Version" = "nvcc --version 2>/dev/null | grep release | awk '{print \`$NF}'; echo"
            "Python Version" = "python3 --version 2>/dev/null; echo"
            "Miniconda" = "test -f /home/agent0/miniconda3/bin/conda && echo 'Found' ; echo"
            "Ollama Version" = "ollama --version 2>/dev/null; echo"
            "Ollama Service" = "systemctl is-active ollama 2>/dev/null; echo"
            "Model Directory" = "test -d /opt/ai_models && echo 'Exists'; echo"
            "Installed Models" = "ollama list 2>/dev/null | grep -v NAME | head -3; echo"
        }
        
        # Run each check
        foreach ($CheckName in $Checks.Keys) {
            $Command = $Checks[$CheckName]
            $SSHCommand = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 agent0@$($Server.IP) `"$Command`""
            
            try {
                Write-Host "  $CheckName`: " -NoNewline -ForegroundColor Gray
                $Result = Invoke-Expression $SSHCommand 2>$null
                
                if ($Result) {
                    # Determine status icon
                    $Icon = "✅"
                    $Color = "Green"
                    if ($Result -match "Not Found|Check failed|No models") {
                        $Icon = "❌"
                        $Color = "Red"
                    } elseif ($Result -match "Not Running") {
                        $Icon = "⚠️"
                        $Color = "Yellow"
                    }
                    
                    Write-Host "$Icon $Result" -ForegroundColor $Color
                    Write-Log "$($Server.Name) - $CheckName`: $Result"
                } else {
                    Write-Host "❌ No response" -ForegroundColor Red
                    Write-Log "$($Server.Name) - $CheckName`: No response"
                }
            } catch {
                Write-Host "❌ Check failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Log "$($Server.Name) - $CheckName`: Check failed - $($_.Exception.Message)"
            }
        }
        
        # Special check for embedding models on orchestration server
        if ($Server.Name -eq "cx-orc") {
            Write-Host "`n  🎯 EMBEDDING MODELS CHECK:" -ForegroundColor Cyan
            $EmbeddingModels = @("mxbai-embed-large", "nomic-embed-text", "all-minilm:22m")
            
            foreach ($Model in $EmbeddingModels) {
                $ModelCheck = "ollama list 2>/dev/null | grep '$Model'; echo"
                $SSHCommand = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 agent0@$($Server.IP) `"$ModelCheck`""
                
                try {
                    $ModelResult = Invoke-Expression $SSHCommand 2>$null
                    $Icon = if ($ModelResult -and $ModelResult.Trim() -ne "") { "✅" } else { "❌" }
                    $Color = if ($ModelResult -and $ModelResult.Trim() -ne "") { "Green" } else { "Red" }
                    $Status = if ($ModelResult -and $ModelResult.Trim() -ne "") { "Installed" } else { "Not Found" }
                    
                    Write-Host "    $Icon $Model`: $Status" -ForegroundColor $Color
                    Write-Log "$($Server.Name) - $Model`: $Status"
                } catch {
                    Write-Host "    ❌ $Model`: Check failed" -ForegroundColor Red
                }
            }
        }
        
    } else {
        Write-Host "❌ Skipping $($Server.Name) - Not accessible via SSH" -ForegroundColor Red
        Write-Log "$($Server.Name): Skipped due to connectivity issues"
    }
}

# Summary
Write-Host "`n" + "="*70 -ForegroundColor Blue
Write-Host "🎯 CX INFRASTRUCTURE PRE-FLIGHT SUMMARY" -ForegroundColor Blue
Write-Host "="*70 -ForegroundColor Blue

$AccessibleCount = ($ConnectivityResults | Where-Object { $_.Connected }).Count
$TotalCount = $ConnectivityResults.Count

Write-Host "`n📊 CONNECTIVITY SUMMARY:" -ForegroundColor Yellow
Write-Host "  Accessible Servers: $AccessibleCount/$TotalCount" -ForegroundColor White

foreach ($Server in $ConnectivityResults) {
    $Icon = if ($Server.Connected) { "✅" } else { "❌" }
    $Color = if ($Server.Connected) { "Green" } else { "Red" }
    Write-Host "  $Icon $($Server.Name) ($($Server.IP)) - $($Server.Type)" -ForegroundColor $Color
}

Write-Host "`n💡 NEXT STEPS:" -ForegroundColor Yellow
if ($AccessibleCount -eq $TotalCount) {
    Write-Host "  🎉 All servers accessible! Ready for deployment checks." -ForegroundColor Green
    Write-Host "  ▶️  Run deployment: .\Deploy-EmbeddingModels.ps1" -ForegroundColor Cyan
} else {
    Write-Host "  ⚠️  Fix connectivity issues before deployment." -ForegroundColor Red
    Write-Host "  🔧 Check SSH configuration and server status." -ForegroundColor Yellow
}

Write-Host "`n📋 Detailed logs saved to: $LogFile" -ForegroundColor Gray
Write-Host "="*70 -ForegroundColor Blue

Write-Log "Pre-flight check completed"
