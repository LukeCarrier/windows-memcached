# Download a file
function Download-File {
    param(
        [string] $url,
        [string] $target,
        [string] $md5,
        [int]    $attempts = 3
    )

    $success = $false

    while (($attempt -lt $attempts) -and !($success)) {
        $attempt++

        Write-Host "Obtaining $($target) (attempt $attempt of $attempts)..."

        if (!(Test-Path $target)) {
            Write-Host "Using URI $url"
            Invoke-WebRequest -OutFile $target `
                              -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox `
                              $url
        }
        $fileMd5 = (Get-FileHash -Algorithm MD5 $target).Hash.ToLower()

        if ($md5 -eq $fileMd5) {
            $success = $true
        } else {
            Write-Host "Hash $($fileMd5) did not match expected $($md5)"
            Remove-Item $target
            continue
        }
    }
}

# Extract a gzipped tarball (requires MSYS)
function Extract-GzippedTarball {
    param(
        [string] $source,
        [string] $target
    )

    &tar -xf $source -C $target
}

# Install a MinGW dependency (requires MinGW)
function Install-MinGWDependency {
    param(
        [string] $spec
    )

    mingw-get install $spec
}

function Join-MingPath {
    param (
        [string] $pathA,
        [string] $pathB
    )

    return "$($pathA)/$($pathB)"
}

# Load additional .NET assemblies
Add-Type -Assembly "System.IO.Compression.FileSystem"

# Configure shell environment for MinGW and MSYS
$env:PATH += ";C:\MinGW\bin"
$env:PATH += ";C:\MinGW\msys\1.0\bin"

# Paths
$rootDir      = $PSScriptRoot
$buildDir     = (Join-Path $rootDir "build")
$mingRootDir  = "/c/windows-memcached"
$mingBuildDir = (Join-MingPath $mingRootDir "build")

# Memcached configuration
$memcachedVer     = "1.4.24"
$memcachedUrl     = "http://www.memcached.org/files/memcached-$($memcachedVer).tar.gz"
$memcachedTar     = (Join-Path $buildDir "memcached-$($memcachedVer).tar.gz")
$mingMemcachedTar = (Join-MingPath $mingBuildDir "memcached-$($memcachedVer).tar.gz")
$memcachedSum     = "4e8285e2407a2fcf43cd2b6084d61bb5"
$mingMemcachedSrc = (Join-MingPath $mingBuildDir "memcached-$($memcachedVer)")

# libevent configuration
$libeventSeries  = "2.0"
$libeventVer     = "$($libeventSeries).22-stable"
$libeventUrl     = "https://sourceforge.net/projects/levent/files/libevent/libevent-$($libeventSeries)/libevent-$($libeventVer).tar.gz"
$libeventTar     = (Join-Path $buildDir "libevent-$($libeventVer).tar.gz")
$mingLibeventTar = (Join-MingPath $mingBuildDir "libevent-$($libeventVer).tar.gz")
$libeventSum     = "c4c56f986aa985677ca1db89630a2e11"
$mingLibeventSrc = (Join-MingPath $mingBuildDir "libevent-$($libeventVer)")

# MSYS utilities required for the build
Install-MinGWDependency "msys-gzip"
Install-MinGWDependency "msys-tar"

# libevent
Download-File $libeventUrl $libeventTar $libeventSum
Extract-GzippedTarball $mingLibeventTar $mingBuildDir

# memcached
Download-File $memcachedUrl $memcachedTar $memcachedSum
Extract-GzippedTarball $mingMemcachedTar $mingBuildDir
