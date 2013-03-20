/* -*- mode: c -*- */
/* $Id: cmp_bytes.c 5687 2010-01-19 10:10:15Z cher $ */

/* Copyright (C) 2005-2007 Alexander Chernov <cher@ejudge.ru> */

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

#define NEED_CORR 1
#define NEED_INFO 0
#define NEED_TGZ  0
#include "checker.h"

int checker_main(int argc, char **argv)
{
  char *corr_data = 0, *out_data = 0;
  size_t corr_size = 0, out_size = 0, i;

  checker_read_file(1, &out_data, &out_size);
  checker_read_file(2, &corr_data, &corr_size);

  if (out_size != corr_size)
    fatal_WA("Different size: out = %zu, corr = %zu", out_size, corr_size);
  for (i = 0; i < corr_size; i++)
    if (corr_data[i] != out_data[i])
      break;
  if (i < corr_size)
    fatal_WA("Difference at byte %zu; out = %d, corr = %d", i,
             ((unsigned char*)out_data)[i],
             ((unsigned char*)corr_data)[i]);

  checker_OK();
}