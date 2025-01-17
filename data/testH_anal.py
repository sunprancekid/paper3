import sys, os
from simbin.python.testH.testH_data import parse_simulation_data
from simbin.python.fig.highlight_plot import gen_highlight_plot
from simbin.python.fig.distribution_plot import gen_dist_plot
import numpy as np

## PARAMETERS
# default color maps used for all figures plotting magnetism data
default_mag_cmap = 'brg_r'
# default color maps used for all figures plotting temperature data
default_temp_cmap = 'brg_r'

## ARGUMENTS
# first argument: path to the directory
path = sys.argv[1]

## SCRIPT
# establish pathways
TX_dir = path + 'TX/'
TH_dir = path + 'TH/'

# determine if TH simulations were performed
if os.path.exists(TH_dir):
	# gather the simulation data into one file
	# if not os.path.exists(TH_dir + 'anal/testH_anal.csv'):
	# df = parse_simulation_data(path = TH_dir, header = ['id', 'd', 'c', 'e', 'r', 'T', 'H'],
	# 	T_col = 'T', X_col = 'H', id_col = 'id')

	gen_highlight_plot(
		file = TH_dir + 'anal/testH_anal.csv',
		dpi = 300,
		y_col = 'mag',
		x_col = 'H',
		iso_col = 'T',
		save = TH_dir + 'anal/testH_TH_isoM.png',
		max_y = 1.,
		y_major_ticks = [0., 0.2, 0.4, 0.6, 0.8, 1.0],
		y_minor_ticks = [0.1, 0.3, 0.5, 0.7, 0.9],
		# iso_vals = [float("{:.2f}".format(x)) for x in np.linspace(0.2, 1.0, 1 * 8 + 1, endpoint = True)],
		highlight = [0.2, 0.4, 0.6, 0.8, 1.0],
		highlight_colormap = default_mag_cmap,
		highlight_label = '$T^{{*}}$ = {:.2f}',
		X_label = '$H^{{*}}$',
		Y_label = '$M_{{measured}}$')

	# plot the system temperature against the external field strength
	# highlight the temperature set points
	gen_highlight_plot(
		file = TH_dir + 'anal/testH_anal.csv',
		dpi = 300,
		y_col = 'temp',
		x_col = 'H',
		iso_col = 'T',
		save = TH_dir + 'anal/testH_TH_isoT.png',
		# iso_vals = [float("{:.2f}".format(x)) for x in np.linspace(0.2, 1.0, 1 * 8 + 1, endpoint = True)],
		highlight = [0.2, 0.4, 0.6, 0.8, 1.0],
		highlight_colormap = default_temp_cmap,
		highlight_label = '$T^{{*}}$ = {:.2f}',
		X_label = '$H^{{*}}$',
		Y_label = '$T_{{measured}}$',
		y_major_ticks = [0.2, 0.4, 0.6, 0.8, 1.0],
		y_minor_ticks = [0.3, 0.5, 0.7, 0.9])


