# Publishing to PyPI

The PyPI distribution name is `lattis`; the Python import name is
`lattis`.

## Local release check

```sh
python3 -m venv .venv
.venv/bin/python -m pip install maturin numpy twine
.venv/bin/python -m maturin build --release --out dist
.venv/bin/python -m maturin sdist --out dist
.venv/bin/python -m twine check dist/*
.venv/bin/python -m pip install --force-reinstall dist/lattis-*.tar.gz
```

## Upload

Preferred: create a GitHub release or manually run the `python-publish`
workflow. Configure a PyPI Trusted Publisher for:

* repository: `todo-group/lattis`
* workflow: `python-publish.yml`
* environment: `pypi`
* project: `lattis`

Manual upload is also possible:

```sh
.venv/bin/python -m maturin upload dist/*
```
