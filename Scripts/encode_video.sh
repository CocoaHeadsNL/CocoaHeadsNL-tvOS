#!/bin/bash
#
# Script to batch compress videos of CocoaHeadsNL meetups.
# It will convert a given video master file to an H.264 MPEG-4 AVC files in several
# different screen resolutions, frame rates and bitrates. These MPEG-4 files will
# then be used to generated HLS file segments and m3u8 playlists.
#
# Created by Marco Miltenburg
# Copyright © 2018-2020 Stichting CocoaHeadsNL. All rights reserved.
# 
# License: Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)
#

# Version number
version="1.2.1"

# The base URL where the videos are stored
baseurl=https://s3.dualstack.eu-central-1.amazonaws.com/tvos.cocoaheads.nl/video

# Set year to default value of current year
year=$(date +%-Y)

# Set month to default value of current month
month=$(date +%-m)

# The base output filename. If none is specified on the command line, a default name will be created based on the input filename.
output_filename=""

# An optional sub-directory, this can be used for special events.
sub_dir=""

# The lowest framerate to use
framerate_low="25"

# The highest framerate to use
framerate_high="50"

# Process a single video file. This will encode the video, split it into segments for HLS and generate the necessary m3u8 playlist files.
# Parameters:
# $1 = Input filename
# $2 = Year
# $3 = Month
# $4 = Base output filename
# $5 = Optional sub-directory, e.g. for special events
process_video()
{
    encode_video "$1" "$(output_directory_for_preset 1 $2 $3 $5)" "$(output_filename_with_extension $2 $3 $4 "mp4")" 1
    encode_video "$1" "$(output_directory_for_preset 2 $2 $3 $5)" "$(output_filename_with_extension $2 $3 $4 "mp4")" 2
    encode_video "$1" "$(output_directory_for_preset 3 $2 $3 $5)" "$(output_filename_with_extension $2 $3 $4 "mp4")" 3
    if [ "$framerate_low" != "$framerate_high" ]; then
        encode_video "$1" "$(output_directory_for_preset 4 $2 $3 $5)" "$(output_filename_with_extension $2 $3 $4 "mp4")" 4
    fi
    encode_video "$1" "$(output_directory_for_preset 5 $2 $3 $5)" "$(output_filename_with_extension $2 $3 $4 "mp4")" 5

    segment_video "$(output_directory_for_preset 1 $2 $3 $5)" "$(base_output_filename $2 $3 "$4")"
    segment_video "$(output_directory_for_preset 2 $2 $3 $5)" "$(base_output_filename $2 $3 "$4")"
    segment_video "$(output_directory_for_preset 3 $2 $3 $5)" "$(base_output_filename $2 $3 "$4")"
    if [ "$framerate_low" != "$framerate_high" ]; then
        segment_video "$(output_directory_for_preset 4 $2 $3 $5)" "$(base_output_filename $2 $3 "$4")"
    fi
    segment_video "$(output_directory_for_preset 5 $2 $3 $5)" "$(base_output_filename $2 $3 "$4")"

    create_master_playlist $2 $3 "$(base_output_filename $2 $3 "$4")" "$5"
}

# Encode a single video file using ffmpeg
# Parameters:
# $1 = Input filename
# $2 = Output directory
# $3 = Output filename
# $4 = The preset number to use for the encoding
encode_video()
{
    mkdir -p "$2"
    printf "\nEncoding video to: $(ffmpeg_preset_description $4)\n"
    ffmpeg -y -v error -stats -i "$1" $(ffmpeg_preset $4) "$2/$3"
}

# Splits a video file into HLS segments and generate the m3u8 playlist index files.
# Parameters:
# $1 = Base directory name
# $2 = Base output filename
segment_video()
{
    mediafilesegmenter -q -base-url "$baseurl/$1/" -file-base "$1/" -index-file "$(add_file_extension "$2" 'm3u8')" -iframe-index-file "$(add_file_extension "$2" "iframes.m3u8")" -base-media-file-name "$2-" "$1/$(add_file_extension "$2" "mp4")"
}

