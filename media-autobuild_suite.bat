@echo off
rem -----------------------------------------------------------------------------
rem LICENSE --------------------------------------------------------------------
rem -----------------------------------------------------------------------------
rem  This Windows Batchscript is for setup a compiler environment for building
rem  ffmpeg and other media tools under Windows.
rem
rem    Copyright (C) 2013  jb_alvarado
rem
rem    This program is free software: you can redistribute it and/or modify
rem    it under the terms of the GNU General Public License as published by
rem    the Free Software Foundation, either version 3 of the License, or
rem    (at your option) any later version.
rem
rem    This program is distributed in the hope that it will be useful,
rem    but WITHOUT ANY WARRANTY; without even the implied warranty of
rem    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
rem    GNU General Public License for more details.
rem
rem    You should have received a copy of the GNU General Public License
rem    along with this program.  If not, see <https://www.gnu.org/licenses/>.
rem -----------------------------------------------------------------------------
setlocal
set "script=%~dp0media-autobuild_suite.ps1"
if not exist "%script%" (
    echo PowerShell entry point not found: "%script%"
    exit /b 1
)

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%script%" %*
exit /b %ERRORLEVEL%

rem Default option data: shared with the unchanged Bash helper.
rem Preserve the original separators for its sed range parser.

:: built-ins
set ffmpeg_options_builtin=--disable-autodetect amf bzlib cuda cuda-llvm cuvid d3d11va d3d12va ^
dxva2 ffnvcodec iconv lzma mediafoundation nvdec nvenc schannel sdl2 zlib

:: common external libs
set ffmpeg_options_basic=--disable-debug gmp gpl libaom libdav1d libfdk-aac libmp3lame libopus ^
libsvtav1 libvorbis libvpl libvpx libx264 libx265

:: options used in zeranoe builds and not present above
set ffmpeg_options_zeranoe=avisynth fontconfig gnutls libass libbluray libfreetype libgsm ^
libharfbuzz libmysofa libopencore-amrnb libopencore-amrwb libopenjpeg libopenmpt librav1e libshine ^
libsnappy libsoxr libspeex libsrt libtheora libtls libtwolame libvidstab libvmaf libvo-amrwbenc ^
libwebp libxml2 libxvid libzimg #mbedtls openssl version3

:: options also available with the suite
set ffmpeg_options_full=audiotoolbox cairo chromaprint #cuda-nvcc decklink frei0r ladspa lcms2 ^
libaribb24 libaribcaption libastcenc libbs2b libcaca libcdio libcodec2 libcurl libdavs2 libdvdnav ^
libdvdread libfdk-xhe-aac libflite libfribidi libgme libilbc libjxl libkvazaar liblc3 #liblensfun libmodplug ^
libmpeghdec liboapv libplacebo libqrencode libquirc librist librtmp librubberband libssh ^
libsvthevc libsvtjpegxs libsvtvp9 libtesseract libuavs3d libvvdec libvvenc libxavs libxavs2 ^
libxevd libxeve libzmq libzvbi openal vapoursynth vulkan

:: options also available with the suite that add shared dependencies
set ffmpeg_options_full_shared=libopenh264 opencl

:: built-ins
set mpv_options_builtin="#-Dcplayer=true" #manpage-build #lua #javascript ^
#libbluray #uchardet #rubberband #lcms2 #libarchive #libavdevice ^
#shaderc #spirv-cross #d3d11 #jpeg #vapoursynth #vulkan

:: overriden defaults
set mpv_options_basic="-Dlua=luajit"

:: all supported options
set mpv_options_full=dvdnav cdda #egl-angle #html-build ^
#pdf-build openal sdl2-gamepad sdl2-audio sdl2-video
