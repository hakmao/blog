.PHONY: clean build push watch-server
export PATH := $(shell pwd)/bin:$(PATH)

watch-server:
	hugo server --bind=0.0.0.0 --watch

clean:
	rm public/* -rf

build: clean
	hugo

push: build
	git push
	cd public && s3cmd sync --delete-removed --disable-multipart /pwd/ s3://blog.afoolishmanifesto.com && set-redirects
