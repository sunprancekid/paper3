# Matthew A. Dorsey
# Chemical Engineering - NCSU
# 2024.02.20
# program for updating and analyzing conH simulations of dipolar suqares

## PACKAGES
import sys, os
from simbin.python.conH.update import update_simulation_results
from simbin.python.conH.anal import ground_state_analysis
from simbin.python.conH.anal import ground_state_magnetic_distribution
from simbin.python.fig.highlight_plot import gen_highlight_plot
from simbin.python.fig.distribution_plot import gen_dist_plot
import numpy as np
import pandas as pd

## PARAMETERS
# execute script verbosely
verbose = True
# file containing simulation parameters
simparm_file = './conH/squ2c32/conH_squ2c32.csv'

## FUNCTIONS
# method that loads the simulation parameters associated with a bath of jobs
# mathod returns a list of conH parameter sets
def load_conH_parms(parm_path):
	# create a data frame that contains the conH simulation parameters for the jobs
	df_simparms = pd.read_csv(parm_path)
	# get the number of parameter sets in the file, create an array that will contain
	# the simulation parameters
	num_parms = len(df_simparms.index)
	conH_parms = []
	# print(f"There are {len(df_simparms.index)} in the parameter set ({parm_path}).")

	# loop through set unique set of simulation parameters
	for index, row in df_simparms.iterrows():
		# load the parameters, initialize the conH_param object, append to the list
		parm = conH_simparm(row['jobid'], 
			# row['annealid'],
			row['simid'],
			row['path'],
			row['XA'],
			row['H'],
			row['ETA'],
			row['RP'])
		conH_parms.append(parm)

	return conH_parms

## CLASS
# class for simulation parameters for conH jobs
class conH_simparm(object):
	""" initialization for conH_simparam object. """ 
	def __init__(self, jobid, simid, path, xa, h, eta, rp):
		# super(conH_simparam, self).__init__()
		self.jobid = jobid # string containing id associated with job
		self.simid = simid # string containing id associated with simulation parameters
		self.path = path # path to simulation from main directory
		self.XA = xa # double / float describing the number fraction of a-chirality
		#	squares present during the simulation
		self.H = h # double / float describing the external field strength of the simulation
		self.ETA = eta # double / float describing the area fraction of the simulation
		self.RP = rp # integer describing the replicate associated with the simulation

	""" method for printing the state of the object. """
	def info(self):
		return vars(self)

## ARGUMENTS
# if update key word is located in script arguments
update = 'update' in sys.argv
# if analysis key word is located in script arguments
anal = 'anal' in sys.argv
# if distributions key word is located in script arguments
test_dist = 'test_dist' in sys.argv

## SCRIPT
# load the job parameters
job_parms = load_conH_parms(simparm_file) # load simulation parameters from file

# perform update and analysis
if update:
	update_simulation_results(job_parms, savedir = './conH/squ2c32/summary/', verbose = True)

if anal:
	## BRAIN STORMING
	# e.g. load ground state properties (ignore simulation data above certain temp, avg replicates)
	## TODO :: transition inflection point calculations to CHTC
	# e.g. parse transition temperatures (calculate if the files do not exist)

	# load simulation parameteres
	# job_parms = load_conH_parms(simparm_file)

	# # load ground state
	# ground_state_analysis(job_parms, max_temp = 0.6, xa = 0.5)

	# load summary file as df
	df = pd.read_csv('./conH/squ2c32/summary/status.csv')

	# loop through all items in list
	# normalize the number of clusters as the average cluster size
	# for index, row in df.iterrows():
	# 	df.at[index, 'nclust'] = math.log10(df.at[index, 'nclust'])
		# df.at[index, 'nclust'] = 1024 / df.at[index, 'nclust']
		# print(df.at[index, 'nclust'])
	# exit()


	for i in [0.5, 1.0]:
		# get masked df
		mask = (df['XA'] == i) & (df['temp'] < 0.6)

		# generate file names
		save_mag_file = "gs_mag_xa{:03d}".format(int(i * 100))
		save_clust_file = "gs_clust_xa{:03d}".format(int(i  * 100))


		# plot the ground state average cluster size of system against
		# the external field strength for different densities
		gen_highlight_plot(
			df = df[mask],
			# file = TH_dir + 'anal/testH_anal.csv',
			y_col = 'nclust',
			x_col = 'H',
			iso_col = 'ETA',
			save = './conH/squ2c32/summary/' + save_clust_file,
			# iso_vals = [float("{:.2f}".format(x)) for x in np.linspace(0.2, 1.0, 1 * 8 + 1, endpoint = True)],
			iso_vals = [0.05, 0.15, 0.30, 0.50, 0.55, 0.60],
			# y_major_ticks = [0., 0.2, 0.4, 0.6, 0.8, 1.0],
			# y_minor_ticks = [0.1, 0.3, 0.5, 0.7, 0.9],
			max_y = 300,
			min_y = 1,
			highlight = [0.05, 0.15, 0.30, 0.50, 0.55, 0.60],
			highlight_colormap = 'flare',
			highlight_label = '$\phi$ = {:.2f}',
			# highlight_label_order = 'max_value',
			X_label = 'External Field Strength ($H^{*}_{set}$)',
			Y_label = 'Number of Clusters')

		# plot the ground state magnetism against the system 
		# against the external field strength for different densities
		gen_highlight_plot(
			df = df[mask],
			# file = TH_dir + 'anal/testH_anal.csv',
			y_col = 'mag',
			x_col = 'H',
			iso_col = 'ETA',
			save = './conH/squ2c32/summary/' + save_mag_file,
			# iso_vals = [float("{:.2f}".format(x)) for x in np.linspace(0.2, 1.0, 1 * 8 + 1, endpoint = True)],
			iso_vals = [0.05, 0.15, 0.30, 0.50, 0.55, 0.60],
			y_major_ticks = [0., 0.2, 0.4, 0.6, 0.8, 1.0],
			y_minor_ticks = [0.1, 0.3, 0.5, 0.7, 0.9],
			highlight = [0.05, 0.15, 0.30, 0.50, 0.55, 0.60],
			highlight_colormap = 'flare',
			highlight_label = '$\phi$ = {:.2f}',
			# highlight_label_order = 'max_value',
			X_label = 'External Field Strength ($H^{*}_{set}$)',
			Y_label = 'System Magnetism ($M$)')


if test_dist:
	# get ground state distributions
	for x in [0.5, 1.0]:
		for h in [0.0, 0.2, 0.4]:
			for d in [0.15, 0.30, 0.45]:
				ground_state_magnetic_distribution(job_parms, XA = x, H = h, ETA = d, save_dir = './conH/squ2c32/summary/')