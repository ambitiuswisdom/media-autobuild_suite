# Menu data for media-autobuild_suite.ps1 (PowerShell 5.1 and 7).
# Choices keep the display label beside the value passed to the Bash build.
# Array order is the saved INI number; keep existing choices in their current order.
# ConfigKey is needed only when the build variable differs from the INI Key.
# Question appears before the numbered choices; Help appears after them.
@{
    Options = @(
        @{
            Key = 'license2'
            Prompt = 'FFmpeg license'
            Question = 'Build FFmpeg with which license?'
            Choices = @(
                @{
                    Label = 'Non-free [unredistributable, but can include anything]'
                    Value = 'nonfree'
                }
                @{ Label = 'GPLv3 [disables FDK-AAC]'; Value = 'gplv3' }
                @{
                    Label = @'
GPLv2
  [Also disables OpenSSL, gmp, opencore codecs]
'@
                    Value = 'gpl'
                }
                @{
                    Label = @'
LGPLv3
  [Disables x264, x265, XviD, GPL filters, etc.
   but allows OpenSSL/FDK-AAC]
'@
                    Value = 'lgplv3'
                }
                @{
                    Label = 'LGPLv2.1 [same disables as LGPLv3 + GPLv2, except OpenSSL]'
                    Value = 'lgpl'
                }
            )
            Help = @'
If building for yourself, it's OK to choose non-free.
If building to redistribute online, choose GPL or LGPL.
If building to include in a GPLv2 binary, choose LGPLv2.1 or GPLv2.
If you want to use FFmpeg together with closed source software, choose LGPL
and follow instructions in https://www.ffmpeg.org/legal.html

OpenSSL 3.0+ uses Apache-2.0 and is allowed with LGPL or GPLv3.
FDK-AAC is GPL-incompatible; it is allowed with LGPL.
'@
        }

        @{
            Key = 'standalone'
            Prompt = 'Build standalone binaries'
            Question = @'
Build standalone binaries for libraries included in FFmpeg?
eg. Compile opusenc.exe if --enable-libopus
'@
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'av1an'
            Prompt = 'Build av1an'
            Question = 'Build Av1an [Scalable video encoding framework]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
Av1an requires local installed copies of Python and Vapoursynth,
an executable of FFmpeg and FFprobe, and one of these encoders to function:
aom, SVT-AV1, rav1e, vpx, x264, or x265
'@
        }

        @{
            Key = 'vpx2'
            Prompt = 'Build vpx'
            Question = 'Build vpx [VP8/VP9 encoder]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = 'Binaries being built depends on "standalone/av1an=y" and are always static.'
        }

        @{
            Key = 'aom'
            Prompt = 'Build aom'
            Question = 'Build aom [Alliance for Open Media codec]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = 'Binaries being built depends on "standalone/av1an=y" and are always static.'
        }

        @{
            Key = 'rav1e'
            Prompt = 'Build rav1e'
            Question = 'Build rav1e [Alternative, faster AV1 standalone encoder]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = 'Binaries being built depends on "standalone/av1an=y" and are always static.'
        }

        @{
            Key = 'dav1d'
            Prompt = 'Build dav1d'
            Question = 'Build dav1d [Alternative, faster AV1 decoder]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = 'Binaries being built depends on "standalone=y" and are always static.'
        }

        @{
            Key = 'libavif'
            Prompt = 'Build libavif'
            Question = 'Build libavif [AV1 image format encoder and decoder]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
Binaries being built depends on "standalone=y" and are always static.
Will build aom, dav1d, and rav1e if not already previously enabled
'@
        }

        @{
            Key = 'libheif'
            Prompt = 'Build libheif'
            Question = 'Build libheif [High Efficiency Image File Format encoder and decoder]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
                @{
                    Label = 'Shared (a single libheif.dll with multiple executables)'
                    Value = 'shared'
                }
            )
            Help = @'
Will use available encoders and decoders supported by libheif.
If not found, built libheif will lack the corresponding encode/decode ability.

Additionally libde265 will always be built.
dec265 executable from libde265 being built depends on "standalone=y"
and is always static.
'@
        }

        @{
            Key = 'jpegxl'
            Prompt = 'Build jpegxl'
            Question = 'Build jpeg-xl tools [JPEG XL image format encoder and decoder]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'jpegli'
            Prompt = 'Build jpegli'
            Question = 'Build jpegli tools [JPEG encoder and decoder with improved compression]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'x2643'
            ConfigKey = 'x264'
            Prompt = 'Build x264'
            Question = 'Build x264 [H.264 encoder]?'
            Choices = @(
                @{ Label = 'Lib/binary with 8 and 10-bit'; Value = 'yes' }
                @{ Label = 'No'; Value = 'no' }
                @{ Label = 'Lib/binary with only 10-bit'; Value = 'high' }
                @{
                    Label = 'Lib/binary with 8 and 10-bit, and libavformat and ffms2'
                    Value = 'full'
                }
                @{ Label = 'Shared lib/binary with 8 and 10-bit'; Value = 'shared' }
                @{
                    Label = 'Same as 4 with video codecs only (can reduce size by ~3MB)'
                    Value = 'fullv'
                }
                @{ Label = 'Lib/binary with only 8-bit'; Value = 'o8' }
            )
            Help = 'Binaries being built depends on "standalone/av1an=y" and are always static.'
        }

        @{
            Key = 'x2653'
            ConfigKey = 'x265'
            Prompt = 'Build x265'
            Question = 'Build x265 [H.265 encoder]?'
            Choices = @(
                @{ Label = 'Lib/binary with Main, Main10 and Main12'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
                @{ Label = 'Lib/binary with Main10 only'; Value = 'o10' }
                @{ Label = 'Lib/binary with Main only'; Value = 'o8' }
                @{ Label = 'Lib/binary with Main, shared libs with Main10 and Main12'; Value = 's' }
                @{ Label = 'Lib/binary with Main12 only'; Value = 'o12' }
            )
            Help = 'Binaries being built depends on "standalone/av1an=y" and are always static.'
        }

        @{
            Key = 'other265'
            Prompt = 'Build kvazaar'
            Question = 'Build Kvazaar? [H.265 encoder]'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'svthevc'
            Prompt = 'Build SVT-HEVC'
            Question = 'Build SVT-HEVC? [H.265 encoder]'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'xvc'
            Prompt = 'Build xvc'
            Question = 'Build xvc? [HEVC and AV1 competitor]'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
Any issues with this will be considered low-priority due to lack of
potential stability
'@
        }

        @{
            Key = 'uvg266'
            Prompt = 'Build uvg266'
            Question = 'Build uvg266? [H.266 encoder by ultravideo, the Kvazaar team]'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'vvenc'
            Prompt = 'Build vvenc'
            Question = 'Build vvenc? [Fraunhofer HHI Versatile Video Encoder]'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'vvdec'
            Prompt = 'Build vvdec'
            Question = 'Build vvdec? [Fraunhofer HHI Versatile Video Decoder]'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'svtav1'
            Prompt = 'Build SVT-AV1'
            Question = 'Build SVT-AV1? [AV1 encoder]'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
Look at the link for hardware requirements
https://github.com/OpenVisualCloud/SVT-AV1/blob/master/README.md#Hardware
'@
        }

        @{
            Key = 'svtvp9'
            Prompt = 'Build SVT-VP9'
            Question = 'Build SVT-VP9? [VP9 encoder]'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
Look at the link for hardware requirements
https://github.com/OpenVisualCloud/SVT-VP9#Hardware
'@
        }

        @{
            Key = 'flac'
            Prompt = 'Build flac'
            Question = 'Build FLAC? [Free Lossless Audio Codec]'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'fdkaac'
            Prompt = 'Build fdkaac'
            Question = 'Build FDK-AAC/xHE-AAC libraries and the fdkaac binary?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'faac'
            Prompt = 'Build faac'
            Question = 'Build FAAC binary? [old, low-quality AAC-LC and HE-AAC v1 encoder]'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'exhale'
            Prompt = 'Build exhale'
            Question = 'Build exhale binary? [open-source ISO/IEC 23003-3 USAC, xHE-AAC encoder]'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = 'Binaries being built do not depend on "standalone=y"'
        }

        @{
            Key = 'mediainfo'
            Prompt = 'Build mediainfo'
            Question = 'Build mediainfo binaries [Multimedia file information tool]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'soxB'
            ConfigKey = 'sox'
            Prompt = 'Build sox'
            Question = 'Build sox binaries [Sound processing tool]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'ffmpegB2'
            ConfigKey = 'ffmpeg'
            Prompt = 'Build FFmpeg'
            Question = 'Build FFmpeg binaries and libraries:'
            Choices = @(
                @{ Label = 'Yes [static] [recommended]'; Value = 'static' }
                @{ Label = 'No'; Value = 'no' }
                @{ Label = 'Shared'; Value = 'shared' }
                @{
                    Label = 'Both static and shared [shared goes to an isolated directory]'
                    Value = 'both'
                }
                @{
                    Label = @'
Shared-only with some shared dependencies (libass, freetype and fribidi)
'@
                    Value = 'sharedlibs'
                }
                @{
                    Label = 'Same as 4, but static compilation ignores shared dependencies'
                    Value = 'bothstatic'
                }
            )
            Help = @'
Note: Option 5 differs from 3 in that libass, freetype and fribidi are
compiled shared so they take less space. Currently broken if libass or libass
dependees are enabled.
Option 6 produces static and shared ffmpeg and ffmpeg libs where the static
one includes only strictly static dependencies (opencl, libopenh264 are
hard disabled.)
'@
        }

        @{
            Key = 'ffmpegUpdate'
            Prompt = 'Build ffmpeg if lib is new'
            Question = 'Always build FFmpeg when libraries have been updated?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
                @{ Label = 'Only build FFmpeg/mpv and missing dependencies'; Value = 'onlyFFmpeg' }
            )
            Help = @'
FFmpeg is updated a lot so you only need to select this if you
absolutely need updated external libraries in FFmpeg.
'@
        }

        @{
            Key = 'ffmpegChoice'
            Prompt = 'Choose ffmpeg and mpv optional libs'
            Question = 'Choose ffmpeg and mpv optional libraries?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No (Light build)'; Value = 'n' }
                @{ Label = 'No (Mimic Zeranoe)'; Value = 'z' }
                @{ Label = 'No (All available external libs)'; Value = 'f' }
            )
            Help = @'
