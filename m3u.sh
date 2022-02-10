#!/bin/sh
KEY="XXXXX-XXX-XXX-XXX-XXXXX"
if [ -z $1 ]
then
echo "usage m3u.sh /opt/rclone/Film ftp://admin:za920600ur@svyaznoy362.synology.me TEST"
exit 0
fi
if [ -z $2 ]
then
echo "usage m3u.sh /opt/rclone/Film ftp://admin:za920600ur@svyaznoy362.synology.me TEST"
exit 0
fi
if [ -z $3 ]
then
echo "usage m3u.sh /opt/rclone/Film ftp://admin:za920600ur@svyaznoy362.synology.me TEST"
exit 0
fi
pattern=$2
echo pattern is $pattern
echo "#EXTM3U" > /opt/$3.m3u

find "$1" -type f -name *.mkv -o -name *.iso -o -name *.m2ts -o -name *.mp4 -o -name *.mp3 -o -name *.flac | sed "s+$1+$2+g" > /opt/$3.txt

while IFS= read -r line; do
#exclude xattr folder

    echo $line | grep ".xattr"
    if [ $? -eq 0 ]
    then
    continue
    fi
    
    FILESIZE=$(ls -lh "$(echo $line | sed "s+$2+$1+g")" | awk '{print  $5}')
    echo "Size of $line = $FILESIZE"
    name=$(echo $line | sed "s+$pattern++g" | rev | cut -d "/" -f 2- | rev )
    nname=$(echo $line | sed "s+$pattern++g" | rev | cut -d "/" -f 1 | rev | cut -d "." -f 1)
    rev_name=$(echo $line | sed "s+$pattern++g" | rev |  cut -d "/" -f 1 | rev |  cut -d "." -f 1 | tr "_" " " | tr "-" " ")
    post=$(echo $line | sed "s+$2+$1+g")
    poster_path=${post%.*}
    postter=$poster_path"-poster.jpg"
    fake_poster=$(echo $pattern${name}/poster.jpg |  sed "s+$2+$1+g")

#   get kp id from name search
    real_kp=$(echo $line | grep -oP 'kp-\K\w+')
    if [ -z $real_kp ]
    then
    kp=$(curl -k --silent -G "https://kinopoiskapiunofficial.tech/api/v2.1/films/search-by-keyword" --data-urlencode "keyword=$rev_name" -H "accept: application/json" -H "X-API-KEY: $KEY" | jq -r '.films[0].filmId')
    else
    kp=$real_kp
    fi
#posters
    if [ -f "$postter" ]; then
    poster=$(echo $postter | sed "s+$1+$2+g" | sed "s+ +%20+g")
    elif [ -f "$fake_poster" ]; then
    poster=$(echo $pattern${name}/poster.jpg | sed "s+ +%20+g")
    else
    poster=$(curl -k --silent -X GET "https://kinopoiskapiunofficial.tech/api/v2.2/films/$kp" -H "accept: application/json" -H "X-API-KEY: $KEY" | jq -r '.posterUrl')
    fi
#get m3u options from api
    options=$(curl -k --silent -X GET "https://kinopoiskapiunofficial.tech/api/v2.2/films/$kp" -H "accept: application/json" -H "X-API-KEY: $KEY" | jq -r '. | "video-title=\"\(.countries[0].country).\(.year).(КП:\(.ratingKinopoisk) | IMDb:\(.ratingImdb))\" video-desc=\"\(.description)\" group-title=\"\(.genres[0].genre)\"" ')
#form m3u
    echo "#EXTINF:-1 $(echo $options | tr -d '\011\012\013\015') tvg-logo=\"$poster\", $name/$nname | $FILESIZE" >> /opt/$3.m3u
    echo $line >> /opt/$3.m3u
done < /opt/$3.txt
