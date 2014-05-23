$targetPath = $PSScriptRoot

$dll = dir $targetPath -Recurse ImageProcessor.dll

if(!$dll) {
    
    if(!(Get-Command nuget -ErrorAction SilentlyContinue)) {
        Write-Warning "Please install nuget http://www.nuget.org/"
        return
    }

    pushd
    cd $targetPath
    nuget install ImageProcessor
    popd
}

$dll = dir $targetPath -Recurse ImageProcessor.dll

Add-Type -Path $dll.FullName

<#
.Synopsis
   Load an Image file from disk.
.DESCRIPTION
   Load an Image file from disk in preparation for processing. Always call this function first.
.PARAMETER Path
   The absolute path to the image to load.
.EXAMPLE
   Get-PIPImage -Path myphoto.jpeg
.EXAMPLE
   $images dir *.png | Get-PIPImage
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
   Change the size of the image.
.DESCRIPTION
   Change the size of the image to the either the absolute height and width 
   or constrained to the height and width but maintaining aspect ratio.
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Width
   The width to set the image to.
.PARAMETER Height
   The height to set the image to.
.PARAMETER ResizeMode
   The ImageProcessor.Imaging.ResizeMode to apply to resized image.
.PARAMETER AnchorPosition
   The ImageProcessor.Imaging.AnchorPosition to apply to resized image.
.PARAMETER BackgroundColor
   The System.Drawing.Color to set as the background color. Used primarily for image formats that do not support transparency.
.PARAMETER UpScale
   Whether to allow up-scaling of images. (Default true)
.EXAMPLE
   Get-ImageStream Capture.png | Set-ImageSize -Width 100 -Height 100
.EXAMPLE
   $images dir *.png | Get-PIPImage | Set-ImageSize -Width 200 -Height 100 -MaintainAspect
#>
function Set-PIPImageSize
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
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
   Sets the output format of the current image
.DESCRIPTION
   Sets the output format of the current image to the matching System.Drawing.Imaging.ImageFormat
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Format
   The System.Drawing.Imaging.ImageFormat to set the image to.
.PARAMETER IndexedFormat
   Whether the pixel format of the image should be indexed. Used for generating Png8 images.
.EXAMPLE
   Get-ImageStream Capture.png | Set-PIPImageFormat -Format Jpeg
#>
function Set-PIPImageFormat
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject,

        [Parameter(Mandatory,Position=1)]
        [Drawing.Imaging.ImageFormat]
        $Format,

        [Parameter(Position=2)]
		[switch]
        $IndexedFormat
    )

    Process
    {

        Write-Output -InputObject $_.Format($Format, $IndexedFormat)
    }
}

<#
.Synopsis
   Alters the output quality of the current image.
.DESCRIPTION
   Alters the output quality of the current image. This method will only effect the output quality of jpeg images.
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Quality
   The percentage by which to alter the images quality. Any integer between 0 and 100.
.EXAMPLE
   Get-ImageStream Capture.png | Set-PIPImageFormat -Format Jpeg | Set-PIPQuality -Quality 70
#>
function Set-PIPQuality
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject,

        [Parameter(Mandatory,Position=1)]
        [ValidateRange(0,100)]
        [int]
        $Quality
    )

    Process
    {
        if ($_.MimeType -ne 'image/jpeg')
        {
            Write-Warning "This method will only effect the output quality of jpeg images."
        }

        Write-Output -InputObject $_.Quality($Quality)
    }
}

<#
.Synopsis
   Applies a filter to the current image.
.DESCRIPTION
   Applies a filter to the current image. Available filters are:

   blackwhite
   comic
   lomograph
   greyscale
   polaroid
   sepia
   gotham
   hisatch
   losatch
   invert
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Filter
   The name of the filter to add to the image.
.EXAMPLE
   Get-ImageStream Capture.png | Add-PIPFilter -Filter blackwhite
#>
function Add-PIPFilter
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject,

        [Parameter(Mandatory,Position=1)]
        [ImageProcessor.Imaging.Filters.MatrixFilters]
        $Filter
    )

    Process
    {
        Write-Output -InputObject $_.Filter($Filter)
    }
}

<#
.Synopsis
   Flips the current image either horizontally or vertically.
.DESCRIPTION
   Flips the current image either horizontally or vertically.
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Vertically
   Whether to flip the image vertically.
.EXAMPLE
   Get-ImageStream Capture.png | Invoke-PIPImageFlip
#>
function Invoke-PIPImageFlip
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
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
   Resets the current image to its original loaded state.
.DESCRIPTION
   Resets the current image to its original loaded state.
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Vertically
   Whether to flip the image vertically.
.EXAMPLE
   Get-ImageStream Capture.png | Invoke-PIPImageFlip
#>
function Reset-PIPImage
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject
    )

    Process
    {
        Write-Output -InputObject $_.Reset()
    }
}

<#
.Synopsis
   Saves the current image to the specified file path. 
.DESCRIPTION
   Saves the current image to the specified file path.
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Path
   The path to save the image to.
.EXAMPLE
   Get-ImageStream C:\temp\Capture.PNG | Set-ImageSize -Width 100 -Height 100 | Save-Image -Path c:\temp\captureresize.png 
#>
function Save-PIPImage
{
    [CmdletBinding()]
    [OutputType([IO.FileInfo])]
    Param
    (
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