# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=${PV}
LLVM_COMPAT=( 20 )

inherit cmake flag-o-matic llvm-r1 rocm

DESCRIPTION="AMD's Machine Intelligence Library"
HOMEPAGE="https://github.com/ROCm/MIOpen"
SRC_URI="https://github.com/ROCm/MIOpen/archive/rocm-${PV}.tar.gz -> MIOpen-${PV}.tar.gz"
S="${WORKDIR}/MIOpen-rocm-${PV}"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

IUSE="composable-kernel debug hipblaslt rocblas roctracer test"

# tests can freeze machine depending on gpu/kernel
RESTRICT="test"

RDEPEND="
	dev-util/hip:${SLOT}
	>=dev-db/sqlite-3.17
	sci-libs/rocRAND:${SLOT}
	>=dev-libs/boost-1.72
	dev-cpp/nlohmann_json
	dev-cpp/frugally-deep

	composable-kernel? ( sci-libs/composable-kernel:${SLOT} )
	hipblaslt? (
		sci-libs/hipBLAS:${SLOT}
		sci-libs/hipBLASLt:${SLOT}
	)
	rocblas? ( sci-libs/rocBLAS:${SLOT} )
	roctracer? ( dev-util/roctracer:${SLOT} )
"

DEPEND="${RDEPEND}"

BDEPEND="
	>=dev-libs/half-1.12.0-r1
	dev-build/rocm-cmake
	test? ( dev-cpp/gtest )
"

PATCHES=(
	"${FILESDIR}"/${PN}-6.1.1-build-all-tests.patch
	"${FILESDIR}"/${PN}-6.3.0-conditional-ck-components.patch
)

src_prepare() {
	cmake_src_prepare

	# complementary replacements for conditional-ck-components patch
	find src -name '*mha*.cpp' -type f | while IFS= read -r file; do
		sed -i "s/MIOPEN_USE_COMPOSABLEKERNEL/MIOPEN_USE_CK_MHA_OPS/g" "$file" || die
	done

	sed -i "s/MIOPEN_USE_COMPOSABLEKERNEL/MIOPEN_USE_CK_XDL_OPS/g" \
		src/mlo_dir_conv.cpp \
		src/solver/conv_ck_igemm_fwd_bias_res_add_activ_fused.cpp \
		src/solver/conv_ck_igemm_fwd_bias_activ_fused.cpp || die
	find src -name '*xdl*.cpp' -type f | while IFS= read -r file; do
		sed -i "s/MIOPEN_USE_COMPOSABLEKERNEL/MIOPEN_USE_CK_XDL_OPS/g" "$file" || die
	done

	sed -e '/MIOPEN_TIDY_ERRORS ALL/d' \
		-e 's/FLAGS_RELEASE} -s/FLAGS_RELEASE}/g' \
		-i CMakeLists.txt || die

	sed -e "/add_test/s:--build \${CMAKE_CURRENT_BINARY_DIR}:--build ${BUILD_DIR}:" \
		-i test/CMakeLists.txt || die

	sed -e "s:\${PROJECT_BINARY_DIR}/miopen/include:\${PROJECT_BINARY_DIR}/include:" \
		-i src/CMakeLists.txt || die
}

src_configure() {
	rocm_use_hipcc

	if ! use debug; then
		append-cflags "-DNDEBUG"
		append-cxxflags "-DNDEBUG"
		CMAKE_BUILD_TYPE="Release"
	else
		CMAKE_BUILD_TYPE="Debug"
	fi

	local mycmakeargs=(
		-DCMAKE_SKIP_RPATH=ON
		-DGPU_TARGETS="$(get_amdgpu_flags)"
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
		-DMIOPEN_BACKEND=HIP
		-DBoost_USE_STATIC_LIBS=OFF
		-DMIOPEN_USE_MLIR=OFF
		-DMIOPEN_USE_ROCTRACER=$(usex roctracer ON OFF)
		-DMIOPEN_USE_ROCBLAS=$(usex rocblas ON OFF)
		-DMIOPEN_USE_HIPBLASLT=$(usex hipblaslt ON OFF)
		-DMIOPEN_USE_COMPOSABLEKERNEL=$(usex composable-kernel ON OFF)
		-DBUILD_TESTING=$(usex test ON OFF)
		-DBUILD_FILE_REORG_BACKWARD_COMPATIBILITY=OFF
		-DROCM_SYMLINK_LIBS=OFF
		-DMIOPEN_HIP_COMPILER="${ESYSROOT}/usr/bin/hipcc"
		-DMIOPEN_AMDGCN_ASSEMBLER="$(get_llvm_prefix)/bin/clang"
		-DHIP_OC_COMPILER="$(get_llvm_prefix)/bin/clang"
	)

	if use test; then
		mycmakeargs+=(
			-DMIOPEN_TEST_ALL=ON
			-DMIOPEN_TEST_GDB=OFF
		)
		# needed by rocminfo
		addpredict /dev/random
		check_amdgpu
	fi

	cmake_src_configure
}

src_test() {
	check_amdgpu
	LD_LIBRARY_PATH="${BUILD_DIR}"/lib MIOPEN_SYSTEM_DB_PATH="${BUILD_DIR}"/share/miopen/db/ cmake_src_test -j1
}

src_install() {
	cmake_src_install
}
