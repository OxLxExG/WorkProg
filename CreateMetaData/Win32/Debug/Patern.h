#pragma once
#pragma once

#include <avr/io.h>
#include <avr/pgmspace.h>

const unsigned char __attribute__ ((section(".meta_data"), used)) cmetaAll[] = {
%s};

inline uint8_t ReadMetaData(uint8_t* p, uint8_t n, uint16_t from)
{
	memcpy_P(p, (uint8_t*) &cmetaAll + from, n);	
	return n;
}
