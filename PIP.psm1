$targetPath = $PSScriptRoot

$dll = Get-ChildItem -Path $targetPath -Recurse ImageProcessor.dll

if(!$dll) {
    
    if(!(Get-Command nuget -ErrorAction SilentlyContinue)) {
        Write-Warning "Please install nuget http://www.nuget.org/"
        return
    }

    Push-Location
    Set-Location -Path $targetPath
    nuget install ImageProcessor
    Pop-Location
}

$dll = Get-ChildItem -Path $targetPath -Recurse ImageProcessor.dll

Add-Type -Path $dll.FullName

# TODO : Read EXIF http://blogs.technet.com/b/jamesone/archive/2007/07/13/exploring-photographic-exif-data-using-powershell-of-course.aspx
# http://www.codeproject.com/Articles/27242/ExifTagCollection-An-EXIF-metadata-extraction-libr
# http://www.codeproject.com/Articles/36342/ExifLib-A-Fast-Exif-Data-Extractor-for-NET Install-Package ExifLib

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
		#if($_) { $file = $_ }

		if ([string]::IsNullOrWhiteSpace((Split-Path $Path)) -or (Split-Path $Path) -eq '.')
		{
			$Path = Join-Path -Path $pwd -ChildPath $Path
		}

		Write-Debug $Path

        $imageFactory = New-Object ImageProcessor.ImageFactory -ArgumentList $true
		
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
.PARAMETER Left
   The [System.Float] defining the left coordinate of the crop layer to offset from the original image. When the crop 
   mode is defined as [CropMode.Percentage] this becomes the percentage you want to remove from the left hand side 
   of the image.
.PARAMETER Top
   The [System.Float] defining the top coordinate of the crop layer to offset from the original image. When the crop 
   mode is defined as [CropMode.Percentage] this becomes the percentage you want to remove from the top of the image.
.PARAMETER Right
   The [System.Float] defining the width of the crop layer. When the crop mode is defined as [CropMode.Percentage] this 
   becomes the percentage you want to remove from the right hand side of the image.
.PARAMETER Bottom
   The [System.Float] defining the height of the crop layer. When the crop mode is defined as [CropMode.Percentage] this 
   becomes the percentage you want to remove from the bottom of the image.
.PARAMETER Percentage
   The default Crop Mode is Pixels. When the Percentage switch is selected this becomes the percentage you want to 
   remove from the bottom of the image.
.EXAMPLE
   Get-ImageStream Capture.png | Set-ImageSize -Width 100 -Height 100
.EXAMPLE
   $images dir *.png | Get-PIPImage | Invoke-PIPImageCrop -Left 10 -Top 10 -Right 10 -Bottom 10 -Percetnage
