function Set-NetSecurityPolicy {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [System.Net.SecurityProtocolType[]] $SecurityProtocol,

        [Parameter()]
        [bool] $IgnoreCertificateErrors
    )

    begin {
        # Create the .NET type for a cert policy that ignores cert errors
        if (-not ([System.Management.Automation.PSTypeName] 'TrustAllCertificatesPolicy').Type) {
            Add-Type @'
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertificatesPolicy : ICertificatePolicy
        {
            public bool CheckValidationResult
            (
                ServicePoint srvPoint,
                X509Certificate certificate,
                WebRequest request,
                int certificateProblem
            )
            {
                return true;
            }
        }
'@
        }
    }

    process {
        if ($SecurityProtocol -and $PSCmdlet.ShouldProcess($SecurityProtocol, 'Change SSL configuration for this PowerShell session')) {
            [System.Net.ServicePointManager]::SecurityProtocol = $SecurityProtocol
        }

        if ($PSBoundParameters.ContainsKey('IgnoreCertificateErrors')) {
            if ($IgnoreCertificateErrors) {
                $msg = 'Ignore any certificate errors for this PowerShell session'
                $certPolicy = New-Object -TypeName TrustAllCertificatesPolicy
            }
            else {
                $msg = 'Use normal certificate handling for this PowerShell session'
                $certPolicy = New-Object -TypeName System.Net.DefaultCertPolicy
            }

            if ($Force -or $PSCmdlet.ShouldProcess($msg)) {
                [System.Net.ServicePointManager]::CertificatePolicy = $certPolicy
            }
        }
    }
}
