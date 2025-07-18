# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{11..13} )

inherit gnome2 meson python-single-r1

DESCRIPTION="Extensible screen reader that provides access to the desktop"
HOMEPAGE="https://orca.gnome.org/"

LICENSE="LGPL-2.1+ CC-BY-SA-3.0"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm arm64 ~loong ~ppc ~ppc64 ~riscv ~sparc x86"

IUSE="+braille"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="${PYTHON_DEPS}
	>=app-accessibility/at-spi2-core-2.50:2[introspection]
	>=dev-libs/glib-2.28:2
	media-libs/gstreamer:1.0[introspection]
	>=x11-libs/gtk+-3.6.2:3[introspection]
	$(python_gen_cond_dep '
		dev-python/gst-python:1.0[${PYTHON_USEDEP}]
		>=dev-python/pygobject-3.18:3[${PYTHON_USEDEP}]
	')
	braille? (
		$(python_gen_cond_dep '
			>=app-accessibility/brltty-5.0-r3[python,${PYTHON_USEDEP}]
			dev-libs/liblouis[${PYTHON_SINGLE_USEDEP}]
		')
	)
"
RDEPEND="${DEPEND}
	$(python_gen_cond_dep '
		>=app-accessibility/speech-dispatcher-0.8[python,${PYTHON_USEDEP}]
		>=dev-python/pyatspi-2.46[${PYTHON_USEDEP}]
		dev-python/setproctitle[${PYTHON_USEDEP}]
	')
	x11-libs/libwnck:3[introspection]
	x11-libs/pango[introspection]
"
BDEPEND="
	dev-util/itstool
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
"
#	app-text/yelp-tools

src_configure() {
	local emesonargs=(
		-Dspiel=false # spiel not yet in gentoo
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	python_fix_shebang "${ED}"
	python_optimize
}
