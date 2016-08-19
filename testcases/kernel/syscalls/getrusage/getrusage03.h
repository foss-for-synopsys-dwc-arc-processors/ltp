/*
 * Copyright (c) 2016 Synopsys, Inc. (www.synopsys.com)
 * Copyright (c) 2016 Yuriy Kolerov <yuriy.kolerov@synopsys.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef GETRUSAGE03_H
#define GETRUSAGE03_H

#define DELTA_MAX		10240
#define CONSUME_INITIAL_MB	100
#define CONSUME_FORK_MALLOC_MB	50
#define CONSUME_GRANDCHILD_MB	300
#define CONSUME_ZOMBIE_MB	400
#define CONSUME_SIG_IGN_MB	500

#define N_TO_STR(s) _N_TO_STR(s)
#define _N_TO_STR(s) #s

#endif
