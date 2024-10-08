# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Performance monitoring tool capable of interactive reporting and logging to disk"
HOMEPAGE="http://collectl.sourceforge.net/"
SRC_URI="https://downloads.sourceforge.net/collectl/${P}.src.tar.gz"

LICENSE="GPL-2 Artistic"
SLOT="0"
KEYWORDS="~alpha amd64 x86"

RDEPEND="
	>=dev-lang/perl-5.8.8
	virtual/perl-Time-HiRes
	>=dev-perl/Archive-Zip-1.20
	sys-apps/ethtool
	sys-apps/pciutils
"

HTML_DOCS=( docs/. )

src_install() {
	dodoc README RELEASE-collectl

	dobin collectl colmux

	insinto /etc
	doins collectl.conf

	insinto /usr/share/collectl
	doins *.ph *.std

	insinto /usr/share/collectl/util
	insopts -m755
	doins client.pl

	doman man1/*
	einstalldocs

	newinitd "${FILESDIR}"/collectl.initd-2 collectl
}
