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

function Join-MingPath {
    param (
        [string] $pathA,
        [string] $pathB
    )

    return "$($pathA)/$($pathB)"
}

# Configure shell environment for MSYS2
$env:PATH += ";C:\msys64\usr\bin"
$msysShell = "C:\msys64\mingw64_shell.bat"

# Paths
$rootDir      = $PSScriptRoot
$buildDir     = (Join-Path $rootDir "build")
$msysRootDir  = "/c/windows-memcached"
$msysBuildDir = (Join-MingPath $msysRootDir "build")
$msysStage2   = (Join-MingPath $msysRootDir "stage2.sh")

# Memcached configuration
$memcachedVer     = "1.4.24"
$memcachedUrl     = "http://www.memcached.org/files/memcached-$($memcachedVer).tar.gz"
$memcachedTar     = (Join-Path $buildDir "memcached-$($memcachedVer).tar.gz")
$msysMemcachedTar = (Join-MingPath $msysBuildDir "memcached-$($memcachedVer).tar.gz")
$memcachedSum     = "4e8285e2407a2fcf43cd2b6084d61bb5"
$msysMemcachedDir = (Join-MingPath $msysBuildDir "memcached-$($memcachedVer)")

# libevent configuration
$libeventSeries  = "2.0"
$libeventVer     = "$($libeventSeries).22-stable"
$libeventUrl     = "https://sourceforge.net/projects/levent/files/libevent/libevent-$($libeventSeries)/libevent-$($libeventVer).tar.gz"
$libeventTar     = (Join-Path $buildDir "libevent-$($libeventVer).tar.gz")
$msysLibeventTar = (Join-MingPath $msysBuildDir "libevent-$($libeventVer).tar.gz")
$libeventSum     = "c4c56f986aa985677ca1db89630a2e11"
$msysLibeventDir = (Join-MingPath $msysBuildDir "libevent-$($libeventVer)")

# Upgrade MSYS2
Start-Process -Wait -FilePath $msysShell -ArgumentList "-c 'pacman --noconfirm --needed -Sy bash pacman --noconfirm pacman --noconfirm-mirrors msys2-runtime'"
Start-Process -Wait -FilePath $msysShell -ArgumentList "-c 'pacman --noconfirm -Su'"

# Install compiler toolchain
Start-Process -Wait -FilePath $msysShell -ArgumentList "-c 'pacman --noconfirm --needed -S autoconf automake libtool make mingw-w64-x86_64-gcc'"

# Fetch the source
Download-File $libeventUrl $libeventTar $libeventSum
Download-File $memcachedUrl $memcachedTar $memcachedSum

$buildArgs = [string]::Join(" ", @(
    ". $msysStage2",
    "--root-dir",               $msysRootDir,
    "--build-dir",              $msysBuildDir,
    "--with-libevent-archive",  $msysLibeventTar,
    "--with-libevent-dir",      $msysLibeventDir,
    "--with-memcached-archive", $msysMemcachedTar,
    "--with-memcached-dir",     $msysMemcachedDir
))
Start-Process -Wait -FilePath $msysShell -ArgumentList "-c '$($buildArgs); sleep 30'"
