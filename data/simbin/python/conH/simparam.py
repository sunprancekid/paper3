# filename: conH_simparam.py
# author: Matthew A. Dorsey (@sunprancekid)
# date: 2023.12.04
# purpose: contains class information for conH simulation parameters


## PACKAGES
import sys, os
import pandas as pd


## PARAMETERS
# none

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
# none

## SCRIPT
# none


