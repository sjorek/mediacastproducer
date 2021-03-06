Mediacast Producer
==================

Version 0.1
Copyright 2011-2017 Stephan Jorek

complements:
Podcast Producer action task, version 2.0
Copyright 2006-2011 Apple, Inc.

The Mediacast Producer action tasks integrate several popular tools as
“ffmpeg” or ”VLC” in Apple's Podcast Producer.  This allows the automatic
production of media-file formats that go far beyond MP4.

IMPORTANT NOTE:  This file is licensed only for use on Apple-branded computers
and is subject to the terms and conditions of the Software License Agreement
accompanying the package this file is a part of.  You may not port this file
to another platform without Apple's written consent.


## Installing

Instructions for installing this software are in [INSTALL](INSTALL.md).


## Usage

Execute `bin/mediacastproducer help` or `bin/mediacastencoder help`
to get an up-to-date command usage reference.

Producer tasks
================================================================================

## ffmpeg

execute ffmpeg with passed arguments

    usage: ffmpeg --prb=PRB -- [--arguments passed to ffmpeg]
             [--path]     print ffmpeg executable path and exit
             [--version]  print ffmpeg executable version and exit


## ffmpeg2theora

execute ffmpeg2theora with passed arguments

    usage: ffmpeg2theora --prb=PRB -- [--arguments passed to ffmpeg2theora]
             [--path]     print ffmpeg2theora executable path and exit
             [--version]  print ffmpeg2theora executable version and exit


## id3taggenerator

execute id3taggenerator with passed arguments

    usage: id3taggenerator --prb=PRB -- [--arguments passed to id3taggenerator]
             [--path]     print id3taggenerator executable path and exit
             [--version]  print id3taggenerator executable version and exit


## mediacastsegmenter

execute mediacastsegmenter with passed arguments

    usage: mediacastsegmenter --prb=PRB -- [--arguments passed to mediacastsegmenter]
             [--path]     print mediacastsegmenter executable path and exit
             [--version]  print mediacastsegmenter executable version and exit


## mediafilesegmenter

execute mediafilesegmenter with passed arguments

    usage: mediafilesegmenter --prb=PRB -- [--arguments passed to mediafilesegmenter]
             [--path]     print mediafilesegmenter executable path and exit
             [--version]  print mediafilesegmenter executable version and exit


## mediastreamsegmenter

execute mediastreamsegmenter with passed arguments

    usage: mediastreamsegmenter --prb=PRB -- [--arguments passed to mediastreamsegmenter]
             [--path]     print mediastreamsegmenter executable path and exit
             [--version]  print mediastreamsegmenter executable version and exit


# mediastreamvalidator

execute mediastreamvalidator with passed arguments

    usage: mediastreamvalidator --prb=PRB -- [--arguments passed to mediastreamvalidator]
             [--path]     print mediastreamvalidator executable path and exit
             [--version]  print mediastreamvalidator executable version and exit


## mp4faststart

optimize MP4-alike (incl. Quicktime) for streaming

    usage: mp4faststart --prb=PRB --input=INPUT
                    [--output=OUTPUT]  write to OUTPUT, otherwise work in place on INPUT
                    [--streamable]     test and exits accordingly with 0 or 1; e.g.:
                                       ... && echo true || echo false


## quicktime

transcodes the input file to the output file with the specified preset

    usage:  quicktime --prb=PRB --input=INPUT --output=OUTPUT --preset=PRESET

    the available presets are:
    …


## reference

copies a reference movie linking the input movies to
the document root of a web server.

    usage: reference --basedir=BASEDIR --web_root=WEB_ROOT --web_url=WEB_URL
                     --title=TITLE
                     --edge_movie=EDGE --wifi_movie=WIFI --desktop_movie=DESKTOP
                     [--iphone_edge_movie=EDGE] [--iphone_wifi_movie=WIFI]
                     [--ipad_edge_movie=EDGE] [--ipad_wifi_movie=WIFI]
                     [--type=MIME_TYPE] [--outfile[=OUTFILE]] [--create_poster_image]


## toolscript

