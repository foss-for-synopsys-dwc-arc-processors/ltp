#!/bin/bash

################################################################################
##                                                                            ##
## Copyright (c) 2009 FUJITSU LIMITED                                         ##
##                                                                            ##
## This program is free software;  you can redistribute it and#or modify      ##
## it under the terms of the GNU General Public License as published by       ##
## the Free Software Foundation; either version 2 of the License, or          ##
## (at your option) any later version.                                        ##
##                                                                            ##
## This program is distributed in the hope that it will be useful, but        ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License   ##
## for more details.                                                          ##
##                                                                            ##
## You should have received a copy of the GNU General Public License          ##
## along with this program;  if not, write to the Free Software               ##
## Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA    ##
##                                                                            ##
## Author: Shi Weihua <shiwh@cn.fujitsu.com>                                  ##
##                                                                            ##
################################################################################

subsystem=$1
remount_use=$2
noprefix_use=$3
release_agent_para=$4
subgroup_exist=$5
attach_operation=$6
remove_operation=$7
notify_on_release=$8
release_agent_echo=$9

remount_use_str="";
noprefix_use_str="";
release_agent_para_str="";
notify_on_release_str="";
release_agent_str="";

expected=1;

# Create some processes and move them to cgroups
pid=0;
pid2=0;

# not output debug info
no_debug=0

usage()
{
	echo "usage of cgroup_fj_function.sh: "
	echo "  ./cgroup_fj_function.sh -subsystem -remount_use -noprefix_use -release_agent_para"
	echo "                          -subgroup_exist -attach_operation -remove_operation"
	echo "                          -notify_on_release -release_agent_echo"
	echo "    subsystem's usable number"
	echo "      debug"
	echo "      cpuset"
	echo "      ns"
	echo "      cpu"
	echo "      cpuacct"
	echo "      memory"
	echo "      all"
	echo "      none: (none)"
	echo "      debug,debug: debug,debug"
	echo "      nonexistent: (nonexistent subsystem), e.g. abc"
	echo "      freezer: freezer"
	echo "      devices: devices"
	echo "    remount_use's usable number"
	echo "      yes: do not use remount in "-o"'s parameter"
	echo "      no: use it"
	echo "    noprefix_use's usable number"
	echo "      yes: do not use noprefix in "-o"'s parameter"
	echo "      no: use it. only cpuset available"
	echo "    release_agent_para's usable number"
	echo "      1: don't use release_agent_para= in "-o"'s parameter"
	echo "      2: empty after "=""
	echo "      3: available commad"
	echo "      4: command name exclude full path"
	echo "      5: command in /sbin"
	echo "      6: command in other directory"
	echo "      7: nonexistent command"
	echo "      8: no-permission command"
	echo "    subgroup_exist's usable number"
	echo "      yes: subgroup will been created"
	echo "      no: subgroup will not been created"
	echo "    attach_operation's usable number"
	echo "      1: attach nothing"
	echo "      2: attach one process by echo"
	echo "      3: attach all processes in root group by echo"
	echo "      4: attach child forked processes automatically"
	echo "      5: move one process to other subgroup by echo"
	echo "      6: move all processes to other subgroup by echo"
	echo "    remove_operation's usable number"
	echo "      1: remove nothing"
	echo "      2: remove some processes by echo"
	echo "      3: remove all processes in sub group by echo"
	echo "      4: remove some processes by kill"
	echo "      5: remove all forked processes by kill"
	echo "    notify_on_release's usable number"
	echo "      1: echo 0 to notify_on_release"
	echo "      2: echo 1 to notify_on_release"
	echo "      3: echo 2 to notify_on_release"
	echo "      4: echo -1 to notify_on_release"
	echo "      5: echo 0ddd to notify_on_release"
	echo "      6: echo 1ddd to notify_on_release"
	echo "      7: echo ddd1 to notify_on_release"
	echo "    release_agent_echo's usable number"
	echo "      1: echo nothing to release_agent"
	echo "      2: available commad"
	echo "      3: command name exclude full path"
	echo "      4: command in /sbin"
	echo "      5: command in other directory"
	echo "      6: nonexistent command"
	echo "      7: no-permission command"
	echo "example: ./cgroup_fj_function.sh debug yes yes 1 yes 1 1 1 1"
	echo "  will use "debug" to test, will not use option "remount","noprefix","release_agent""
	echo "  in in "-o"'s parameter, will create some subgroup, will not attach/remove any process"
	echo "  will echo 0 to notify_on_release and will not echo anything to release_agent"
}

export TESTROOT=`pwd`

export TMPFILE=$TESTROOT/tmp_tasks

. $TESTROOT/cgroup_fj_utility.sh

##########################  main   #######################
if [ "$#" -ne "9" ]; then
	echo "ERROR: Wrong input parameters... Exiting test";
	usage;
	exit -1;
fi

