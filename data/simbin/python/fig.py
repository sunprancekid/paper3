
# Matthew A. Dorsey
# Chemical Engineering - NSCU
# 2024.01.11
# use ground state magnetism data to make a decent figure
# for publication

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

## PARAMETERS
# print debugging statements to the CML
debug=False
# name of the file containing the ground state magnetism data
mag_data_file="conH_rod4c16_alignVAL.csv"
# name of the file containing the ground state magnetism inflection point data
inflect_data_file="conH_rod4c16_DHalignINFLECT.csv"
# name of file containing testH_TH dataset
TH_data_file = "../fig2/testH_TH.csv"
# global colors
pink="#E73F74"
orange="#E68310"
yellow="#F2B701"
limegreen="#80BA5A"
teal="#11A579"
blue="#3969AC"
purple="#7F3C8D"
# shades of grey
GREY10 = "#1a1a1a"
GREY30 = "#4d4d4d"
GREY40 = "#666666"
GREY50 = "#7f7f7f"
GREY60 = "#999999"
GREY75 = "#bfbfbf"
GREY91 = "#e8e8e8"
GREY98 = "#fafafa"

## FUNCTIONS
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

# parse gound state magnetism data from file, return
def load_ground_state_magnetism_dataframe(file, x_col = None, y_col = None, v_col = None):
	if file is None:
		print("File is none.")
		exit()

	# create data frame containing information stored in file
	mag_df = pd.read_csv(file)
	# create lists that contain the relevant information
	x = mag_df[x_col].tolist()
	y = mag_df[y_col].tolist()
	v = mag_df[v_col].tolist()
	# return datafram containing columns
	return pd.DataFrame({x_col: x, y_col: y, v_col: v})

# TODO :: move this function to be called from within the color plot function
# parse ground state magnetism data from file passed as argument to function
def load_ground_state_magnetism_mesh(file):
	# create data frame containing information stored in file
	mag_df = pd.read_csv(file)
	# create lists that contain the relevant information
	den_sp = mag_df['den'].sort_values().unique().tolist()
	field_sp = mag_df['field'].sort_values().unique().tolist()
	mag_val = mag_df['val'].sort_values().unique().tolist()

	# generate meshgrid for the dependent variables
	X_FIELD, Y_DEN = np.meshgrid(field_sp, den_sp, indexing='ij')

	# create a mesh corresponding to the ground state magnetism
	MAG = np.zeros_like(X_FIELD, dtype = float)
	for x in range(len(field_sp)):
		for y in range(len(den_sp)):
			# get value
			val = mag_df.loc[(mag_df['field'] == field_sp[x]) & \
					 	(mag_df['den'] == den_sp[y])]
			MAG[x,y] = val['val'].mean()
			if debug:
				print ("VAL :: @ FIELD of {:.2f}  ({:02d} / {:02d}) & DENSITY of {:.2f} ({:02d} / {:02d}), MAG is {:.3f}" \
					.format(X_FIELD[x,y],x,len(field_sp) - 1,Y_DEN[x,y],y,len(den_sp) - 1,MAG[x,y]))

	return X_FIELD, Y_DEN, MAG

# parse inflection points for ground state magnetism data from file 
# passed as argument to function
def load_inflection_point_data(file):
	# load file as data frame
	inflect_df = pd.read_csv(file)
	# create lists for the inflection point and the density that it occurs at
	Y = inflect_df['den'].tolist()
	INF = inflect_df['field'].tolist()
	# return to user
	return Y, INF

