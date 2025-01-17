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
import matplotlib.pyplot as plt
# from simparam import conH_simparm as parm

## PARAMETERS
# integer the specifies the number of points contained in a data series plot
max_ds_points = 10000


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

# method that generates a plot of time series data from simulations
def plot_temp_time_series (save_path, time, temp):

	# TODO :: add simid and job id to method call, add to plot sub titles
	# TODO :: generalize method for all properties
	# TODO :: save data series with plot

	# determine the maximum number of events that have occured
	tot_time = 0
	for i in range(len(time)):
		tot_time += time[i]

	# create empty list that contains the total number ds points
	ds_time = np.linspace(0, tot_time, num=max_ds_points)
	ds_temp = np.empty(max_ds_points, dtype = float)

	# loop through temperature points, assign temperature corresponding to time
	j = 0 
	# print(time)
	curr_time = time[j]
	for i in range(len(ds_time)):

		# determine if the time should be incremented
		if ds_time[i] > curr_time:
			j += 1 
			curr_time += time[j]

		# determine temperature that corresponds to the current time
		ds_temp[i] = temp[j]

	# plot the results
	fig = plt.figure()
	ax = plt.gca()
	ax.plot(ds_time, ds_temp)
	ax.set_yscale('log')
	plt.xlabel('Simulation Time ($s^{{*}}$)', fontsize=14)
	plt.ylabel('System Temperature ($log(T^{{*}})$)', fontsize=14)
	plt.suptitle('Annealing Simulation Temperature', fontsize=14)
	# plt.title('($S_{{ub}} = {:.2f}$, $N_{{squares}} = {:d}$)'.format(ub_val, n_squares), fontsize=14)
	# plt.show()
	plt.savefig(save_path, bbox_inches='tight', dpi = 200)
	plt.close(fig)

# method used to compile results from the annealing simulation, 
# then report the current state of the simulation to the user
def compile_simulation_results (sim_parm):

	# # parse the simid from the splice file
	# simid = glob.glob(sim_dir + "*.spl")
	# simid = simid[0].replace(sim_dir, '').replace(".spl", '')

	# # parse the job id from the initial simulations
	# jobid = glob.glob(sim_parm.path + "/anneal/init/*" + simid + "__simSAVE.dat")
	# if len(jobid) == 0:
	# 	print("Unable to parse JOBID from DIR ({sim_dir}). Initial simulation directory does not exist.")
	# 	return None
	# jobid = jobid[0].replace(sim_dir + "anneal/init/", '').replace(simid + "__simSAVE.dat", '')

	# create the analysis directory, if it does not exist already
	if not os.path.exists(sim_parm.path + "/anal/"):
		os.mkdir(sim_parm.path + "/anal/")

	# get the list of directories in the annealing directory that
	# match the naming convention
	anneal_dir_list = glob.glob(sim_parm.path + "/anneal/[0-9][0-9][0-9]/")
	anneal_int_list = np.empty(len(anneal_dir_list), dtype=int)
	for i in range(len(anneal_dir_list)):
		anneal_int_list[i] = int(anneal_dir_list[i].\
			replace(sim_parm.path + "/anneal/", '').replace('/', ''))
	anneal_int_list = np.sort(anneal_int_list)

	# parse the header for the anneal file from the first simulation
	anneal_dir = "/anneal/{:03d}/".format(anneal_int_list[0])
	anneal_file = sim_parm.path + anneal_dir + sim_parm.jobid + sim_parm.simid + "_anneal.csv"
	if not os.path.exists(anneal_file):
		print("Unable to open ANNEAL FILE ({anneal_file}). Cannot parse header.")
		return None
	f = open(anneal_file, 'r')
	while True:
		line = f.readline()
		head = line.replace(" ", '').replace("\n", '').split(',')
		break
	f.close()

	# create empty data frame that will contain all of the simulation results
	df = pd.DataFrame(columns = head)

	# loop through each anneal directory, get the simulation results from the anneal file
	for i in anneal_int_list:

		# establish the annealing file
		anneal_dir = "/anneal/{:03d}/".format(anneal_int_list[i])
		anneal_file = sim_parm.path + anneal_dir + sim_parm.jobid + sim_parm.simid + "_anneal.csv"
		# print(anneal_dir)

		# establish that the file exists
		if not os.path.exists(anneal_file):
			# if the path does not exist, break from the loop
			continue

		# parse the results from the simulation
		f = open(anneal_file, 'r')
		results = f.readlines()
		f.close()
		if (len(results) > 1):
			# if the file contains a second line
			# parse the second line, which contains the results
			results = results[1].split(',')
		else:
			# otherwise, break from the loop
			continue

		# check that the number of items in the result line is the same
		# as the number of items in the results header
		if len(head) != len(results):
			# if they are not equal, break skip this annealing iteration,
			# and move to the next one
			continue 

		# create a dictionary that contains the results formatted according to the header
		prop_dict = {}
		for j in range(len(head)):
			if "NaN" in results[j]:
				results[j] = "0."
			if head[j] == 'id':
				prop_dict[head[j]] = i
			else:
				prop_dict[head[j]] = float(results[j])

		# add the dictionary to the next row in the dataframe
		df = pd.concat([df, pd.DataFrame(prop_dict, index = [i])])
		# replace id column of current row with current index

	# write the annealing results from each simulation to the simulation
	# summary file
	sim_sum_file = sim_parm.path + "/anal/" + sim_parm.jobid + sim_parm.simid + "_sum.csv"
	df.to_csv(sim_sum_file, index = False)

	# plot the temperature profile of the simulation as a function of the 
	# simulation time and simulation events
	plot_temp_time_series(sim_parm.path + "/anal/" + sim_parm.jobid + sim_parm.simid + "_temptime.png",\
		df["time"].tolist(), df["temp"].tolist())

	# parse the results for each order parameter / fluctuation, 
	# and the corresponding temperature that they were calculated at

	# plot the current temperature of the simulation and the assign temperature
	# according to the number of steps that the simulation has taken / current
	# simuation iteration

	## TODO :: plot properties and fluctuations for all properties (make dict?)
	## TODO :: return most recent point in data series for sim update file
	return prop_dict

# method that gets updates from simulations, described by
# list of simulation parameters passed to method
def update_simulation_results (simparms, savedir = None, saveas = None, verbose = False):

	df_results = pd.DataFrame() # establish empty data frame that contains the results
	i = 0 # used to count the number of rows in the data frame

	# loop through parameters, load results
	for p in simparms:
		# inform user
		if verbose:
			print("Summarizing directory no. {:d} ({:s})".format(i, p.path))

		# compile the current results of the simulation, return sim infor
		prop_dict = compile_simulation_results (p)

		# create dictionary containing simulation parameters, add to dataframe
		sim_dict = p.info() | prop_dict
		df_results = pd.concat([df_results, pd.DataFrame(sim_dict, index = [i])])

		# increment the number of rows in the data frame
		i += 1

	# if save dir was specified
	if savedir is not None:
		# print the results as a csv
		# create summary directories
		if not os.path.exists(savedir):
			os.mkdir(savedir)

		# establish save file
		if saveas is not None:
			savefile = savedir + saveas
		else:
			savefile = savedir + 'status.csv'

		# write the sim status file to the summary directory
		df_results.to_csv(savefile, index = False)