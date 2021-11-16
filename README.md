# idr0094-ellinger-sarscov2

Notebook: [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/IDR/idr0094-ellinger-sarscov2/master?urlpath=notebooks%2Fnotebooks%2Fidr0094-ic50.ipynb%3FscreenId%3D2603)

RShiny: [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/IDR/idr0094-ellinger-sarscov2/master?urlpath=shiny/apps/)

To build locally the notebooks and shiny apps locally:

 * Install [Docker](https://www.docker.com/) if required
 * Create a virtual environment and install repo2docker from PyPI.
 * Clone this repository
 * Run  ``repo2docker``. 
 * Depending on the permissions, you might have to run the commands as an administrator.

```
pip install jupyter-repo2docker
git clone https://github.com/IDR/idr0094-ellinger-sarscov2.git
cd idr0094-ellinger-sarscov2
repo2docker .
```

## License

The code in this repository is licensed under [BSD 2-Clause](LICENSE_BSD.md).
