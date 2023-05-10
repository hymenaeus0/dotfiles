#!/data/data/com.termux/files/usr/bin/bash

NDK_TAGS=('__INTRODUCED_IN'
          '__INTRODUCED_IN_NO_GUARD_FOR_NDK'
          '__DEPRECATED_IN'
          '__REMOVED_IN'
          '__INTRODUCED_IN_32'
          '__INTRODUCED_IN_64'
          '__INTRODUCED_IN_ARM'
          '__INTRODUCED_IN_X86'
          '__INTRODUCED_IN_X86_NO_GUARD_FOR_NDK'
          )

if [ -z "$1" -o ! -d "$1" ]; then
	echo "Usage: $(basename $0) DIR" >&2
	exit 1
fi

if [ -z "$(command -v unifdef)" ]; then
	echo "unifdef is required but not installed." >&2
	while true; do
		echo -n "would you like to install unifdef now? (Y/n) "
		read -n 1 input
		echo

		case "$input" in
			"\n"|Y|y)
				echo "ok, installing unifdef..."
				pkg install unifdef
				break
				;;
			n|N)
				echo "screw it." >&2
				exit 1
				;;
			*)
				echo "??? \"$input\" is not a valid response." >&2
				continue
				;;
		esac
	done
fi

cd "$1"

echo -n "scanning $1 ..."
headers="$(grep -rl '__INTRODUCED_IN' *)"
echo " done"

for hdr in $headers ; do
	unset is_patched

	echo -n "$hdr ... "

	cp -f $hdr ${hdr}.orig
	unifdef -D__ANDROID_API__=34 ${hdr}.orig > $hdr

	if [ -n "$(cmp ${hdr}.orig $hdr)" ]; then
		diff -Naur ${hdr}.orig $hdr >> "$OLDPWD/ndk-hdrs.$$.patch"
		is_patched=1
	else
		rm -f ${hdr}.orig
	fi

	if [ "$is_patched" ]; then
		echo -e '\e[1;32mPATCHED\e[0;0m'
	else
		echo -e '\e[1;33mNO CHANGE\e[0;0m'
	fi
done

cd "$OLDPWD"
