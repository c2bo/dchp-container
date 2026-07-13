# dchp-container

Run `git submodule update --remote` to update dependency

Run container with this command:

```
docker run --rm -v "$PWD:/work" ghcr.io/c2bo/dchp-container
```

Expects to be in the root of the dchp repository, consumes `draft/digital-credentials-harmonized-presentation.md` and creates a `build/` folder.
