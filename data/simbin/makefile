#!/user/bin/env make

# specify the fortran compiler
FORT:=gfortran

# location of fortran simclass files
FORTBIN=./fortran

# debugging / testing flags
DEBUG=-fcheck=all -fbounds-check


default:
	echo "No command given."

clean:
	rm -f *.txt
	rm -f *.csv
	rm -f *.o
	rm -f *.mod
	rm -f *.exc
	rm -f *.dat
	rm -f *.xyz
	rm -f a.out
	rm -f fort.*
	rm -f *.ex

open: 
	sublime ${FORTBIN}/*.f90

# constants associated with files
POLSQU_MOD=polsqu2x2_mod
POLSQU_SIM=polsqu2x2_sim
TESTH_SIM=testH

polsqu_test: clean
	# compile module, simulation program
	$(FORT) -O3 $(DEBUG) -c $(FORTBIN)/$(POLSQU_MOD).f90 $(FORTBIN)/$(POLSQU_SIM).f90
	# link module and program
	$(FORT) -o polsqu_test.ex $(POLSQU_SIM).o $(POLSQU_MOD).o
	./polsqu_test.ex 0

polsqu_run: clean
	# compile module, simulation program
	$(FORT) -O3 $(DEBUG) -c $(FORTBIN)/$(POLSQU_MOD).f90 $(FORTBIN)/$(POLSQU_SIM).f90
	# link module and program
	$(FORT) -o polsqu_test.ex $(POLSQU_SIM).o $(POLSQU_MOD).o
	./polsqu_test.ex 1

polsqu_testH: clean
	# compile module, simulation program
	$(FORT) -O3 $(DEBUG) -c $(FORTBIN)/$(POLSQU_MOD).f90 $(FORTBIN)/$(TESTH_SIM).f90
	# link module and program
	$(FORT) -o polsqu_test.ex $(TESTH_SIM).o $(POLSQU_MOD).o
	./polsqu_test.ex 0.25 0.5 400 testH

polsqu_anneal:
	# compile module, simulation program with out cleaning previous files
	$(FORT) -O3 $(DEBUG) -c $(FORTBIN)/$(POLSQU_MOD).f90 $(FORTBIN)/$(POLSQU_SIM).f90
	# link module and program
	$(FORT) -o polsqu_test.ex $(POLSQU_SIM).o $(POLSQU_MOD).o
	./polsqu_test.ex 1


# rod3_test: clean
# 	$(FORT) $(DEBUG) $(FORTBIN)/$(ROD3_FILE)
# 	./a.out

# rod4: clean
# 	$(FORT) -O3 -c $(FORTBIN)/$(ROD4_FILE) $(FORTBIN)/$(ROD4_SIM)
# 	$(FORT) -o rod4.ex rod4simulation.o rod4.o
# 	./rod4.ex

# rod4_test: clean
# 	$(FORT) $(DEBUG) $(FORTBIN)/$(ROD4_FILE)
# 	./a.out
