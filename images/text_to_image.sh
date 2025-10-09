#imagemagick hates apostrophes
if [ "$1" == "'" ]; then
    exit 0
fi
FP="menu/"
if [ "$5" == "en" ]; then
    if [ "$3" == "5" ]; then
        WIDTH=$(magick -debug annotate  xc: -font TinyUnicode -pointsize 16 -interword-spacing 2 -gravity west \
                -annotate 0 "$1" null: 2>&1 |\
            grep Metrics: | grep -Po 'width: \K\d+')

        WIDTH=$((WIDTH+1))

        magick -size ${WIDTH}x9 xc:transparent +antialias \
        -font TinyUnicode -pointsize 16 -interword-spacing 2 -gravity west \
        -draw "fill black         text  2,-4  '$1' \
            fill black         text  2,-3  '$1' \
            fill black         text  2,-2  '$1' \
            fill black         text  0,-4  '$1' \
            fill black         text  0,-3  '$1' \
            fill black         text  0,-2  '$1' \
            fill black         text  1,-4  '$1' \
            fill black         text  1,-3  '$1' \
            fill black         text  1,-2  '$1' \
            fill '$4'          text  1,-3  '$1' " \
        png32:"${FP}$2".png
    fi
elif [ "$5" == "jp" ]; then
    if [ "$3" == "10" ]; then
        WIDTH=$(magick -debug annotate  xc: -font BestTenDOT -pointsize 10 \
                -annotate 0 "$1" null: 2>&1 |\
            grep Metrics: | grep -Po 'width: \K\d+')

        WIDTH=$((WIDTH+1))

        magick -size ${WIDTH}x12 xc:transparent +antialias \
        -font BestTenDOT -pointsize 10  -gravity west \
        -draw "fill black         text  2,2  '$1' \
            fill black         text  2,0  '$1' \
            fill black         text  2,1  '$1' \
            fill black         text  0,2  '$1' \
            fill black         text  0,0  '$1' \
            fill black         text  0,1  '$1' \
            fill black         text  1,2  '$1' \
            fill black         text  1,0  '$1' \
            fill black         text  1,1  '$1' \
            fill '$4'          text  1,1  '$1' " \
        png32:"${FP}$2".png
    elif [ "$3" == "8" ]; then
        WIDTH=$(magick -debug annotate  xc: -font MisakiGothic2nd -pointsize 8 \
                -annotate 0 "$1" null: 2>&1 |\
            grep Metrics: | grep -Po 'width: \K\d+')

        WIDTH=$((WIDTH+1))

        magick -size ${WIDTH}x9 xc:transparent +antialias \
        -font MisakiGothic2nd -pointsize 8  -gravity west \
        -draw "fill black         text  2,2  '$1' \
            fill black         text  2,0  '$1' \
            fill black         text  2,1  '$1' \
            fill black         text  0,2  '$1' \
            fill black         text  0,0  '$1' \
            fill black         text  0,1  '$1' \
            fill black         text  1,2  '$1' \
            fill black         text  1,0  '$1' \
            fill black         text  1,1  '$1' \
            fill '$4'          text  1,1  '$1' " \
        png32:"${FP}$2".png
    fi
elif [ "$5" == "jp_ext" ]; then
        WIDTH=$(magick -debug annotate  xc: -font battlenet -pointsize 16 -interword-spacing 2 -gravity west \
                -annotate 0 "$1" null: 2>&1 |\
            grep Metrics: | grep -Po 'width: \K\d+')

        WIDTH=$((WIDTH+1))

        magick -size ${WIDTH}x12 xc:transparent +antialias \
        -font battlenet -pointsize 16 -interword-spacing 2 -gravity west \
        -draw "fill black         text  2,1  '$1' \
            fill black         text  2,0  '$1' \
            fill black         text  2,-1  '$1' \
            fill black         text  0,1  '$1' \
            fill black         text  0,0  '$1' \
            fill black         text  0,-1  '$1' \
            fill black         text  1,1  '$1' \
            fill black         text  1,0  '$1' \
            fill black         text  1,-1 '$1' \
            fill '$4'          text  1,0 '$1' " \
        png32:"${FP}$2".png
elif [ "$5" == "jp_8_ext" ]; then
        WIDTH=$(magick -debug annotate  xc: -font Thintel -pointsize 18 -interword-spacing 2 -gravity west \
                -annotate 0 "$1" null: 2>&1 |\
            grep Metrics: | grep -Po 'width: \K\d+')

        WIDTH=$((WIDTH+1))

        magick -size ${WIDTH}x9 xc:transparent +antialias \
        -font Thintel -pointsize 18 -interword-spacing 2 -gravity west \
        -draw "fill black         text  2,-2  '$1' \
            fill black         text  2,0  '$1' \
            fill black         text  2,-1  '$1' \
            fill black         text  0,-2  '$1' \
            fill black         text  0,0  '$1' \
            fill black         text  0,-1  '$1' \
            fill black         text  1,-2  '$1' \
            fill black         text  1,0  '$1' \
            fill black         text  1,-1 '$1' \
            fill '$4'          text  1,-1 '$1' " \
        png32:"${FP}$2".png
elif [ "$5" == "score" ]; then
        WIDTH=$(magick -debug annotate  xc: -font Synthetica -pointsize 16 -interword-spacing 2 -gravity west \
                -annotate 0 "$1" null: 2>&1 |\
            grep Metrics: | grep -Po 'width: \K\d+')

        WIDTH=$((WIDTH+1))

        magick -size ${WIDTH}x12 xc:transparent +antialias \
        -font Synthetica -pointsize 16 -interword-spacing 2 -gravity west \
        -draw "fill black         text  2,0  '$1' \
            fill black         text  2,1  '$1' \
            fill black         text  2,2  '$1' \
            fill black         text  0,0  '$1' \
            fill black         text  0,1  '$1' \
            fill black         text  0,2  '$1' \
            fill black         text  1,0  '$1' \
            fill black         text  1,1  '$1' \
            fill black         text  1,2  '$1' \
            fill '$4'          text  1,1  '$1' " \
        png32:"${FP}$2".png
fi
