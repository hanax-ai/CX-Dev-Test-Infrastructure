# CX Infrastructure Pre-Flight Check Script
# Windows PowerShell script to run comprehensive infrastructure checks

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerFilter = "ai_servers",
    
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
function Show-Header {
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host "CX Infrastructure Pre-Flight Check" -ForegroundColor Blue
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Yellow
    Write-Host "Checking: $ServerFilter servers" -ForegroundColor Yellow
    Write-Host "Log file: $LogFile" -ForegroundColor Yellow
    Write-Host ""
}

# Check prerequisites
function Test-Prerequisites {
    Write-Log "Checking prerequisites for pre-flight check..."
    
    # Check if we have the inventory file
    $InventoryFile = Join-Path $ScriptDir "inventory\hosts.yml"
    if (!(Test-Path $InventoryFile)) {
        Write-Log "ERROR: Inventory file not found at $InventoryFile" "ERROR"
        return $false
    }
    
    # Check if we have the playbook
    $PlaybookFile = Join-Path $ScriptDir "playbooks\preflight-checks.yml"
    if (!(Test-Path $PlaybookFile)) {
        Write-Log "ERROR: Pre-flight playbook not found at $PlaybookFile" "ERROR"
        return $false
    }
    
    Write-Log "Prerequisites check passed" "SUCCESS"
    return $true
}

# SSH command execution for individual server checks
function Test-ServerConnectivity {
    Write-Log "Testing connectivity to all servers..."
    
    # Read inventory and test each server
    $ServersToTest = @(
        @{ Name = "cx-llm-01"; IP = "192.168.10.29"; Type = "Chat Models" },
        @{ Name = "cx-llm-02"; IP = "192.168.10.28"; Type = "Instruct Models" },
        @{ Name = "cx-orc"; IP = "192.168.10.31"; Type = "Embedding Models" }
    )
    
    $ConnectivityResults = @()
    
    foreach ($Server in $ServersToTest) {
        Write-Host "Testing $($Server.Name) ($($Server.IP))..." -ForegroundColor Yellow
        
        $ConnTest = Test-NetConnection -ComputerName $Server.IP -Port 22 -WarningAction SilentlyContinue
        $Status = if ($ConnTest.TcpTestSucceeded) { "✅ Connected" } else { "❌ Failed" }
        
        $ConnectivityResults += [PSCustomObject]@{
            Server = $Server.Name
            IP = $Server.IP
            Type = $Server.Type
            Status = $Status
            Accessible = $ConnTest.TcpTestSucceeded
        }
        
        Write-Log "$($Server.Name): $Status"
    }
    
    return $ConnectivityResults
}

