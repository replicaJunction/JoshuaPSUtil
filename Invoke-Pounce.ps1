function Invoke-Pounce {
    [CmdletBinding(DefaultParameterSetName = 'CommandLine',
                   SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory,
                ValueFromPipeline)]
        [String[]] $ComputerName,

        [Parameter(ParameterSetName = 'CommandLine',
                Mandatory)]
        [String] $CommandLine,

        [Parameter(ParameterSetName = 'PSFile',
                Mandatory)]
        [String] $ScriptFile,

        [Parameter(ParameterSetName = 'PSFile')]
        [String] $Parameters,

        # Server to use for execution. Note that if this is specified, the ScriptFile parameter will be used as a local path on that server rather than a local path.
        [Parameter()]
        [String] $Server,

        # How long to wait between attempts to ping the target machine
        [Parameter()]
        [int] $DelaySeconds = 30,

        # How long to wait after a successful ping (for example, to wait for services to start)
        [Parameter()]
        [int] $PauseAfterSuccess = 30
    )

    begin {
        $batchFileContent = @"
@echo off

:loop
ping -n 1 %1
if %errorlevel% == 0 goto success

rem Wait for $DelaySeconds seconds
ping -n $DelaySeconds 127.0.0.1 > nul
goto loop

:success
rem Computer is online. Wait $PauseAfterSuccess seconds for services to start
ping -n $PauseAfterSuccess 127.0.0.1 > nul

rem Confirm online
ping -n 1 %1
if not %errorlevel% == 0 goto loop

rem Execute command
$(
    switch($PSCmdlet.ParameterSetName) {
        'CommandLine' {
            $CommandLine
        }
        'PSFile' {
            "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""$ScriptFile"" $Parameters"
        }
        default {
        throw "Unrecognized parameter set name [$(PSCmdlet.ParameterSetName)]. You need to add this ParameterSetName to the Switch statement!"
        }
    }
)
"@
        $tempDir = Join-Path -Path $env:TEMP -ChildPath 'Invoke-Pounce'
        if (-not (Test-Path -Path $tempDir)) {
            New-Item -Path $tempDir -ItemType 'Directory' | Out-Null
        }
        $batchFile = Join-Path -Path $tempDir -ChildPath 'InvokePounce.bat'
        $batchFileContent | Set-Content -Path $batchFile -Encoding Ascii -Force -WhatIf:$false

        if ($Server) {
            # If a server is used, this script tries to use Invoke-PsExec
            # to run the batch script.
            if (-not (Import-Module -Name 'PsExec' -PassThru -ErrorAction SilentlyContinue)) {
                throw "PsExec module is required to use the -Server parameter. Download the PsExec module from PS Gallery using the command ""Install-Module PsExec""."
            }
        }
    }

    process {
        foreach ($c in $ComputerName) {
            if ($Server) {
                if ($PSCmdlet.ShouldProcess($c, "Invoke pounce using server $Server")) {
                    Invoke-PsExec -Command "$batchFile $c" -Copy -ComputerName $Server
                }
            }
            else {
                if ($PSCmdlet.ShouldProcess($c, "Invoke pounce")) {
                    Start-Process -FilePath $batchFile -ArgumentList $c
                }
            }
        }
    }
}
