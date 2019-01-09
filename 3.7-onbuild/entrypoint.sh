#!/usr/bin/dumb-init /bin/bash
set -e

APK_REQUIREMENTS=()
BUILD_REQUIREMENTS=()
PIP_REQUIREMENTS=()
APKFILE='/apk-requirements.txt'
BUILDFILE='/build-requirements.txt'
REQFILE='/requirements.txt'
VERBOSITY=1

TMP_REQFILE='/tmp/requirements.txt'

function usage () {
	echo <<"EOF"
Usage: $0 [-a -b -p -A -B -P -r -q -x] [--] <your command line>
 -a : APK requirement. Can be specified multiple times.
 -b : APK build requirement. These will be removed at the end to save space.
 -p : Pip requirement. Can be specified multiple times.

 -A : apk-requirements.txt file location,   default: /apk-requirements.txt
 -B : build-requirements.txt file location, default: /build-requirements.txt
 -P : requirements.txt file location,       default: /requirements.txt
 -r : same as above, just to match Pip's -r flag.

 -q : quiet, doesn't print anything at all.
 -x : Bash debug mode. Extremely verbose!

 -- : Separator for flags and your command

 Whatever you provide after your arguments is run at the end.
EOF
  exit 1
}

function vlog () {
	if [ $VERBOSITY -gt 0 ]; then
		echo $1
	fi
}

# Get and process arguments
while getopts ":a:b:p:A:B:P:r:qx" opt; do
  case $opt in
    a) APK_REQUIREMENTS+=("$OPTARG") ;;
    b) BUILD_REQUIREMENTS+=("$OPTARG") ;;
    p) PIP_REQUIREMENTS+=("$OPTARG") ;;
    A) APKFILE="$OPTARG" ;;
    B) BUILDFILE="$OPTARG" ;;
    P) REQFILE="$OPTARG" ;;
		r) REQFILE="$OPTARG" ;;
    q) VERBOSITY=0 ;;
		x) set -x ;;
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

# Make some common flags objects
PIP_FLAGS=''
if [ $VERBOSITY -eq 0 ]; then
	PIP_FLAGS="$PIP_FLAGS -q"
fi

APK_FLAGS='--no-cache --no-progress'
if [ $VERBOSITY -eq 0 ]; then
	APK_FLAGS="$APK_FLAGS -q"
fi

# Don't do anything if we've already done this.
if [[ ! -f /requirements.installed ]]; then
	vlog "First run, checking for any requirements..."

  # Install any APK requirements
  if [[ -f "$APKFILE" ]]; then
		vlog "APK requirements file detected!"
    APK_REQUIREMENTS+=($( cat "$APKFILE" ))
  fi

  if [[ -f "$BUILDFILE" ]]; then
		vlog "Build requirements file detected!"
    BUILD_REQUIREMENTS+=($( cat "$BUILDFILE" ))
  fi

  # Unfortunately the Alpine repositories are in a slightly inconsistent state for now-- python2 only exists in 'edge', not main.
  # if [[ "$PYTHON_VERSION" == '2' ]]; then BUILD_PACKAGES="$(echo $BUILD_PACKAGES | sed -e 's/python2/python/g')"; fi \
	vlog "Installing all APK requirements..."
  apk add $APK_FLAGS $BUILD_PACKAGES "${APK_REQUIREMENTS[@]}" "${BUILD_REQUIREMENTS[@]}"

  # Install any Pip requirements
	if [[ -f "$REQFILE" && "$(cat $REQFILE | wc -l)" -gt 0 ]]; then
		# Do this check a little early-- since we merge cli in with file,
		# we'd get a false positive for logging otherwise.
		vlog "Pip requirements file detected!"
	fi

	# If we use CLI parameters, we'll have to reassign this.
	TARGET_REQFILE="$REQFILE"
	if [[ ${#PIP_REQUIREMENTS[@]} -gt 0 ]]; then
		# Put all Pip requirements into the same file.
		printf "%s\n" "${PIP_REQUIREMENTS[@]}" >> "$TMP_REQFILE"

		if [[ -f "$REQFILE" && "$(cat $REQFILE | wc -l)" -gt 0 ]]; then
			cat "$REQFILE" >> "$TMP_REQFILE"
		fi

		TARGET_REQFILE="$TMP_REQFILE"
	fi

  if [[ -f $TARGET_REQFILE && "$(cat $TARGET_REQFILE | wc -l)" -gt 0 ]]; then
		vlog "Upgrading Pip..."
		pip install $PIP_FLAGS --upgrade pip
		vlog "Installing all Pip requirements..."
    pip install $PIP_FLAGS -r "$TARGET_REQFILE"
  fi

  # Remove packages that were only required for build.
  apk del $APK_FLAGS $BUILD_PACKAGES "${BUILD_REQUIREMENTS[@]}"

  touch /requirements.installed
else
	vlog "/requirements.installed file exists-- skipping requirements installs."
fi


if [[ ! -z "$@" ]]; then
	# If the user has given us a command, run it.
	$@
else
	# Otherwise, default to running 'python'.
	python
fi
