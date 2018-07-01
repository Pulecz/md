# Hi

this is just a test to see how
```bash
tree content/ --noreport
```

will look like on homepage

# result 1

Sadly the current jekkyl theme converts the markdown code:
```markdown
Contents:
content/
├── [arch00_install.md](content/arch00_install)
└── [test.md](content/test)
```
as this html:
```html
<p>Contents:
content/
├── <a href="content/arch00_install">arch00_install.md</a>
└── <a href="content/test">test.md</a></p>
```

Which is one liner, the </br> tags are needed for nice result
```html
<p>Contents: content/</br>
├── <a href="content/arch00_install">arch00_install.md</a></br>
└── <a href="content/test">test.md</a></p>
```

Going to have to figure out other way.
Update1: [contents](contents) seem to work, but lets do it nicer
