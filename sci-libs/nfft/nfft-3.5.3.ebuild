# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools toolchain-funcs

DESCRIPTION="library for nonequispaced discrete Fourier transformations"
HOMEPAGE="https://www-user.tu-chemnitz.de/~potts/nfft/"
SRC_URI="https://github.com/NFFT/nfft/releases/download/${PV}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc openmp"

RDEPEND="sci-libs/fftw:3.0=[threads,openmp?]"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}/${P}-gcc15.patch"
	"${FILESDIR}/${P}-rtc.patch"
)

pkg_pretend() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

pkg_setup() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	econf \
		--enable-all \
		$(use_enable openmp)
}

src_install() {
	default

	if ! use doc; then
		rm -r "${ED}"/usr/share/doc/${P}/html || die
	fi

	# no static archives
	find "${ED}" -name '*.la' -delete || die
}
