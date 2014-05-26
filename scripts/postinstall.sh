set_synaptics()
{
    cat << EOF > ${DESTDIR}/etc/X11/xorg.conf.d/50-synaptics.conf 
# Example xorg.conf.d snippet that assigns the touchpad driver
# to all touchpads. See xorg.conf.d(5) for more information on
# InputClass.
# DO NOT EDIT THIS FILE, your distribution will likely overwrite
# it when updating. Copy (and rename) this file into
# /etc/X11/xorg.conf.d first.
# Additional options may be added in the form of
#   Option "OptionName" "value"
#
Section "InputClass"
        Identifier "touchpad catchall"
        Driver "synaptics"
        MatchIsTouchpad "on"
        Option "TapButton1" "1"
        Option "TapButton2" "2"
        Option "TapButton3" "3"
# This option is recommend on all Linux systems using evdev, but cannot be
# enabled by default. See the following link for details:
# http://who-t.blogspot.com/2010/11/how-to-ignore-configuration-errors.html
        MatchDevicePath "/dev/input/event*"
EndSection

Section "InputClass"
        Identifier "touchpad ignore duplicates"
        MatchIsTouchpad "on"
        MatchOS "Linux"
        MatchDevicePath "/dev/input/mouse*"
        Option "Ignore" "on"
EndSection

# This option enables the bottom right corner to be a right button on
# non-synaptics clickpads.
# This option is only interpreted by clickpads.
Section "InputClass"
        Identifier "Default clickpad buttons"
        MatchDriver "synaptics"
        Option "SoftButtonAreas" "50% 0 82% 0 0 0 0 0"
EndSection

# This option disables software buttons on Apple touchpads.
# This option is only interpreted by clickpads.
Section "InputClass"
        Identifier "Disable clickpad buttons on Apple touchpads"
        MatchProduct "Apple|bcm5974"
        MatchDriver "synaptics"
        Option "SoftButtonAreas" "0 0 0 0 0 0 0 0"
EndSection
EOF

}

gnome_settings(){
	# Set Adwaita cursor theme
	chroot ${DESTDIR} ln -s /usr/share/icons/Adwaita /usr/share/icons/default

	# Set gsettings input-source
	if [[ "${KEYBOARD_VARIANT}" != '' ]];then
		sed -i "s/'us'/'${KEYBOARD_LAYOUT}+${KEYBOARD_VARIANT}'/" /usr/share/cnchi/scripts/set-settings
	else
		sed -i "s/'us'/'${KEYBOARD_LAYOUT}'/" /usr/share/cnchi/scripts/set-settings
        fi
	# Set gsettings
	cp /usr/share/cnchi/scripts/set-settings ${DESTDIR}/usr/bin/set-settings
	mkdir -p ${DESTDIR}/var/run/dbus
	mount -o bind /var/run/dbus ${DESTDIR}/var/run/dbus
	chroot ${DESTDIR} su -c "/usr/bin/set-settings ${DESKTOP}" ${USER_NAME} >/dev/null 2>&1

	# Set gdm shell logo
	cp /usr/share/antergos/logo.png ${DESTDIR}/usr/share/antergos/
	chroot ${DESTDIR} sudo -u gdm dbus-launch gsettings set org.gnome.login-screen logo "/usr/share/antergos/logo.png" >/dev/null 2>&1

	rm ${DESTDIR}/usr/bin/set-settings

	# Set skel directory
	cp -R ${DESTDIR}/home/${USER_NAME}/.config ${DESTDIR}/etc/skel

	## Set defaults directories
	chroot ${DESTDIR} su -c xdg-user-dirs-update ${USER_NAME}
	
	# xscreensaver config
	cat << EOF > ${DESTDIR}/home/${USER_NAME}/.xscreensaver 
newLoginCommand: dm-tool switch-to-greeter
timeout:	0:10:00
EOF

	cp ${DESTDIR}/home/${USER_NAME}/.xscreensaver ${DESTDIR}/etc/skel

	cat << EOF > ${DESTDIR}/etc/xdg/autostart/xscreensaver.desktop
[Desktop Entry]
Name=xscreensaver
Exec=/usr/bin/xscreensaver -no-splash &
Terminal=false
Type=Application
Icon=screensaver
StartupNotify=false
X-GNOME-Autostart-Delay=30
Categories=System;Display;GTK;
EOF

}

