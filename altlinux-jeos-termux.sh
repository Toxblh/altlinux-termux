#!/data/data/com.termux/files/usr/bin/bash

# Подготовка, загружаем FS и распаковываем
folder=altlinux-fs

if [ -d "$folder" ]; then
	first=1
	echo "Уже скачено, пропуск шага"
fi
tarball="altlinux-rootfs.tar.xz"

if [ "$first" != 1 ]; then
	if [ ! -f $tarball ]; then
		echo "Скачиваем Rootfs"
		wget "http://nightly.altlinux.org/unstable/aarch64/current/regular-lxde-latest-aarch64.tar.xz" -O $tarball
	fi

	current=$(pwd)
	mkdir -p "$folder"
	cd $folder
	echo "Распаковка Rootfs, может быть долго, ожидайте."
	proot --link2symlink tar -xJf ${current}/${tarball} --exclude='dev' || :

	echo "Setting up name server"
	echo "127.0.0.1 localhost" > etc/hosts
	echo "nameserver 8.8.8.8" > etc/resolv.conf
	echo "nameserver 8.8.4.4" >> etc/resolv.conf
	cd "$current"
fi

# Создание скрипта запуска AltLinux
mkdir -p altlinux-binds
bin=start-altlinux.sh

echo "Создаём скрипты для запуска"
cat >$bin <<-EOM
	#!/bin/bash
	cd \$(dirname \$0)
	## unset LD_PRELOAD in case termux-exec is installed
	unset LD_PRELOAD
	command="proot"
	command+=" --link2symlink"
	command+=" -0"
	command+=" -r $folder"
	if [ -n "\$(ls -A altlinux-binds)" ]; then
	    for f in altlinux-binds/* ;do
	      . \$f
	    done
	fi
	command+=" -b /dev"
	command+=" -b /proc"
	command+=" -b altlinux-fs/root:/dev/shm"
	## uncomment the following line to have access to the home directory of termux
	#command+=" -b /data/data/com.termux/files/home:/root"
	## uncomment the following line to mount /sdcard directly to / 
	#command+=" -b /sdcard"
	command+=" -w /root"
	command+=" /usr/bin/env -i"
	command+=" HOME=/root"
	command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
	command+=" TERM=\$TERM"
	command+=" LANG=C.UTF-8"
	command+=" /bin/bash --login"
	com="\$@"
	if [ -z "\$1" ];then
	    exec \$command
	else
	    \$command -c "\$com"
	fi
EOM

echo "Исправляем возможные проблемы с $bin"
termux-fix-shebang $bin

echo "Делаем $bin исполняемым"
chmod +x $bin

echo "Подчищаем за собой"
rm $tarball

echo "Готово - для запуска AltLinux выполните команду ./${bin}"
