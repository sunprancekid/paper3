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
from simbin.python.fig.distribution_plot import gen_dist_plot


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
	if not os.path.exists(gs_path):
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

# collect ground state for certain simulation conditions
# returns data frame containing simulation properties at conditions
def ground_state_analysis(simparm_df, max_temp = None, xa = None):
	print(simparm_df)
	exit()
	# use simulation parameters to grab ground state
	if xa is not None:
		pass
		# remove simulation parameters from data frame
		# that do not correspond to constant xa

def ground_state_magnetic_distribution (simparm, XA, H, ETA, RP = 0, show = True, save_dir = None, expectation = False):

	if save_dir is None:
		save_dir = ""

	# get the simulation parameters that match the constraints passed to the method
	for p in simparm:
		if p.XA == XA and p.H == H and p.ETA == ETA and p.RP == RP:
			# for the simulation that meets the constrains
			# load the analysis file
			anal_file = p.path + "/anal/" + p.jobid + p.simid + "_sum.csv"
			df = pd.read_csv(anal_file)
			# get the integer corresponding to the lowest temperature
			ann_id = "{:03d}".format(df['id'].max())
			# create the distirbution file
			dist_file = p.path + "/anneal/" + ann_id + "/" + p.jobid + p.simid + "_aligndist.csv"
			# determine the relevant quantities from the file name, labels, etc.
			temp = df.iloc[int(ann_id)]['temp']
			X = H / temp
			# create the distribution plot, save
			gen_dist_plot (file = dist_file,
				x_col = 'theta',
				y_col = 'align',
				# circular_bool = True,
				# figure settings
				save = save_dir + p.simid + '_GSaligndist.png',
				title = "Ground State Angular Distribution",
				subtitle = '$x_{{a}}$ = {:.2f}, $H^{{*}}$ = {:.2f}, $\phi$ = {:.2f}, $T^{{*}}$ = {:.2f}'.format(XA, H, ETA, temp),
				Y_label = 'Normalized Probability',
				X_label = '$\\theta$',
				min_y = 0.,
				max_y = 1.0,
				min_x = -np.pi,
				max_x = np.pi,
				bar_color = '#AFE1AF',
				bar_label = 'Simulation Distribution',
				# axis ticks and labels
				x_major_ticks = [float("{:.2f}".format(x)) for x in np.linspace(-np.pi, np.pi, 5, endpoint = True)],
				x_minor_ticks = [float("{:.2f}".format(x)) for x in np.linspace(-np.pi * 3 / 4, np.pi * 3 / 4, 4, endpoint = True)],
				x_major_ticks_labels = ['-$\pi$', '-$\pi$ / 2', '0', '$\pi$ / 2', '$\pi$'],
				y_major_ticks = [float("{:.2f}".format(x)) for x in np.linspace(0., 1., 6, endpoint = True)],
				y_minor_ticks = [float("{:.2f}".format(x)) for x in np.linspace(0.1, 0.9, 5, endpoint = True)],
				# add von mises expectation plots
				plot_expectation = expectation,
				X = X,
				expectation_label = '$f (\\theta, X)$')


## ARGUMENTS
# first argument: path to directory containing simulation files
# anal_dir = sys.argv[1]


# ## SCRIPT
# # load data frame which contains the simulation results
# sim_df = pd.read_csv(anal_dir + 'summary/status.csv')

# # calculate phase diagrams for conH annealing simulations
# calculate_phase_diagrams(anal_dir, sim_df, GSPD = True, AnPD = False)