#>
function Invoke-PIPImageCrop
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject,

        [Parameter(Mandatory,Position=1)]
        [float]
        $Left,

        [Parameter(Mandatory,Position=2)]
        [float]
        $Top,

		[Parameter(Mandatory,Position=3)]
        [float]
        $Right,

		[Parameter(Mandatory,Position=4)]
        [float]
        $Botom,

		[Parameter()]
        [Switch]
        $Percentage

    )

    Begin
    {
		$size = New-Object Drawing.Size($Width, $Height)

        $CropMode = [ImageProcessor.Imaging.CropMode]::Pixels

        if ($Percentage)
        {
            $CropMode = [ImageProcessor.Imaging.CropMode]::Percentage
        }       

		$layer = New-Object ImageProcessor.Imaging.ResizeLayer($Left, $Top, $Right, $Bottom, $CropMode)
    }

    Process
    {
		Write-Output -InputObject $_.Crop($layer)
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
function Resize-PIPImage
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
   Change the size of the image.
.DESCRIPTION
   Change the size of the image to the either the absolute height and width 
   or constrained to the height and width but maintaining aspect ratio.
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Text
   The text to write to the image.
.PARAMETER Color
   The System.Drawing.Color to render the text.
.PARAMETER Font
   The name of the font to apply to the text.
.PARAMETER FontSize
   The size of the text in pixels.
.PARAMETER Style
   The System.Drawing.FontStyle to apply to the text.
.PARAMETER Opacity
   The opacity of the text.
.PARAMETER X
   The X coordiante determining the position within the current image to render the text.
.PARAMETER Y
   The Y coordiante determining the position within the current image to render the text.
.PARAMETER DropShadow
   Whether to apply a drop shadow to the text.
.EXAMPLE
   $images dir *.png | Get-PIPImage | Add-PIPWatermark -Text "Copywrite Bob 2014"
#>
function Add-PIPWatermark
{
    [CmdletBinding()]
    [OutputType([ImageProcessor.ImageFactory])]
    Param
    (
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [ImageProcessor.ImageFactory]
        $InputObject,

        [Parameter(Mandatory,Position=1)]
        [string]
        $Text,

        [Parameter(Position=2)]
        [System.Drawing.Color]
        $Color,

        [Parameter(Position=3)]
        [string]
        $Font,

        [Parameter(Position=4)]
        [int]
        $FontSize,

        [Parameter(Position=5)]
        [System.Drawing.FontStyle]
        $Style,

        [Parameter(Position=6)]
		[ValidateRange(0,100)]
        [int]
        $Opacity,

		[Parameter(Position=7)]
        [int]
        $X,
		
		[Parameter(Position=8)]
        [int]
        $Y,

		[Parameter()]
        [switch]
        $DropShadow
    )

    Begin
    {
        $layer = New-Object ImageProcessor.Imaging.TextLayer

        if ($PSBoundParameters["Text"])
        {
            $layer.Text = $Text
        }
        if ($PSBoundParameters["Color"])
        {
            $layer.Color = $Color
        }
        if ($PSBoundParameters["Font"])
        {
            $layer.Font = $Font
        }
        if ($PSBoundParameters["FontSize"])
        {
            $layer.FontSize = $FontSize
        }
		if ($PSBoundParameters["Style"])
        {
            $layer.Style = $Style
        }
		if ($PSBoundParameters["Opacity"])
        {
            $layer.Opacity = $Opacity
        }
		if ($PSBoundParameters["X"] -and $PSBoundParameters["Y"])
        {
			$point = New-Object System.Drawing.Point($X, $Y)
            $layer.Point = $point
        }
		if ($DropShadow)
		{
			$layer.DropShadow = $DropShadow
		}
    }

    Process
    {
        Write-Output -InputObject $_.Watermark($layer)
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
        [ValidateSet("Bitmap","Jpeg","Gif","Png","Tiff")]
        [string]
        $Format
    )

    Process
    {
        $formatObject = New-Object "ImageProcessor.Imaging.Formats.$($Format)Format"

        Write-Output -InputObject $_.Format($formatObject)
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

	Begin
	{
		$layer = New-Object ImageProcessor.Imaging.RoundedCornerLayer

		if ($PSBoundParameters["Radius"])
		{
			$layer.Radius = $Radius
		}
		if ($PSBoundParameters["BackgroundColor"])
		{
			$layer.BackgroundColor = $BackgroundColor
		}
		if ($TopLeft)
		{
			$layer.TopLeft = $TopLeft
		}
		if ($TopRight)
		{
			$layer.TopRight = $TopRight
		}
		if ($BottomLeft)
		{
			$layer.BottomLeft = $BottomLeft
		}
		if ($BottomRight)
		{
			$layer.BottomRight = $BottomRight
		}
	}

    Process
    {		
        Write-Output -InputObject $_.RoundedCorners($layer)
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
   Changes the saturation of the current image.
.DESCRIPTION
   Changes the saturation of the current image.
.PARAMETER InputObject
   Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or
   expression that gets the objects.
.PARAMETER Percentage
	The percentage by which to alter the images saturation. Any integer between 0 and 100.
.EXAMPLE
   Get-ImageStream Capture.png | Invoke-PIPSaturation -Percentage 50
#>
function Set-PIPSaturation
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
        Write-Output -InputObject $_.Saturation($Percentage)
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