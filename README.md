# AMP Docker Images

This repository contains images for use with AMP by CubeCoders. These images are updated at least weekly.

These images are not designed to be run directly. Instead, they should be run via the AMP Instance Manager.

Currently maintained image tags:

- [debian](https://github.com/CubeCoders/dockerfiles/tree/master/base/debian): the primary AMP base image, used for most AMP instances. Currently based on Debian 12. Usually updated to the current stable Debian release after the first point release
- [debian-13](https://github.com/CubeCoders/dockerfiles/tree/master/base/debian-13): an alternate AMP base image, based on Debian 13. This is available for testing before the `debian` image is updated
- [ubuntu](https://github.com/CubeCoders/dockerfiles/tree/master/base/ubuntu): an alternate AMP base image, currently based on Ubuntu 24.04. Usually updated to the current Ubuntu LTS release after the first point release
- [java-lts](https://github.com/CubeCoders/dockerfiles/tree/master/base/java-lts): an image based on the `debian` image, incorporating Adoptium Eclipse Temurin Java 8, 11, 17 and 21 LTS builds from https://adoptium.net
- [python-3](https://github.com/CubeCoders/dockerfiles/tree/master/base/python-3): an image based on the `debian` image, incorporating official builds for Python 3.10, 3.11 (default), 3.12 and 3.13
- [python-3.10](https://github.com/CubeCoders/dockerfiles/tree/master/base/python-3.10): an image based on the `debian` image, incorporating the official build for Python 3.10
- [python-3.11](https://github.com/CubeCoders/dockerfiles/tree/master/base/python-3.11): an image based on the `debian` image, incorporating the official build for Python 3.11
- [python-3.12](https://github.com/CubeCoders/dockerfiles/tree/master/base/python-3.12): an image based on the `debian` image, incorporating the official build for Python 3.12
- [python-3.13](https://github.com/CubeCoders/dockerfiles/tree/master/base/python-3.13): an image based on the `debian` image, incorporating the official build for Python 3.13
- [mono-latest](https://github.com/CubeCoders/dockerfiles/tree/master/base/mono-latest): an image based on the `debian` image, incorporating the latest official build for Mono from https://mono-project.com
- [wine-stable](https://github.com/CubeCoders/dockerfiles/tree/master/base/wine-stable): an image based on the `debian` image, incorporating the latest Wine stable build from https://winehq.org
- [wine-devel](https://github.com/CubeCoders/dockerfiles/tree/master/base/wine-devel): an image based on the `debian` image, incorporating the latest Wine devel build from https://winehq.org
- [wine-staging](https://github.com/CubeCoders/dockerfiles/tree/master/base/wine-staging): an image based on the `debian` image, incorporating the latest Wine staging build from https://winehq.org
- [wine-10-stable](https://github.com/CubeCoders/dockerfiles/tree/master/base/wine-10-stable): an image based on the `debian` image, incorporating the latest Wine 10 stable build from https://winehq.org
- [wine-9-stable](https://github.com/CubeCoders/dockerfiles/tree/master/base/wine-9-stable): an image based on the `debian` image, incorporating the latest Wine 9 stable build from https://winehq.org

All images are built for `linux/amd64` and `linux/arm64`. The `linux/arm64` builds include [box86](https://github.com/Pi-Apps-Coders/box86-debs) and [box64](https://github.com/Pi-Apps-Coders/box64-debs).