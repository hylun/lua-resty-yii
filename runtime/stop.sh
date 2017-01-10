#!/bin/bash
cd `dirname $0`/../

ps -ef|grep `pwd`|grep openresty |grep -v grep |awk '{print $2}'|xargs kill
