<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-PIPImage
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,Position=0)]
        [Alias("FullName")]
        [string]
        $Path
    )

    Process
    {
        $imageFactory = New-Object ImageProcessor.ImageFactory

        $null = $imageFactory.Load($_)

        Write-Output -InputObject $imageFactory
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Set-PIPImageSize
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject,

        [Parameter(Mandatory,Position=1)]
        [int]
        $Width,

        [Parameter(Mandatory,Position=2)]
        [int]
        $Height,

        [Parameter(Position=3, ParameterSetName='Exact')]
        [ImageProcessor.Imaging.ResizeMode]
        $ResizeMode,

        [Parameter(Position=4, ParameterSetName='Exact')]
        [ImageProcessor.Imaging.AnchorPosition]
        $AnchorPosition,

        [Parameter(Position=5, ParameterSetName='Exact')]
        [System.Drawing.Color]
        $BackgroundColor,

        [Parameter(Position=6, ParameterSetName='Exact')]
        [switch]
        $UpScale = $true,

        [Parameter(Position=3, ParameterSetName='MaintainAspect')]
        [switch]
        $MaintainAspect
    )

    Begin
    {
        $layer = New-Object ImageProcessor.Imaging.ResizeLayer

        $layer.Size = (New-Object Drawing.Size($Width, $Height))

        if ($PSBoundParameters["ResizeMode"])
        {
            $layer.ResizeMode = $ResizeMode
        }
        if ($PSBoundParameters["AnchorPosition"])
        {
            $layer.AnchorPosition = $AnchorPosition
        }
        if ($PSBoundParameters["BackgroundColor"])
        {
            $layer.BackgroundColor = $BackgroundColor
        }
        if ($PSBoundParameters["UpScale"])
        {
            $layer.Upscale = $UpScale
        }
    }

    Process
    {
        if ($MaintainAspect)
        {
            Write-Output -InputObject $_.Constrain($layer)
        }
        else
        {
            Write-Output -InputObject $_.Resize($layer)
        }
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Set-PIPImageFormat
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject,

        [Parameter(Mandatory,Position=1)]
        [Drawing.Imaging.ImageFormat]
        $Format,

        [Parameter(Position=2)]
        $IndexedFormat
    )

    Process
    {

        Write-Output -InputObject $_.Format($Format, $IndexedFormat)
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Set-PIPQuality
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject,

        [Parameter(Mandatory,Position=1)]
        [ValidateRange(1,100)]
        [int]
        $Quality
    )

    Process
    {

        if ($_.MimeType -ne 'image/jpeg')
        {
            Write-Warning "This method will only effect the output quality of jpeg images."
        }

        $_.Quality($Quality) | Write-Output
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Invoke-PIPImageFlip
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject,

        [Parameter(Mandatory,Position=1)]
        [switch]
        $Vertically
    )

    Process
    {
        Write-Output -InputObject $_.Flip($Vertically)
    }
}

<#
.Synopsis
   Save the edited 
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Save-PIPImage
{
    [CmdletBinding()]
    [OutputType([IO.FileInfo])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject,

        [Parameter(Mandatory,Position=1)]
        [string]
        $Path
    )

    Process
    {
		# ImageProcessor.ImageFactory.Save() Requires an aboslute path
		if ([string]::IsNullOrWhiteSpace((Split-Path $Path)))
		{
			$Path = Join-Path -Path $pwd -ChildPath $Path
		}
		
		Try
		{
			$output = $_.Save($Path) 
		}
		Catch
		{
			Write-Error -ErrorRecord $_
		}
        
        Write-Output -InputObject (Get-Item $output.ImagePath)
    }
}