# determine if TX simulations were performed
if os.path.exists(TX_dir):
	# analyze the data stored in the file containing the testH data points
	# df = parse_simulation_data(path = TX_dir, header = ['id', 'd', 'c', 'e', 'r', 'T', 'X'],
	# 	T_col = 'T', X_col = 'X', id_col = 'id')

	# create magnetization and temperature graphs
	gen_highlight_plot(
		file = TX_dir + 'anal/testH_anal.csv',
		y_col = 'mag',
		x_col = 'X',
		iso_col = 'T',
		save = TX_dir + 'anal/testH_TXisoM.png',
		# iso_vals = [float("{:.2f}".format(x)) for x in np.linspace(0.2, 1.0, 5 * 12 + 1, endpoint = True)],
		highlight = [0.2, 0.4, 0.6, 0.8, 1.0],
		highlight_colormap = default_mag_cmap,
		highlight_label = '$T^{{*}}$ = {:.2f}',
		highlight_label_order = 'max_value',
		X_label = '$\mu^{{*}} H^{{*}} / T^{{*}}$',
		Y_label = '$M_{{measured}}$',
		# x_major_ticks = [0., 2.0, 4.0, 6.0, 8.0, 10.0],
		# x_minor_ticks = [1.0, 3.0, 5.0, 7.0, 9.0],
		x_major_ticks = [0., 1.0, 2.0, 3.0, 4.0, 5.0],
		x_minor_ticks = [0.5, 1.5, 2.5, 3.5, 4.5],
		y_major_ticks = [0., 0.2, 0.4, 0.6, 0.8, 1.0],
		y_minor_ticks = [0.1, 0.3, 0.5, 0.7, 0.9],
		max_y = 1.,
		plot_expectation = True)

	gen_highlight_plot(
		file = TX_dir + 'anal/testH_anal.csv',
		y_col = 'temp',
		x_col = 'X',
		iso_col = 'T',
		save = TX_dir + 'anal/testH_TXisoT.png',
		# iso_vals = [float("{:.2f}".format(x)) for x in np.linspace(0.2, 1.0, 5 * 12 + 1, endpoint = True)],
		highlight = [0.2, 0.4, 0.6, 0.8, 1.0],
		highlight_colormap = default_temp_cmap,
		highlight_label = '$T^{{*}}$ = {:.2f}',
		highlight_label_order = 'max_value',
		X_label = '$\mu^{{*}} H^{{*}} / T^{{*}}$',
		Y_label = '$T_{{measured}}$',
		# x_major_ticks = [0., 2.0, 4.0, 6.0, 8.0, 10.0],
		# x_minor_ticks = [1.0, 3.0, 5.0, 7.0, 9.0],
		x_major_ticks = [0., 1.0, 2.0, 3.0, 4.0, 5.0],
		x_minor_ticks = [0.5, 1.5, 2.5, 3.5, 4.5],
		y_major_ticks = [0.2, 0.4, 0.6, 0.8, 1.0],
		y_minor_ticks = [0.3, 0.5, 0.7, 0.9],
		max_y = 1.)

	# create angular distribution plots
	for t in [0.60]:
		for x in [0.50, 1.00, 2.00, 3.00]:
			simid = "t{:03d}x{:03d}r000".format(int(t * 100), int(x * 100))
			dist_file = TX_dir + 'dist/' + simid + '_aligndist.csv'
			gen_dist_plot (file = dist_file,
				x_col = 'theta',
				y_col = 'align',
				fontsize = 18,
				# circular_bool = True,
				# figure settings
				save = TX_dir + 'anal/' + simid + '_dist.png',
				title = '$T^{{*}}$ = {:.2f}, $\mu^{{*}} H^{{*}} / T^{{*}}$ = {:.2f}'.format(t, x),
				Y_label = 'Normalized Probability',
				X_label = '$\\theta$',
				min_y = 0.,
				max_y = 1.0,
				min_x = -np.pi,
				max_x = np.pi,
				bar_color = '#AFE1AF',
				bar_label = 'Simulation\nDistribution',
				# axis ticks and labels
				x_major_ticks = [float("{:.2f}".format(x)) for x in np.linspace(-np.pi, np.pi, 5, endpoint = True)],
				x_minor_ticks = [float("{:.2f}".format(x)) for x in np.linspace(-np.pi * 3 / 4, np.pi * 3 / 4, 4, endpoint = True)],
				x_major_ticks_labels = ['-$\pi$', '-$\pi$ / 2', '0', '$\pi$ / 2', '$\pi$'],
				y_major_ticks = [float("{:.2f}".format(x)) for x in np.linspace(0., 1., 6, endpoint = True)],
				y_minor_ticks = [float("{:.2f}".format(x)) for x in np.linspace(0.1, 0.9, 5, endpoint = True)],
				# add von mises expectation plots
				plot_expectation = True,
				X = x,
				expectation_label = '$f (\\theta, X)$')


