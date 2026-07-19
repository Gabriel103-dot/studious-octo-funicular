# ============================================
# CONFIGURACAO BASICA DO SISTEMA E SEGURANCA
# ============================================
Write-Host "Configurando politica de senhas..." -ForegroundColor Cyan;
secedit /export /cfg C:\secpol.cfg;
$secpol = Get-Content C:\secpol.cfg;
$secpol = $secpol -replace "PasswordComplexity = 1", "PasswordComplexity = 0";
$secpol = $secpol -replace "MinimumPasswordLength = 14", "MinimumPasswordLength = 1";
$secpol = $secpol -replace "MinimumPasswordLength = 7", "MinimumPasswordLength = 1";
$secpol | Set-Content C:\secpol.cfg;
secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY;
Remove-Item C:\secpol.cfg -Force;

$username = "StreamUser";
$password = "SuperStreamerPass2026!@#";

Write-Host "Criando usuario $username para RDP..." -ForegroundColor Cyan;
$userExists = Get-LocalUser -Name $username -ErrorAction SilentlyContinue;
if (-not $userExists) {
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
    New-LocalUser -Name $username -Password $securePassword -FullName "Game Streaming User";
    Add-LocalGroupMember -Group "Administrators" -Member $username;
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member $username;
}

Write-Host "Otimizando Sistema e Ligando Audio..." -ForegroundColor Cyan;
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False;
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue;

Set-Service -Name "Audiosrv" -StartupType Automatic -ErrorAction SilentlyContinue;
Start-Service -Name "Audiosrv" -ErrorAction SilentlyContinue;

Write-Host "Instalando dependencias basicas..." -ForegroundColor Cyan;
Set-ExecutionPolicy Bypass -Scope Process -Force;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));
$env:Path += ";C:\ProgramData\chocolatey\bin";

choco install -y vcredist-all directx --ignore-checksums;

Write-Host "Baixando Drivers de Audio para o Desktop..." -ForegroundColor Cyan;
$vbCableZip = "C:\Users\Public\Desktop\Instalar_VB_Cable.zip";
Invoke-WebRequest -Uri "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip" -OutFile $vbCableZip -ErrorAction SilentlyContinue;

Write-Host "Instalando Sunshine..." -ForegroundColor Cyan;
# URL corrigida para o instalador executavel oficial estável do Sunshine
$sunshineUrl = "https://github.com/LizardByte/Sunshine/releases/download/v2025.1220.194215/sunshine-windows-x64-installer.exe";
$sunshinePath = "C:\Sunshine";
$sunshineInstaller = "C:\Temp\sunshine_installer.exe";
New-Item -ItemType Directory -Force -Path "C:\Temp" | Out-Null;

# Baixa e instala de forma silenciosa
Invoke-WebRequest -Uri $sunshineUrl -OutFile $sunshineInstaller;
Start-Process -FilePath $sunshineInstaller -ArgumentList "/S" -Wait;

# Criando atalho funcional a partir da instalacao padrao do Sunshine
$sunshineShortcut = "C:\Users\Public\Desktop\Iniciar_Sunshine.lnk";
$WScriptShell = New-Object -ComObject WScript.Shell;
$Shortcut = $WScriptShell.CreateShortcut($sunshineShortcut);
$Shortcut.TargetPath = "C:\Program Files\Sunshine\sunshine.exe";
$Shortcut.WorkingDirectory = "C:\Program Files\Sunshine";
$Shortcut.Save();

# Inicia o Sunshine em background
Start-Process -FilePath "C:\Program Files\Sunshine\sunshine.exe" -WorkingDirectory "C:\Program Files\Sunshine";