# function that gets data for highlighted lines
def get_highlights (hvals, max_hvals, scale_constant, colormap, label_order, action_constant = None):

	# max_hvals :: maximum heights for order parameter high-lights
	# scale_constant :: constant associated with maximum length of labels

	# list of high-lighter actions
	action_key = ['label_colors', 'label_heights']

	# check action constant
	if action_constant is None:
		print('get_highlights :: must specify action constant')
		exit()
	else:
		# check the action constant passed to the method
		if action_constant not in action_key:
			print(f'get_highlights :: action_constant ({action_constant}) not in action_key.')
			exit()

	if action_constant == 'label_colors':
		# get the colormap
		if colormap in matplotlib.colormaps:
			cmap = matplotlib.colormaps[colormap]
			cmap_vals = np.linspace(0.05,0.95,len(hvals), endpoint = True)
			colormap = []
			for i in cmap_vals:
				colormap.append(cmap(i))
			return colormap
		else:
			print(f"Unable to find colormap {colormap}")
			exit()
	elif action_constant == 'label_heights':
		# create ordered list of height indicies 
		if label_order == 'height':
			ol = [] # list of pointers ordered by height
			vals = max_hvals.copy()
			for i in range(len(hvals)):
				# get index of largest item in list
				ol.append(vals.index(max(vals)))
				# remove the item from the list
				vals[ol[i]] = min(vals) - 1
		elif label_order == 'max_value':
			ol = [] # list of pointers ordered by their value
			vals = hvals.copy()
			for i in range(len(hvals)):
				# get index of largest item in list
				ol.append(vals.index(max(vals)))
				# remove the item from the list
				vals[ol[i]] = min(vals) - 1
		elif label_order == 'min_value':
			ol = [] # list of pointers ordered by their value
			vals = hvals.copy()
			for i in range(len(hvals)):
				# get index of largest item in list
				ol.append(vals.index(min(vals)))
				# remove the item from the list
				vals[ol[i]] = max(vals) + 1
		else:
			# TODO add option for sorting my min_val
			print(f"get_highlights :: label_order option {label_order} not specified.")
			exit()

		# create an evenly spaced list
		# label_distance = len(hvals) * (scale_constant / 200)
		label_distance = max(max_hvals) - min(max_hvals)
		label_length = label_distance / (len(hvals) - 1) #* scale_constant
		# label_length = scale_constant / 200
		# 1.0 - (1.0 / (len(hvals) * 2.)) / (len(hvals) - 1)
		# label_start = (1.0 - (label_length / 2.)) - (3. * label_length)
		label_start = max(max_hvals)
		# label_start = 1.0
		for i in range(len(hvals)):
			max_hvals[ol[i]] = label_start - (float(i) * label_length)

		# check if order labels are overlapping
		label_length = max(max_hvals) / (scale_constant * 0.8)
		for i in range(len(max_hvals)):
			if i == 0:
				# skip the first entry
				continue
			# check if the label center is higher than the max 
			# distance of seperation
			if max_hvals[ol[i]] > (max_hvals[ol[i-1]] - label_length):
				max_hvals[ol[i]] = max_hvals[ol[i-1]] - label_length

		# assign heights that are equally spaced from one another
		# return label heights and colors
		return max_hvals
	else:
		print(f"get_highlights :: specify action for action_constant ({action_constant})")
		exit()

