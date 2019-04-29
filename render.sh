#!/bin/bash
set -euo pipefail
set -x

BASE_DIR="${BASE_DIR:-/tmp/}"

has_program() {
    hash $1 2> /dev/null
    return $?
}

get() {
    local url=${1/https:\/\/www/http:\/\/xml}

    if has_program curl; then
        curl -Ls $url
    elif has_program wget; then
        wget $url --quiet -O -
    else
        echo "Neither curl nor wget found. Aborting."
        usage
        exit 1
    fi
}

getImages() {
    grep -Po '(?<=<img src=")(.+?)(?=")' $1 | while read line
    do
        local imageUrl=$(echo "$line" | sed 's/http:\/\/xml/https:\/\/img/g')
        local imageFile=$(mktemp -p $2 "image.XXXXXXX.jpg")
        get "$imageUrl" > $imageFile
        sed -i "s|$line|${imageFile##*/}|g" $1

    done

}

convert() {
    xsltproc $1 -
}

usage() {
    cat <<EOF
Usage: $0 [-df] URL

Converts articles from zeit.de from XML to simple HTML.

Requires either curl or wget for downloading, xsltproc for conversion and
xdg-open or open for viewing.

-d : Download images locally

-f : Produce a more fancy version with better styling
EOF
}

redirect_to() {
  cat << _EOF_
Content-type: text/html

<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Refresh" content="0; url="/${1}" />
  </head>
</html>
_EOF_
}

main() {
    local downloadImages=false
    local xsltFile="zeitoffline.xslt"
    if [[ $# -gt 0 ]]; then
        while getopts ":df" opt
        do
            case $opt in
                d)
                    downloadImages=true
                    ;;
                f)
                    xsltFile="zeitoffline-fancy.xslt"
                    ;;
                \?)
                    echo "Invalid option: -$OPTARG" >&2
                    usage
                    exit 1
            esac
        done
        shift $(expr $OPTIND - 1 )
        # local folder=$(mktemp -d)
        # local filename=$(make_filename $folder)

        # Remove trailing slash and use article name as folder name
        local folder_name="$(echo ${1%/} | sed -r 's#.*/(.*)#\1#')"
				local folder_path="${BASE_DIR}/${folder_name}"
        local file_name="index.html"
        local file_path="${folder_path}/${file_name}"
        mkdir -p "${folder_path}"

        get $1 | convert $xsltFile > $file_path
        if [[ $downloadImages = true ]]; then
            getImages $file_path $folder_path
        fi
        redirect_to "${folder_name}/${file_name}"
    else
        usage
        exit 1
    fi
}

main "$@"
