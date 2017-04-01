#!/bin/bash
#切到根目录下执行命令，跟lua的require默认路径相关
cd `dirname $0`/../

if [ ! -d " runtime/logs" ]; then
  mkdir runtime/logs
fi

#如果找不到openresty，请修改以下openresty的路径
/usr/local/openresty/bin/openresty -p `pwd`/runtime -c `pwd`/runtime/nginx.conf
