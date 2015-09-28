# Linux Test Project for ARC Linux

For details about LTP see README.ltp and http://ltp.sourceforge.net/
For details about ARC processors see http://www.synopsys.com/dw/ipdir.php?ds=arc_770d

Not all tests from LTP suite are applicable to ARC Linux which is an embedded
system based on uClibc and BusyBox. So some of the tests need to be disabled in
order for LTP to build and run succesfully.


## Build instructions

```
git clone git://github.com/anthony-kolesov/ltp.git
cd ltp
make autotools
./configure --host=arc-linux-uclibc CC=arc-linux-uclibc-gcc STRIP=arc-linux-uclibc-strip --enable-arc-support CFLAGS="-Dlinux"
make
sudo make install
```

If you want to make out-of-tree then consult `INSTALL` for details and possible issues.

To add Open Posix Test suite to the list of tests, add option
`--with-open-posix-testsuite` to configure. Also set `CC` for make:
```
make CC=arc-linux-uclibc-gcc
```


## Run on target

```
[ARCLinux] $ cd ltp
[ARCLinux] $ ./runltp
```

Only `runltp` configuration is supported. `runalltests.sh` and `runltplite.sh` will probably
run some tests that may crash or hang target system or take too much time to finish.


## Modifications to original LTP

### Tests that cannot be built

These tests cannot be build by ARC Linux uClibc Toolchain (as of version 4.4). To disable all of
them at once provide --enable-arc-support flag to ./configure command.

* controllers/cpuset
* security/tomoyo
* kernel/syscalls/clock_nanosleep (also must be disable in ./runtest/syscalls)
* kernel/syscalls/ustat - obscolete syscall, not available on ARC
* misc/math/float/float_bessel - bessel extensions are not build in uClibc by default
* misc/math/float/bessel - bessel extensions are not build in uClibc by default
* network/lib6, sctp, stress, tcp_cmds - IP v6 is not built by default
* kernel/timers/leapsec - uses clock_nanosleep
* kernel/syscalls/flock/flock03 - build error
* kernel/syscalls/fadvise - build error
* kernel/syscalls/ustat - build error
* security/prot_hsymlinks - build error
* kernel/containers/mqns/check_mqns_enabled.c - linker error
* kernel/containers/utsname/check_utsns_enabled.c - linker error.

Several tests use obsolete BSD signal system calls. These calls are disabled in
buildroot uClibc configuration and so they are disabled by default for ARC. You
can enable them if you build uClibc with support for obsolete BSD systemc calls:
* kernel/fs/ftest01, 03, 04, 05, 07, 08
* kernel/fs/inode02
* kernel/mem/mmapstress01, 09, 10
* kernel/mem/vmtests/data_space
* kernel/syscalls/sighold
* kernel/syscalls/sigrelse
* kernel/syscalls/fcntl14, 14_64, 17, 17_64
* kernel/syscalls/kill11, 12
* kernel/syscalls/vfork02
* kernel/syscalls/ipc/msgctl08, 09, 10, 11


### Tests with changed parameters

These tests can be run on ARC Linux but require are different from default
parameters because they either take too much time to execute or use values that
are too big for an embedded system.

* math/float_bessel - with default parameters take too much time to finish
* math/float_exp_log - with default parameters take too much time to finish
* math/float_iperb - with default parameters take too much time to finish
* math/float_power - with default parameters take too much time to finish
* math/float_trigo - with default parameters take too much time to finish
* syscalls/fork13 - change value of -i from 1000000 to 10000 so it will take
  bearable amount of time to complete   
* sched/hackbench01 - reduce number of iterations to reduce run time. Reduce
  number of processes because ARC doesn't support more than 4096 processes at
  one time.
* sched/hackbench02 - ARC Linux has problems if amount of threads in one
  process is more that 380.
* syscalls/getrusage03 - Some of test cases in it allocate large amounts of
  memory which are not available in our default Linux setup. These cases are
  disabled inside the C source with preprocessor for ARC.
* syscalls/splice02 - change input from seq 1 10000000 to seq 1 20000
  The stock value takes 30+ mins on FPGA @ 50MHz
* mm/mallocstress01 - default loop iters 100 and 60 threads take too long
  So iters reduced to 10


### Fatal tests

These tests cause system to crash or hung so they must be disabled.

* syscalls/sendfile04 - it is required to find why this tests causes system to hang
* syscalls/sendfile04_64 - it is required to find why this tests causes system to hang.
* syscalls/mkdir09 - hangs system
* syscalls/pth_str02 - hangs system
* syscalls/epoll-ltp - hangs system


### Not applicable tests

These tests are not applicable to ARC Linux but are reported as failed, so they
should be disabled.

* admin_tools/su01 - requires `useradd/userdel` commands
* admin_tools/cron02 - requires `useradd/userdel` commands
* admin_tools/cron_deny01 - requires `useradd/userdel` commands
* admin_tools/cron_allow01 - requires `useradd/userdel` commands
* admin_tools/cron_dirs_checks - cron isn't available
* admin_tools/acl_test01 - requires `mkfs` command. `mke2fs` can be used
  instead but then it fails due to lack of `useradd`
