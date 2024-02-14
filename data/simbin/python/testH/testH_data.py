# filename :: testH_data.py
# author :: Matthew Dorsey (@sunprancekid)
# date :: 2023-08-06
# purpuse :: program that collects data and analyzes data
#			 from testH simulations

import sys, os
import math
import pandas as pd 
# used for generating graphs
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.cbook as cbook
import matplotlib as mpl
from statistics import mean
from matplotlib import cm
from matplotlib.colors import ListedColormap, LinearSegmentedColormap
from scipy.interpolate import RegularGridInterpolator


## PARAMETERS
# boolen that determines if the script should execture verbosely
verb = True
# boolean that determines if the script is in debug mode
debug = False
# implicit header that contains simulation parameters, 
# which are used to initialize testH simulations on the CHTCH node
testH_header = ['n','simid','rp', 'area_frac', 'events', 'cell', 'temp_set','vmag_set','ffrq_set']
# header used for simparams in anal file
simparam_header = "n,simid,rp,temp_set,vmag_set,ffrq_set"


## ARGUMENTS
# first arg: path to directory containing files
# path = sys.argv[1]


## FUNCTIONS
"""function for parsing data from simulation results. Returns
	data frame containing averaged simulation results."""
def parse_simulation_data(path='./', header = None, T_col = None, X_col = None, id_col = None, verbose = verb, properties = ['temp', 'mag']):
	# open file containing simulation parameters
	simparam_file = path + "testH.csv"
	# header used by testH_simparam : "n,simid,rp,area_frac,events,cell,temp,vmag,ffrq"
	simparam_df = pd.read_csv(simparam_file, header = None, names=header)
	# inform user
	if verbose:
		print (f"Parsing testH simulation data from {simparam_file} ..")

	# translate columns to unique lists
	simid = simparam_df[id_col].tolist()
	T_set = simparam_df[T_col].tolist()
	X_set = simparam_df[X_col].tolist()

	# get the header for the results files
	anneal_file = path + "anneal/" + simid[0] + "_anneal.csv"
	f = open(anneal_file, 'r')
	anneal_header = f.readlines()
	header = f"{id_col},{T_col},{X_col}," + anneal_header[0]
	f.close()

	# loop through all simulation parameters
	# parse sim data for file writing
	n_sims = len(simparam_df.index)
	success = [ "" for _ in range(n_sims)]
	failure = [ "" for _ in range(n_sims)]
	a = 0 # successful simdata counter
	b = 0 # failed simdata counter
	for i in range(0, (n_sims)):
		# determine the annealing file
		anneal_file = path + "anneal/" + simid[i] + "_anneal.csv"
		
		# check if the file exists, parse results
		simresults = f"{simid[i]},{T_set[i]},{X_set[i]}"
		isValid = True # used for debugging
		if os.path.exists(anneal_file):
			# open the file
			f = open(anneal_file, "r")
			info = f.readlines()
			# if the file has two lines
			if (len(info) > 1):
				simresults = f"{simresults}, {info[1]}" # get the second line
				if (len(simresults) < 10):
					isValid = False
			else:
				# if the second line in the file is not present, skip the entry
				isValid = False
		else:
			# if the file does not exist 
			isValid = False

		if isValid:
			success[a] = simresults
			if debug:
				print(f"{a} :: {i}, {anneal_file}")
			a += 1
		else:
			# the simulation failed or was unable to be accessed
			# write the entry to the failed save file
			failure[b] = simresults
			# iterate, skip the entry
			b += 1

	# report the successful and un-successful simulation data to the user
	if verbose:
		print(f"From {n_sims} simulations, {a} completed successfully and {b} failed.")

	## write successful and unsuccessful simulation data to analysis file
	anal_path = path + 'anal/'
	if not os.path.exists(anal_path):
		os.makedirs(anal_path)

	# open file, write header and data to file
	print(f"Parsing complete. Writing to file ..")
	anal_file = anal_path + "testH_success.csv"
	with open(anal_file, 'w') as f:
		# write header
		f.write(f"{header}\n")
		for i in range(a):
			f.write(f"{success[i]}\n".replace(" ", ""))
	f.close()

	fail_file = anal_path + "testH_fail.csv"
	with open(fail_file, 'w') as f:
		# write header
		f.write(f"{simparam_header}\n")
		for i in range(b):
			f.write(f"{failure[i]}\n".replace(" ", ""))
	f.close()

	## average results for unique combinations of the desired properties
	# create a data frame that contains the successful data
	df = pd.read_csv(anal_path + "testH_success.csv")
	result_header = f"{T_col},{X_col}"
	for p in properties:
		result_header = result_header + f",{p}"
	results = []
	for t in df[T_col].unique().tolist():
		for x in df[X_col].unique().tolist():
			result_string = f"{t},{x}"
			result_df = df.loc[(df[T_col] == t) & (df[X_col] == x)]
			for p in properties:
				result_string = result_string + ",{:.3f}".format(result_df[p].mean())
			results.append(result_string)

	# write the results to file
	results_file = anal_path + "testH_anal.csv"
	with open(results_file, 'w') as f:
		# write header
		f.write(f"{result_header}\n")
		for i in range(len(results)):
			f.write(f"{results[i]}\n".replace(" ", ""))
	f.close()

	# return a dataframe containing the averaged results to the user
	return pd.read_csv(results_file)