Write-Host "Instalando Tailscale..." -ForegroundColor Cyan;
$tailscaleInstaller = "C:\Temp\Tailscale.msi";
Invoke-WebRequest -Uri "https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi" -OutFile $tailscaleInstaller;
Start-Process msiexec.exe -ArgumentList "/i `"$tailscaleInstaller`" /quiet" -Wait;

# Conectando usando a variável de ambiente segura
Start-Process -FilePath "C:\Program Files\Tailscale\tailscale.exe" -ArgumentList "up --authkey $env:TS_AUTHKEY" -Wait;

Start-Sleep -Seconds 10;
$tailscaleIP = & "C:\Program Files\Tailscale\tailscale.exe" ip -4;

Write-Host "============================================" -ForegroundColor Green;
Write-Host "VM PRONTA!" -ForegroundColor Yellow;
Write-Host "IP Tailscale: $tailscaleIP" -ForegroundColor White;
Write-Host "Usuario: $username" -ForegroundColor White;
Write-Host "Senha: $password" -ForegroundColor White;
Write-Host "============================================" -ForegroundColor Green;
$env:Path += ";C:\ProgramData\chocolatey\bin";

choco install -y vcredist-all directx --ignore-checksums;

Write-Host "Baixando Drivers de Audio para o Desktop..." -ForegroundColor Cyan;
$vbCableZip = "C:\Users\Public\Desktop\Instalar_VB_Cable.zip";
Invoke-WebRequest -Uri "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip" -OutFile $vbCableZip -ErrorAction SilentlyContinue;

Write-Host "Instalando Sunshine..." -ForegroundColor Cyan;
$sunshineUrl = "https://github.com/LizardByte/Sunshine/releases/latest/download/Sunshine-Windows.zip";
$sunshinePath = "C:\Sunshine";
$sunshineZip = "C:\Temp\Sunshine.zip";
New-Item -ItemType Directory -Force -Path "C:\Temp" | Out-Null;
Invoke-WebRequest -Uri $sunshineUrl -OutFile $sunshineZip;
Expand-Archive -Path $sunshineZip -DestinationPath $sunshinePath -Force;

$sunshineShortcut = "C:\Users\Public\Desktop\Iniciar_Sunshine.lnk";
$WScriptShell = New-Object -ComObject WScript.Shell;
$Shortcut = $WScriptShell.CreateShortcut($sunshineShortcut);
$Shortcut.TargetPath = "$sunshinePath\sunshine.exe";
$Shortcut.WorkingDirectory = $sunshinePath;
$Shortcut.Save();

$sunshineConfig = '{"apps": [{"name": "Desktop","output": "","cmd": "C:\\Windows\\System32\\mstsc.exe","prep-cmd": []}],"port": 47989,"flags": {"upnp": false}}';
New-Item -ItemType Directory -Force -Path "$sunshinePath\config" | Out-Null;
$sunshineConfig | Out-File -FilePath "$sunshinePath\config\sunshine.json" -Encoding ASCII;
Start-Process -FilePath "$sunshinePath\sunshine.exe" -WorkingDirectory $sunshinePath;

Write-Host "Instalando Tailscale..." -ForegroundColor Cyan;
$tailscaleInstaller = "C:\Temp\Tailscale.msi";
Invoke-WebRequest -Uri "https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi" -OutFile $tailscaleInstaller;
Start-Process msiexec.exe -ArgumentList "/i `"$tailscaleInstaller`" /quiet" -Wait;

# Conectando usando a variável de ambiente segura
Start-Process -FilePath "C:\Program Files\Tailscale\tailscale.exe" -ArgumentList "up --authkey $env:TS_AUTHKEY" -Wait;

Start-Sleep -Seconds 10;
$tailscaleIP = & "C:\Program Files\Tailscale\tailscale.exe" ip -4;

Write-Host "============================================" -ForegroundColor Green;
Write-Host "VM PRONTA!" -ForegroundColor Yellow;
Write-Host "IP Tailscale: $tailscaleIP" -ForegroundColor White;
Write-Host "Usuario: $username" -ForegroundColor White;
Write-Host "Senha: $password" -ForegroundColor White;
Write-Host "============================================" -ForegroundColor Green;
