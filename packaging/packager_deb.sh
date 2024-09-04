#!/bin/bash
set -e

readonly distro="${DISTRO:-ubuntu}"
readonly distro_version="${VERSION:-xenial}"
readonly distro_root="${ROOT:-$HOME}"

# deb dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
# python3
apt-get -y install python3 python3-coverage python3-venv
# pip dependencies (for dependencies not available as DEB)
apt-get -y install gcc libx11-dev libxtst-dev python3-dev libpng-dev python3-pip
# create a venv to use that as the python env
rm -rf docker_venv
python3 -m venv docker_venv
source docker_venv/bin/activate
pip3 install --upgrade pip
# setup tools
pip3 install setuptools setuptools-rust
# python-imaging
apt-get -y install python3-pil
pip3 install pillow==10.4.0
# upgrade pip
pip3 install --upgrade pip
echo "contour, template, feature, cascade, text matching"
apt-get -y install python3-numpy
pip3 install numpy

pip3 install opencv-python

echo "text matching"

apt-get -y install tesseract-ocr libtesseract-dev
apt-get -y install g++ pkg-config
pip3 install pytesseract==0.3.10 tesserocr==2.7.0

echo "deep learning"
pip3 install torch==2.2.0 torchvision==0.17.0
echo "screen controlling"
#if [[ $DISABLE_AUTOPY == 1 ]]; then
#  export DISABLE_AUTOPY=1
#else
#  pip3 install autopy
#fi
export DISABLE_AUTOPY=1
# TODO: vncdotool doesn't control its Twisted which doesn't control its "incremental" dependency
pip3 install incremental==22.10.0
pip3 install vncdotool==0.12.0
apt-get -y install xdotool x11-apps imagemagick
apt-get -y install python3-tk scrot
apt-get -y install gnome-screenshot
pip3 install pyautogui==0.9.54
apt-get -y install x11vnc

echo "------------- deb packaging and installing of current guibot source -------------"
apt-get -y install dh-make dh-python debhelper python3-all devscripts
NAME=$(sed -n 's/^Package:[ \t]*//p' "$distro_root/guibot/packaging/debian/control")
CHANGELOG_REVS=($(sed -n -e 's/^guibot[ \t]*(\([0-9]*.[0-9]*\)-[0-9]*).*/\1/p' "$distro_root/guibot/packaging/debian/changelog"))
VERSION=${CHANGELOG_REVS[0]}
echo "------------- COPY -------------"
cp -r "$distro_root/guibot" "$distro_root/$NAME-$VERSION"
echo "------------- CD -------------"
cd "$distro_root/$NAME-$VERSION/packaging"
echo "------------- debuild -------------"
debuild --no-tgz-check --no-lintian -i -us -uc -b
echo "------------- copy -------------"
cp ../${NAME}_${VERSION}*.deb "$distro_root/guibot"
echo "------------- install guibot -------------"
apt-get -y install "$distro_root/guibot/"${NAME}_${VERSION}*.deb
echo "------------- rm -fr -------------"
rm -fr "$distro_root/$NAME-$VERSION"

echo "virtual display"
apt-get -y install xvfb vim-common
export DISPLAY=:99.0
Xvfb :99 -screen 0 1024x768x24 &> /tmp/xvfb.log  &
touch /root/.Xauthority
xauth add ${HOST}:99 . $(xxd -l 16 -p /dev/urandom)
sleep 3  # give xvfb some time to start

echo "------------- unit tests -------------"
apt-get install -y python3-pyqt5
export XDG_RUNTIME_DIR="/tmp/runtime-root"
mkdir /tmp/runtime-root
chmod 0700 /tmp/runtime-root
echo "--------- cd ---------"
cd /usr/lib/python3/dist-packages/guibot/tests
LIBPATH=".." COVERAGE="python3-coverage" sh coverage_analysis.sh

exit 0
