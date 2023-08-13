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
CONH_INIT=conH_init
CONH_ANNEAL=conH_anneal

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
	./polsqu_test.ex 0.2 10000000 16 0.25 0.0 400 testH

polsqu_conH_init: clean
	# compile module, simulation program
	$(FORT) -O3 $(DEBUG) -c $(FORTBIN)/$(POLSQU_MOD).f90 $(FORTBIN)/$(CONH_INIT).f90
	# link module and program
	$(FORT) -o $(CONH_INIT).ex $(CONH_INIT).o $(POLSQU_MOD).o
	./$(CONH_INIT).ex conH test 0.2 12 1.0 0.5 3.0 1000000 0.96

polsqu_conH_anneal:
	# compile the module, simulation program, without cleaning the previous simulation files
	$(FORT) -O3 $(DEBUG) -c $(FORTBIN)/$(POLSQU_MOD).f90 $(FORTBIN)/$(CONH_ANNEAL).f90
	# link module and program
	$(FORT) -o $(CONH_ANNEAL).ex $(CONH_ANNEAL).o $(POLSQU_MOD).o
	./$(CONH_ANNEAL).ex conH test 0.2 12 1.0 0.5 1000000


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
