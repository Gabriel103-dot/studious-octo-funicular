# ============================================
# CONFIGURACAO BASICA DO SISTEMA E SEGURANCA
# ============================================
try {
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

    Write-Host "Otimizando Sistema e Forcando RDP..." -ForegroundColor Cyan;
    # Desativa o Firewall completamente para nao bloquear conexoes
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False;
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue;
    
    # ATIVACAO DO ACESSO REMOTO (RDP) NO REGISTRO DO WINDOWS
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0;
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue;

    # Ativa os servicos de Audio do Windows
    Set-Service -Name "Audiosrv" -StartupType Automatic -ErrorAction SilentlyContinue;
    Start-Service -Name "Audiosrv" -ErrorAction SilentlyContinue;
} catch { Write-Host "Aviso: Falha na configuracao inicial, prosseguindo..." -ForegroundColor Yellow; }

# ============================================
# INSTALACAO DE PROGRAMAS (CHOCOLATEY)
# ============================================
try {
    Write-Host "Instalando dependencias e Sunshine..." -ForegroundColor Cyan;
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));
    $env:Path += ";C:\ProgramData\chocolatey\bin";

    choco install -y vcredist-all directx sunshine --ignore-checksums;
} catch { Write-Host "Aviso: Falha no Chocolatey, prosseguindo..." -ForegroundColor Yellow; }

# ============================================
# CONFIGURACAO DO SUNSHINE
# ============================================
try {
    Write-Host "Configurando e iniciando Sunshine..." -ForegroundColor Cyan;
    $sunshineFolder = "C:\Program Files\Sunshine";
    
    # Criando atalho na Area de Trabalho Publica
    $sunshineShortcut = "C:\Users\Public\Desktop\Iniciar_Sunshine.lnk";
    $WScriptShell = New-Object -ComObject WScript.Shell;
    $Shortcut = $WScriptShell.CreateShortcut($sunshineShortcut);
    $Shortcut.TargetPath = "$sunshineFolder\sunshine.exe";
    $Shortcut.WorkingDirectory = $sunshineFolder;
    $Shortcut.Save();

    # Inicia o Sunshine se a pasta existir
    if (Test-Path "$sunshineFolder\sunshine.exe") {
        Start-Process -FilePath "$sunshineFolder\sunshine.exe" -WorkingDirectory $sunshineFolder -ErrorAction SilentlyContinue;
    }
} catch { Write-Host "Aviso: Nao foi possivel iniciar o Sunshine, prosseguindo..." -ForegroundColor Yellow; }

# ============================================
# CONEXAO TAILSCALE
# ============================================
try {
    Write-Host "Instalando e conectando ao Tailscale..." -ForegroundColor Cyan;
    $tailscaleInstaller = "C:\Temp\Tailscale.msi";
    New-Item -ItemType Directory -Force -Path "C:\Temp" | Out-Null;
    Invoke-WebRequest -Uri "https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi" -OutFile $tailscaleInstaller -ErrorAction SilentlyContinue;
    Start-Process msiexec.exe -ArgumentList "/i `"$tailscaleInstaller`" /quiet" -Wait;

    Start-Process -FilePath "C:\Program Files\Tailscale\tailscale.exe" -ArgumentList "up --authkey $env:TS_AUTHKEY" -Wait -ErrorAction SilentlyContinue;

    Start-Sleep -Seconds 10;
    $tailscaleIP = & "C:\Program Files\Tailscale\tailscale.exe" ip -4;
    
    Write-Host "======================================" -ForegroundColor Green;
    Write-Host "IP DA MAQUINA: $tailscaleIP" -ForegroundColor Green;
    Write-Host "======================================" -ForegroundColor Green;
} catch { Write-Host "Aviso: Falha no Tailscale, prosseguindo..." -ForegroundColor Yellow; }

# Mensagem final indicando sucesso na execucao do script básico
Write-Host "Script finalizado. Passando o controle para o mantenedor ativo do Github." -ForegroundColor Green;
try {
    Write-Host "Instalando dependencias e Sunshine..." -ForegroundColor Cyan;
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));
    $env:Path += ";C:\ProgramData\chocolatey\bin";

    choco install -y vcredist-all directx sunshine --ignore-checksums;
} catch { Write-Host "Aviso: Falha no Chocolatey, prosseguindo..." -ForegroundColor Yellow; }

# ============================================
# CONFIGURACAO DO SUNSHINE (PASTAS CORRIGIDAS)
# ============================================
try {
    Write-Host "Configurando e iniciando Sunshine..." -ForegroundColor Cyan;
    $sunshineFolder = "C:\Program Files\Sunshine";
    
    # Criando atalho na Area de Trabalho Publica
    $sunshineShortcut = "C:\Users\Public\Desktop\Iniciar_Sunshine.lnk";
    $WScriptShell = New-Object -ComObject WScript.Shell;
    $Shortcut = $WScriptShell.CreateShortcut($sunshineShortcut);
    $Shortcut.TargetPath = "$sunshineFolder\sunshine.exe";
    $Shortcut.WorkingDirectory = $sunshineFolder;
    $Shortcut.Save();

    # Inicia o Sunshine se a pasta existir
    if (Test-Path "$sunshineFolder\sunshine.exe") {
        Start-Process -FilePath "$sunshineFolder\sunshine.exe" -WorkingDirectory $sunshineFolder -ErrorAction SilentlyContinue;
    }
} catch { Write-Host "Aviso: Nao foi possivel iniciar o Sunshine, prosseguindo..." -ForegroundColor Yellow; }

# ============================================
# CONEXAO TAILSCALE
# ============================================
try {
    Write-Host "Instalando e conectando ao Tailscale..." -ForegroundColor Cyan;
    $tailscaleInstaller = "C:\Temp\Tailscale.msi";
    New-Item -ItemType Directory -Force -Path "C:\Temp" | Out-Null;
    Invoke-WebRequest -Uri "https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi" -OutFile $tailscaleInstaller -ErrorAction SilentlyContinue;
    Start-Process msiexec.exe -ArgumentList "/i `"$tailscaleInstaller`" /quiet" -Wait;

    Start-Process -FilePath "C:\Program Files\Tailscale\tailscale.exe" -ArgumentList "up --authkey $env:TS_AUTHKEY" -Wait -ErrorAction SilentlyContinue;

    Start-Sleep -Seconds 10;
    $tailscaleIP = & "C:\Program Files\Tailscale\tailscale.exe" ip -4;
    
    Write-Host "======================================" -ForegroundColor Green;
    Write-Host "IP DA MAQUINA: $tailscaleIP" -ForegroundColor Green;
    Write-Host "======================================" -ForegroundColor Green;
} catch { Write-Host "Aviso: Falha no Tailscale, prosseguindo..." -ForegroundColor Yellow; }

# Mensagem final indicando sucesso na execucao do script básico
Write-Host "Script finalizado. Passando o controle para o mantenedor ativo do Github." -ForegroundColor Green;
