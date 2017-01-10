#!/bin/bash
#切到根目录下执行命令，跟lua的require默认路径相关
cd `dirname $0`/../

/usr/local/openresty/bin/openresty -p `pwd`/runtime -c `pwd`/runtime/nginx.conf
