# Installation

Bubble requires **Python 3.9+** (3.12 recommended). External tools (Pandoc, LaTeX, …) are listed in [System requirements](system-requirements.md).

## Install from PyPI (recommended)

Wheels are published as **`peanutbook`** (PyPI name `bubble` is taken):

```bash
pip install peanutbook
```

Import name remains `bubble`; all `bubble-*` entry points are installed on your `PATH`.

## Conda environment

```bash
conda create -n bubble python=3.12
conda activate bubble
pip install peanutbook
```

Many book projects use a conda env for chapter figure scripts; set `"conda_env"` in `peanut.config` if your `img/*.py` generators need it.

## Linux: system Python and pip

On Debian/Ubuntu, system Python may report **externally-managed-environment** when installing with pip. Use a virtualenv or conda env (recommended), or:

```bash
pip install peanutbook --user --break-system-packages
```

Optional pip user config (`~/.pip/pip.conf` or `~/.config/pip/pip.conf`):

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
