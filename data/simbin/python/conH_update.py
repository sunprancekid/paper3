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

## PARAMETERS
# execute script verbosely
verbose = True
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
	plt.savefig(save_path, dpi = 200) # bbox_inches='tight', 

# method used to compile results from the simulation, report the current
# state of the simulation to the user
def update_simulation_results(sim_dir):

	# parse the simid from the splice file
	simid = glob.glob(sim_dir + "*.spl")
	simid = simid[0].replace(sim_dir, '').replace(".spl", '')

	# parse the job id from the initial simulations
	jobid = glob.glob(sim_dir + "anneal/init/*" + simid + "__simSAVE.dat")
	if len(jobid) == 0:
		print("Unable to parse JOBID from DIR ({sim_dir}). Initial simulation directory does not exist.")
		return None
	jobid = jobid[0].replace(sim_dir + "anneal/init/", '').replace(simid + "__simSAVE.dat", '')

	# create the analysis directory, if it does not exist already
	if not os.path.exists(sim_dir + "anal/"):
		os.mkdir(sim_dir + "anal/")

	# get the list of directories in the annealing directory that
	# match the naming convention
	anneal_dir_list = glob.glob(sim_dir + "anneal/[0-9][0-9][0-9]/")
	anneal_int_list = np.empty(len(anneal_dir_list), dtype=int)
	for i in range(len(anneal_dir_list)):
		anneal_int_list[i] = int(anneal_dir_list[i].\
			replace(sim_dir + "anneal/", '').replace('/', ''))
	anneal_int_list = np.sort(anneal_int_list)

	# parse the header for the anneal file from the first simulation
	anneal_dir = "anneal/{:03d}/".format(anneal_int_list[0])
	anneal_file = sim_dir + anneal_dir + jobid + simid + "_anneal.csv"
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
		anneal_dir = "anneal/{:03d}/".format(anneal_int_list[i])
		anneal_file = sim_dir + anneal_dir + jobid + simid + "_anneal.csv"

		# establish that the file exists
		if not os.path.exists(anneal_file):
			# if the path does not exist, break from the loop
			break

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
			break

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
	sim_sum_file = sim_dir + "anal/" + jobid + simid + "_sum.csv"
	df.to_csv(sim_sum_file, index = False)

	# plot the temperature profile of the simulation as a function of the 
	# simulation time and simulation events
	plot_temp_time_series(sim_dir + "anal/" + jobid + simid + "_temptime.png",\
		df["time"].tolist(), df["temp"].tolist())

	# parse the results for each order parameter / fluctuation, 
	# and the corresponding temperature that they were calculated at

	# plot the current temperature of the simulation and the assign temperature
	# according to the number of steps that the simulation has taken / current
	# simuation iteration

	## TODO :: plot properties and fluctuations for all properties (make dict?)
	## TODO :: return most recent point in data series for sim update file
	return simid, jobid, prop_dict


## ARGUMENTS
# path to directory containing simulation files
anal_dir = sys.argv[1]


## SCRIPT
## create data frame which stores results for the simulation
df_results = pd.DataFrame()
i = 0 # used to count the number of rows in the data frame

##  determine the simulation parameters based on the directory hirearchy
# variable that contains the current operating directory
curr_dir = anal_dir

# the first directory is the number fraction of achirality particles
# determine the simulation parameters according to the directory hirerarchy
achai_params = get_dir_params(curr_dir, "a")

# loop through each achirality directory, determine next set of parameters
for achai_val in achai_params:

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
			if verbose:
				print("Summarizing directory no. {:d} ({:s})".format(i, curr_dir))

			# compile the current results of the simulation, return sim infor
			simid, jobid, prop_dict = update_simulation_results(curr_dir)

			# create dictionary containing simulation parameters, add to dataframe
			sim_dict = {'jobid': jobid, 'simid': simid, 'achai': achai_val, \
				'field': field_val, 'density': density_val}
			sim_dict = sim_dict | prop_dict
			df_results = pd.concat([df_results, pd.DataFrame(sim_dict, index = [i])])

			# increment the number of rows in the data frame
			i += 1

# using the simulation directories, create phase diagrams for the following conditions


# print the results as a csv
# create summary directories file
if not os.path.exists(anal_dir + "summary/"):
	os.mkdir(anal_dir + "summary/")
# write the sim status file to the summary directory
df_results.to_csv(anal_dir+ "summary/status.csv", index = False)