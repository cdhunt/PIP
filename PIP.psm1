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
		if ([string]::IsNullOrWhiteSpace((Split-Path $Path)) -or (Split-Path $Path) -eq '.')
		{
			$Path = Join-Path -Path $pwd -ChildPath $Path
		}

		Write-Debug $Path

        $imageFactory = New-Object ImageProcessor.ImageFactory
		
		$null = $imageFactory.Load($Path)

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
		$size = New-Object Drawing.Size($Width, $Height)

        $layer = New-Object ImageProcessor.Imaging.ResizeLayer($size)

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
            Write-Output -InputObject $_.Constrain($size)
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
		[ValidateSet("BlackWhite","Comic","Lomograph","GreyScale","Polaroid","Sepia","gotham","hisatch","losatch","invert")]
        [string]
        $Filter
    )

    Process
    {
		
		switch ($Filter.ToLower())
		{
			'blackwhite'	{$filterObject = [ImageProcessor.Imaging.Filters.MatrixFilters]::BlackWhite }
			'comic'			{$filterObject = [ImageProcessor.Imaging.Filters.MatrixFilters]::Comic }
			'lomograph'		{$filterObject = [ImageProcessor.Imaging.Filters.MatrixFilters]::Lomograph }
			'greyscale'		{$filterObject = [ImageProcessor.Imaging.Filters.MatrixFilters]::GreyScale }
			'polaroid'		{$filterObject = [ImageProcessor.Imaging.Filters.MatrixFilters]::Polaroid }
			'sepia'			{$filterObject = [ImageProcessor.Imaging.Filters.MatrixFilters]::Sepia }
			'gotham'		{$filterObject = [ImageProcessor.Imaging.Filters.MatrixFilters]::Gotham }
			'hisatch'		{$filterObject = [ImageProcessor.Imaging.Filters.MatrixFilters]::HiSatch }
			'losatch'		{$filterObject = [ImageProcessor.Imaging.Filters.MatrixFilters]::LoSatch }
			'invert'		{$filterObject = [ImageProcessor.Imaging.Filters.MatrixFilters]::Invert }
			Default {}
		}

        Write-Output -InputObject $_.Filter($filterObject)
    }
}

<#
.Synopsis
   Adds rounded corners to the current image.
.DESCRIPTION
   Adds rounded corners to the current image.
.PARAMETER Radius
   The radius at which the corner will be rounded.
.PARAMETER TopLeft
   A value indicating whether top left corners are to be added.
.PARAMETER TopRight
   A value indicating whether top right corners are to be added.
.PARAMETER BottomLeft
   A value indicating whether bottom left corners are to be added.
.PARAMETER BottomRight
   A value indicating whether bottom right corners are to be added.
.PARAMETER BackgroundColor
   The System.Drawing.Color to set as the background color. Used primarily for image formats that do not support transparency.
.EXAMPLE
   Get-ImageStream Capture.png | Add-PIPRoundedCorners
#>
function Add-PIPRoundedCorners
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject,

        [Parameter(Position=1)]
		[ValidateRange(0,360)]
        [int]
        $Radius,

		[Parameter(Position=2)]
        [System.Drawing.Color]
        $BackgroundColor,

        [Parameter()]
        [switch]
        $TopLeft,

        [Parameter()]
        [switch]
        $TopRight,

        [Parameter()]
        [switch]
        $BottomLeft,

        [Parameter()]
        [switch]
        $BottomRight
    )

    Process
    {
	
		$roundedCornerLayer = New-Object ImageProcessor.Imaging.RoundedCornerLayer

		if ($PSBoundParameters["Radius"])
		{
			$roundedCornerLayer.Radius = $Radius
		}
		if ($PSBoundParameters["BackgroundColor"])
		{
			$roundedCornerLayer.BackgroundColor = $BackgroundColor
		}
		if ($TopLeft)
		{
			$roundedCornerLayer.TopLeft = $TopLeft
		}
		if ($TopRight)
		{
			$roundedCornerLayer.TopRight = $TopRight
		}
		if ($BottomLeft)
		{
			$roundedCornerLayer.BottomLeft = $BottomLeft
		}
		if ($BottomRight)
		{
			$roundedCornerLayer.BottomRight = $BottomRight
		}

        Write-Output -InputObject $_.RoundedCorners($roundedCornerLayer)
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

        [Parameter()]
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
   Adds a vignette image effect to the current image.
.DESCRIPTION
   Adds a vignette image effect to the current image.
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.EXAMPLE
   Get-ImageStream Capture.png | Invoke-PIPVignette
#>
function Add-PIPVignette
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
        Write-Output -InputObject $_.Vignette()
    }
}

<#
.Synopsis
   Changes the opacity of the current image.
.DESCRIPTION
   Changes the opacity of the current image.
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Percentage
	The percentage by which to alter the images opacity. Any integer between 0 and 100.
.EXAMPLE
   Get-ImageStream Capture.png | Invoke-PIPAlpha -Percentage 50
#>
function Set-PIPAlpha
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
		$Percentage
    )

    Process
    {
        Write-Output -InputObject $_.Alpha($Percentage)
    }
}

<#
.Synopsis
   Changes the brightness of the current image.
.DESCRIPTION
   Changes the brightness of the current image.
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Percentage
	The percentage by which to alter the images brightness. Any integer between 0 and 100.
.EXAMPLE
   Get-ImageStream Capture.png | Invoke-PIPBrightness -Percentage 50
#>
function Set-PIPBrightness
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
		$Percentage
    )

    Process
    {
        Write-Output -InputObject $_.Brightness($Percentage)
    }
}

<#
.Synopsis
   Changes the contrast of the current image.
.DESCRIPTION
   Changes the contrast of the current image.
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Percentage
	The percentage by which to alter the images contrast. Any integer between 0 and 100.
.EXAMPLE
   Get-ImageStream Capture.png | Invoke-PIPContrast -Percentage 50
#>
function Set-PIPContrast
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
		$Percentage
    )

    Process
    {
        Write-Output -InputObject $_.Contrast($Percentage)
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
		if ([string]::IsNullOrWhiteSpace((Split-Path $Path)) -or (Split-Path $Path) -eq '.')
		{
			$Path = Join-Path -Path $pwd -ChildPath $Path
		}

		Write-Debug $Path
		
		Try
		{
			$output = $_.Save($Path) 
		}
		Catch
		{
			Write-Error -ErrorRecord $_
		}
        
        Write-Output -InputObject (Get-Item $Path)
    }
}