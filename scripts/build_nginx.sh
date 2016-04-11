#!/bin/bash
# Build NGINX and modules on Heroku.
# This program is designed to run in a web dyno provided by Heroku.
# We would like to build an NGINX binary for the builpack on the
# exact machine in which the binary will run.
# Our motivation for running in a web dyno is that we need a way to
# download the binary once it is built so we can vendor it in the buildpack.
#
# Once the dyno has is 'up' you can open your browser and navigate
# this dyno's directory structure to download the nginx binary.

NGINX_VERSION=${NGINX_VERSION-1.9.14}
PCRE_VERSION=${PCRE_VERSION-8.38}
HEADERS_MORE_VERSION=${HEADERS_MORE_VERSION-0.29}
LUA_MODULE_VERSION=${LUA_MODULE_VERSION-0.10.2}
LUA_SRC_VERSION=${LUA_SRC_VERSION-5.1.4}

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
pcre_tarball_url=http://downloads.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.bz2
headers_more_nginx_module_url=https://github.com/agentzh/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz
lua_module_url=https://github.com/openresty/lua-nginx-module/archive/v${LUA_MODULE_VERSION}.tar.gz
lua_src=http://www.lua.org/ftp/lua-${LUA_SRC_VERSION}.tar.gz

temp_dir=$(mktemp -d /tmp/nginx.XXXXXXXXXX)

#define where lua libs are
export LUA_LIB=/${temp_dir}/nginx-${NGINX_VERSION}/lua-${LUA_SRC_VERSION}/lib
export LUA_INC=/${temp_dir}/nginx-${NGINX_VERSION}/lua-${LUA_SRC_VERSION}/include

echo "Serving files from /tmp on $PORT"
cd /tmp
#python -m SimpleHTTPServer $PORT &

cd $temp_dir
echo "Temp dir: $temp_dir"

echo "Downloading $nginx_tarball_url"
curl -L $nginx_tarball_url | tar xzv

echo "Downloading $pcre_tarball_url"
(cd nginx-${NGINX_VERSION} && curl -L $pcre_tarball_url | tar xvj )

echo "Downloading $headers_more_nginx_module_url"
(cd nginx-${NGINX_VERSION} && curl -L $headers_more_nginx_module_url | tar xvz )

echo "Downloading $lua_module_url"
(cd nginx-${NGINX_VERSION} && curl -L $lua_module_url | tar xvz )

echo "Downloading and building $lua_src"
(
	cd nginx-${NGINX_VERSION} && curl -L $lua_src | tar xvz
	cd /${temp_dir}/nginx-${NGINX_VERSION}/lua-${LUA_SRC_VERSION}
	make linux
)

echo "Building Nginx ${NGINX_VERSION}"
(
	cd nginx-${NGINX_VERSION}
	./configure \
		--with-pcre=pcre-${PCRE_VERSION} \
		--prefix=/tmp/nginx \
		--add-module=/${temp_dir}/nginx-${NGINX_VERSION}/headers-more-nginx-module-${HEADERS_MORE_VERSION} \
		--add-module=/${temp_dir}/nginx-${NGINX_VERSION}/lua-nginx-module-${LUA_MODULE_VERSION}
	pwd	
	make install
)

while true
do
	sleep 1
	echo "."
done
