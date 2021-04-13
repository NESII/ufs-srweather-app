#!/bin/bash

usage () {
  printf "Usage: $0 PLATFORM [OPTIONS]...\n"
  printf "\n"
  printf "PLATFORM\n"
  printf "  Name of machine you are building on\n"
  printf "\n"
  printf "OPTIONS\n"
  printf "  -c, --compiler=COMPILER\n"
  printf "      compiler to use; valid options are 'intel(d)', 'gnu'\n"
  printf "  -t, --components=\"COMPONENT1;COMPONENT2...\"\n"
  printf "      components to include in model build, delimited with ';'\n"
  printf "  -r, --remove_build\n"
  printf "      remove existing build directory\n"
  printf "\n"
  printf "NOTE: This script is for internal developer use only;\n"
  printf "See User's Guide for detailed build instructions\n"
}

PLATFORM=""
COMPILER="intel"
COMPONENTS=""
RMBUILD=false

if [ $# -lt 1 ]; then
  echo "ERROR: not enough arguments"; usage; exit 1
elif [[ $1 == "-"* ]]; then
  echo "ERROR: missing arguments"; usage; exit 1
fi
PLATFORM="$1"; shift

while :; do
  case $1 in
# HELP
    --help|-h) usage; exit 0 ;;
# PLATFORM
    --platform|-p)
      if [ "$2" ]; then
        PLATFORM=$2; shift
      else
        echo "ERROR: $1 requires an argument."; usage; exit 1
      fi
      ;;
    --platform=?*) PLATFORM=${1#*=} ;;
    --platform=) echo "ERROR: $1 requires an argument."; usage; exit 1 ;;
# COMPILER
    --compiler|-c)
      if [ "$2" ]; then
        COMPILER=$2; shift
      else
        echo "ERROR: $1 requires an argument."; usage exit 1
      fi
      ;;
    --compiler=?*) COMPILER=${1#*=} ;;
    --compiler=) echo "ERROR: $1 requires an argument."; usage; exit 1 ;;
# COMPONENTS
    --components|-t)
      if [ "$2" ]; then
        COMPONENTS=$2; shift
      else
        echo "ERROR: $1 requires an argument."; usage; exit 1
      fi
      ;;
    --components=?*) COMPONENTS=${1#*=} ;;
    --components=)
      echo "ERROR: $1 requires an argument."; usage; exit 1 ;;
# REMOVE BUILD
    --remove_build|-r) RMBUILD=true ;;
# END
    --)
      shift; break ;;
# UNKNOWN
    -?*)
      echo "ERROR: Unknown option $1"; usage; exit 1 ;;
# DEFAULT
    *)
      break
  esac
  shift
done

set -eu

#cd to location of script
MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)

ENV_FILE="env/build_${PLATFORM}_${COMPILER}.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: environment file ($ENV_FILE) does not exist for this platform/compiler combination"
  echo "PLATFORM=$PLATFORM"
  echo "COMPILER=$COMPILER"
  echo ""
  echo "See User's Guide for detailed build instructions"
  exit 64
fi

# If build directory already exists, offer a choice
BUILD_DIR=${MYDIR}/build

if [ "${RMBUILD}" = true ] ; then
  rm -rf ${BUILD_DIR}
fi

if [ -d "${BUILD_DIR}" ]; then
  while true; do
    echo "Build directory (${BUILD_DIR}) already exists! Please choose what to do:"
    echo ""
    echo "[R]emove the existing directory"
    echo "[C]ontinue building in the existing directory"
    echo "[Q]uit this build script"
    read -p "Choose an option (R/C/Q):" choice
    case $choice in
      [Rr]* ) rm -rf ${BUILD_DIR}; break;;
      [Cc]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid option selected.\n";;
    esac
  done
fi

# Source the README file for this platform/compiler combination, then build the code
. $ENV_FILE

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
if [ ! -z "$COMPONENTS" ]; then
  cmake .. -DCMAKE_INSTALL_PREFIX=.. -DINCLUDE_COMPONENTS=${COMPONENTS}
else
  cmake .. -DCMAKE_INSTALL_PREFIX=..
fi
make -j ${BUILD_JOBS:-4}

exit 0
