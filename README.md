# JSOC Workflow

This repository hosts the scripts and executables for operating the JSOC
pipeline workflow.

## Compiling and installing

We have one executable, `GetNextID`, that needs to be compiled.
This is done by using either CMake, for systems with Cmake >= 3.6, or by using
our custom Makefile.
For older machines, you may need to default to `make`.
Both make systems allow you to install the compiled binary and copy the
appropriate scripts to a runtime directory.
See the following subsections for information to do this.

In general, it is good practice to remove the build and install directories if
you are making changes that add or remove files in the final install directory,
to make sure nothing is left over from previous builds.

### CMake

If you are using CMake, the commands follow the fairly standard format.
Run CMake to configure the make files, run in build mode to compile the
executable, and follow in install mode to install everything needed for runtime.
This is done by doing the following:

```bash
cmake -B build -D CMAKE_INSTALL_PREFIX=/some/directory/to/install/to
cmake --build build
cmake --install build
```
where `-B build` is specifying the name of the build directory ("build") which
holds all the CMake information used to compile and install,
`-D CMAKE_INSTALL_PREFIX=` is specifying the directory in which to install the
executable and scripts, `--build` is compiling the executables, and `--install`
is installing everything to the directory specified by `CMAKE_INSTALL_PREFIX`.

After running in install mode, all necessary runtime files should be in your
install directory.
To clear any previous CMake files, you can just delete your build directory.
To remove the install directory, just delete it as well.

### Makefile

If you need to use `make` instead, you will want to run the following commands:

```bash
make
make install MAKE_INSTALL_PREFIX=/some/directory/to/install/to
```
where `MAKE_INSTALL_PREFIX=` is specifying the directory in which to install
the executable and scripts.

There is also a `make uninstall` target to clear out the install directory.
To use this, just call
`make uninstall MAKE_INSTALL_PREFIX=/some/directory/to/install/to`, to let it
know where you installed the files.
You could also just delete the install directory manually.

## Modifying the repo

If you are adding new scripts or removing some, you may need to update the
make systems to know which files to include in the installation.
This should only be necessary if you are adding scripts that do not have the
extension `.csh`, `.pm`, or `.pl`.