# Run comprehensive checks using Ansible (if available) or SSH commands
function Invoke-PreFlightChecks {
    Write-Log "Starting comprehensive pre-flight checks..."
    
    # First test basic connectivity
    $ConnectivityResults = Test-ServerConnectivity
    
    Write-Host "`n📋 CONNECTIVITY SUMMARY:" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    foreach ($Result in $ConnectivityResults) {
        $Color = if ($Result.Accessible) { "Green" } else { "Red" }
        Write-Host "  $($Result.Server) ($($Result.IP)): $($Result.Status)" -ForegroundColor $Color
        Write-Host "    Purpose: $($Result.Type)" -ForegroundColor Gray
    }
    
    # Check if Ansible is available
    $AnsibleAvailable = $false
    try {
        $AnsibleVersion = Invoke-Expression "ansible --version 2>$null" -ErrorAction SilentlyContinue
        if ($AnsibleVersion -and $AnsibleVersion.Contains("ansible")) {
            $AnsibleAvailable = $true
            Write-Log "Ansible detected - using comprehensive playbook checks"
        }
    } catch {
        Write-Log "Ansible not available - using basic SSH checks"
    }
    
    if ($AnsibleAvailable) {
        # Run Ansible playbook
        Write-Host "`n🚀 Running Ansible Pre-Flight Checks..." -ForegroundColor Green
        
        $AnsibleCommand = "ansible-playbook -i `"$($ScriptDir)\inventory\hosts.yml`" `"$($ScriptDir)\playbooks\preflight-checks.yml`""
        Write-Log "Executing: $AnsibleCommand"
        
        try {
            $PlaybookResult = Invoke-Expression $AnsibleCommand
            Write-Log "Ansible playbook completed successfully" "SUCCESS"
            return $PlaybookResult
        } catch {
            Write-Log "Ansible playbook failed: $($_.Exception.Message)" "ERROR"
            Write-Host "❌ Ansible playbook failed. Falling back to basic checks..." -ForegroundColor Red
        }
    }
    
    # Fallback to basic SSH checks
    Write-Host "`n🔍 Running Basic SSH Checks..." -ForegroundColor Yellow
    $BasicResults = @()
    
    foreach ($Result in $ConnectivityResults) {
        if ($Result.Accessible) {
            Write-Host "`nChecking $($Result.Server)..." -ForegroundColor Yellow
            
            # Basic checks via SSH
            $Checks = @{
                "NVIDIA Driver" = "nvidia-smi --version 2>/dev/null | head -1 || echo 'Not Found'"
                "CUDA Version" = "nvcc --version 2>/dev/null | grep release || echo 'Not Found'"
                "Ollama Status" = "ollama --version 2>/dev/null || echo 'Not Found'"
                "Model Directory" = "ls -la /opt/ai_models 2>/dev/null | head -1 || echo 'Not Found'"
                "System Info" = "uname -a"
            }
            
            $ServerResults = @{
                Server = $Result.Server
                IP = $Result.IP
                Checks = @{}
            }
            
            foreach ($CheckName in $Checks.Keys) {
                $Command = $Checks[$CheckName]
                $SSHCommand = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 agent0@$($Result.IP) `"$Command`""
                
                try {
                    $CheckResult = Invoke-Expression $SSHCommand -ErrorAction SilentlyContinue
                    $ServerResults.Checks[$CheckName] = $CheckResult
                    Write-Host "  $CheckName`: " -NoNewline -ForegroundColor Gray
                    Write-Host $CheckResult -ForegroundColor White
                } catch {
                    $ServerResults.Checks[$CheckName] = "Check Failed"
                    Write-Host "  $CheckName`: Check Failed" -ForegroundColor Red
                }
            }
            
            $BasicResults += $ServerResults
        } else {
            Write-Host "❌ Skipping $($Result.Server) - Not accessible" -ForegroundColor Red
        }
    }
    
    return $BasicResults
}

# Generate summary report
function Show-Summary {
    param($Results)
    
    Write-Host "`n" + "="*60 -ForegroundColor Blue
    Write-Host "🎯 CX INFRASTRUCTURE PRE-FLIGHT SUMMARY" -ForegroundColor Blue
    Write-Host "="*60 -ForegroundColor Blue
    
    if ($Results -is [Array] -and $Results.Count -gt 0 -and $Results[0].PSObject.Properties.Name -contains "Checks") {
        # Basic results format
        foreach ($ServerResult in $Results) {
            Write-Host "`n📍 $($ServerResult.Server) ($($ServerResult.IP)):" -ForegroundColor Cyan
            foreach ($Check in $ServerResult.Checks.Keys) {
                $Status = $ServerResult.Checks[$Check]
                $Icon = if ($Status -ne "Not Found" -and $Status -ne "Check Failed") { "✅" } else { "❌" }
                Write-Host "   $Icon $Check`: $Status" -ForegroundColor White
            }
        }
    }
    
    Write-Host "`n🏁 Pre-flight check completed!" -ForegroundColor Green
    Write-Host "📋 Detailed logs saved to: $LogFile" -ForegroundColor Yellow
    Write-Host "`n💡 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Review the results above" -ForegroundColor White
    Write-Host "   2. Address any missing components" -ForegroundColor White
    Write-Host "   3. Run deployment when ready: .\Deploy-EmbeddingModels.ps1" -ForegroundColor White
    Write-Host "="*60 -ForegroundColor Blue
}

# Main execution
function Main {
    Show-Header
    
    if (Test-Prerequisites) {
        Write-Log "Starting pre-flight checks for $ServerFilter"
        $Results = Invoke-PreFlightChecks
        
        if ($Summary -or $true) {  # Always show summary for now
            Show-Summary -Results $Results
        }
        
        Write-Log "Pre-flight check completed successfully" "SUCCESS"
    } else {
        Write-Host "❌ Prerequisites check failed." -ForegroundColor Red
        exit 1
    }
}

# Execute main function
Main
