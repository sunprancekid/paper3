import sys, os
from simbin.python.testH.testH_data import parse_simulation_data
from simbin.python.fig import gen_highlight_plot
import numpy as np

## PARAMETERS
# path to the file contiaining the testH data
path = './testH/squ2c16/e05/TX/'

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
	if not os.path.exists(TH_dir + 'anal/testH_anal.csv'):
		df = parse_simulation_data(path = TH_dir, header = ['id', 'd', 'c', 'e', 'r', 'T', 'H'],
			T_col = 'T', X_col = 'H', id_col = 'id')

	# plot the system temperature against the external field strength
	# highlight the temperature set points
	gen_highlight_plot(
		file = TH_dir + 'anal/testH_anal.csv',
		y_col = 'temp',
		x_col = 'H',
		iso_col = 'T',
		save = TH_dir + 'anal/testH_TH_isoT.png',
		# iso_vals = [float("{:.2f}".format(x)) for x in np.linspace(0.2, 1.0, 1 * 8 + 1, endpoint = True)],
		highlight = [0.2, 0.4, 0.6, 0.8, 1.0],
		highlight_colormap = 'flare',
		highlight_label = '$T_{{set}}$ = {:.2f}',
		X_label = 'External Field Strength ($H^{*}_{set}$)',
		Y_label = 'Measured System Temperature ($T$)')

	gen_highlight_plot(
		file = TH_dir + 'anal/testH_anal.csv',
		y_col = 'mag',
		x_col = 'H',
		iso_col = 'T',
		save = TH_dir + 'anal/testH_TH_isoM.png',
		max_y = 1.,
		# iso_vals = [float("{:.2f}".format(x)) for x in np.linspace(0.2, 1.0, 1 * 8 + 1, endpoint = True)],
		highlight = [0.2, 0.4, 0.6, 0.8, 1.0],
		highlight_colormap = 'flare',
		highlight_label = '$T_{{set}}$ = {:.2f}',
		X_label = 'External Field Strength ($H^{*}_{set}$)',
		Y_label = 'Measured System Magnetism ($M$)')


# determine if TX simulations were performed
if os.path.exists(TX_dir):
	# analyze the data stored in the file containing the testH data points
	if not os.path.exists(TX_dir + 'anal/testH_anal.csv'):
		df = parse_simulation_data(path = TX_dir, header = ['id', 'd', 'c', 'e', 'r', 'T', 'X'],
			T_col = 'T', X_col = 'X', id_col = 'id')

	# create graphs
	gen_highlight_plot(
		file = TX_dir + 'anal/testH_anal.csv',
		y_col = 'mag',
		x_col = 'X',
		iso_col = 'T',
		save = TX_dir + 'anal/testH_TX.png',
		# iso_vals = [float("{:.2f}".format(x)) for x in np.linspace(0.2, 1.0, 5 * 12 + 1, endpoint = True)],
		highlight = [0.25, 0.4, 0.6, 0.8, 1.0],
		highlight_colormap = 'flare',
		highlight_label = '$T_{{set}}$ = {:.2f}',
		highlight_label_order = 'max_value',
		X_label = 'Ratio of Magnetic to Thermal Energy ($X_{set}$)',
		Y_label = 'Measured System Magnetism ($M$)',
		x_major_ticks = [0., 1.0, 2.0, 3.0, 4.0, 5.0],
		x_minor_ticks = [0.5, 1.5, 2.5, 3.5, 4.5],
		y_major_ticks = [0., 0.2, 0.4, 0.6, 0.8, 1.0],
		y_minor_ticks = [0.1, 0.3, 0.5, 0.7, 0.9],
		max_y = 1.,
		plot_expectation = True)


