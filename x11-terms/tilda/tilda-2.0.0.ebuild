# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic

DESCRIPTION="A drop down terminal, similar to the consoles found in first person shooters"
HOMEPAGE="https://github.com/lanoxx/tilda"
SRC_URI="https://github.com/lanoxx/tilda/archive/${P}.tar.gz"

S="${WORKDIR}/${PN}-${P}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm64 ppc ~ppc64 ~riscv x86 ~amd64-linux ~x86-linux"

RDEPEND="x11-libs/vte:2.91
	>=dev-libs/glib-2.8.4:2
	dev-libs/confuse:=
	gnome-base/libglade
	x11-libs/gtk+:3
	x11-libs/libX11"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig
	sys-devel/gettext"

src_prepare() {
	default
	append-cflags -std=c99
	eautoreconf
}