# Creates the master playlist from the individual m3u8 playlist created for each resolution.
# Parameters:
# $1 = Year
# $2 = Month
# $3 = Base output filename
# $4 = Optional sub-directory, e.g. for special events
create_master_playlist()
{
    if [ "$framerate_low" != "$framerate_high" ]; then
        variantplaylistcreator -o "$(output_directory $1 $2 $4)/$(add_file_extension "$3" 'm3u8')" \
            $(variantplaylist_parameters_for_preset 3 $1 $2 $3 $4) \
            $(variantplaylist_parameters_for_preset 1 $1 $2 $3 $4) \
            $(variantplaylist_parameters_for_preset 2 $1 $2 $3 $4) \
            $(variantplaylist_parameters_for_preset 4 $1 $2 $3 $4) \
            $(variantplaylist_parameters_for_preset 5 $1 $2 $3 $4)
    else
        variantplaylistcreator -o "$(output_directory $1 $2 $4)/$(add_file_extension "$3" 'm3u8')" \
            $(variantplaylist_parameters_for_preset 3 $1 $2 $3 $4) \
            $(variantplaylist_parameters_for_preset 1 $1 $2 $3 $4) \
            $(variantplaylist_parameters_for_preset 2 $1 $2 $3 $4) \
            $(variantplaylist_parameters_for_preset 5 $1 $2 $3 $4)
    fi
}

# Return the parameters to use for the variantplaylistcreater for a specific preset.
# Parameters:
# $1 = The preset number
# $2 = Year
# $3 = Month
# $4 = Base output filename
# $5 = Optional sub-directory, e.g. for special events
variantplaylist_parameters_for_preset()
{
    # Special case for 1280 x 720 as we don't need to encode that twice when the low and high framerates are the same
    if [ "$1" != "4" ] || [ "$framerate_low" != "$framerate_high" ]; then
        echo "$baseurl/$(output_directory_for_preset $1 $2 $3 $5)/$(add_file_extension "$4" 'm3u8')" "$(output_directory_for_preset $1 $2 $3 $5)/$(add_file_extension "$4" 'plist')" \
             "$baseurl/$(output_directory_for_preset $1 $2 $3 $5)/$(add_file_extension "$4" 'iframes.m3u8')" "$(output_directory_for_preset $1 $2 $3 $5)/$(add_file_extension "$4" 'plist')"
    fi
}

# Returns the ffmpeg parameters to use for a specific preset
# Parameters:
# $1 = The preset number
ffmpeg_preset()
{
    case $1 in

        # AVC - 640 x 360 @ 25/30fps
        1) echo "-c:a aac -ac 2 -b:a 64k -ar 48000 -c:v libx264 -flags +cgop -pix_fmt yuv420p -profile:v baseline -level 3.1 -maxrate $(bitrate_for_preset $1)K -bufsize 3M -crf 20 -r $(framerate_for_preset $1) -f mp4 -s $(resolution_for_preset $1)";;

        # AVC - 960 x 540 @ 25/30fps
        2) echo "-c:a aac -ac 2 -b:a 64k -ar 48000 -c:v libx264 -flags +cgop -pix_fmt yuv420p -profile:v main -level 3.2 -maxrate $(bitrate_for_preset $1)K -bufsize 5M -crf 20 -r $(framerate_for_preset $1) -f mp4 -s $(resolution_for_preset $1)";;

        # AVC - 1280 x 720 @ 25/30fps
        3) echo "-c:a aac -ac 2 -b:a 96k -ar 48000 -c:v libx264 -flags +cgop -pix_fmt yuv420p -profile:v main -level 3.2 -maxrate $(bitrate_for_preset $1)K -bufsize 8M -crf 20 -r $(framerate_for_preset $1) -f mp4 -s $(resolution_for_preset $1)";;

        # AVC - 1280 x 720 @ 50/60fps
        4) echo "-c:a aac -ac 2 -b:a 96k -ar 48000 -c:v libx264 -flags +cgop -pix_fmt yuv420p -profile:v main -level 3.2 -maxrate $(bitrate_for_preset $1)K -bufsize 10M -crf 20 -r $(framerate_for_preset $1) -f mp4 -s $(resolution_for_preset $1)";;

        # AVC - 1920 x 1280 @ 50/60fps
        5) echo "-c:a aac -ac 2 -b:a 128k -ar 48000 -c:v libx264 -flags +cgop -pix_fmt yuv420p -profile:v high -level 4.2 -maxrate $(bitrate_for_preset $1)K -bufsize 16M -crf 20 -r $(framerate_for_preset $1) -f mp4 -s $(resolution_for_preset $1)";;

    esac
}

# Returns a description for a specific preset
# Parameters:
# $1 = The preset number
ffmpeg_preset_description()
{
    echo "H.264 MPEG-4 AVC - $(resolution_for_preset $1) @ $(framerate_for_preset $1)fps (max. $(bitrate_for_preset $1) kbits/s)"
}

# Returns a string that represents the frame rate to use for the given preset
# Parameters:
# $1 = The preset number
framerate_for_preset()
{
    case $1 in

        # Low framerates for these presets
        [1-3]) echo "$framerate_low";;

        # High framerate for these presets
        [4-5]) echo "$framerate_high";;

    esac
}