check_para;
if [ $? -ne 0 ]; then
	usage;
	exit -1;
fi
setup;

mount_cgroup;

$TESTROOT/cgroup_fj_proc &
pid=$!

mkdir_subgroup;

# cpuset.cpus and cpuset.mems should be specified with suitable value
# before attaching operation if subsystem is cpuset
if [ "$subsystem" == "cpuset" ] || [ "$subsystem" == "all" ] || [ $subsystem == "none" ] ; then
	exist=`grep -w cpuset /proc/cgroups | cut -f1`;
	if [ "$exist" != "" ]; then
		if [ "$noprefix_use" == "no" ]; then
			do_echo 1 1 `cat /dev/cgroup/cpus` /dev/cgroup/subgroup_1/cpus;
			do_echo 1 1 `cat /dev/cgroup/mems` /dev/cgroup/subgroup_1/mems;
		else
			do_echo 1 1 `cat /dev/cgroup/cpuset.cpus` /dev/cgroup/subgroup_1/cpuset.cpus;
			do_echo 1 1 `cat /dev/cgroup/cpuset.mems` /dev/cgroup/subgroup_1/cpuset.mems;
		fi
	fi
fi

# attaching operation
case $attach_operation in
"1" )
	;;
"2" )
	do_echo 1 1 $pid /dev/cgroup/subgroup_1/tasks;
	;;
"3" )
	$TESTROOT/cgroup_fj_proc &
	pid2=$!
	cat /dev/cgroup/tasks > $TMPFILE
	nlines=`cat $TMPFILE | wc -l`
	for i in `seq 1 $nlines`
	do
		cur_pid=`sed -n "$i""p" $TMPFILE`
		if [ -e /proc/$cur_pid/ ];then
			#For kernel 3.4.0 and higher, kernel disallow attaching kthreadd or
			#threads with flag 0x04000000 to cgroups.
			#kernel commit:
			#c4c27fbdda4e8ba87806c415b6d15266b07bce4b
			#14a40ffccd6163bbcd1d6f32b28a88ffe6149fc6
			tst_kvercmp 3 4 0
			if [ $? -ne 0 ]; then
				thread_flag=$(awk '{print $9}' /proc/$cur_pid/stat)
				thread_name=$(awk '{print $2}' /proc/$cur_pid/status | head -1)
				if [ "$thread_name" = "kthreadd" -o $((${thread_flag}&0x04000000)) -ne 0 ];then
					continue
				fi
			fi
			do_echo 1 1 "$cur_pid" /dev/cgroup/subgroup_1/tasks
		fi
	done
	;;
"4" )
	do_echo 1 1 $pid /dev/cgroup/subgroup_1/tasks;
	sleep 1
	do_kill 1 1 10 $pid
	;;
esac

# echo notify_on_release that analysed from parameter
case $notify_on_release in
"1"|"2"|"3")
	expected=1
	;;
*)
	expected=0
	;;
esac

#if [ $notify_on_release -ne 0 ] && [ $notify_on_release -ne 1 ] && [ $notify_on_release -ne 2 ];then
#	expected=0
#fi
do_echo 1 $expected $notify_on_release_str /dev/cgroup/subgroup_1/notify_on_release;

# echo release_agent that analysed from parameter
if [ $release_agent_echo -ne 1 ]; then
	do_echo 1 1 $release_agent_str /dev/cgroup/release_agent;
fi

sleep 1

# pid could not be echoed from subgroup if subsystem is ( or include ) ns,
# so we kill them here
if [ "$subsystem" == "ns" ] || [ "$subsystem" == "all" ] || [ $subsystem == "none" ] ; then
	do_kill 1 1 9 $pid
	do_kill 1 1 9 $pid2
# removing operation
else
	case $remove_operation in
	"1" )
		;;
	"2" )
		do_echo 1 1 $pid /dev/cgroup/tasks
		if [ $pid2 -ne 0 ]  ; then
			do_echo 1 1 $pid2 /dev/cgroup/tasks
		fi
		;;
	"3" )
		cat /dev/cgroup/subgroup_1/tasks > $TMPFILE
		nlines=`cat $TMPFILE | wc -l`
		if [ $nlines -ne 0 ]; then
			for i in `seq 1 $nlines`
			do
				cur_pid=`sed -n "$i""p" $TMPFILE`
				if [ -e /proc/$cur_pid/ ];then
					do_echo 1 1 "$cur_pid" /dev/cgroup/tasks
				fi
			done
		fi
		;;
	"4" )
		do_kill 1 1 9 $pid
		;;
	"5" )
		do_kill 1 1 9 $pid
		do_kill 1 1 9 $pid2
		;;
	esac
fi

sleep 1

do_rmdir 0 1 /dev/cgroup/subgroup_*

cleanup;
do_kill 1 1 9 $pid
do_kill 1 1 9 $pid2
sleep 1
exit 0;
