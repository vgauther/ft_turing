#!/bin/sh

set -eu

install_opam() {
	printf '%s\n' "OPAM was not found. Installing it..."

	if command -v brew >/dev/null 2>&1; then
		brew install opam
	elif command -v apt-get >/dev/null 2>&1; then
		if [ "$(id -u)" -eq 0 ]; then
			apt-get update
			apt-get install -y opam
		elif command -v sudo >/dev/null 2>&1; then
			sudo apt-get update
			sudo apt-get install -y opam
		else
			printf '%s\n' "Error: root privileges are required to install OPAM with apt-get." >&2
			exit 1
		fi
	else
		printf '%s\n' "Error: unable to install OPAM (Homebrew or apt-get is required)." >&2
		exit 1
	fi
}

if ! command -v opam >/dev/null 2>&1; then
	install_opam
else
	printf '%s\n' "OPAM is already installed."
fi

if ! opam var root >/dev/null 2>&1; then
	opam init --yes --no-setup
fi

opam install --yes ocamlfind yojson
