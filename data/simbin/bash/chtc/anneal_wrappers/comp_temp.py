#!/usr/bin/env python3
import sys, os
current_temp = float(sys.argv[1])
anneal_temp = float(sys.argv[2])
if (current_temp < anneal_temp):
	print(1)
else:
	print(0)