cinnamon_settings(){
	# Set Adwaita cursor theme
	chroot ${DESTDIR} ln -s /usr/share/icons/Adwaita /usr/share/icons/default

	# Set gsettings input-source
	if [[ "${KEYBOARD_VARIANT}" != '' ]];then
		sed -i "s/'us'/'${KEYBOARD_LAYOUT}+${KEYBOARD_VARIANT}'/" /usr/share/cnchi/scripts/set-settings
	else
		sed -i "s/'us'/'${KEYBOARD_LAYOUT}'/" /usr/share/cnchi/scripts/set-settings
        fi
	# copy antergos menu icon
	mkdir -p ${DESTDIR}/usr/share/antergos/
	cp /usr/share/antergos/antergos-menu.png ${DESTDIR}/usr/share/antergos/antergos-menu.png

	# Set gsettings
	cp /usr/share/cnchi/scripts/set-settings ${DESTDIR}/usr/bin/set-settings
	mkdir -p ${DESTDIR}/var/run/dbus
	mount -o bind /var/run/dbus ${DESTDIR}/var/run/dbus
	chroot ${DESTDIR} su -c "/usr/bin/set-settings ${DESKTOP}" ${USER_NAME} >/dev/null 2>&1
	rm ${DESTDIR}/usr/bin/set-settings

	# Copy menu@cinnamon.org.json to set menu icon
	mkdir -p ${DESTDIR}/home/${USER_NAME}/.cinnamon/configs/menu@cinnamon.org/
	cp -f /usr/share/cnchi/scripts/menu@cinnamon.org.json ${DESTDIR}/home/${USER_NAME}/.cinnamon/configs/menu@cinnamon.org/

	# Set Cinnamon in .dmrc
	echo "[Desktop]" > ${DESTDIR}/home/${USER_NAME}/.dmrc
	echo "Session=cinnamon" >> ${DESTDIR}/home/${USER_NAME}/.dmrc
	chroot ${DESTDIR} chown ${USER_NAME}:users	/home/${USER_NAME}/.dmrc

	# Temporary alternative until upower bug is fixed.
	if [[ $6 -eq "True" ]]; then 
		cat << EOF > ${DESTDIR}/home/${USER_NAME}/.config/autostart/cbatticon.desktop
[Desktop Entry]
Name=cbatticon
Comment=Lightweight system tray battery indicator.
Icon=battery
Type=Application
Exec=/usr/bin/cbatticon -i symbolic -l 15 -c "systemctl poweroff"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
		chroot ${DESTDIR} chmod +x ${DESTDIR}/home/${USER_NAME}/.config/autostart/cbatticon.desktop
	fi

	# Set skel directory
	cp -R ${DESTDIR}/home/${USER_NAME}/.config ${DESTDIR}/home/${USER_NAME}/.cinnamon ${DESTDIR}/etc/skel

	## Set defaults directories
	chroot ${DESTDIR} su -c xdg-user-dirs-update ${USER_NAME}
}

xfce_settings(){
	# Set Adwaita cursor theme
	chroot ${DESTDIR} ln -s /usr/share/icons/Adwaita /usr/share/icons/default

	# copy antergos menu icon
	mkdir -p ${DESTDIR}/usr/share/antergos/
	cp /usr/share/antergos/antergos-menu.png ${DESTDIR}/usr/share/antergos/antergos-menu.png

	# Set settings
	mkdir -p ${DESTDIR}/home/${USER_NAME}/.config/xfce4/xfconf/xfce-perchannel-xml
	cp -R ${DESTDIR}/etc/xdg/xfce4/panel ${DESTDIR}/etc/xdg/xfce4/helpers.rc ${DESTDIR}/home/${USER_NAME}/.config/xfce4
	sed -i "s/WebBrowser=firefox/WebBrowser=chromium/" ${DESTDIR}/home/${USER_NAME}/.config/xfce4/helpers.rc
	chroot ${DESTDIR} chown -R ${USER_NAME}:users /home/${USER_NAME}/.config
	cp /usr/share/cnchi/scripts/set-settings ${DESTDIR}/usr/bin/set-settings
	mkdir -p ${DESTDIR}/var/run/dbus
	mount -o bind /var/run/dbus ${DESTDIR}/var/run/dbus
	chroot ${DESTDIR} su -c "/usr/bin/set-settings ${DESKTOP}" ${USER_NAME} >/dev/null 2>&1
	rm ${DESTDIR}/usr/bin/set-settings

	# Set skel directory
	cp -R ${DESTDIR}/home/${USER_NAME}/.config ${DESTDIR}/etc/skel

	## Set defaults directories
	chroot ${DESTDIR} su -c xdg-user-dirs-update ${USER_NAME}

	# Set xfce in .dmrc
	echo "[Desktop]" > ${DESTDIR}/home/${USER_NAME}/.dmrc
	echo "Session=xfce" >> ${DESTDIR}/home/${USER_NAME}/.dmrc
	chroot ${DESTDIR} chown ${USER_NAME}:users	/home/${USER_NAME}/.dmrc
}

