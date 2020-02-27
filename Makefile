clean-build:
	rm -rf jx bdd-jx

init:
	mkdir -p build

bddjx: init
	git clone https://github.com/jenkins-x/bdd-jx.git
	cd bdd-jx && ./build-bddjx-linux.sh
	cp bdd-jx/build/bddjx-linux build

jx:
	git clone -b multicluster https://github.com/jenkins-x/jx.git
	cd jx && make linux
	cp jx/build/linux/jx build
