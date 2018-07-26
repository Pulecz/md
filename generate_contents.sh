find content -type f | xargs -I {} echo "* [{}]({})" | sed 's/.md//g' | sed 's/content\///'
