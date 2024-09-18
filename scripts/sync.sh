#!/bin/bash
export PATH="$PATH:$(pwd)"
RUN_CONVERT="java -jar ./Lite2Edit-1.2.0.jar --convert "

mkdir -p ../result
mkdir -p ../tmp

process() {
  if [[ $1 == *.schem ]]; then
    echo "cp $1 ../result"
  elif [[ $1 == *.litematic ]]; then
    cp "$1" ../tmp
    FILE=../tmp/$(basename "$1")
    $RUN_CONVERT "$FILE"
    rm -f "$FILE"
    echo "Processed: $1 ->\n $(ls ../tmp)"
    mv ../tmp/* ../result
  fi
}

remove_remote() {
  echo "Removing file on server: $1"
  special_curl "$API_ENDPOINT/api/client/servers/$SERVER_ID/files/delete" -H "Content-Type: application/json" -H "Accept: application/json" -X POST -H "Authorization: Bearer $TOKEN" -d "{\"root\": \"/config/worldedit/schematics\", \"files\": $1}"
}

upload_remote(){
  echo "Uploading file to server: $1"
  SIGNED_URL=$(special_curl $API_ENDPOINT/api/client/servers/$SERVER_ID/files/upload -H "Authorization: Bearer $TOKEN" | jq -r ".attributes.url")
  special_curl "$SIGNED_URL&directory=/config/worldedit/schematics" -X POST -F "files=@$1"
}


for entry in "../structures"/*
do
  process "$entry"
done

echo "Removing old versions..."
PAYLOAD=$(special_curl $API_ENDPOINT/api/client/servers/$SERVER_ID/files/list\?directory\=/config/worldedit/schematics -H "Authorization: Bearer $TOKEN" | jq -c "[.data[] | .attributes.name]")
remove_remote "$PAYLOAD"

echo "Uploading to server..."
for entry in "../result"/*
do
  upload_remote "$entry"
done

echo "DONE!"