transcodes the INPUT file to the OUTPUT file with the specified tool SCRIPT

    usage:  toolscript --prb=PRB --input=INPUT --output=OUTPUT --script=SCRIPT
            [--verbose]  run with verbose output
            [-- [...]]   additional options depending on the script choosen,
                         leave empty to get help

    the available scripts are:
    …


## variantplaylistcreator

execute variantplaylistcreator with passed arguments

    usage: variantplaylistcreator --prb=PRB -- [--arguments passed to variantplaylistcreator]
             [--path]     print variantplaylistcreator executable path and exit
             [--version]  print variantplaylistcreator executable version and exit


## videosize

get Quicktime or Mp4-alike movie- and render-dimensions

    usage: videosize --prb=PRB --input=INPUT
                    [--output=OUTPUT]    re-encode INPUT to OUTPUT if dimensions differ
                    [--key=KEY]          KEY to lookup, forces the dimension if OUTPUT is given
                    [--human]            display human readable values


## vlc

execute vlc with passed arguments

    usage: vlc --prb=PRB -- [--arguments passed to vlc]
             [--path]     print vlc executable path and exit
             [--version]  print vlc executable version and exit


## webpreview

starts a web- and optionally a proxy-server for preview purposes.

    usage: webpreview --basedir=BASEDIR
                     [--verbose]    run with verbose output

    web-server configuration:
                     [--web_vhost]  virtual hostname (FQDN) to serve
                     [--web_alias]  path alias rule(s)

    web-proxy configuration:
                     [--proxy_rw]   hostname rewrite rule(s)
                     [--proxy_dl]   download bandwidth limit
                     [--proxy_ul]   upload bandwidth limit
                     [--proxy_ip]   IP adress to serve, default:
                                      all (locally) available IPs
                     [--proxy_if]   Network interface to serve, default:
                                      all (locally) available interfaces
                                    IP adress and network interface
                                    are mutually exclusive.


Encoder scripts
================================================================================

## ffmpeg2theora_cbr

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a constant bitrate for both tracks

    usage:  ffmpeg2theora_cbr --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## ffmpeg2theora_cbr_4:3_320x240_576kbit_44,1khz_stereo_192kbit

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a constant bitrate for both tracks

    usage:  ffmpeg2theora_cbr_4:3_320x240_576kbit_44,1khz_stereo_192kbit --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## ffmpeg2theora_qbr

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a quality based variable bitrate for both tracks

    usage:  ffmpeg2theora_qbr --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_quality      video-quality, value range from 0 to 10
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_quality      audio-quality, value range from -2 to 10
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## ffmpeg2theora_qbr_4:3_320x240_q6_44,1khz_stereo_q6

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a quality based variable bitrate for both tracks

    usage:  ffmpeg2theora_qbr_4:3_320x240_q6_44,1khz_stereo_q6 --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_quality      video-quality, value range from 0 to 10
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_quality      audio-quality, value range from -2 to 10
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## ffmpeg2theora_vbr

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a variable bitrate for both tracks

    usage:  ffmpeg2theora_vbr --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      average video bitrate in kBit per second
            [--video_quality]     optional: minimum allowed video quality,
                                  value-range from 0 to 10
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## ffmpeg2theora_vbr_4:3_320x240_576kbit_44,1khz_stereo_128-192-256kbit

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a variable bitrate for both tracks

    usage:  ffmpeg2theora_vbr_4:3_320x240_576kbit_44,1khz_stereo_128-192-256kbit --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      average video bitrate in kBit per second
            [--video_quality]     optional: minimum allowed video quality,
                                  value-range from 0 to 10
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## vlc_mp4_cbr

transcode INPUT to an MP4 container with H264 encoded video-track and AAC
encoded audio-track, using a constant bitrate for both tracks

ATTENTION: broken (very poor quality) due to missing vlc capabilities

    usage:  vlc_mp4_cbr --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000



## vlc_mp4_cbr_3:2_480x320_576kbit_44,1khz_stereo_192kbit

transcode INPUT to an MP4 container with H264 encoded video-track and AAC
encoded audio-track, using a constant bitrate for both tracks

ATTENTION: broken (very poor quality) due to missing vlc capabilities

    usage:  vlc_mp4_cbr_3:2_480x320_576kbit_44,1khz_stereo_192kbit --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000



## vlc_mpeg2_ts_mediastreamsegmenter

