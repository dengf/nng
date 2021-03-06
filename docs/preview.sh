#!/bin/bash
#
# Copyright 2018 Staysail Systems, Inc. <info@staysail.tech>
# Copyright 2018 Capitar IT Group BV <info@capitar.com>
# This software is supplied under the terms of the MIT License, a
# copy of which should be located in the distribution where this
# file was obtained (LICENSE.txt).  A copy of the license may also be
# found online at https://opensource.org/licenses/MIT.
#

# This script is used to preview in HTML or man format, the documentation.
# I use it during development, YMMV.  It is probably completely useless
# on Windows.

case $(uname -s) in
Darwin)
	OPEN=open
	MAN=man
	;;
Linux)
	OPEN=xdg-open
	MAN=man
	;;
*)
	echo "No idea how to preview on this system."
	exit 2
esac

if [[ -n "$DISPLAY" ]]
then
	style=html
else
	style=man
fi

while getopts cs: arg
do
	case "${arg}" in
	c)	cleanup=yes;;
	s)	style=$OPTARG;;
	?)	echo "Usage: $0 [-s <style>][-c] <files...>"; exit 1 ;;
	esac
done
shift $(( $OPTIND - 1 ))

case $style in
html)
	suffix=.html
	;;
ps)
	suffix=.ps
	;;
pdf)
	suffix=.pdf
	;;
man)
	suffix=.man
	OPEN=${MAN}
	;;
*)
	echo "Unknown style, choose one of [html|man|pdf|ps]." 1>&2
	exit 2
esac

version=$(cat $(dirname $0)/../.version)
name=nng

generate_pdf() {
	typeset input=$1
	typeset output=$2
	asciidoctor-pdf -aversion-label=${name} -arevnumber=${version} \
		-asource-highlighter=pygments -aicons=font \
		-b pdf -a notitle -d article -o ${output} $input
}

generate_html() {
	typeset input=$1
	typeset output=$2
	asciidoctor -aversion-label=${name} -arevnumber=${version} \
		-aicons=font -asource-highlighter=pygments \
		-b html5 -o ${output} $input
}

generate_man() {
	typeset input=$1
	typeset output=$2
	asciidoctor -aversion-label=${name} -arevnumber=${version} \
		-b manpage -o ${output} $input
}

generate_ps() {
	typeset input=$1
	typeset output=$2
	manpage=${2%.ps}.man
	generate_man $1 $manpage
	if [ $? -eq 0 ]; then
		man -t $manpage > $output
	fi
}


if [ -n "${cleanup}" ]
then
	tempdir=$(mktemp -d)
	clean() {
		sleep 1
		rm -rf ${tempdir}
	}
	trap clean 0
	mkdir -p ${tempdir}
else
	tempdir=/tmp/${LOGNAME}.${name}.preview
	mkdir -p ${tempdir}
fi

for input in "$@"; do
	base=$(basename $input)
	base=${base%.adoc}
	output=${tempdir}/${base}${suffix}
	generate_${style} $input $output
	$OPEN $output
done
