# CX Embedding Models Deployment - PowerShell Script
# Windows-compatible deployment automation

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("deploy", "verify", "dry-run")]
    [string]$Action = "deploy",
    
    [Parameter(Mandatory=$false)]
    [string]$ServerIP = "192.168.10.31",
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "agent0",
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogDir = Join-Path $ScriptDir "logs"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path $LogDir "deployment_$Timestamp.log"

# Embedding models to install
$EmbeddingModels = @(
    @{ Name = "mxbai-embed-large"; Size = "334M"; Description = "Large embedding model for high-quality text representations" },
    @{ Name = "nomic-embed-text"; Size = "137M"; Description = "Efficient text embedding model" },
    @{ Name = "all-minilm:22m"; Size = "22M"; Description = "Lightweight embedding model for fast inference" }
)

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
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "CX Embedding Models Deployment" -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Yellow
    Write-Host "Server: $ServerIP" -ForegroundColor Yellow
    Write-Host "Action: $Action" -ForegroundColor Yellow
    Write-Host "Log file: $LogFile" -ForegroundColor Yellow
    Write-Host ""
}

# Check prerequisites
function Test-Prerequisites {
    Write-Log "Checking prerequisites..."
    
    # Check if SSH is available (Windows 10/11 has built-in SSH)
    if (!(Get-Command ssh -ErrorAction SilentlyContinue)) {
        Write-Log "ERROR: SSH is not available. Please install OpenSSH or use WSL." "ERROR"
        return $false
    }
    
    # Check connectivity
    Write-Log "Testing connectivity to server $ServerIP..."
    $ConnTest = Test-NetConnection -ComputerName $ServerIP -Port 22 -WarningAction SilentlyContinue
    if (!$ConnTest.TcpTestSucceeded) {
        Write-Log "ERROR: Cannot connect to $ServerIP on port 22" "ERROR"
        return $false
    }
    
    Write-Log "Prerequisites check passed" "SUCCESS"
    return $true
}

# SSH command execution
function Invoke-SSHCommand {
    param([string]$Command, [switch]$ReturnOutput)
    
    $SSHCommand = "ssh -o StrictHostKeyChecking=no $Username@$ServerIP `"$Command`""
    
    if ($VerboseOutput) {
        Write-Log "Executing: $Command" "DEBUG"
    }
    
    if ($ReturnOutput) {
        $Result = Invoke-Expression $SSHCommand
        return $Result
    } else {
        Invoke-Expression $SSHCommand
        return $LASTEXITCODE -eq 0
    }
}

# Install embedding models
function Install-EmbeddingModels {
    Write-Log "Starting embedding models installation..."
    
    # Install Ollama if not present
    Write-Log "Checking Ollama installation..."
    $OllamaCheck = Invoke-SSHCommand "command -v ollama" -ReturnOutput
    if ([string]::IsNullOrEmpty($OllamaCheck)) {
        Write-Log "Installing Ollama..." "WARN"
        Write-Host "Installing Ollama on server..." -ForegroundColor Yellow
        $OllamaInstall = Invoke-SSHCommand "curl -fsSL https://ollama.com/install.sh | sh"
        if ($OllamaInstall) {
            Write-Log "Ollama installed successfully" "SUCCESS"
        } else {
            Write-Log "Failed to install Ollama" "ERROR"
            return $false
        }
    } else {
        Write-Log "Ollama already installed: $OllamaCheck"
    }
    
    # Check Ollama service status
    Write-Log "Checking Ollama service status..."
    $OllamaStatus = Invoke-SSHCommand "systemctl is-active ollama" -ReturnOutput
    if ($OllamaStatus -ne "active") {
        Write-Log "Starting Ollama service..." "WARN"
        Invoke-SSHCommand "sudo systemctl start ollama"
        Invoke-SSHCommand "sudo systemctl enable ollama"
    }
    
    # Get current models
    Write-Log "Checking current installed models..."
    $CurrentModels = Invoke-SSHCommand "ollama list" -ReturnOutput
    Write-Log "Current models: $CurrentModels"
    
    $SuccessCount = 0
    
    foreach ($Model in $EmbeddingModels) {
        Write-Log "Installing model: $($Model.Name) ($($Model.Size))"
        Write-Host "Installing $($Model.Name)..." -ForegroundColor Yellow
        
        $InstallCommand = "ollama pull $($Model.Name)"
        $Success = Invoke-SSHCommand $InstallCommand
        
        if ($Success) {
            Write-Log "Successfully installed $($Model.Name)" "SUCCESS"
            Write-Host "✓ $($Model.Name) installed successfully" -ForegroundColor Green
            $SuccessCount++
        } else {
            Write-Log "Failed to install $($Model.Name)" "ERROR"
            Write-Host "✗ $($Model.Name) installation failed" -ForegroundColor Red
        }
        
        # Small delay between installations
        Start-Sleep -Seconds 2
    }
    
    Write-Log "Installation completed. $SuccessCount/$($EmbeddingModels.Count) models installed successfully"
    return $SuccessCount -eq $EmbeddingModels.Count
}

# Verify deployment
function Test-Deployment {
    Write-Log "Verifying deployment..."
    Write-Host "Testing embedding models..." -ForegroundColor Yellow
    
    $SuccessCount = 0
    
    foreach ($Model in $EmbeddingModels) {
        Write-Host "Testing $($Model.Name): " -NoNewline
        
        $TestPayload = @{
            model = $Model.Name
            prompt = "test embedding functionality"
        } | ConvertTo-Json -Compress
        
        $CurlCommand = "curl -s -X POST http://localhost:11434/api/embeddings -H 'Content-Type: application/json' -d '$TestPayload' --max-time 30"
        $TestResult = Invoke-SSHCommand $CurlCommand -ReturnOutput
        
        if ($TestResult -and $TestResult.Contains("embedding")) {
            Write-Host "✓ Working" -ForegroundColor Green
            Write-Log "$($Model.Name): Working" "SUCCESS"
            $SuccessCount++
        } else {
            Write-Host "✗ Failed" -ForegroundColor Red
            Write-Log "$($Model.Name): Failed" "ERROR"
        }
    }
    
    Write-Log "Verification completed. $SuccessCount/$($EmbeddingModels.Count) models working correctly"
    return $SuccessCount -eq $EmbeddingModels.Count
}

# Display summary
function Show-Summary {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "Deployment Summary" -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "Server: hx-orc-server ($ServerIP)" -ForegroundColor Yellow
    Write-Host "Models Installed:" -ForegroundColor Yellow
    
    foreach ($Model in $EmbeddingModels) {
        Write-Host "  - $($Model.Name) ($($Model.Size) parameters)"
    }
    
    Write-Host ""
    Write-Host "API Endpoints:" -ForegroundColor Yellow
    Write-Host "  - http://$ServerIP`:11434/api/embeddings"
    Write-Host ""
    Write-Host "Usage Example:" -ForegroundColor Yellow
    Write-Host '  curl -X POST "http://' -NoNewline
    Write-Host $ServerIP -NoNewline -ForegroundColor Cyan
    Write-Host ':11434/api/embeddings" \'
    Write-Host '    -H "Content-Type: application/json" \'
    Write-Host '    -d ''{"model":"mxbai-embed-large","prompt":"Your text here"}'''
    Write-Host ""
    Write-Host "Log File: $LogFile" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Blue
}

