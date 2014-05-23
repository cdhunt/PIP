PIP
===

### PowerShell ImageProcessor

This PowerShell module wraps [James M South's ImageProcessor](http://jimbobsquarepants.github.io/ImageProcessor/ "ImageProcessor") library.

> ImageProcessor is a collection of lightweight libraries written in C# that allows you to manipulate images on-the-fly using .NET 4+
> 
> It's lighting fast, extensible, easy to use, comes bundled with some great features and is fully open source.

Install
===

To install in your personal modules folder (e.g. ~\Documents\WindowsPowerShell\Modules), run:

```powershell
iex (new-object System.Net.WebClient).DownloadString('https://raw.github.com/cdhunt/PIP/master/Install.ps1')
```