""" function that takes data from testH simulations,
	and parses the values that correspond to one constant temperature
	set of simulations """
def parse_conT_data (conT_path, conT_val):

	# open the simulation parameter data
	simparam_file = path + "testH.csv"
	if not os.path.exists(simparam_file):
		print("\nPath does not exist: " + simparam_file)
		print("Exiting program .. \n")
		exit()
	simparam_data = pd.read_csv(simparam_file, dtype = str, names=testH_header, low_memory = False)

	# identify all data matching the constant temperature value
	conT_data = simparam_data.loc[(simparam_data['temp_set'] == str(conT_val)) & \
		(simparam_data['rp'] == ("1"))]
	simid_conT_list = conT_data['simid'].unique().tolist()
	temp_set_conT_list = conT_data['temp_set'].tolist() # temperature set point
	ffrq_set_conT_list = conT_data['ffrq_set'].tolist() # frequency of field collisions
	vmag_set_conT_list = conT_data['vmag_set'].tolist() # magnitude of velocity 


	## process data from anal file, write to file
	# open csv with pandas
	analfile = path + "testH_anal.csv"
	if not os.path.exists(analfile):
		print("\nPath does not exist: " + analfile)
		print("Exiting program ..\n")
		exit()
	data = pd.read_csv(analfile, dtype = str, low_memory = False)
	if verb:
		print("\nReading from: ", analfile, " (total data points = ", len(data), ")")
		#print(list(data))
		#print(f"{data.dtypes}")
		#print(f"{data}")

	# initialize arrays for file writing
	n_sims = len(simid_conT_list) # number of unique simulations at conT
	string_array = ["" for x in range(n_sims)] # array contains results in string format
	if verb:
		print(str(n_sims) + " unique simulations were performed at a temperature set point of " + str(conT_val) + ".")
		print("Averaging data .. ")

	# loop through all simulations performed at constant temperature value
	for i in range(0, (n_sims)):
		# identify the simid associated with the iteration, data associated with simid
		simid = simid_conT_list[i]
		sim_rep = data.loc[data['simid'] == simid]

		# average, store temperature, nematic values
		temp_avg = sim_rep[' temp'].astype(float).mean()
		nem_avg = sim_rep[' nematic'].astype(float).mean()
		if verb and debug:
			print("{:06d} :: ".format(i) + str(simid) + " :: average temperature = {:.3f}, average nematic OP = {:.3f}".format(temp_avg, nem_avg))

		string_array[i] = "{:06d},{:s},{:s},{:s},{:s},{:f},{:f}".format(i,simid,temp_set_conT_list[i], \
			vmag_set_conT_list[i],ffrq_set_conT_list[i],temp_avg,nem_avg)


	## write data to file
	conT_format = "{:03d}".format(int(float(conT_val) * 100))
	save_dir = path + "anal/conT/"
	save_file = "testH_conT_" + conT_format + ".csv"
	if verb:
		print("Saving conT data to " + save_dir + save_file + ".")

	# check path, create directory if it does not exist
	if not os.path.exists(save_dir):
		os.makedirs(save_dir)

	# open file, write header and string array
	file = save_dir + save_file
	header = "n,simid,temp_set,vmag_set,ffrq_set" + ",temp,nem"
	with open(file, 'w') as f:
		# write header
		f.write(f"{header}\n")
		for l in string_array:
			f.write(f"{l}\n")

""" function that generates graphs for visualizing results from
	testH simulations performed at one temperature. """
