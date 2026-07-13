# dchp-container

Run `git submodule update --remote` to update dependency

## Build a specific markdown file

Pass a path to a mmark markdown file. Output (`.html` editor's copy and `.docx`)
is written to the current directory:

```
docker run --rm -v "$PWD:/work" ghcr.io/c2bo/dchp-container spec.md
```

Add a target to build only one format: `spec.md html` or `spec.md docx`
(default is both).
