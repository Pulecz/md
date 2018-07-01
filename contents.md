# Contents
my url should be **$0/md/contents**
where:
* $0 is $username.github.io
* md is $repo_name
* conetets is file name

## (semi)-auto generated list of contents:
```bash
$ find content -type f | xargs -I {} echo "* [{}]({})" | sed 's/.md//g' | sed 's/content\///'
```
```plain
find all files in content
  | then print it in markdown link fmt
  | then remove all .md (global regex) |
  | then remove first notion of content/
```

## TODO html tingy which creates something like:
```bash
$ tree content
content
├──  arch00_install.md
├──  arch_tips.md
├──  arch_what_install.md
├──  arch_zsh.md
├──  i3.md
├──  python_edu.md
├──  test.md

0 directories, 7 files
```