mux INPUT into MPEG2 transport stream segments consisting of H264 video-track
and AAC audio-track, using a constant bitrate for both tracks

ATTENTION: broken (very poor quality) due to missing vlc capabilities

    usage:  vlc_mpeg2_ts_mediastreamsegmenter --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000

             --base_url           a base url the stream will be published to
             --segment_duration   duration of the generated segments in seconds,
                                  value-range from 7 seconds to 30 seconds


## vlc_ogv_cbr

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a constant bitrate for both tracks

    usage:  vlc_ogv_cbr --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## vlc_ogv_cbr_4:3_320x240_576kbit_44,1khz_stereo_192kbit

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a constant bitrate for both tracks

    usage:  vlc_ogv_cbr_4:3_320x240_576kbit_44,1khz_stereo_192kbit --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## vlc_ogv_qbr

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a quality based variable bitrate for both tracks

    usage:  vlc_ogv_qbr --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_quality      video-quality, value-range from 0 to 10
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_quality      audio-quality, value-range from -2 to 10
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## vlc_ogv_qbr_4:3_320x240_q6_44,1khz_stereo_q6

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a quality based variable bitrate for both tracks

    usage:  vlc_ogv_qbr_4:3_320x240_q6_44,1khz_stereo_q6 --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_quality      video-quality, value-range from 0 to 10
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_quality      audio-quality, value-range from -2 to 10
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## vlc_ogv_vbr

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a variable bitrate for both tracks

    usage:  vlc_ogv_vbr --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      average audio bitrate in kBit per second
             --audio_bitrate_min  minimum audio bitrate in kBit per second
             --audio_bitrate_max  maximum audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## vlc_ogv_vbr_4:3_320x240_576kbit_44,1khz_stereo_128-192-256kbit:

transcode INPUT to an OGG container with Theora encoded video-track and Vorbis
encoded audio-track, using a variable bitrate for both tracks

    usage:  vlc_ogv_vbr_4:3_320x240_576kbit_44,1khz_stereo_128-192-256kbit --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      average audio bitrate in kBit per second
             --audio_bitrate_min  minimum audio bitrate in kBit per second
             --audio_bitrate_max  maximum audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## vlc_webm_cbr

transcode INPUT to an WebM container with VP80 encoded video-track and Vorbis
encoded audio-track, using a constant bitrate for both tracks

    usage:  vlc_webm_cbr --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## vlc_webm_cbr_4:3_320x240_576kbit_44,1khz_stereo_192kbit

transcode INPUT to an WebM container with VP80 encoded video-track and Vorbis
encoded audio-track, using a constant bitrate for both tracks

    usage:  vlc_webm_cbr_4:3_320x240_576kbit_44,1khz_stereo_192kbit --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000

## vlc_webm_vbr

transcode INPUT to an WebM container with VP80 encoded video-track and Vorbis
encoded audio-track, using a variable bitrate for both tracks

    usage:  vlc_webm_vbr --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      average audio bitrate in kBit per second
             --audio_bitrate_min  minimum audio bitrate in kBit per second
             --audio_bitrate_max  maximum audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000


## vlc_webm_vbr_4:3_320x240_576kbit_44,1khz_stereo_128-192-256kbit:

transcode INPUT to an WebM container with VP80 encoded video-track and Vorbis
encoded audio-track, using a variable bitrate for both tracks

    usage:  vlc_webm_vbr_4:3_320x240_576kbit_44,1khz_stereo_128-192-256kbit --prb=PRB --input=INPUT --output=OUTPUT
            [--verbose]  run with verbose output

             --video_bitrate      video bitrate in kBit per second
             --video_width        video width in pixel
             --video_height       video height in pixel
            [--video_fps]         optional: video frames per second

             --audio_bitrate      average audio bitrate in kBit per second
             --audio_bitrate_min  minimum audio bitrate in kBit per second
             --audio_bitrate_max  maximum audio bitrate in kBit per second
            [--audio_channels]    optional: number of audio channels,
                                  possible values: 1 (mono) or 2 (stereo)
            [--audio_samplerate]  optional: audio samplerate in hz, possible values:
                                  8000, 11025, 12000, 16000, 22500, 24000, 32000,
                                  44100 or 48000