openbox_settings(){
	# Set Adwaita cursor theme
	chroot ${DESTDIR} ln -s /usr/share/icons/Adwaita /usr/share/icons/default

	# copy antergos menu icon
	mkdir -p ${DESTDIR}/usr/share/antergos/
	cp /usr/share/antergos/antergos-menu.png ${DESTDIR}/usr/share/antergos/antergos-menu.png
    
	# Get zip file from github, unzip it and copy all setup files in their right places.
	wget -q -O /tmp/master.zip "https://github.com/Antergos/openbox-setup/archive/master.zip"
   	unzip -o -qq /tmp/master.zip -d /tmp

	## Copy slim theme
	#mkdir -p ${DESTDIR}/usr/share/slim/themes/antergos-slim
	#cp ${DESTDIR}/tmp/openbox-setup-master/antergos-slim/* ${DESTDIR}/usr/share/slim/themes/antergos-slim
    
	# Copy home files
	cp /tmp/openbox-setup-master/gtkrc-2.0 ${DESTDIR}/home/${USER_NAME}/.gtkrc-2.0
	chroot ${DESTDIR} chown -R ${USER_NAME}:users /home/${USER_NAME}/.gtkrc-2.0  
	cp /tmp/openbox-setup-master/xinitrc ${DESTDIR}/home/${USER_NAME}/.xinitrc
	chroot ${DESTDIR} chown -R ${USER_NAME}:users /home/${USER_NAME}/.xinitrc
    
	# Copy .config files
	mkdir -p ${DESTDIR}/home/${USER_NAME}/.config
	cp -R /tmp/openbox-setup-master/config/* ${DESTDIR}/home/${USER_NAME}/.config

    # Copy /etc setup files
    cp -R /tmp/openbox-setup-master/etc/* ${DESTDIR}/etc
    chroot ${DESTDIR} chown -R ${USER_NAME}:users /home/${USER_NAME}/.config
	
    # Set settings
    cp /usr/share/cnchi/scripts/set-settings ${DESTDIR}/usr/bin/set-settings
	mkdir -p ${DESTDIR}/var/run/dbus
	mount -o bind /var/run/dbus ${DESTDIR}/var/run/dbus
	chroot ${DESTDIR} su -c "/usr/bin/set-settings ${DESKTOP}" ${USER_NAME} >/dev/null 2>&1
	rm ${DESTDIR}/usr/bin/set-settings
    
	# Set skel directory
	cp -R ${DESTDIR}/home/${USER_NAME}/.config ${DESTDIR}/etc/skel

	## Set defaults directories
	#chroot ${DESTDIR} su -c xdg-user-dirs-update ${USER_NAME}

	# Set openbox in .dmrc
	echo "[Desktop]" > ${DESTDIR}/home/${USER_NAME}/.dmrc
	echo "Session=openbox" >> ${DESTDIR}/home/${USER_NAME}/.dmrc
	chroot ${DESTDIR} chown ${USER_NAME}:users	/home/${USER_NAME}/.dmrc
}

razor_settings(){
	# Set theme
	mkdir -p ${DESTDIR}/home/${USER_NAME}/.config/razor/razor-panel
	echo "[General]" > ${DESTDIR}/home/${USER_NAME}/.config/razor/razor.conf
	echo "__userfile__=true" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/razor.conf
	echo "icon_theme=Faenza" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/razor.conf
	echo "theme=ambiance" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/razor.conf

	# Set panel launchers
	echo "[quicklaunch]" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/razor-panel/panel.conf
	echo "apps\1\desktop=/usr/share/applications/razor-config.desktop" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/razor-panel/panel.conf
	echo "apps\size=3" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/razor-panel/panel.conf
	echo "apps\2\desktop=/usr/share/applications/kde4/konsole.desktop" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/razor-panel/panel.conf
	echo "apps\3\desktop=/usr/share/applications/chromium.desktop" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/razor-panel/panel.conf

	# Set Wallpaper
	echo "[razor]" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/desktop.conf
	echo "screens\size=1" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/desktop.conf
	echo "screens\1\desktops\1\wallpaper_type=pixmap" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/desktop.conf
	echo "screens\1\desktops\1\wallpaper=/usr/share/antergos/wallpapers/antergos-wallpaper.png" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/desktop.conf
	echo "screens\1\desktops\1\keep_aspect_ratio=false" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/desktop.conf
	echo "screens\1\desktops\size=1" >> ${DESTDIR}/home/${USER_NAME}/.config/razor/desktop.conf

	# Set Razor in .dmrc
	echo "[Desktop]" > ${DESTDIR}/home/${USER_NAME}/.dmrc
	echo "Session=razor" >> ${DESTDIR}/home/${USER_NAME}/.dmrc
	chroot ${DESTDIR} chown ${USER_NAME}:users	/home/${USER_NAME}/.dmrc
	
	chroot ${DESTDIR} chown -R ${USER_NAME}:users /home/${USER_NAME}/.config
}

kde_settings(){

	# Set KDE in .dmrc
	echo "[Desktop]" > ${DESTDIR}/home/${USER_NAME}/.dmrc
	echo "Session=kde-plasma" >> ${DESTDIR}/home/${USER_NAME}/.dmrc
	chroot ${DESTDIR} chown ${USER_NAME}:users /home/${USER_NAME}/.dmrc

	# Force QtCurve to use our theme
	rm -R ${DESTDIR}/usr/share/apps/QtCurve/
	
	# Get zip file from github, unzip it and copy all setup files in their right places.
   	wget -q -O /tmp/master.tar.xz "https://github.com/Antergos/kde-setup/raw/master/kde-setup-2014-25-05.tar.xz"
   	#xz -d -qq /tmp/master.tar.xz
   	#cd ${DESTDIR}
    cd /tmp
   	tar xfJ /tmp/master.tar.xz
    chown -R root:root /tmp/etc
    chown -R root:root /tmp/usr
   	cp -R /tmp/etc/* ${DESTDIR}/etc
   	cp -R /tmp/usr/* ${DESTDIR}/usr

	# Set User & Root environments
	cp -R ${DESTDIR}/etc/skel/.config ${DESTDIR}/home/${USER_NAME}
	cp -R ${DESTDIR}/etc/skel/.kde4 ${DESTDIR}/home/${USER_NAME}
	cp ${DESTDIR}/etc/skel/.gtkrc-2.0-kde4 ${DESTDIR}/home/${USER_NAME}
	cp -R ${DESTDIR}/etc/skel/.config ${DESTDIR}/root
	cp -R ${DESTDIR}/etc/skel/.kde4 ${DESTDIR}/root
	cp ${DESTDIR}/etc/skel/.gtkrc-2.0-kde4 ${DESTDIR}/root
	chroot ${DESTDIR} "ln -s /home/${USER_NAME}/.gtkrc-2.0-kde4 /home/${USER_NAME}/.gtkrc-2.0" ${USER_NAME}
	chroot ${DESTDIR} "ln -s /root/.gtkrc-2.0-kde4 /root/.gtkrc-2.0"
	
	## Set defaults directories
	chroot ${DESTDIR} su -c xdg-user-dirs-update ${USER_NAME}
}

mate_settings() {

	# Set MATE in .dmrc
	echo "[Desktop]" > ${DESTDIR}/home/${USER_NAME}/.dmrc
	echo "Session=mate-session" >> ${DESTDIR}/home/${USER_NAME}/.dmrc
	chroot ${DESTDIR} chown ${USER_NAME}:users	/home/${USER_NAME}/.dmrc

	## Set default directories
	chroot ${DESTDIR} su -c xdg-user-dirs-update ${USER_NAME}

   	# Set gsettings input-source
	if [[ "${KEYBOARD_VARIANT}" != '' ]];then
		sed -i "s/'us'/'${KEYBOARD_LAYOUT}+${KEYBOARD_VARIANT}'/" /usr/share/cnchi/scripts/set-settings
	else
		sed -i "s/'us'/'${KEYBOARD_LAYOUT}'/" /usr/share/cnchi/scripts/set-settings
  	 fi
	# Fix for Zukitwo Metacity Theme
	cp ${DESTDIR}/usr/share/themes/Zukitwo/metacity-1/metacity-theme-2.xml ${DESTDIR}/usr/share/themes/Zukitwo/metacity-1/metacity-theme-1.xml
	
    	# copy antergos menu icon
	mkdir -p ${DESTDIR}/usr/share/antergos/
	cp /usr/share/antergos/antergos-menu.png ${DESTDIR}/usr/share/antergos/antergos-menu.png
	chroot ${DESTDIR} ln -sf /usr/share/antergos/antergos-menu.png /usr/share/icons/Numix/24x24/places/start-here.png

    	# Set gsettings
	cp /usr/share/cnchi/scripts/set-settings ${DESTDIR}/usr/bin/set-settings
	mkdir -p ${DESTDIR}/var/run/dbus
	mount -o bind /var/run/dbus ${DESTDIR}/var/run/dbus
	chroot ${DESTDIR} su -l -c "/usr/bin/set-settings ${DESKTOP}" ${USER_NAME} >/dev/null 2>&1
	rm ${DESTDIR}/usr/bin/set-settings
	
	# Set MintMenu Favorites
	cat << EOF > ${DESTDIR}/usr/lib/linuxmint/mintMenu/applications.list
location:/usr/share/applications/chromium.desktop
location:/usr/share/applications/pacmanxg.desktop
separator
location:/usr/share/applications/galculator.desktop
location:/usr/share/applications/pluma.desktop
location:/usr/share/applications/mate-terminal.desktop
location:/usr/share/applications/mate-system-monitor.desktop
separator
location:/usr/share/applications/mate-mplayer.desktop
location:/usr/share/applications/xnoise.desktop
EOF

	# Copy panel layout
	cp /usr/share/cnchi/scripts/antergos.layout ${DESTDIR}/usr/share/mate-panel/layouts/antergos.layout


}

nox_settings(){
	echo "Done"
}

enlightenment_settings(){
    echo "TODO"
}


postinstall(){
	USER_NAME=$1
	DESTDIR=$2
	DESKTOP=$3
	KEYBOARD_LAYOUT=$4
	KEYBOARD_VARIANT=$5
	# Specific user configurations

	## Set desktop-specific settings
	"${DESKTOP}_settings"
	
	## Ensure user permissions are set in /home
	chroot ${DESTDIR} chown -R ${USER_NAME}:users /home/${USER_NAME}

	## Workaround for LightDM bug https://bugs.launchpad.net/lightdm/+bug/1069218
	chroot ${DESTDIR} sed -i 's|UserAccounts|UserList|g' /etc/lightdm/users.conf

	## Unmute alsa channels
	chroot ${DESTDIR} amixer -c 0 set Master playback 50% unmute>/dev/null 2>&1

	# Fix transmission leftover
    	if [ -f ${DESTDIR}/usr/lib/tmpfiles.d/transmission.conf ];
    	then
	    mv ${DESTDIR}/usr/lib/tmpfiles.d/transmission.conf ${DESTDIR}/usr/lib/tmpfiles.d/transmission.conf.backup
    	fi

	# Configure touchpad. Skip with base installs
	if [[ $DESKTOP != 'nox' ]];then
		set_synaptics
	fi
    
    	# Configure fontconfig
    	FONTCONFIG_FILE="/usr/share/cnchi/scripts/fonts.conf"
    	FONTCONFIG_DIR="${DESTDIR}/home/${USER_NAME}/.config/fontconfig"
    	if [ -f ${FONTCONFIG_FILE} ]; then
        	mkdir -p ${FONTCONFIG_DIR}
	    	cp ${FONTCONFIG_FILE} ${FONTCONFIG_DIR}
   	fi

	# Set Antergos name in filesystem files
	cp /etc/arch-release ${DESTDIR}/etc
	cp -f /etc/os-release ${DESTDIR}/etc/os-release
	
}

touch /tmp/.postinstall.lock
postinstall $1 $2 $3 $4 $5 $6 > /tmp/postinstall.log 2>&1
rm /tmp/.postinstall.lock
