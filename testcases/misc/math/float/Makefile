#
#    misc/math/float test suite Makefile.
#
#    Copyright (C) 2009, Cisco Systems Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Garrett Cooper, July 2009
#

top_srcdir	?= ../../../..

include $(top_srcdir)/include/mk/testcases.mk

LDLIBS		+= -lpthread -lm

# main.c doesn't compile...
MAKE_TARGETS	:= $(patsubst $(abs_srcdir)/%.c,%,$(wildcard $(abs_srcdir)/float*.c))

ifeq ($(ENABLE_ARC_SUPPORT), yes)
FILTER_OUT_MAKE_TARGETS += float_bessel
FILTER_OUT_DIRS += bessel
endif

include $(top_srcdir)/include/mk/generic_trunk_target.mk
