#!/bin/bash

showMenu (){
	clear
	echo "BBB Setup Menu : "
	echo "[1] Install BigBlueButton 0.81"
	echo "[2] Install Matterhorn"
	echo "[x] Exit"
}

gototemp() {
	if [ ! -d ~/tmp ]; then
		mkdir ~/tmp
	fi
	cd ~/tmp
}

installbbb () {
	# Add the BigBlueButton key
	wget http://ubuntu.bigbluebutton.org/bigbluebutton.asc -O- | sudo apt-key add -

	# Add the BigBlueButton repository URL and ensure the multiverse is enabled
	echo "deb http://ubuntu.bigbluebutton.org/lucid_dev_081/ bigbluebutton-lucid main" | sudo tee /etc/apt/sources.list.d/bigbluebutton.list
	sudo apt-add-repository ppa:libreoffice/libreoffice-4-0

	sudo apt-get -y update
	sudo apt-get -y dist-upgrade

	installLibreOffice

	installRuby

	sudo apt-get -y install bigbluebutton
	sudo apt-get -y install bbb-demo
	sudo apt-get -y install bbb-playback-matterhorn

	sudo bbb-conf --clean
	sudo bbb-conf --check
	
	echo
	echo "BigBlueButton installed. Press any key to continue..."
	pause
}

installLibreOffice() {
	gototemp
	sudo apt-get -y remove --purge openoffice.org-*
	wget http://bigbluebutton.googlecode.com/files/openoffice.org_1.0.4_all.deb
	sudo dpkg -i openoffice.org_1.0.4_all.deb
	sudo apt-get -y autoremove

	sudo apt-get -y nstall python-software-properties
	sudo apt-get -y install libreoffice-common
	sudo apt-get -y install libreoffice
}

installYasm(){
	cd /usr/local/src
	sudo apt-get -y install build-essential git-core checkinstall yasm texi2html libopencore-amrnb-dev libopencore-amrwb-dev libsdl1.2-dev libtheora-dev libvorbis-dev libx11-dev libxfixes-dev libxvidcore-dev zlib1g-dev
	sudo wget http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz
	sudo tar xzvf yasm-1.2.0.tar.gz
	cd yasm-1.2.0
	sudo ./configure
	sudo make
	sudo checkinstall --pkgname=yasm --pkgversion="1.2.0" --backup=no --deldoc=yes --default
}

installLibvpx() {
	# Setup libvpx
	if [ ! -d /usr/local/src/libvpx ]; then
	  cd /usr/local/src
	  sudo git clone http://git.chromium.org/webm/libvpx.git
	  cd libvpx
	  sudo ./configure --enable-shared
	  sudo make
	  sudo make install
	fi	
}

installX264() {
	#Install X264
	if [ ! -d /usr/local/src/x264 ]; then
		cd /usr/local/src
		sudo git clone git://git.videolan.org/x264
		cd x264/
		sudo ./configure --enable-shared
		sudo make
		sudo make install
	fi
}


installffmpeg(){
	
	installYasm
	installLibvpx
	installX264

	# Install ffmpeg
	cd /usr/local/src
	sudo wget http://ffmpeg.org/releases/ffmpeg-0.11.3.tar.gz
	sudo tar -xvzf ffmpeg-0.11.3.tar.gz
	cd ffmpeg-0.11.3
	sudo ./configure --enable-gpl --enable-version3 --enable-nonfree --enable-postproc --enable-libfaac --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libtheora --enable-libvorbis --enable-libx264 --enable-libxvid --enable-x11grab --enable-libmp3lame --enable-libvpx --enable-shared
	sudo make
	sudo make install
	sudo checkinstall --pkgname=ffmpeg --pkgversion="5:$(./version.sh)" --backup=no --deldoc=yes --default
}