def gen_conT_graph (conT_path, conT_val):
	## pull data from file containing constant temperature data
	# find file
	conT_format = "{:03d}".format(int(float(conT_val) * 100))
	save_file = "testH_conT_" + conT_format + ".csv"
	save_dir = path + "anal/conT/"
	file = save_dir + save_file
	if not os.path.isfile(file):
		# if the save file does not exist
		# inform the user and exit the program
		print("\n" + file + " does not exist.")
		print("Exiting program .. ")
		exit()

	# pull data
	data = pd.read_csv(file, low_memory = False)
	temp_set = data['temp_set'].sort_values().unique().tolist()
	ffrq_set = data['ffrq_set'].sort_values().unique().tolist()
	vmag_set = data['vmag_set'].sort_values().unique().tolist()
	temp_val = data['temp'].sort_values().unique().tolist()
	nem_val = data['nem'].sort_values().unique().tolist()
	if verb and debug:
		print("\nPLOTTING :: Field Frequency (X) vs. Velocity Magnitude (Y)")
		#print(list(data))
		#print(f"{data.dtypes}")
		#print(f"{data}")

	# match experimental values with results
	# generate meshgrid
	X_FFRQ, Y_VMAG = np.meshgrid(ffrq_set, vmag_set, indexing='ij')

	# assign temperatre and nematic OP values
	# loop through all combinations
	TEMP = np.zeros_like(X_FFRQ, dtype = float)
	NEM = np.zeros_like(Y_VMAG, dtype = float)
	for x in range(len(ffrq_set)):
		for y in range(len(vmag_set)):
			# get value
			val = data.loc[(data['ffrq_set'] == ffrq_set[x]) & \
					 	(data['vmag_set'] == vmag_set[y])]
			TEMP[x,y] = val['temp'].mean()
			NEM[x,y] = val['nem'].mean()
			if debug:
				# print ("FFRQ: {} / {}  VMAG: {} / {}" \
				# 	.format(ffrq_set[x],X_FFRQ[y,x],vmag_set[y],\
				# 		Y_VMAG[y,x]))
				print ("VAL: temp ({}) nem ({}) X: ({} / {})  Y: ({} / {})" \
					.format(TEMP[x,y], NEM[x,y], x,len(ffrq_set) - 1,y,len(vmag_set) - 1))


	## generate pcolor plot of temperature and 
	## nematic order parameter values

	# generate custom color map for temperature data
	# find the where the temperature set point lies
	# between the min and max temp values
	conT_scale = (float(conT_val) - np.nanmin(TEMP)) / (np.nanmax(TEMP) - np.nanmin(TEMP))
	cmp_pts = 128*2
	bottom_cmp_pts = math.floor(float(cmp_pts) * conT_scale)
	top_cmp_pts = cmp_pts - bottom_cmp_pts
	# scale color map so merge between two colormap 
	# arrays is located at the temperature set point
	tempcolor_top = mpl.colormaps['Oranges'].resampled(128)
	tempcolor_bottom = mpl.colormaps['Blues_r'].resampled(128)
	newcolors = np.vstack((tempcolor_bottom(np.linspace(0, 1, bottom_cmp_pts)),
	                       tempcolor_top(np.linspace(0, 1, top_cmp_pts))))
	tempcmp = ListedColormap(newcolors, name='OrangeBlue')

	# generate custom axis for v_mag
	vmag_min = min(vmag_set)
	vmag_max = max(vmag_set)
	vmag_mid = math.sqrt(2.*float(conT_val)) # avg of 2D MB-dist
	vmag_1qtr = (vmag_min + vmag_mid) / 2.
	vmag_3qtr = (vmag_mid + vmag_max) / 2.
	vmag_ticks = [vmag_min, vmag_1qtr, vmag_mid, vmag_3qtr, vmag_max]
	vmag_ticklabels = ["{:.2f}".format(vmag_min), \
		"{:.2f}".format(vmag_1qtr), r"$\sqrt{2*T_{set}}$", \
		"{:.2f}".format(vmag_3qtr), "{:.2f}".format(vmag_max)]

	# generate color plots
	fig, ax = plt.subplots(2, 1, constrained_layout=True)

	pcm = ax[0].pcolormesh(X_FFRQ, Y_VMAG, TEMP, cmap=tempcmp)
	fig.colorbar(pcm, ax=ax[0], extend='max', label='System Temperature')
	ax[0].set_yticks(vmag_ticks)
	ax[0].set_yticklabels(vmag_ticklabels)
	ax[0].set_xlabel("$f_{field}$")
	ax[0].set_ylabel("$v_{mag}$")
	pcm = ax[1].pcolor(X_FFRQ, Y_VMAG, NEM, cmap='Greens', vmax=1.)
	fig.colorbar(pcm, ax=ax[1], extend='max',label='Nematic Order Parameter')
	ax[1].set_yticks(vmag_ticks)
	ax[1].set_yticklabels(vmag_ticklabels)
	ax[1].set_xlabel("$f_{field}$")
	ax[1].set_ylabel("$v_{mag}$")

	# save plot
	fig.suptitle("Simulation Data for Dipoles Rods Under the Influence of \na Stochastic External Field ($T_{{set}}$ = {:s})".format(str(conT_val)))
	fig_name = "testH_conT_" + conT_format + "_pcolor.png"
	plt.savefig(save_dir + fig_name, dpi = 600)

## SCRIPT
if __name__ == '__main__':
	# parse simulation data
	parse_simulation_data(path)
	# parse the constantT data
	parse_conT_data(path, 0.25)
	# generate graph
	gen_conT_graph(path, 0.25)
