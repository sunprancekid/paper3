# Matthew A. Dorsey
# Chemical Engineering - NCSU
# 2024.02.20
# methods that abstract the generation of distribution plots

## PACKAGES
import sys, os, math
import pandas as pd 
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.cbook as cbook
import matplotlib as mpl
import matplotlib.ticker as tck
import seaborn as sns
from scipy.optimize import minimize
from scipy.stats import vonmises
from basic_units import cos, degrees, radians

## METHODS
# given a set of set points, plots the expected magnetization M according
# to the ratio of magnetic to thermal energy (X)
#
# X :: array containing a series of points represnted 
# 		the ratio of magnetic to thermal energy, calculated as
#		meu * field strength / boltzman constant * temperature
def get_magnetic_expectation(X):
	# fineness of mesh used to calculate expected magnetization
	# from von Mises distribution
	n_VM_pts = 500
	# assumes direction of external field, in radians
	field_dir = 0. * np.pi # direction is x_hat = 0, y_hat = 1
	# empty array containing expected magnetism
	M = []
	for i in range(len(X)):
		# calculate the expected von Mises distribution
		if X[i] <= 0.001: 
			X[i] = 0.001
		VM_mesh = np.linspace(-np.pi, np.pi, n_VM_pts)
		VM_pdf = vonmises.pdf(field_dir, X[i], VM_mesh) # expcted distribution
		# get the average of the expected distribution
		A = 0.
		A_norm = 0.
		delta = VM_mesh[1] - VM_mesh[0] # size of mesh step, used to calculate area
		for j in range(len(VM_mesh)):
			A += math.cos(VM_mesh[j]) * VM_pdf[j] * delta
			A_norm += VM_pdf[j] * delta
		M.append(A / A_norm)

	return M # return array of same size, which is the average 
	# of the von Mises distribution for each point in the array X

# generate distribution plot and save to specified location
def gen_dist_plot(file = None, x_col = None, y_col = None,
	plot_expectation = False, X = None, expectation_label = None,
	# generate distribution in circular format
	circular_bool = False,
	# figure properties
	save = None, # location to save figure to
	title = None, # graph title
	subtitle = None, # graph subtitle
	X_label = None, # x-axis label
	Y_label = None, # y_axis label
	fontsize = None, # plot fontsize
	max_y = None, # maximum y-axis value
	min_y = None, # minimum y-axis value
	max_x = None, # maximum x-axis value
	min_x = None, # minimum x-axis value
	bar_color = None,
	bar_label = None,
	x_major_ticks = None,
	x_major_ticks_labels = None,
	x_minor_ticks = None,
	y_major_ticks = None,
	y_major_ticks_labels = None,
	y_minor_ticks = None):
	
	## TODO :: set figure / program defaults
	default_fig_fontsize = 14
	if fontsize is None:
		fontsize = default_fig_fontsize

	default_bar_color = 'tab:oragne'
	if bar_color is None:
		bar_color = default_bar_color
	## TODO :: load several files, average distributions

	# load the file as a data frame
	dist = pd.read_csv(file)

	# parse data from file
	x_dist = dist['theta'].tolist()
	y_dist = dist['align'].tolist()
	n_bins = len(x_dist)

	# get figure max and min axis values
	if min_x is None:
		min_x = min(x_dist)
	if max_x is None:
		max_x = max(x_dist)
	if min_y is None:
		min_y = min(y_dist)
	if max_y is None:
		max_y = max(y_dist)
	elif max_y < max(y_dist):
		max_y = max(y_dist)

	# plot linear distribution
	if not circular_bool:
		fig, ax = plt.subplots()
		ax.spines[['right', 'top']].set_visible(False)
		ax.set_xlim(min_x, max_x)
		ax.set_ylim(min_y, max_y)
		if plot_expectation and X is not None:
			# establish the relative strength and orientation of the external field
			loc = 0.0 * np.pi  # HARD CODE: circular mean, direction of field
			if X <= 0.:
				X = 0.0001
			x_vm = np.linspace(-np.pi, np.pi, n_bins)
			y_vm = vonmises.pdf(loc, X, x_vm) # expcted distribution
			# add von mises dist to plot
			ax.plot(x_vm, y_vm, '--', linewidth = 2., \
				color = "black", label = expectation_label, xunits=radians)

		# plot the distribution
		bar_width = ((max(x_dist) - min(x_dist)) / n_bins) * 0.8
		ax.bar(x_dist, y_dist, facecolor = bar_color, edgecolor="black", \
			alpha=0.8, width = bar_width, label = bar_label) #, label = left_bar_label
		ax.tick_params(axis='both', which='major', labelsize=fontsize - 2) 
		ax.tick_params(axis='both', which='minor', labelsize=fontsize - 2) 
		# add ticks, if specified
		if x_major_ticks is not None:
			ax.set_xticks(x_major_ticks, minor=False)
		if x_major_ticks_labels is not None:
			ax.set_xticklabels(x_major_ticks_labels)
		if x_minor_ticks is not None:
			ax.set_xticks(x_minor_ticks, minor=True)
		if y_major_ticks is not None:
			ax.set_yticks(y_major_ticks, minor=False)
		if y_minor_ticks is not None:
			ax.set_yticks(y_minor_ticks, minor=True)
	else:
		# plot circular distribution in polar coordinates
		fig, ax = plt.subplots(subplot_kw={'projection': 'polar'})
		if plot_expectation is not None and X is not None:
			# establish the relative strength and orientation of the external field
			loc = 0.0 * np.pi  # HARD CODE: circular mean, direction of field
			if X <= 0.:
				X = 0.0001
			x_vm = np.linspace(-np.pi, np.pi, n_bins + 1)
			y_vm = vonmises.pdf(loc, X, x_vm) # expcted distribution
			# add von mises dist to plot
			ax.plot(x_vm, y_vm, '--', linewidth = 2., \
				color = "black", label = expectation_label, xunits=radians)

		# plot the distribution
		bar_width = ((max(x_dist) - min(x_dist)) / n_bins) * 0.8
		ax.bar(x_dist, y_dist, facecolor = 'tab:orange', edgecolor="black", \
			alpha=0.8, width = bar_width, label = 'Simulation Distribution') #, label = left_bar_label
		ax.set_rmax(max_y)
		ax.set_xlim(min_x, max_x)
		ax.set_rlabel_position(-90)
		# ax.grid(True)

	# add figure labels and titles
	if X_label is not None:
		plt.xlabel(X_label, fontsize=fontsize)
	if Y_label is not None:
		plt.ylabel(Y_label, fontsize=fontsize)
	if subtitle is not None:
		plt.title(subtitle, fontsize = fontsize)
	if title is not None:
		plt.suptitle(title, fontsize = fontsize)
	ax.legend(prop={'size': fontsize * 0.75})
	plt.savefig(save, dpi = 600, bbox_inches="tight") 
	plt.show()