# Returns a string that represents the resolution to use for the given preset
# Parameters:
# $1 = The preset number
resolution_for_preset()
{
    case $1 in

        # AVC - 640 x 360 @ 25/30fps
        1) echo "640x360";;

        # AVC - 960 x 540 @ 25/30fps
        2) echo "960x540";;

        # AVC - 1280 x 720 @ 25/30fps
        3) echo "1280x720";;

        # AVC - 1280 x 720 @ 50/60fps
        4) echo "1280x720";;

        # AVC - 1920 x 1280 @ 50/60fps
        5) echo "1920x1080";;

    esac
}

# Returns a string that represents the codec to use for the given preset
# Parameters:
# $1 = The preset number
codec_for_preset()
{
    case $1 in

        # AVC
        [1-5]) echo "avc";;

    esac
}

# Returns the maximum bitrate in kbit/s to use for the given preset
# Parameters:
# $1 = The preset number
bitrate_for_preset()
{
    case $1 in

        # AVC - 640 x 360 @ 25/30fps
        1) echo "800";;

        # AVC - 960 x 540 @ 25/30fps
        2) echo "2000";;

        # AVC - 1280 x 720 @ 25/30fps
        3) echo "3000";;

        # AVC - 1280 x 720 @ 50/60fps
        4) echo "4500";;

        # AVC - 1920 x 1280 @ 50/60fps
        5) echo "7800";;

    esac
}

# Returns the base output directory to use.
# Parameters:
# $1 = The year of the date of the video
# $2 = The month of the date of the video
# $3 = Optional sub-directory, e.g. for special events
output_directory()
{
    if [ "$3" != "" ]; then
        echo "$1-$2/$3"
    else
        echo "$1-$2"
    fi
}

# Returns the output directory to use for a given preset
# Parameters:
# $1 = The preset number
# $2 = The year of the date of the video
# $3 = The month of the date of the video
# $4 = Optional sub-directory, e.g. for special events
output_directory_for_preset()
{
    echo "$(output_directory $2 $3 $4)/$(resolution_for_preset $1)@$(framerate_for_preset $1)-$(codec_for_preset $1)"
}

# Returns the output file name to use
# Parameters:
# $1 = The year of the date of the video
# $2 = The month of the date of the video
# $3 = The base filename
# $4 = The file extension
output_filename_with_extension()
{
    echo "$(add_file_extension $(base_output_filename $1 $2 $3) $4)"
}

# Returns the output file name to use
# Parameters:
# $1 = The year of the date of the video
# $2 = The month of the date of the video
# $3 = The base filename
base_output_filename()
{
    echo "$1-$2-$3"
}

# Adds the file extension to the file name
# Parameters:
# $1 = The base filename
# $2 = The file extension
add_file_extension()
{
    echo "$1.$2"
}

