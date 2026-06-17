# Installation

Bubble requires **Python 3.9+** (3.12 recommended). External tools (Pandoc, LaTeX, …) are listed in [System requirements](system-requirements.md).

## Install from PyPI (recommended)

Wheels are published as **`bubble-book`** (PyPI name `bubble` is taken):

```bash
pip install bubble-book
```

Import name remains `bubble`; all `bubble-*` entry points are installed on your `PATH`.

## Editable install (toolchain development)

If you have the private **peanutbook** source tree (not the public docs repo):

```bash
cd /path/to/peanutbook
pip install -e .
```

Use the **same Python environment** for installs and builds (e.g. `conda activate your-env`). After install, `which bubble-build` should point at that env’s `bin/` directory.

If `pip install -e .` succeeds but no `bubble-*` commands appear, reinstall from a recent tree — console scripts are declared in `setup.py` and must be listed as `dynamic = ["scripts"]` in `pyproject.toml` so current setuptools installs them.

## Conda environment

```bash
conda create -n bubble python=3.12
conda activate bubble
pip install bubble-book
```

Many book projects use a conda env for chapter figure scripts; set `"conda_env"` in `peanut.config` if your `img/*.py` generators need it.

## macOS Homebrew Python

If you see **externally-managed-environment**, either use a virtualenv/conda env, or:

```bash
pip install bubble-book --user --break-system-packages
```

Permanent pip user install (optional), in `~/.pip/pip.conf` or `~/.config/pip/pip.conf`:

```ini
[global]
break-system-packages = true
user = true
```

## Verify installation

```bash
bubble-build --help
bubble-convert --help
python -c "import bubble; print('bubble OK')"
```

## Default configuration template

Copy the bundled default config into your book project:

```bash
cp "$(python -c "import bubble, os; print(os.path.join(os.path.dirname(bubble.__file__), 'peanut.config.default'))")" ./peanut.config
```

Edit `peanut.config` in your project root; values merge with the package default (project keys win). See [Configuration](configuration.md).
