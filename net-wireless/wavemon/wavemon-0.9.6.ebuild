# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools linux-info

DESCRIPTION="Ncurses based monitor for IEEE 802.11 wireless LAN cards"
HOMEPAGE="https://github.com/uoaerg/wavemon/"
SRC_URI="https://github.com/uoaerg/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 arm ~hppa ppc sparc x86"

IUSE="caps"
RDEPEND="
	dev-libs/libnl:3[utils]
	sys-libs/ncurses:0=
	caps? ( sys-libs/libcap )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

DOCS=( README.md )

pkg_pretend() {
	local CONFIG_CHECK="~CFG80211"
	check_extra_config
}

src_prepare() {
	default

	# Do not install docs to /usr/share
	sed -i -e '/^install:/s/install-docs//' Makefile.in || die \
		'sed on Makefile.in failed'

	# automagic on libcap, discovered in bug #448406
	use caps || export ac_cv_lib_cap_cap_get_flag=false

	eautoreconf
}

src_configure () {
	CFLAGS="${CFLAGS}" econf
}

src_compile() {
	unset CFLAGS
	default
}

src_install() {
	default

	# Install man files manually(bug #397807)
	doman wavemon.1
	doman wavemonrc.5
}
