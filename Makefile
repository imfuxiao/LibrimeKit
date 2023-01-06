mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

.PHONY: boost-build boost-clean librime-build librime-clean

boost-build:
	sudo gem install cocoapods
	${MAKE} -f boost-iosx/Makefile build
	cd ${mkfile_dir} && 
		mkdir -p Frameworks && \
		cp -rf boost-iosx/frameworks/boost_atomic.xcframework Frameworks && \
		cp -rf boost-iosx/frameworks/boost_filesystem.xcframework Frameworks && \
		cp -rf boost-iosx/frameworks/boost_regex.xcframework Frameworks && \
		cp -rf boost-iosx/frameworks/boost_system.xcframework Frameworks

boost-clean:
	${MAKE} -f boost-iosx/Makefile clean

librime-build:
	# brew install cmake
	# git submodule update --init
	${mkfile_dir}/librimeBuild.sh

librime-clean:
	rm -rf ${mkfile_dir}/librime.patch.apply
	rm -rf Frameworks/lib*.xcframework lib/*.xcframework lib/*.a