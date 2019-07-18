# wine-build-script

Script for building Wine on 64-bit Ubuntu 18.04.

Resulting Wine build will support 32-bit and 64-bit applications.
The host system (64-bit Ubuntu 18.04) running the script builds 64-bit Wine and
Docker container (32-bit Ubuntu 18.04) builds 32-bit Wine.

## Usage

1. Clone this repository.

2. Enable source repositories for `apt-get build-dep` command.

3. Install Wine runtime and build dependencies, Docker and git.

```
sudo apt install wine-stable docker.io git
sudo apt-get build-dep wine-stable
```

4. Add your user account to `docker` group.
Change username to command below before running it.
```
sudo usermod -a -G docker change-your-username-here
```

Logging out and in is probably required to
make Docker know about this change.

5. Test that there isn't permission errors
from Docker.

```
docker --version
docker info
```

4. Run build script.

By default script uses directory `~/wine-build-script` for the source code and builds.
Set environment variable `WINE_BUILD_SCRIPT_DIR` to change this directory.

Script creates Docker image with tag `wine-32-bit-build-environment`.

```
./wine-build-script.sh --download-source-code --create-docker-image
./wine-build-script.sh --configure
./wine-build-script.sh --build -j4
```

5. Wine build with 32-bit and 64-bit support is in directory `~/wine-build-script/wine-build`.

Example command to run `winecfg`. Change home directory name to command below before running it.

```
WINESERVER=/home/change-your-home-directory-name-here/wine-build-script/wine-build/server/wineserver \
~/wine-build-script/wine-build/wine winecfg
```

## Additional details

* When using script option `--create-docker-image` file `template-Dockerfile` must be in
the current working directory. Script copies this file and adds your user id and group id into it.
* Script supports `configure` and `make` options.
* Script option `--help` also prints current working directory, build directory, Wine git repository URL and Docker image tag.

## License

MIT License
