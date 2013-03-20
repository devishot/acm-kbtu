/* -*- mode: c -*- */
/* $Id: xcalloc.c 5687 2010-01-19 10:10:15Z cher $ */

/* Copyright (C) 2003 Alexander Chernov <cher@ispras.ru> */

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

void *
xcalloc(size_t nmemb, size_t size)
{
  void *ptr = calloc(nmemb, size);
  if (!ptr) fatal_CF("Out of heap memory: calloc(%zu,%zu) failed",nmemb, size);
  return ptr;
}

/*
 * Local variables:
 *  compile-command: "make"
 *  c-font-lock-extra-types: ("\\sw+_t" "FILE")
 * End:
 */