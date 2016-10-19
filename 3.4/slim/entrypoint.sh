#!/usr/bin/dumb-init /bin/bash
set -e

APK_REQUIREMENTS=()
BUILD_REQUIREMENTS=()
PIP_REQUIREMENTS=()
APKFILE='/apk-requirements.txt'
BUILDFILE='/build-requirements.txt'
REQFILE='/requirements.txt'

function usage () {
	echo <<"EOF"
Usage: $0 [-a -b -p -A -B -P -r] [--] <your command line>
 -a : APK requirement. Can be specified multiple times.
 -b : APK build requirement. These will be removed at the end to save space.
 -p : Pip requirement. Can be specified multiple times.

 -A : apk-requirements.txt file location,   default: /apk-requirements.txt
 -B : build-requirements.txt file location, default: /build-requirements.txt
 -P : requirements.txt file location,       default: /requirements.txt
 -r : same as above, just to match Pip's -r flag.

 -- : Separator for flags and your command

 Whatever you provide after your arguments is run at the end.
EOF
  exit 1
}

# Get and process arguments
while getopts ":a:b:p:A:B:P:r:" opt; do
  case $opt in
    a) APK_REQUIREMENTS+=("$OPTARG") ;;
    b) BUILD_REQUIREMENTS+=("$OPTARG") ;;
    p) PIP_REQUIREMENTS+=("$OPTARG") ;;
    A) APKFILE="$OPTARG" ;;
    B) BUILDFILE="$OPTARG" ;;
    P) REQFILE="$OPTARG" ;;
    r) REQFILE="$OPTARG" ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done

# Bad arguments
if [ $? -ne 0 ];
then
  usage
fi

# Strip out all the arguments that have been processed
shift $((OPTIND-1))

# If there's a double dash at the end, get that off
[[ $1 = "--" ]] && shift

# Don't do anything if we've already done this.
if [[ ! -f /requirements.installed ]]; then

  # Install any APK requirements
  if [[ -f "$APKFILE" ]]; then
    APK_REQUIREMENTS+=($( cat "$APKFILE" ))
  fi

  if [[ -f "$BUILDFILE" ]]; then
    BUILD_REQUIREMENTS+=($( cat "$BUILDFILE" ))
  fi

  # Unfortunately the Alpine repositories are in a slightly inconsistent state for now-- python2 only exists in 'edge', not main.
  # if [[ "$PYTHON_VERSION" == '2' ]]; then BUILD_PACKAGES="$(echo $BUILD_PACKAGES | sed -e 's/python2/python/g')"; fi \

  apk add --no-cache $BUILD_PACKAGES "${APK_REQUIREMENTS[@]}" "${BUILD_REQUIREMENTS[@]}"

  # Install any Pip requirements
  if [[ -f "$REQFILE" ]]; then
    PIP_REQUIREMENTS+=($( cat "$REQFILE" ))
  fi

  if [[ ${#PIP_REQUIREMENTS[@]} -gt 0 ]]; then
    pip install --upgrade pip
    pip install "${PIP_REQUIREMENTS[@]}"
  fi

  # Remove packages that were only required for build.
  apk del $BUILD_PACKAGES "${BUILD_REQUIREMENTS[@]}"

  touch /requirements.installed
fi


if [[ ! -z "$@" ]]; then
	# If the user has given us a command, run it.
	$@
else
	# Otherwise, default to running 'python'.
	python
fi
