# filename :: conH_anal.py
# author :: Matthew Dorsey (@sunprancekid)
# date :: 2023-09-28
# purpuse :: program that calculates phase diagrams for 
#			 data from the conH simulations


import sys, os
import pandas as pd
import numpy as np
import glob
import matplotlib.pyplot as plt


## PARAMETERS
# minimum order parameter value (between 0 and 1) in order for 
# an annealing simulationto be considered to have transition to 
# a phase corresponding to that order parameter
min_op_val = 0.7

# maximum temperature in order for a simulation to be considered
# fully annealed and its order parameters calculated
max_anneal_temp = 0.05

# dictionary that contains properties that should be considered
# and the headers for the order parameter values / fluctuations 
# during the simulation


## FUNCTIONS
# calculates ground state phase diagrams
def calc_ground_state (sim_df):

	# create directory which contains ground state phase diagrams
	gs_path = anal_dir + "summary/GSPD/"
	if not os.path.exists(gs_path)
		os.mkdir(gs_path)


	## DH :: ground-state density-field (@ constant chirality fraction)
	gs_path = anal_dir + "summary/GSPD/DH/"
	if not os.path.exists(gs_path):
		os.mkdir(gs_path)

	# calculate 

	# AH :: ground-state chirality-field (@ constant density)
	# AD :: ground-state chirality-density (@ constant field)

# calculates inflection points for all simulations and their order parameters
def calc_inflect (sim_df):
	pass

	# DT :: density-temperature (@ constant chirality fraction, constant density)
	# HT :: field-temperature (@ constant chirality fraction, constant density)
	# AT :: chirality-temperature (@ constant field strength, constant density)

# main method that calculates all phase diagrams
def calculate_phase_diagrams(anal_dir, sim_df, GSPD = True, AnPD = True):
	pass

	# empty dataframe which will contain a list of simulations
	# which either failed in calculating inflection points
	# or have not yet reached a temperature which enables them
	# to be considered for temperature calculation

	if GSPD:
		## calculate ground state phase diagrams
		calc_ground_state(anal_dir, sim_df)

	if AnPD:
		pass
		## calculate inflection points for all simulations
		## calculate annealing phase diagrams

## ARGUMENTS
# first argument: path to directory containing simulation files
anal_dir = sys.argv[1]


## SCRIPT
# load data frame which contains the simulation results
sim_df = pd.read_csv(anal_dir + 'summary/status.csv')

# calculate phase diagrams for conH annealing simulations
calculate_phase_diagrams(anal_dir, sim_df, GSPD = True, AnPD = False)