#!/usr/bin/bash

rm -rf *dat x86_64 *.spk

export OMP_NUM_THREADS=1

spike_comparisson_tests="bbcore conc deriv gf kin patstim vecplay watch vecevent"

direct_tests="netstimdirect"

declare -A mpi_ranks
mpi_ranks["bbcore"]=1
mpi_ranks["conc"]=1
mpi_ranks["deriv"]=1
mpi_ranks["gf"]=2
mpi_ranks["kin"]=1
mpi_ranks["patstim"]=2
mpi_ranks["vecplay"]=2
mpi_ranks["watch"]=2
mpi_ranks["vecevent"]=4
mpi_ranks["netstimdirect"]=2

~/bbp_repos/nrn/build/install/bin/nrnivmodl -coreneuron mod

for test in $spike_comparisson_tests; do
  echo "Running neuron for $test"
  num_ranks=${mpi_ranks[$test]}
  mpirun -n $num_ranks ./x86_64/special -mpi -c sim_time=100 test${test}.hoc
  cat out${test}.dat | sort -k 1n,1n -k 2n,2n > out_nrn_${test}.spk
  rm out${test}.dat

  echo "Running coreneuron for $test"
  mpirun -n $num_ranks ./x86_64/special -mpi -c sim_time=100 -c coreneuron=1 test${test}.hoc
  cat out${test}.dat | sort -k 1n,1n -k 2n,2n > out_cn_${test}.spk
  rm out${test}.dat
done

for test in $spike_comparisson_tests; do
  DIFF=$(diff -w -q out_nrn_${test}.spk out_cn_${test}.spk)
  if [ "$DIFF" != "" ]
  then
    echo "Test ${test} failed"
  fi
done

for test in $direct_tests; do
  echo "Running neuron and coreneuron for $test"
  num_ranks=${mpi_ranks[$test]}
  mpirun -n $num_ranks ./x86_64/special -mpi -c sim_time=100 test${test}.hoc
done
