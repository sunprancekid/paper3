# filename :: conH_update.py
# author :: Matthew Dorsey (@sunprancekid)
# date :: 2023-09-05
# purpuse :: program that collects data from conH simulations
#			 compliles them in a way they they can be analyzed
#			 by the user and by other programs


import sys, os
import pandas as pd
import numpy as np
import glob

## PARAMETERS
# none


## FUNCTIONS
# used to get sub-directories that match a certain naming convention.
# subroutine returns a np array that contains that sorted values that
# match the sub-directory naming convention
def get_dir_params(dir_path, subdir_regex):
	# name of directory regex used with globbing
	dir_regex = dir_path + subdir_regex
	# get list of directories that match the subdirectory regular expression
	dir_list = glob.glob(dir_regex + "*")
	# parse the parameters from the directory list
	param_list = np.empty(len(dir_list), dtype = float)
	for i in range(len(dir_list)):
		s = dir_list[i].replace(dir_regex, '')
		s = float(s)
		param_list[i] = s / 100

	# return the sorted list to the user
	return np.sort(param_list)

# method used to compile results from the simulation, report the current
# state of the simulation to the user
def update_simulation_results(sim_dir):
	print(sim_dir)


## ARGUMENTS
# path to directory containing simulation files
anal_dir = sys.argv[1]


## SCRIPT
##  determine the simulation parameters based on the directory hirearchy

# variable that contains the current operating directory
curr_dir = anal_dir

# the first directory is the number fraction of achirality particles
# determine the simulation parameters according to the directory hirerarchy
achirality_params = get_dir_params(curr_dir, "a")

# loop through each achirality directory, determine next set of parameters
for achai_val in achirality_params:

	# get the directory corresponding to the achiraliry parameter value
	achai_dir = "a{:03d}/".format(int(achai_val * 100))
	curr_dir = anal_dir + achai_dir

	# the second directory in the hirearchy is the set point of 
	# the external field strength
	field_params = get_dir_params(curr_dir, "h")

	# loop through each directory external field strength parameters
	for field_val in field_params:

		# get the directory corresponding to the external field parameter value
		field_dir = "h{:02d}/".format(int(field_val * 100))
		curr_dir = anal_dir + achai_dir + field_dir

		# the third directory in the hirearchy is the simulation density
		density_params = get_dir_params(curr_dir, "e")

		# loop through each density directory
		for density_val in density_params:

			# get the directory corresponding to the simulation density
			density_dir = "e{:02d}/".format(int(density_val * 100))
			curr_dir = anal_dir + achai_dir + field_dir + density_dir

			# compile the current results of the simulation
			update_simulation_results(curr_dir)
