/* -*- mode: c -*- */
/* $Id: read_team_long_long.c 5913 2010-06-27 03:52:08Z cher $ */

/* Copyright (C) 2003-2010 Alexander Chernov <cher@ejudge.ru> */

/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#include "checker_internal.h"

int
checker_read_out_long_long(
        const char *name,
        int eof_error_flag,
        long long *p_val)
{
  return checker_read_long_long(1, name, eof_error_flag, p_val);
}

int
checker_read_team_long_long(
        const char *name,
        int eof_error_flag,
        long long *p_val)
{
  return checker_read_long_long(1, name, eof_error_flag, p_val);
}