Avoid the last two unless you really want useless libraries you'll never use.
Just because you can include a shitty codec no one uses doesn't mean you should.

If you select yes, we will create files with the default options
we use with FFmpeg and mpv. You can remove any that you don't need or prefix
them with #
'@
        }

        @{
            Key = 'mp4box'
            Prompt = 'Build mp4box'
            Question = 'Build static mp4box [mp4 muxer/toolbox] binary?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'rtmpdump'
            Prompt = 'Build rtmpdump'
            Question = 'Build static rtmpdump binaries [rtmp tools]?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'mpv'
            Prompt = 'Build mpv'
            Question = 'Build mpv?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
Note: when built with shared-only FFmpeg, mpv is also shared.
Note: the third option was removed since vapoursynth is now a delay-import
dependency that is only required if you try to use the corresponding filter.
'@
        }

        @{
            Key = 'vlc'
            Prompt = 'Build vlc'
            Question = @'
Build VLC media player?
Takes a long time because of qt5 and wouldn't recommend it if you
don't have ccache enabled.
'@
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
Note: compilation of VLC is currently broken, do not enable unless you know
what you are doing.
'@
        }

        @{
            Key = 'bmx'
            Prompt = 'Build bmx'
            Question = 'Build static bmx tools?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'curl'
            Prompt = 'Build curl'
            Question = 'Build static curl?'
            Choices = @(
                @{ Label = 'Yes (same backend as FFmpeg''s)'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
                @{ Label = 'SChannel backend'; Value = 'schannel' }
                @{ Label = 'GnuTLS backend'; Value = 'gnutls' }
                @{ Label = 'OpenSSL backend'; Value = 'openssl' }
                @{ Label = 'LibreSSL backend'; Value = 'libressl' }
                @{ Label = 'mbedTLS backend'; Value = 'mbedtls' }
            )
            Help = @'
A curl-ca-bundle.crt will be created to be used as trusted certificate store
for all backends except SChannel.
'@
        }

        @{
            Key = 'cyanrip2'
            ConfigKey = 'cyanrip'
            Prompt = 'Build cyanrip'
            Question = 'Build cyanrip (CLI CD ripper)?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'ripgrep'
            Prompt = 'Build ripgrep'
            Question = 'Build ripgrep (faster grep in Rust)?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'jq'
            Prompt = 'Build jq'
            Question = 'Build jq (CLI JSON processor)?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'jo'
            Prompt = 'Build jo'
            Question = 'Build jo (CLI JSON from shell)?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'dssim'
            Prompt = 'Build dssim'
            Question = 'Build dssim (multiscale SSIM in Rust)?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'gifski'
            Prompt = 'Build gifski'
            Question = 'Build gifski (high quality GIF encoder in Rust)?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'With built-in video support'; Value = 'video' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'avs2'
            Prompt = 'Build avs2'
            Question = 'Build avs2 (Audio Video Coding Standard Gen2 encoder/decoder)?'
            Choices = @(
                @{ Label = 'Yes (official davs2, 8-bit only)'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
                @{ Label = 'Yes (unofficial davs2 fork with 10-bit support)'; Value = '10bit' }
            )
            Help = 'Binaries being built depends on "standalone=y" and are always static.'
        }

        @{
            Key = 'dovitool'
            Prompt = 'Build dovi_tool'
            Question = 'Build dovi_tool (CLI tool for working with Dolby Vision)?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'hdr10plustool'
            Prompt = 'Build hdr10plus_tool'
            Question = 'Build hdr10plus_tool (CLI utility to work with HDR10+ in HEVC files)?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
        }

        @{
            Key = 'zlib'
            Prompt = 'Build zlib'
            Question = 'Build zlib?'
            Choices = @(
                @{ Label = 'Yes, build zlib'; Value = 'y' }
                @{ Label = 'Yes, build zlib (Chromium fork)'; Value = 'chromium' }
                @{ Label = 'Yes, build zlib (Cloudflare fork)'; Value = 'cloudflare' }
                @{ Label = 'Yes, build zlib-ng'; Value = 'ng' }
                @{ Label = 'Yes, build zlib-rs'; Value = 'rs' }
                @{ Label = 'No, use msys2 package when needed [Recommended]'; Value = 'n' }
            )
            Help = 'If "standalone=y", then minizip will be built alongside zlib.'
        }

        @{
            Key = 'CC'
            Prompt = 'Build using clang'
            Question = @'
Use clang instead of gcc (C compiler)?
Experimental and possibly broken due to gcc assumptions
'@
            Choices = @(
                @{ Label = 'Yes'; Value = 'clang' }
                @{ Label = 'No [Recommended]'; Value = 'gcc' }
            )
        }

        @{
            Key = 'deleteSource'
            Prompt = 'Delete source'
            Question = 'Delete versioned source folders after compile is done?'
            Choices = @(
                @{ Label = 'Yes [recommended]'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = 'This will save a bit of space for libraries not compiled from git.'
        }

        @{
            Key = 'strip'
            ConfigKey = 'stripFile'
            Prompt = 'Strip files'
            Question = 'Strip compiled files binaries?'
            Choices = @(
                @{ Label = 'Yes [recommended]'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = 'Makes binaries smaller at only a small time cost after compiling.'
        }

        @{
            Key = 'pack'
            ConfigKey = 'packFile'
            Prompt = 'Pack files'
            Question = 'Pack compiled files?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No [recommended]'; Value = 'n' }
            )
            Help = @'
Attention: Some security applications may detect packed binaries as malware.
Increases delay on runtime during which files need to be unpacked.
Makes binaries smaller at a big time cost after compiling and on runtime.

If distributing the files, consider packing them with 7-zip instead.
'@
        }

        @{
            Key = 'logging'
            Prompt = 'Write logs'
            Question = 'Write logs of compilation commands?'
            Choices = @(
                @{ Label = 'Yes [recommended]'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
Note: Setting this to yes will also hide output from these commands.
On successful compilation, these logs are deleted since they aren't needed.
'@
        }

        @{
            Key = 'updateSuite'
            Prompt = 'Create update script'
            Question = 'Create script to update suite files automatically?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
If you have made changes to the scripts, they will be reset but saved to a
.diff text file inside build
'@
        }

        @{
            Key = 'timeStamp'
            Prompt = 'Show timestamps'
            Question = 'Show timestamps of commands during compilation?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
This will show the start times of commands during compilation.
Don't turn this on unless you really want to see the timestamps.
'@
        }

        @{
            Key = 'ccache'
            Prompt = 'Use ccache'
            Question = 'Use ccache when compiling?'
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
Speeds up rebuilds and recompilations, but requires the files
to be compiled at least once before any effect is seen
'@
        }

        @{
            Key = 'noMintty'
            Prompt = 'SSH'
            Question = @'
Are you running this script through ssh or similar?
(Can't open another window outside of this terminal)
'@
            Choices = @(
                @{ Label = 'Yes'; Value = 'y' }
                @{ Label = 'No'; Value = 'n' }
            )
            Help = @'
This will disable the use of mintty and print the output to this console.
There is no guarantee that this will work properly.
You must make sure that you have ssh keep-alive enabled or something similar
to screen that will allow you to run this script in the background.
'@
        }
    )
}
