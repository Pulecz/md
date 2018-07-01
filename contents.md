# Contents
my url should be $0/md/contents

md is $repo_name

## (semi)-auto generated list of contents:
```bash
$ find content -type f | xargs -I {} echo "* [{}]({})" | sed 's/.md//g' | sed 's/content\///'
```
```plain
find all files in content | then print it in markdown link fmt | then remove all .md (global regex) | then remove first notion of content/
then remove .md
```