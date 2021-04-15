#!/bin/bash

# usage instructions
usage () {
  printf "Usage: $0 PLATFORM [OPTIONS]...\n"
  printf "\n"
  printf "PLATFORM\n"
  printf "  Name of machine you are building on\n"
  printf "  (.e.g. cheyenne | hera | jet | orion | wcoss)\n"
  printf "\n"
  printf "OPTIONS\n"
  printf "  --compiler=COMPILER\n"
  printf "      compiler to use; valid options are 'intel(D)', 'gnu'\n"
  printf "  --ccpp=CCPP_SUITES\n"
  printf "      CCCP suites to include in build; delimited with ','\n"
  printf "  --components=\"COMPONENT1,COMPONENT2...\"\n"
  printf "      components to include in build; delimited with ','\n"
  printf "  --overwrite=SETTING\n"
  printf "      overwrite setting; valid options are 'interactive(D)', \n"
  printf "      'continue', 'clean'\n"
  printf "  --build-dir=BUILD_DIR\n"
  printf "      build directory\n"
  printf "  --install-dir=INSTALL_DIR\n"
  printf "      installation prefix\n"
  printf "  --verbose\n"
  printf "      build with verbose output\n"
  printf "\n"
  printf "NOTE: This script is for internal developer use only;\n"
  printf "See User's Guide for detailed build instructions\n"
}

# print settings
settings () {
  printf "Settings:\n"
  printf "\n"
  printf "  SRC_DIR=${SRC_DIR}\n"
  printf "  BUILD_DIR=${BUILD_DIR}\n"
  printf "  INSTALL_DIR=${INSTALL_DIR}\n"
  printf "  PLATFORM=${PLATFORM}\n"
  printf "  COMPILER=${COMPILER}\n"
  if [ ! -z "${CCPP}" ]; then printf "  CCPP=${CCPP}\n"; fi
  if [ ! -z "${COMPONENTS}" ]; then printf "  COMPONENTS=${COMPONENTS}\n"; fi
  printf "  OVERWRITE=${OVERWRITE}\n"
  printf "  VERBOSE=${VERBOSE}\n"
  printf "\n"
}

# default settings
SRC_DIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
BUILD_DIR=${SRC_DIR}/build
INSTALL_DIR=${SRC_DIR}
PLATFORM=""
COMPILER="intel"
CCPP=""
COMPONENTS=""
OVERWRITE="interactive"
VERBOSE=false

# required arguments
if [ $# -lt 1 ]; then
  printf "ERROR: not enough arguments\n"; usage; exit 1
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  usage
  exit 0
elif [[ $1 == "-"* ]]; then
  printf "ERROR: missing PLATFORM\n"; usage; exit 1
fi
PLATFORM="$1"; shift

# process arguments
while :; do
  case $1 in
    --help|-h) usage; exit 0 ;;
    --compiler=?*) COMPILER=${1#*=} ;;
    --compiler) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --compiler=) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --ccpp=?*) CCPP=${1#*=} ;;
    --ccpp) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --ccpp=) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --components=?*) COMPONENTS=${1#*=} ;;
    --components) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --components=) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --overwrite=?*) OVERWRITE=${1#*=} ;;
    --overwrite) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --overwrite=) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --build-dir=?*) BUILD_DIR=${1#*=} ;;
    --build-dir) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --build-dir=) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --install-dir=?*) INSTALL_DIR=${1#*=} ;;
    --install-dir) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --install-dir=) printf "ERROR: $1 requires an argument.\n"; usage; exit 1 ;;
    --verbose) VERBOSE=true ;;
    --verbose=?*) printf "ERROR: $1 argument ignored.\n"; usage; exit 1 ;;
    --verbose=) printf "ERROR: $1 argument ignored.\n"; usage; exit 1 ;;
    -?*) printf "ERROR: Unknown option $1\n"; usage; exit 1 ;;
    *) break
  esac
  shift
done

set -eu

# print settings
if [ "${VERBOSE}" = true ] ; then
  settings
fi

# Source the README file for this platform/compiler combination
ENV_FILE="${SRC_DIR}/env/build_${PLATFORM}_${COMPILER}.env"
if [ ! -f "${ENV_FILE}" ]; then
  printf "ERROR: environment file does not exist for this platform/compiler\n"
  printf "  ENV_FILE=${ENV_FILE}\n"
  printf "  PLATFORM=${PLATFORM}\n"
  printf "  COMPILER=${COMPILER}\n"
  printf "\n"
  printf "See User's Guide for detailed build instructions\n"
  exit 64
fi
. ${ENV_FILE}

# If build directory already exists, offer a choice
if [ "${OVERWRITE}" = "interactive" ]; then
  if [ -d "${BUILD_DIR}" ]; then
    while true; do
      printf "Build directory (${BUILD_DIR}) already exists!\n"
      printf "Please choose what to do:\n"
      printf "\n"
      printf "[R]emove the existing directory\n"
      printf "[C]ontinue building in the existing directory\n"
      printf "[Q]uit this build script\n"
      read -p "Choose an option (R/C/Q):" choice
      case ${choice} in
        [Rr]* ) rm -rf ${BUILD_DIR}; break;;
        [Cc]* ) break;;
        [Qq]* ) exit;;
        * ) printf "Invalid option selected.\n";;
      esac
    done
  fi
elif [ "${OVERWRITE}" = "continue" ]; then
  printf "Continue build in directory\n"
  printf "  BUILD_DIR=${BUILD_DIR}\n"
elif [ "${OVERWRITE}" = "clean" ]; then
  printf "Remove build directory\n"
  printf "  BUILD_DIR=${BUILD_DIR}\n"
  rm -rf ${BUILD_DIR}
else
  printf "ERROR: OVERWRITE has unknown argument.\n"
  printf "  OVERWRITE=${OVERWRITE}\n"
  exit 1
fi
mkdir -p ${BUILD_DIR}

# cmake settings
CMAKE_SETTINGS=""
if [ ! -z "${CCPP}" ]; then
  CMAKE_SETTINGS="-DCCPP=${CCPP} ${CMAKE_SETTINGS}"
fi
if [ ! -z "${COMPONENTS}" ]; then
  CMAKE_SETTINGS="-DINCLUDE_COMPONENTS=${COMPONENTS} ${CMAKE_SETTINGS}"
fi

# make settings
MAKE_SETTINGS=""
if [ "${VERBOSE}" = true ]; then
  MAKE_SETTINGS="VERBOSE=1 ${MAKE_SETTINGS}"
fi

# build the code
cd ${BUILD_DIR}
cmake ${SRC_DIR} -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} ${CMAKE_SETTINGS}
make -j ${BUILD_JOBS:-4} ${MAKE_SETTINGS}

exit 0
