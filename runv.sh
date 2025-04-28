#!/bin/bash
iverilog $1 && ./a.out | tee log.txt