# Dry run mode
function Invoke-DryRun {
    Write-Log "Running in dry-run mode..."
    Write-Host "DRY RUN - No changes will be made" -ForegroundColor Cyan
    
    Write-Host "`nWould install the following models:" -ForegroundColor Yellow
    foreach ($Model in $EmbeddingModels) {
        Write-Host "  - $($Model.Name) ($($Model.Size)) - $($Model.Description)" -ForegroundColor Gray
    }
    
    Write-Host "`nTarget server: $ServerIP" -ForegroundColor Yellow
    Write-Host "Storage path: /opt/ai_models" -ForegroundColor Yellow
    Write-Host "API port: 11434" -ForegroundColor Yellow
}

# Main execution
function Main {
    Show-Header
    
    switch ($Action) {
        "dry-run" {
            if (Test-Prerequisites) {
                Invoke-DryRun
            }
        }
        "verify" {
            if (Test-Prerequisites) {
                $VerifySuccess = Test-Deployment
                if ($VerifySuccess) {
                    Write-Host "🎉 All embedding models are working correctly!" -ForegroundColor Green
                } else {
                    Write-Host "❌ Some embedding models are not working properly." -ForegroundColor Red
                    exit 1
                }
            }
        }
        "deploy" {
            if (Test-Prerequisites) {
                Write-Log "Starting deployment process..."
                $InstallSuccess = Install-EmbeddingModels
                
                if ($InstallSuccess) {
                    Write-Log "Installation successful, running verification..."
                    $VerifySuccess = Test-Deployment
                    
                    if ($VerifySuccess) {
                        Show-Summary
                        Write-Host "🎉 Embedding models deployment completed successfully!" -ForegroundColor Green
                        Write-Log "Deployment completed successfully" "SUCCESS"
                    } else {
                        Write-Host "⚠️ Installation completed but some models are not responding correctly." -ForegroundColor Yellow
                        Write-Log "Deployment completed with warnings" "WARN"
                        exit 1
                    }
                } else {
                    Write-Host "❌ Deployment failed during installation." -ForegroundColor Red
                    Write-Log "Deployment failed" "ERROR"
                    exit 1
                }
            } else {
                Write-Host "❌ Prerequisites check failed." -ForegroundColor Red
                exit 1
            }
        }
    }
}

# Execute main function
Main
