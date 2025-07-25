# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic gnome2-utils meson-multilib xdg

DESCRIPTION="Internationalized text layout and rendering library"
HOMEPAGE="https://www.gtk.org/docs/architecture/pango https://gitlab.gnome.org/GNOME/pango"
SRC_URI="https://download.gnome.org/sources/pango/$(ver_cut 1-2)/${P}.tar.xz"

LICENSE="LGPL-2+"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"

IUSE="debug examples gtk-doc +introspection sysprof test X"
REQUIRED_USE="gtk-doc? ( introspection )"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-libs/glib-2.82:2[${MULTILIB_USEDEP}]
	>=dev-libs/fribidi-1.0.6[${MULTILIB_USEDEP}]
	>=media-libs/harfbuzz-8.4.0:=[glib(+),introspection?,truetype(+),${MULTILIB_USEDEP}]
	>=media-libs/fontconfig-2.15.0:1.0[${MULTILIB_USEDEP}]
	>=x11-libs/cairo-1.18.0[X?,${MULTILIB_USEDEP}]
	>=media-libs/freetype-2.5.0.1:2[${MULTILIB_USEDEP}]
	introspection? ( >=dev-libs/gobject-introspection-1.83.2:= )
	X? (
		>=x11-libs/libX11-1.6.2[${MULTILIB_USEDEP}]
		>=x11-libs/libXft-2.3.1-r1[${MULTILIB_USEDEP}]
		>=x11-libs/libXrender-0.9.8[${MULTILIB_USEDEP}]
	)
"
DEPEND="${RDEPEND}
	sysprof? ( >=dev-util/sysprof-capture-3.40.1:4[${MULTILIB_USEDEP}] )
	X? ( x11-base/xorg-proto )
"
BDEPEND="
	dev-util/glib-utils
	virtual/pkgconfig
	dev-python/docutils
	gtk-doc? ( dev-util/gi-docgen )
	test? ( media-fonts/cantarell )
"

src_prepare() {
	default
	xdg_environment_reset
	gnome2_environment_reset

	# get rid of a win32 example
	rm examples/pangowin32tobmp.c || die

	# Skip broken test:
	# https://gitlab.gnome.org/GNOME/pango/-/issues/677
	rm tests/layouts/valid-20.layout || die
}

multilib_src_configure() {
	if use debug; then
		append-cflags -DPANGO_ENABLE_DEBUG
	else
		append-cflags -DG_DISABLE_CAST_CHECKS
	fi

	local emesonargs=(
		# Never use gi-docgen subproject
		--wrap-mode nofallback

		$(meson_use gtk-doc documentation)
		$(meson_native_use_feature introspection)
		-Dman-pages=true
		$(meson_use test build-testsuite)
		-Dbuild-examples=false
		-Dfontconfig=enabled
		$(meson_feature sysprof)
		-Dlibthai=disabled
		-Dcairo=enabled
		$(meson_feature X xft)
		-Dfreetype=enabled
	)
	meson_src_configure
}

multilib_src_install_all() {
	if use examples; then
		dodoc -r examples
	fi

	if use gtk-doc; then
		mkdir -p "${ED}"/usr/share/gtk-doc/html/ || die
		mv "${ED}"/usr/share/doc/Pango* "${ED}"/usr/share/gtk-doc/html/ || die
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	if has_version 'media-libs/freetype[-harfbuzz]' ; then
		ewarn "media-libs/freetype is installed without harfbuzz support. This may"
		ewarn "lead to minor font rendering problems, see bug 712374."
	fi
}
