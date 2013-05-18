#!/bin/bash

source ~/.profile

BBBHome="/home/$USER/dev/bigbluebutton"
BBBDemoSite="/var/www/bigbluebutton-default"


showMenu (){
	clear
	echo "BBB Setup Menu : "
	echo "[1] Install BigBlueButton"
	echo "[2] Setup Development Tools"
	echo "[3] Checkout Source"
	echo "[4] Setup Client Dev"
	echo "[5] Setup API Dev"
	echo "[6] Setup App Dev"
	echo "[7] Build Client"
	echo "[8] Show IP"
	echo "[x] Exit"
}

installbbb () {
# Add the BigBlueButton key
wget http://ubuntu.bigbluebutton.org/bigbluebutton.asc -O- | sudo apt-key add -

# Add the BigBlueButton repository URL and ensure the multiverse is enabled
echo "deb http://ubuntu.bigbluebutton.org/lucid_dev_08/ bigbluebutton-lucid main" | sudo tee /etc/apt/sources.list.d/bigbluebutton.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ lucid multiverse" | sudo tee -a /etc/apt/sources.list

sudo apt-get update
sudo apt-get dist-upgrade

sudo apt-get install -f -q -y zlib1g-dev libssl-dev libreadline5-dev libyaml-dev build-essential bison checkinstall libffi5 gcc checkinstall libreadline5 libyaml-0-2


######## RUBY INSTALLATION
cd /tmp
wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p290.tar.gz
tar xvzf ruby-1.9.2-p290.tar.gz
cd ruby-1.9.2-p290
./configure --prefix=/usr\
            --program-suffix=1.9.2\
            --with-ruby-version=1.9.2\
            --disable-install-doc
make
sudo checkinstall -D -y\
                  --fstrans=no\
                  --nodoc\
                  --pkgname='ruby1.9.2'\
                  --pkgversion='1.9.2-p290'\
                  --provides='ruby'\
                  --requires='libc6,libffi5,libgdbm3,libncurses5,libreadline5,openssl,libyaml-0-2,zlib1g'\
                  --maintainer=brendan.ribera@gmail.com
sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.2 500 \
                         --slave /usr/bin/ri ri /usr/bin/ri1.9.2 \
                         --slave /usr/bin/irb irb /usr/bin/irb1.9.2 \
                         --slave /usr/bin/erb erb /usr/bin/erb1.9.2 \
                         --slave /usr/bin/rdoc rdoc /usr/bin/rdoc1.9.2
sudo update-alternatives --install /usr/bin/gem gem /usr/bin/gem1.9.2 500
sudo rm /tmp/ruby-1.9.2-p290.tar.gz
######## END OF RUBY INSTALLATION

######## BIGBLUEBUTTON INSTALLATION
sudo apt-get -f -q -y install bigbluebutton
sudo apt-get -f -q -y install bbb-demo
sudo bbb-conf --clean
sudo bbb-conf --check
echo "Please enter any key to continue"
pause
}

checkoutsource(){
	git clone https://github.com/bigbluebutton/bigbluebutton.git
	cd bigbluebutton
	git checkout -b develop v0.8
	echo "Press any key to continue"
	pause	
}

setuptools (){
	cd ~
	if [ ! -d dev/ ]; then
		mkdir dev
	fi
	cd dev
	bbb-conf --setup-dev tools
	source ~/.profile
	echo "Press any key to continue"
	pause	
}

setupclientdev() {
	bbb-conf --setup-dev client
	echo "Press any key to continue"
	pause
}

setupapidev() {
	bbb-conf --setup-dev web
	cd $BBBHome/bigbluebutton-web
	stopapi
	grails -Dserver.port=8888 run-app
	stopapi
	startapi
	echo "Press any key to continue"
	pause
}

startapi() {
    nohup grails -Dserver.port=8888 run-app &
}

stopapi() {
	service=$(sudo netstat -nap|grep 8888 | awk '{ print $7}' | cut -d/ -f1)
    if [ -n "$service" ]; then
    	kill $service
    fi
}

setupappdev() {
	sudo chmod -R 777 /usr/share/red5/webapps
	sudo service red5 stop
	bbb-conf --setup-dev apps
	mv "$BBBHome"/bigbluebutton-apps/build.gradle "$BBBHome"/bigbluebutton-apps/build.gradle.BAK
	cp build.gradle.app "$BBBHome"/bigbluebutton-apps/build.gradle
	gradle resolveDeps
	gradle clean war deploy
}

buildclient() {
	cd "$BBBHome"/bigbluebutton-client
	if [ ! -d bin/ ]; then
		mkdir bin
	fi
	ant locales
	ant clean-build-all
	echo "Press any key to continue"
	pause
}

showIP (){
	DEFAULT_IP=$(ifconfig | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
	echo "Your IP(s):"
	echo "$DEFAULT_IP"
}

pause (){
   read -p "$*"
}


while [ "$OPT" != "x" ]
do
	showMenu
	echo -n "Enter option number : "
	read OPT
	echo
	case $OPT in
		1) installbbb ;;
		2) setuptools ;;
		3) checkoutsource ;;		
		4) setupclientdev ;;
		5) setupapidev ;;
		6) setupappdev ;;
		7) buildclient ;;
		8) showIP ;echo "Press any key to continue";pause;
	esac
done
