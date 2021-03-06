/*
 * Copyright (c) 2015 Cedric Hnyda <chnyda@suse.com>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of version 2 of the GNU General Public License as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it would be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * Further, this software is distributed without any warranty that it is
 * free of the rightful claim of any third person regarding infringement
 * or the like.  Any license provided herein, whether implied or
 * otherwise, applies only to this software file.  Patent licenses, if
 * any, provided herein do not apply to combinations of this program with
 * other software, or any other product whatsoever.
 */

 /* Description:
 *   Calls renameat2(2) with the flag RENAME_EXCHANGE and check that
 *   the content was swapped
 */

#define _GNU_SOURCE

#include "test.h"
#include "safe_macros.h"
#include "lapi/fcntl.h"
#include "renameat2.h"

#define TEST_DIR "test_dir/"
#define TEST_DIR2 "test_dir2/"

#define TEST_FILE "test_file"
#define TEST_FILE2 "test_file2"

char *TCID = "renameat202";

static int olddirfd;
static int newdirfd;
static int fd = -1;
static int cnt;

static const char content[] = "content";


int TST_TOTAL = 1;

static void setup(void);
static void cleanup(void);
static void renameat2_verify(void);


int main(int ac, char **av)
{
	int lc;

	tst_parse_opts(ac, av, NULL, NULL);

	setup();

	for (lc = 0; TEST_LOOPING(lc); lc++) {

		tst_count = 0;

		TEST(renameat2(olddirfd, TEST_FILE,
				newdirfd, TEST_FILE2, RENAME_EXCHANGE));

		cnt++;

		renameat2_verify();
	}

	cleanup();
	tst_exit();
}

static void setup(void)
{
	if ((tst_kvercmp(3, 15, 0)) < 0) {
		tst_brkm(TCONF, NULL,
			"This test can only run on kernels that are 3.15. and higher");
	}

	tst_tmpdir();

	SAFE_MKDIR(cleanup, TEST_DIR, 0700);
	SAFE_MKDIR(cleanup, TEST_DIR2, 0700);

	SAFE_TOUCH(cleanup, TEST_DIR TEST_FILE, 0600, NULL);
	SAFE_TOUCH(cleanup, TEST_DIR2 TEST_FILE2, 0600, NULL);

	olddirfd = SAFE_OPEN(cleanup, TEST_DIR, O_DIRECTORY);
	newdirfd = SAFE_OPEN(cleanup, TEST_DIR2, O_DIRECTORY);

	SAFE_FILE_PRINTF(cleanup, TEST_DIR TEST_FILE, "%s", content);

}

static void cleanup(void)
{
	if (olddirfd > 0 && close(olddirfd) < 0)
		tst_resm(TWARN | TERRNO, "close olddirfd failed");

	if (newdirfd > 0 && close(newdirfd) < 0)
		tst_resm(TWARN | TERRNO, "close newdirfd failed");

	if (fd > 0 && close(fd) < 0)
		tst_resm(TWARN | TERRNO, "close fd failed");

	tst_rmdir();

}

static void renameat2_verify(void)
{
	char str[sizeof(content)];
	struct stat st;
	char *emptyfile;
	char *contentfile;

	if (TEST_RETURN != 0) {
		tst_resm(TFAIL, "renameat2() failed unexpectedly");
		return;
	}

	if (cnt % 2 == 1) {
		emptyfile = TEST_DIR TEST_FILE;
		contentfile = TEST_DIR2 TEST_FILE2;
	} else {
		emptyfile = TEST_DIR2 TEST_FILE2;
		contentfile = TEST_DIR TEST_FILE;
	}

	fd = SAFE_OPEN(cleanup, contentfile, O_RDONLY);

	SAFE_STAT(cleanup, emptyfile, &st);

	SAFE_READ(cleanup, 0, fd, str, strlen(content) + 10);

	if (close(fd) < 0)
		tst_brkm(TERRNO | TFAIL, cleanup, "close fd failed");
	fd = 0;

	if (str[strlen(content)] == '\0' && !strcmp(content, str)
		&& !st.st_size)
		tst_resm(TPASS,
			"renameat2() swapped the content of the two files");
	else
		tst_resm(TFAIL,
			"renameat2() didn't swap the content of the two files");
}
