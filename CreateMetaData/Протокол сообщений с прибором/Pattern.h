#pragma once

extern uint8_t ReadMetaData(uint8_t* p, uint8_t n, uint16_t from);

const unsigned char __attribute__ ((section(".meta_data"), used)) cmetaAll[] = {
%s}; 
