# Matthew A. Dorsey
# Chemical Engineering - NCSU
# 2024.02.20
# program for updating and analyzing conH simulations of dipolar suqares

## PACKAGES
import sys, os
import simbin.python.conH.update
import numpy as np

## PARAMETERS
# file containing simulation parameters
simparm_file = './conH/squ2c32/conH_squ2c32.csv'

## ARGUMENTS
# load arguments containing instructions for analysis
update = 'update' in sys.argv