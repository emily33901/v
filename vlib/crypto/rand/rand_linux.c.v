// Copyright (c) 2019-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module rand

#include <sys/syscall.h>
const (
	read_batch_size = 256
)

// read returns an array of `bytes_needed` random bytes read from the OS.
pub fn read(bytes_needed int) ?[]byte {
	mut buffer := &byte(0)
	unsafe {
		buffer = malloc(bytes_needed)
	}
	mut bstart := buffer
	mut bytes_read := 0
	mut remaining_bytes := bytes_needed
	// getrandom syscall wont block if requesting <= 256 bytes
	for bytes_read < bytes_needed {
		batch_size := if remaining_bytes > read_batch_size { read_batch_size } else { remaining_bytes }
		unsafe {
			bstart = buffer + bytes_read
		}
		rbytes := getrandom(batch_size, bstart)
		if rbytes == -1 {
			free(buffer)
			return read_error
		}
		bytes_read += rbytes
	}
	return c_array_to_bytes_tmp(bytes_needed, buffer)
}

fn getrandom(bytes_needed int, buffer voidptr) int {
	if bytes_needed > read_batch_size {
		panic('getrandom() dont request more than $read_batch_size bytes at once.')
	}
	return unsafe { C.syscall(C.SYS_getrandom, buffer, bytes_needed, 0) }
}
