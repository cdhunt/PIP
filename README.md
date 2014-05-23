PIP
===

### PowerShell ImageProcessor

This PowerShell module wraps [James M South's ImageProcessor](http://jimbobsquarepants.github.io/ImageProcessor/ "ImageProcessor") library.

> ImageProcessor is a collection of lightweight libraries written in C# that allows you to manipulate images on-the-fly using .NET 4+
> 
> It's lighting fast, extensible, easy to use, comes bundled with some great features and is fully open source.

This is not the first image manipulation module for PowerShell, but it's fast, functional and a good example of how to expose functionality from a .Net library via PowerShell.

Install
===

To install in your personal modules folder (e.g. ~\Documents\WindowsPowerShell\Modules), run:

```powershell
iex (new-object System.Net.WebClient).DownloadString('https://raw.github.com/cdhunt/PIP/master/Install.ps1')
```

Examples
===

```powershell
Get-PIPImage source.bmp | 
	Set-PIPImageSize -Width 100 -Height 100 | 
	Add-PIPFilter -Filter blackwhite |
	Add-PIPRoundedCorners |
	Set-PIPFormat -Format Jpeg |
	Save-PIPImage -Path output.jpg 
```