# Set the output filename to a sanitized version of the given filename so that it only contains alpha-numeric characters, minus and underscore.
# Parameters:
# $1 = Filename to sanitize
create_output_filename()
{
    local sanitized="$1"

    # Remove extension from filename
    sanitized=${sanitized%.*}
    
    # Clean out anything that's not alphanumeric, a minus or an underscore
    sanitized=${sanitized//[^a-zA-Z0-9_- ]/_}

    # Convert to lowercase
    output_filename="$(echo -n $sanitized | tr 'A-Z' 'a-z')"
}

# Returns the given default value in case the given first parameter is an empty string. If not, it returns the first parameter within single quotes.
# Parameters:
# $1 = The parameter to check if it's empty.
# $2 = The default value to use
default_for_quoted()
{
    if [ "$1" == "" ]; then
        echo "$2"
    else
        echo "'$1'"
    fi
}

# Retuns the ANSI code to switch back to no color
nocolor()
{
    echo "\033[0m"
}

# Retuns the ANSI code for color to use for errors
errorcolor()
{
    echo "\033[0;31m"
}

# Retuns the ANSI code for color to use for headers
headercolor()
{
    echo "\033[0;36m"
}

# Retuns the ANSI code for color to use for parameters
parametercolor()
{
    echo "\033[0;32m"
}

# Retuns the ANSI code for color to use for options
optioncolor() 
{
    echo "\033[0;33m"
}

# Retuns the ANSI code for color to use for dimmed text
dimmedcolor()
{
    echo "\033[1;30m"
}

# Retuns the Show version information
show_version()
{
    echo "$version"
}

# Show usage information with command line options
show_usage()
{
    printf "\n$(headercolor)Usage:$(nocolor)\n"
    printf "  $0 [$(optioncolor)options$(nocolor)] <$(parametercolor)input-file$(nocolor)>\n"
    printf "\n$(headercolor)Parameters:$(nocolor)\n"
    printf "  $(parametercolor)input-file$(nocolor)                  The input video file to process.\n"
    printf "\n$(headercolor)Options:$(nocolor)\n"
    printf "  $(optioncolor)-o$(nocolor)   $(dimmedcolor)(or $(optioncolor)--output-file$(dimmedcolor))$(nocolor)     The base name for the output file (default is based on input filename).\n"
    printf "  $(optioncolor)-m$(nocolor)   $(dimmedcolor)(or $(optioncolor)--month$(dimmedcolor))$(nocolor)           The year of the recording of the video (default is $(default_for_quoted "$year" "none")).\n"
    printf "  $(optioncolor)-y$(nocolor)   $(dimmedcolor)(or $(optioncolor)--year$(dimmedcolor))$(nocolor)            The month of the recording of the video (default is $(default_for_quoted "$month" "none")).\n"
    printf "  $(optioncolor)-s$(nocolor)   $(dimmedcolor)(or $(optioncolor)--sub-dir$(dimmedcolor))$(nocolor)         Optional sub-directory for output (default is $(default_for_quoted "$sub_dir" "none")).\n"
    printf "  $(optioncolor)-fl$(nocolor)  $(dimmedcolor)(or $(optioncolor)--framerate-low$(dimmedcolor))$(nocolor)   The lowest framerate to use (default is $(default_for_quoted "$framerate_low" "none")).\n"
    printf "  $(optioncolor)-fh$(nocolor)  $(dimmedcolor)(or $(optioncolor)--framerate-high$(dimmedcolor))$(nocolor)  The highest framerate to use (default is $(default_for_quoted "$framerate_high" "none")).\n"
    printf "  $(optioncolor)-v$(nocolor)   $(dimmedcolor)(or $(optioncolor)--version$(dimmedcolor))$(nocolor)         Show the version number.\n"
    printf "  $(optioncolor)-h$(nocolor)   $(dimmedcolor)(or $(optioncolor)--help$(dimmedcolor))$(nocolor)            Show this help screen.\n"
    printf "\n"
}

# Show header with name, version and copyright
show_header()
{
    printf "\n$(dimmedcolor)CocoaHeadsNL Video Encoding Utility v$version\n"
    printf "Copyright © $(copyright_years) Stichting CocoaHeadsNL. All rights reserved.$(nocolor)\n"
}

# Show error message
show_error_message()
{
    if [ "$1" != "" ]; then
        printf "\n$(errorcolor)$1$(nocolor)\n"
    fi
}

# Show both header and usage information and optionally an error message
show_header_and_usage()
{
    show_header
    show_error_message "$1"
    show_usage
}

# Returns the years to use for the copyright message
copyright_years()
{
    startyear="2018"
    endyear="$(date +%Y)"
    if [ "$startyear" != "$endyear" ]; then
        echo "$startyear-$endyear";
    else
        echo "$startyear"
    fi
}

arguments=()

# Main entry point that will parse command line options
while [[ $# -gt 0 ]]; do
    key="$1"
    
    case $key in

        -y | --year)
            year="$2"
            shift;;

        -m | --month)
            month="$2"
            shift;;
        
        -o | --output-file)
            output_filename="$2"
            shift;;

        -s | --sub-dir)
            sub_dir="$2"
            shift;;

        -fl | --framerate_low)
            framerate_low="$2"
            shift;;

        -fh | --framerate_high)
            framerate_high="$2"
            shift;;

        -h | --help)
            show_header_and_usage
            exit;;

        -v | --version)
            show_version
            exit;;

        -* | --*)
            # Argument starts with '-' or '--' but we don't know it
            show_header_and_usage "Unknown option '$key'"
            exit 1;;

        *)
            # Additional arguments, just save them
            arguments+=("$1");;

    esac
    
    shift

done

# Restore additional arguments as positional arguments
set -- "${arguments[@]}"

# Make sure we have an input filename
if [ "$1" == "" ]; then
    show_header_and_usage "No input file specified"
    exit 1
fi

show_header

# If no output filename is specified, we create one based on the input filename
if [ "$output_filename" == "" ]; then
    create_output_filename "$1"
fi

# Add leading zero's to year and month
year=$(printf "%04d" $year)
month=$(printf "%02d" $month)

# Process the video file
process_video "$1" "$year" "$month" "$output_filename" "$sub_dir"
exit 0
