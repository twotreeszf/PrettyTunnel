all:
	xcodebuild clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -configuration Release

clean:
	rm -Rf build

distclean: clean
	rm -f release/*.deb

.PHONY: all clean distclean
