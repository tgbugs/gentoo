# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( pypy3 python3_{10..13} )

inherit distutils-r1

MY_P=munkres-release-${PV}
DESCRIPTION="Module implementing munkres algorithm for the Assignment Problem"
HOMEPAGE="
	https://github.com/bmc/munkres/
	https://pypi.org/project/munkres/
"
SRC_URI="
	https://github.com/bmc/munkres/archive/release-${PV}.tar.gz
		-> ${MY_P}.gh.tar.gz
"
S=${WORKDIR}/${MY_P}

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~s390 ~x86"

distutils_enable_tests pytest
