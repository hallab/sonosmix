VERSION=0.1
FREE=Free
BUILDDIR=/usr/local/src/python-for-android/dist/default/
BUILDARGS=--dir $(shell pwd)/dist --package se.hallab.sonosmixer`echo $(FREE) | tr F f` --icon $(shell pwd)/icon_256.png --orientation sensor --name "SonosMixer"$(FREE) --permission INTERNET
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
	grep -v ONLY_IN_FREE_VERSION  main.py > main_free.py
	python -O -m compileall  main_free.py
	mv main_free.pyo dist/main.pyo
	rm main_free.py
	$(MAKE) FREE='' release-apk

release-apk:
	cd $(BUILDDIR) && JAVA_HOME=$(JAVA_HOME) python2.7 build.py $(BUILDARGS) --version $(VERSION) release
	jarsigner $(BUILDDIR)/bin/SonosMixer$(FREE)-$(VERSION)-release-unsigned.apk hakan
	/usr/local/src/android-sdk-linux/tools/zipalign -v 4 \
			$(BUILDDIR)/bin/SonosMixer$(FREE)-$(VERSION)-release-unsigned.apk \
			SonosMixer$(FREE)-$(VERSION)-release.apk
	cp SonosMixer$(FREE)-$(VERSION)-release.apk /tmp