# use seaborn to create figures
def gen_highlight_plot(
		file = None, y_col = None, x_col = None, iso_col = None, # data for seabornplot
		expect_file = None, x_exp_col = None, y_exp_col = None,# conditions underwhich the inflection take place, corresponds to Y potion of 2D mesh
		# figure properties (title, etc.)
		save =  None,
		title = None, # graph title
		X_label = None, # x-axis label
		Y_label = None, # y_axis label
		fontsize = None, # plot fontsize
		max_y = None, # maximum y-axis value
		min_y = None, # minimum y-axis value
		max_x = None, # maximum x-axis value
		min_x = None, # minimum x-axis value
		x_major_ticks = None,
		x_minor_ticks = None,
		y_major_ticks = None,
		y_minor_ticks = None,
		# specific to highlighting values
		iso_vals = None, # list of values that will be isolated from file
		highlight = None, # list of iso_vals that should be highlighted
		highlight_colormap = None, # color map used to highlight lines
		highlight_label = None, # string used for format labels
		highlight_label_order = None,
		# expectation values
		plot_expectation = False
		):

	# function constants
	# prcentage constant used to scale axis by
	pad = 0.05
	# function defaults, used if value isn't specified in method call
	default_fig_save = 'fig4.png'
	default_fig_title = None
	default_fig_subtitle = ''
	default_fig_colormap = 'flare'
	default_fig_colorbar = None
	default_fig_fontsize = 14
	default_highlight_label = "{:.2f}"
	default_highlight_label_order = 'height'

	# assign figure properties
	if save is None:
		# assign default figure save path
		save = default_fig_save

	if title is None:
		# assign default figure title
		title = default_fig_title

	if fontsize is None:
		fontsize = default_fig_fontsize

	if X_label is None:
		X_label = x_col

	if Y_label is None:
		Y_label = v_col

	if highlight_label is None:
		highlight_label = default_highlight_label

	if highlight_label_order is None:
		highlight_label_order = default_highlight_label_order
		
	# TODO check that the information for the data frame has been loaded properly
	# load the data frame from the file
	df = load_ground_state_magnetism_dataframe(file, x_col, iso_col, y_col)

	# determine the information that will be plotted on the seaborn plot
	## TODO check that highlights are in isolated values
	if iso_vals is None:
		iso_vals = df[iso_col].unique().tolist()

	# initialize arrays that contain the information that will be plotted
	x = []
	y = []
	iso = []
	h = []
	for i in iso_vals:
		# get the y_values that correspond to the index
		iso_df = df.loc[df[iso_col] == i]
		for j in iso_df.index:
			# append the values in the data frame to the lists
			x.append(iso_df[x_col][j])
			y.append(iso_df[y_col][j])
			iso.append(iso_df[iso_col][j])
			if highlight is not None:
				if i in highlight:
					h.append("h")
				else:
					h.append("o")
			else:
				h.append("o")

	# get minimum and maximum values for plotting, pad values
	if min_x is None:
		min_x = min(x)
	if max_x is None:
		max_x = max(x) * (1. + pad)
	if min_y is None:
		min_y = min(y)
	if max_y is None:
		max_y = max(y)

	dy = max_y - min_y
	min_y = min_y - dy * pad
	max_y = max_y + dy * pad

	# plot each line that is not highlighted
	# remove the top and right axis lines
	# set the axis lengths
	fig, ax = plt.subplots()
	ax.set_xlim(min_x, max_x)
	ax.set_ylim(min_y, max_y)
	ax.spines[['right', 'top']].set_visible(False)
	df = pd.DataFrame({x_col: x, y_col: y, iso_col: iso, 'highlight': h})
	df_other = df[df['highlight'] == 'o']
	df_highlight = df[df['highlight'] == 'h']
	for j in df_other[iso_col].unique():
	    data = df[df[iso_col] == j]
	    ax.plot(x_col, y_col, c=GREY50, lw=1.2, alpha=0.5, data=data)

	if highlight is not None:
		y_pos = [] # list containing the final hight of each highligted line
		colors = get_highlights (highlight, y_pos, fontsize, highlight_colormap, highlight_label_order, action_constant='label_colors')
		for i, j in enumerate(df_highlight[iso_col].unique()):
		    data = df[df[iso_col] == j]
		    color = colors[i]
		    ax.plot(x_col, y_col, color=color, lw=1.8, data=data)
		    # get the final height of the line
		    y_pos.append(data[y_col].iloc[-1])

		ypos = get_highlights (highlight, y_pos, fontsize, highlight_colormap, highlight_label_order, action_constant='label_heights')
		# add labels to the highlighted lines
		for i, j in enumerate(df_highlight[iso_col].unique()):
			data = df[(df[iso_col] == j) & (df[x_col] == max(x))]
			color = colors[i]
			
			# assigned density
			text = highlight_label.format(j)

			# Vertical start of label line
			y_start = data[y_col].values[0]
			# Vertical end of label line
			y_end = y_pos[i]

		    # Add line based on three points
			# parameters that scale the axis label lines
			x_start = max(x)
			x_end = max(x) * (1. + pad)
			PAD = 0.
			ax.plot(
				[x_start, (x_start + x_end - PAD) / 2 , x_end - PAD], 
				[y_start, y_end, y_end], 
				color=color, 
				alpha=0.5, 
				ls="dashed"
			)

		    # Add label text
			ax.text(
				x_end, 
				y_end, 
				text, 
				color=color, 
				fontsize=fontsize, 
				weight="bold", 
				# fontfamily="Montserrat", 
				va="center"
			)

	# plot expectation magnestism, if called
	if plot_expectation:
		# TODO how to avoid hard coding this
		# get all of the expectation values for all unique X
		X = df[x_col].unique().tolist()
		M = get_magnetic_expectation(X)
		# plot the line
		ax.plot(X, M, '--', color='black', lw=1.8)
		# label the line
		# Vertical start and end of label line
		y_start = max(M)
		label_length = (max(y_pos) - min(y_pos)) / (len(y_pos) - 1)
		y_end = label_length + max(y_pos)
		# horizontal start and end of label line
		x_start = max(X)
		x_end = max(X) * (1. + pad)
		PAD = 0.
		ax.plot(
			[x_start, (x_start + x_end - PAD) / 2 , x_end - PAD], 
			[y_start, y_end, y_end], 
			color='black', 
			alpha=0.5, 
			ls="dashed"
		)

		# Add label text
		ax.text(
			x_end, 
			y_end, 
			'$ \hat{M}$', 
			color='black', 
			fontsize=fontsize, 
			weight="bold", 
			# fontfamily="Montserrat", 
			va="center"
		)

	# add figure labels	
	if X_label is not None:
		plt.xlabel(X_label, fontsize=fontsize)
	if Y_label is not None:
		plt.ylabel(Y_label, fontsize=fontsize)
	if title is not None:
		plt.title(title, fontsize = fontsize)
	# figure axes
	# ax = plt.gca()
	ax.tick_params(axis='both', which='major', labelsize=fontsize) 
	ax.tick_params(axis='both', which='minor', labelsize=fontsize) 
	# add ticks, if specified
	if x_major_ticks is not None:
		ax.set_xticks(x_major_ticks, minor=False)
	if x_minor_ticks is not None:
		ax.set_xticks(x_minor_ticks, minor=True)
	if y_major_ticks is not None:
		ax.set_yticks(y_major_ticks, minor=False)
	if y_minor_ticks is not None:
		ax.set_yticks(y_minor_ticks, minor=True)
	# plt.xticks(fontsize = fontsize)
	plt.savefig(save, dpi = 600, bbox_inches="tight") # , bbox_inches="tight"
	plt.show()