installRuby() {
	gototemp
	wget https://bigbluebutton.googlecode.com/files/ruby1.9.2_1.9.2-p290-1_amd64.deb

	sudo apt-get install libreadline5 libyaml-0-2
	sudo dpkg -i ruby1.9.2_1.9.2-p290-1_amd64.deb

	sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.2 500 \
	                         --slave /usr/bin/ri ri /usr/bin/ri1.9.2 \
	                         --slave /usr/bin/irb irb /usr/bin/irb1.9.2 \
	                         --slave /usr/bin/erb erb /usr/bin/erb1.9.2 \
	                         --slave /usr/bin/rdoc rdoc /usr/bin/rdoc1.9.2
	                         
	sudo update-alternatives --install /usr/bin/gem gem /usr/bin/gem1.9.2 500
}

installMatterhorn(){

	sudo mkdir -p /opt/matterhorn
	sudo chown $USER:$GROUPS /opt/matterhorn
	sudo apt-get -y install subversion
	svn checkout https://opencast.jira.com/svn/MH/tags/1.4.0 /opt/matterhorn/1.4.0
	ln -s /opt/matterhorn/1.4.0 /opt/matterhorn/felix

	sudo add-apt-repository ppa:webupd8team/java
	sudo apt-get -y update
	sudo apt-get -y install oracle-java7-installer
	sudo apt-get -y install maven2

	configureMatterhorn

	export MAVEN_OPTS='-Xms256m -Xmx960m -XX:PermSize=64m -XX:MaxPermSize=256m'
	cd /opt/matterhorn/1.4.0
	mvn clean install -DdeployTo=/opt/matterhorn/1.4.0

	echo "export M2_REPO=/home/$USER/.m2/repository" >> ~/.bashrc
	echo "export FELIX_HOME=/opt/matterhorn/1.4.0" >> ~/.bashrc
	echo "export JAVA_OPTS='-Xms1024m -Xmx1024m -XX:MaxPermSize=256m'" >> ~/.bashrc
	
	installMatterhorn3P
	installffmpeg

	echo "Load profile with : source ~/.bashrc before you run Matterhorn"
	echo
	echo "To Run Matterhorn : sh /opt/matterhorn/felix/bin/start_matterhorn.sh"
	echo
	echo "To Stop Matterhorn : sh /opt/matterhorn/felix/bin/shutdown_matterhorn.sh"
	echo
	echo "To run Matterhorn as service : sudo service matterhorn start"
	pause
}

installMatterhorn3P(){
	cd /opt/matterhorn/1.4.0/docs/scripts/3rd_party
	./check-prereq
	./download-sources
	./linux-compile
}

configureMatterhorn() {
	echo "Change server url "http://localhost" to your hostname"
	ip=`ifconfig eth0 | sudo sed -n 's/.*dr:\(.*\)\s Bc.*/\1/p'`
	sudo sed -i "s/192.168.0.147/$ip/g" /usr/local/bigbluebutton/core/scripts/matterhorn.yml
	sed -i "s/PICT_TYPE_I/I/g" /opt/matterhorn/felix/etc/encoding/engage-images.properties
	sed -i "s/PICT_TYPE_I/I/g" /opt/matterhorn/felix/etc/encoding/feed-images.properties
	ssh-keygen -t rsa
	sudo cp ~/.ssh/id_rsa /usr/local/bigbluebutton/core/scripts/matt_id_rsa
	sudo chmod 600 /usr/local/bigbluebutton/core/scripts/matt_id_rsa
	sudo chown tomcat6:tomcat6 /usr/local/bigbluebutton/core/scripts/matt_id_rsa
	sudo mkdir /root/.ssh
	sudo cp ~/.ssh/id_rsa.pub /root/.ssh/authorized_keys

	sudo cp /opt/matterhorn/1.4.0/docs/scripts/init/matterhorn_init_d.sh /etc/init.d/matterhorn
	sudo update-rc.d matterhorn defaults 99
	sudo sed -i "s/\$\USER/root/g" /etc/init.d/matterhorn
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
		2) installMatterhorn ;;
	esac
done
