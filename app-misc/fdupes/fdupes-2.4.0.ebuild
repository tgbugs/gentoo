# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Identify/delete duplicate files residing within specified directories"
HOMEPAGE="https://github.com/adrianlopezroche/fdupes"
if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/adrianlopezroche/fdupes.git"
	inherit autotools git-r3
else
	SRC_URI="https://github.com/adrianlopezroche/${PN}/releases/download/v${PV}/${P}.tar.gz"
	KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~x64-macos"
fi

LICENSE="MIT"
SLOT="0"
IUSE="+ncurses sqlite"

RDEPEND="
	dev-libs/libpcre2:=[pcre32]
	ncurses? ( sys-libs/ncurses:= )
	sqlite? ( dev-db/sqlite:3 )
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

DOCS=( CHANGES CONTRIBUTORS README )

src_prepare() {
	default

	[[ ${PV} == *9999 ]] && eautoreconf
}

src_configure() {
	econf $(use_with ncurses) $(use_with sqlite)
}
