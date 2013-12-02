VERSION=0.1
BUILDDIR=/usr/local/src/python-for-android/dist/default/
BUILDARGS=--dir $(shell pwd)/dist --package se.hallab.sonosmixer`echo $(FAN) | tr F f` --icon $(shell pwd)/icon_256.png --orientation sensor --name "SonosMixer"$(FAN) --permission INTERNET
JAVA_HOME=/usr/lib/jvm/default-java

install:
	-rm -r dist
	mkdir dist
	python -O -m compileall  .
	cp -r main.pyo  soco.pyo sonosmixer.kv dist
	tar cf - `find requests/ -name \*.pyo` | tar -C dist -x -f -

apk: install
	cd $(BUILDDIR) && JAVA_HOME=$(JAVA_HOME) python2.7 build.py $(BUILDARGS) --version $(VERSION).`date +%s` debug installd

release: install release-apk
	$(MAKE) FAN='Fan' release-apk

release-apk:
	cd $(BUILDDIR) && JAVA_HOME=$(JAVA_HOME) python2.7 build.py $(BUILDARGS) --version $(VERSION) release
	jarsigner $(BUILDDIR)/bin/SonosMixer$(FAN)-$(VERSION)-release-unsigned.apk hakan
	/usr/local/src/android-sdk-linux/tools/zipalign -v 4 \
			$(BUILDDIR)/bin/SonosMixer$(FAN)-$(VERSION)-release-unsigned.apk \
			SonosMixer$(FAN)-$(VERSION)-release.apk
	cp SonosMixer$(FAN)-$(VERSION)-release.apk /tmp
