#!/bin/bash

export OMP_NUM_THREADS=1

declare -A mpi_ranks
mpi_ranks["bbcore"]=1
mpi_ranks["conc"]=1
mpi_ranks["deriv"]=1
mpi_ranks["gf"]=2
mpi_ranks["kin"]=1
mpi_ranks["patstim"]=2
mpi_ranks["vecplay"]=2
mpi_ranks["watch"]=2

for test in "${!mpi_ranks[@]}" ; do
  mkdir -p test${test}dat
done

for test in "${!mpi_ranks[@]}" ; do
  echo "Running neuron for $test"
  num_ranks=${mpi_ranks[$test]}
  srun -n $num_ranks ./x86_64/special -mpi -c sim_time=100 test${test}.hoc
  cat out${test}.dat | sort -k 1n,1n -k 2n,2n > out_nrn_${test}.spk
  rm out${test}.dat
done

#prepare coreneuron executable
for test in "${!mpi_ranks[@]}" ; do
  echo "Running coreneuron for $test"
  num_ranks=${mpi_ranks[$test]}
  if [ "${test}" = "patstim" ]
  then
    srun -n $num_ranks ./x86_64/special-core -mpi -d test${test}dat -e 100 --pattern patstim.spk
  else
    srun -n $num_ranks ./x86_64/special-core -mpi -d test${test}dat -e 100
  fi
  cat out.dat > out_cn_${test}.spk
  rm out.dat
done

for test in "${!mpi_ranks[@]}" ; do
  DIFF=$(diff -w -q out_nrn_${test}.spk out_cn_${test}.spk)
  if [ "$DIFF" != "" ]
  then
    echo "Test ${test} failed"
  fi
done