* commands/ar - command is unsupported on ARC Linux
* commands/ld - command is unsupported on ARC Linux
* commands/ldd - command is unsupported on ARC Linux
* commands/nm - command is unsupported on ARC Linux
* commands/objdump - command is unsupported on ARC Linux
* commands/file - command is unsupported on ARC Linux
* commands/tar - test uses `file` command which is unsupported on ARC Linux
* commands/cron - command is unsupported on ARC Linux
* commands/logrotate - command is unsupported on ARC Linux
* commands/cpio - test uses `file` command which is unsupported on ARC Linux
* commands/gzip01 - gzip in BusyBox doesn't support option `-r`
* controllers/cgroup
* controllers/controllers
* fs/rwtest01 - this test requires BASH which isn't available
* fs/rwtest02 - this test requires BASH which isn't available
* fs/rwtest03 - this test requires BASH which isn't available
* fs/rwtest04 - this test requires BASH which isn't available
* fs/rwtest05 - this test requires BASH which isn't available
* fs/iogen01 - this test requires BASH which isn't available
* fs_bind/BindMounts - this test requires BASH which isn't available
* io/aio01 - asynchronous IO isn't supported by uClibc
* io/aio02 - asynchronous IO isn't supported by uClibc
* mm/mtest06_2 - test requires 1 GiB of RAM but board has only 512 MiB
* numa/Numa-testcases - test requires command `numactl`
* mv/mv_tests.sh - disable test02 subtest because it uses `-b` flag of `mv`
  which is not presented in `mv` from BusyBox

## Notes

* commands/unzip01 - tests expect different output from `unzip` however it is
  just different words with same meaning so they cn be safely replaces in test
* fs/fs_racer* - these tests are written for bash which isn't available however
  they doesn't use syntax unsupported by BusyBox so they run nicely if `bash`
  is replaced with `sh`.
* mm/mmapstress06 - to pass this test requires 512 MiB RAM on board. So either
  ARC Linux kernel image must be compiled with 512 MiB RAM or
  ANON_GRAN_PAGES_MAX in test source code must be changed to 16U instead of 32U.
* sched/pth_str02 - this test will fail with current paramter "-n 1000" until
  STAR 9000579074 will be fixed
* syscalls/acct01 - will fail if BSD process accounting isn't enabled. Test
  source has been changes so test won't run if it isn't applicable.
* syscalls/epoll_create1_01 - epoll is disabled in ARC Linux by default but can
  be switched on.
* syscalls/epoll01 - epoll is disabled in ARC Linux by default but can be
  switched on.
* syscalls/ioctl03 - requires /dev/net/tun device.
* several shell scripts in Open POSIX test suite start with empty line. These
  need to be removed so bash bang will be on the first line.
* `dd` utility from BusyBox uses kD suffix instead of kB for 1000 multiplier.
  Thus it's fixed in `runltp` script.
* syscalls/chmod06 - loopback device is required
* syscalls/inotify03 - loopback device is required
* syscalls/chmod06 - loopback device is required
* syscalls/chown04 - loopback device is required
* syscalls/creat06 - loopback device is required
* syscalls/fchmod06 - loopback device is required
* syscalls/ftruncate04 - loopback device is required
* syscalls/ftruncate04_64 - loopback device is required
* syscalls/lchown03 - loopback device is required
* syscalls/link08 - loopback device is required
* syscalls/mkdir03 - loopback device is required
* syscalls/mkdirat02 - loopback device is required
* syscalls/mknod07 - loopback device is required
* syscalls/mknodat02 - loopback device is required
* syscalls/mmap16 - loopback device is required
* syscalls/mount01 - loopback device is required
* syscalls/mount02 - loopback device is required
* syscalls/mount03 - loopback device is required
* syscalls/mount04 - loopback device is required
* syscalls/mount06 - loopback device is required
* syscalls/open12 - loopback device is required
* syscalls/rmdir02 - loopback device is required
* syscalls/umount01 - loopback device is required
* syscalls/umount02 - loopback device is required
* syscalls/umount03 - loopback device is required
* syscalls/umount2_01 - loopback device is required
* syscalls/umount2_02 - loopback device is required
* syscalls/umount2_03 - loopback device is required
* syscalls/utimes01 - loopback device is required
* syscalls/utime06 - loopback device is required

## Requirements for the environment

* Linux must be built with support of loop block devices. Thus it's
  necessary to enable these Linux kernel options:
  CONFIG_BLK_DEV
  CONFIG_BLK_DEV_LOOP
* Linux must contain these packages: `util-linux`, `e2fsprogs`, `bash`. They
  may be included by enabling these Buildroot options:
  BR2_PACKAGE_UTIL_LINUX
  BR2_PACKAGE_UTIL_LINUX_BINARIES
  BR2_PACKAGE_E2FSPROGS
  BR2_PACKAGE_BUSYBOX_SHOW_OTHERS
  BR2_PACKAGE_BASH
