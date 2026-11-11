#!/bin/zsh

# Build the vendored xvcd binary for the current Mac (Apple Silicon).
#
# Requires Homebrew plus libftdi and libusb:
#     brew install libftdi libusb
#
# The binary is statically linked against both libraries, so the resulting
# bin/xvcd has no runtime dependency on Homebrew libraries.

script_dir=$(dirname -- "$(readlink -nf $0)";)
cd "$script_dir" || exit 1

if ! command -v brew > /dev/null 2>&1
then
    echo "Homebrew is required: https://brew.sh"
    exit 1
fi

missing=()
for formula in libftdi libusb
do
    if ! brew list --versions "$formula" > /dev/null 2>&1
    then
        missing+=("$formula")
    fi
done
if [ ${#missing[@]} -gt 0 ]
then
    echo "Missing Homebrew formulas: ${missing[@]}"
    echo "Install them with: brew install ${missing[@]}"
    exit 1
fi

# The Makefile takes O as the output directory; use bin/ so the result replaces
# the shipped binary. Remove the previous objects first so a rebuild is clean.
if [ -d "$script_dir/bin/obj" ]
then
    rm -rf "$script_dir/bin/obj"
fi

echo "Building xvcd..."
if ! make -C "$script_dir/src" O="$script_dir/bin"
then
    echo "Build failed."
    exit 1
fi

if [ ! -f "$script_dir/bin/xvcd" ]
then
    echo "Build did not produce bin/xvcd."
    exit 1
fi

echo
file "$script_dir/bin/xvcd"
if otool -L "$script_dir/bin/xvcd" 2>/dev/null | grep -Eq 'libftdi|libusb'
then
    echo "Warning: bin/xvcd links dynamically against libftdi/libusb; expected static linking."
fi
echo
echo "Rebuilt $script_dir/bin/xvcd. Commit it together with the source changes."