# use contour to create figures
def gen_contourplot(VAL, X_MESH, Y_MESH, # figure mesh data
		INF = None, X_INF = None, Y_INF = None,  # data for inflection point overlay
		# figure properties (title, etc.)
		save =  None,
		title = None,
		colormap = None,
		colorbar = None,
		fontsize = None,
		contours = None):
	
	# default function parameters
	default_fig_save = 'fig4.png'
	default_fig_title = None
	default_fig_subtitle = ''
	default_fig_colormap = 'cool'
	default_fig_colorbar = None
	default_fig_fontsize = 16

	# assign figure properties
	if save is None:
		# assign default figure save path
		save = default_fig_save

	if title is None:
		# assign default figure title
		title = default_fig_title

	if colormap is None:
		colormap = default_fig_colormap

	if colorbar is None:
		colorbar = default_figure_colorbar

	if fontsize is None:
		fontsize = default_fig_fontsize

	# plot the figure data 
	# f, ax = plt.subplots(1,2, sharex=True, sharey=True)
	if contours is not None:
		contours_plt_label = plt.contour(X_MESH, Y_MESH, VAL, [0.1, 0.3, 0.5, 0.7, 0.9], colors = 'black')
		contours_plt_label = plt.contour(X_MESH, Y_MESH, VAL, [0.2, 0.4, 0.6, 0.8], colors = 'black')
		plt.clabel(contours_plt_label, inline = True, fontsize = 10)
	pcm = plt.contourf(X_MESH, Y_MESH, VAL, 10, cmap = colormap, alpha = 0.9) # , cmap=tempcmp
	# pcm = plt.contourf(X_MESH, Y_MESH, VAL, cmap = colormap, alpha = 0.9) # , cmap=tempcmp
	# add color bar
	if colorbar is not None:
		cb = plt.colorbar(pcm, extend='max', ticks=[0, 0.2, 0.4, 0.6, 0.8, 1])
		cb.set_label(fontsize = fontsize, label=colorbar)
		# TODO function that automates linespace generation
	# figure labels
	plt.ylabel("External Field Strength ($H^{*}$)", fontsize = fontsize)
	plt.xlabel("Area Fraction ($\phi$)", fontsize = fontsize)
	if title is not None:
		plt.title(title, fontsize = fontsize)
	# figure axes
	ax = plt.gca()
	ax.tick_params(axis='both', which='major', labelsize=12) 
	ax.tick_params(axis='both', which='minor', labelsize=12) 
	ax.set_xticks([0.05, 0.15, 0.25, 0.35, 0.45, 0.55], minor=True)
	cb.ax.tick_params(labelsize=12)
	plt.yticks([0.0, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16], fontsize = 12)
	ax.set_yticks([0.1, 0.3, 0.5, 0.7, 0.9, 0.11, 0.13, 0.15], minor=True)
	# add the inflection point overlay
	if INF is not None:
		if Y_INF is not None:
			# use INF and Y_INF to find X_INF
			# x_inf = get_contour(INF, y = Y_INF, X_MESH = X_MESH, Y_MESH = Y_MESH)
			plt.plot(Y_INF, INF, '--or', label = 'Inflection Point')
			plt.legend(loc = 'upper left')
		elif X_INF is not None:
			# use INF and X_INF to find Y_INF
			pass
		else:
			print("Must specify axis.")
			exit(1)
	plt.savefig(save, dpi = 600, bbox_inches="tight") 
	plt.show()

