function Get-ArrayRegex {
    <#
    .Synopsis
       Buils a regex to use for matching a single value in an array
    .DESCRIPTION
       This function builds a "runtime Regex" from an array that can be used
       with the -match operator instead of using the -contains operator with
       the array itself. This can dramatically enhance performance when working
       with large arrays.

       https://blogs.technet.microsoft.com/heyscriptingguy/2011/02/18/speed-up-array-comparisons-in-powershell-with-a-runtime-regex/
    .EXAMPLE
       Example of how to use this cmdlet
    .EXAMPLE
       Another example of how to use this cmdlet
    #>
    [CmdletBinding()]
    [OutputType([System.Text.RegularExpressions.Regex])]
    param(
        # Source array to use for the regex
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Object[]] $InputObject,

        # Use exact String matching instead of fuzzy matching
        [Parameter(Mandatory = $false)]
        [Switch] $Exact,

        # Use case-sensitive matching
        [Parameter(Mandatory = $false)]
        [Switch] $CaseSensitive
    )

    begin {
        $builder = New-Object -TypeName System.Text.StringBuilder
        if ($CaseSensitive) {
            [void] $builder.Append('(?-i)')
        }
        else {
            [void] $builder.Append('(?i)')
        }

        if ($Exact) {
            [void] $builder.Append('^')
        }

        # We'll use a trick here to avoid putting an extra separator on after every
        # record. After one loop, this char gets changed to the | character.
        $prependChar = '('
    }

    process {
        foreach ($i in $InputObject) {
            [void] $builder.Append($prependChar)
            [void] $builder.Append([Regex]::Escape($i))
            $prependChar = '|'
        }
    }

    end {
        [void] $builder.Append(')')

        if ($Exact) {
            [void] $builder.Append('$')
        }

        [regex] $result = $builder.ToString()
        Write-Output $result
    }
}