## ARGUMENTS
# none

## BRAINSTORMING OBJECTS


## SCRIPT
if __name__ == '__main__':
	# TODO set file name dictionaries
	# mag_file_dict = 
	# files
	# name / path
	# important columns
	# load data
	# TODO move file load to figure functions
	X_V, Y_V, V = load_ground_state_magnetism_mesh(mag_data_file)
	Y_I, I = load_inflection_point_data(inflect_data_file)


	# TODO establish figure properties
	# 	- I should be able to give the same property object to both graph functions
	# figure properties
	# - list of options parameters 
	# - instructions for default values if they aren't specified

	# generate graphs
	if 'fig2' in sys.argv:
		gen_highlight_plot(
			file = TH_data_file,
			y_col = 'temp',
			x_col = 'field_set',
			iso_col = 'temp_set',
			save = '../fig2/testTH_temp.png',
			iso_vals = [float("{:.2f}".format(x)) for x in np.linspace(0.2, 1.4, 5 * 12 + 1, endpoint = True)],
			highlight = [0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4],
			highlight_colormap = 'crest',
			highlight_label = '$T_{{set}}$ = {:.2f}',
			X_label = 'External Field Strength ($H^{*}_{set}$)',
			Y_label = 'Measured System Temperature ($T$)')

		gen_highlight_plot(
			file = TH_data_file,
			y_col = 'allign',
			x_col = 'field_set',
			iso_col = 'temp_set',
			save = '../fig2/testTH_mag.png',
			max_y = 1.,
			iso_vals = [float("{:.2f}".format(x)) for x in np.linspace(0.2, 1.4, 5 * 12 + 1, endpoint = True)],
			highlight = [0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4],
			highlight_colormap = 'crest',
			highlight_label = '$T_{{set}}$ = {:.2f}',
			X_label = 'External Field Strength ($H^{*}_{set}$)',
			Y_label = 'Measured System Magnetism ($M$)')


	# - pass file dictionaries and figure settings to figure methods
	## TODO can i consolidate all of the data needed for this figure?
	if 'fig5' in sys.argv:
		## TODO pass file to method, load data internally
		gen_contourplot(
			VAL = V, # magnetism values that correspond to the 2D mesh
			X_MESH = Y_V, # x-portion of 2D mesh that contains field values
			Y_MESH = X_V, # y-portion of 2D mesh that contains density values
			INF = I, # inflection point values of the ground state magnetism
			Y_INF = Y_I, # conditions underwhich the inflection take place, corresponds to Y potion of 2D mesh
		  	# figure properties
			contours = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9],
			# title = 'Ground State Magnetic Phase Behavior',
			# contours = [0.2, 0.4, 0.6, 0.8],
			colormap = 'Greys',
			save = '../fig5/fig5_cplot.png', 
			colorbar = 'Magnetic Strength ($M$)'
			)

	# first sns graph
	if 'fig4' in sys.argv:

		# graph with specific highlights
		# [yellow, orange, pink, purple, teal, blue]
		gen_snsplot(
			file = mag_data_file,
			v_col = 'val', # label of column containing value data in mag data file
			x_col = 'field', # label of column containing x-axis data in mag data file
			y_col = 'den', # label of column containing y-axis data in mag data file
			# expect_file = 'testH_TH.csv', 
			# x_exp_col = 'field_set',
			# y_exp_col = 'allign',
			# figure properties
			save = 'fig4.png',
			fontsize = 14,
			# y_vals = [0.05, 0.15, 0.25, 0.35, 0.45, 0.55],
			# highlight = [0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.6],
			highlight = [0.05, 0.15, 0.30, 0.5, 0.55, 0.6],
			# title = 'Ground State Magnetism at Different Densities ($\phi$)',
			X_label = 'External Field Strength ($H^{*}$)',
			Y_label = 'System Net Magnetism ($M$)',
			# c_label = '$\phi$',
			colormap = 'Dark2'
			)
		exit()

		# make plots without highlights
		gen_snsplot(
			file = mag_data_file,
			v_col = 'val', # label of column containing value data in mag data file
			x_col = 'field', # label of column containing x-axis data in mag data file
			y_col = 'den', # label of column containing y-axis data in mag data file
			# expect_file = 'testH_TH.csv', 
			# x_exp_col = 'field_set',
			# y_exp_col = 'allign',
			# figure properties
			save = 'fig4_nohighlight.png',
			fontsize = 14,
			# y_vals = [0.05, 0.15, 0.25, 0.35, 0.45, 0.55],
			# highlight = [0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.6],
			# highlight = [0.05, 0.30, 0.5, 0.55, 0.6],
			title = 'Ground State Magnetism at Different Densities ($\phi$)',
			X_label = 'External Field Strength ($H^{*}$)',
			Y_label = 'System Net Magnetism ($M$)',
			# c_label = '$\phi$',
			colormap = 'Dark2'
			)
		exit()

		# second sns graph
		gen_snsplot(
			file = mag_data_file,
			v_col = 'val', # label of column containing value data in mag data file
			x_col = 'field', # label of column containing x-axis data in mag data file
			y_col = 'den', # label of column containing y-axis data in mag data file
			# figure properties
			save = 'fig4_sns2.png',
			title = 'Ground State Magnetism',
			X_label = 'External Field Strength ($H^{*}$)',
			Y_label = 'Net Magnetism ($M$)',
			# c_label = '$\phi$',
			colormap = 'crest',
			y_vals = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6]
			)

		# third sns graph
		gen_snsplot(
			file = mag_data_file,
			v_col = 'val', # label of column containing value data in mag data file
			x_col = 'field', # label of column containing x-axis data in mag data file
			y_col = 'den', # label of column containing y-axis data in mag data file
			# figure properties
			save = 'fig4_sns3.png',
			title = 'Ground State Magnetism',
			X_label = 'External Field Strength ($H^{*}$)',
			Y_label = 'System Net Magnetism ($M$)',
			# c_label = '$\phi$',
			colormap = 'crest',
			y_vals = [0.5, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6]
			)
