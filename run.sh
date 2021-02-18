#!/bin/bash
set -e

export OMP_NUM_THREADS=1

spike_comparison_tests="bbcore conc deriv gf kin patstim vecplay watch vecevent"

direct_tests="netstimdirect"

# gpu_tests="bbcore kin"

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

EXTRA_ARGS=""
GPU_ARG="-c gpu=1"

# Run tests that require separate runs of NEURON and CoreNEURON to compare their spikes only
for test in $spike_comparison_tests; do
  echo "Running neuron for $test"
  num_ranks=${mpi_ranks[$test]}
  if [[ "$test" == "patstim" ]]; then
    EXTRA_ARGS="-c dumpmodel=1"
  fi
  mpirun -n $num_ranks ./x86_64/special -mpi -c sim_time=100 $EXTRA_ARGS test${test}.hoc
  cat out${test}.dat | sort -k 1n,1n -k 2n,2n > out_nrn_${test}.spk
  rm out${test}.dat

  echo "Running coreneuron for $test"
  if [[ "$gpu_tests" == *"$test"* ]]; then
    EXTRA_ARGS="$EXTRA_ARGS $GPU_ARG"
  fi
  if [[ "$test" == "patstim" ]] ; then
    mpirun -n $num_ranks ./x86_64/special-core -d coredat --mpi -e 100 --pattern patstim.spk
    mv out.dat out${test}.dat
  else
    mpirun -n $num_ranks ./x86_64/special -mpi -c sim_time=100 -c coreneuron=1 $EXTRA_ARGS test${test}.hoc
  fi
  cat out${test}.dat | sort -k 1n,1n -k 2n,2n > out_cn_${test}.spk
  rm out${test}.dat
done

# Compare the spikes of the spike_comparison_test with the reference spikes
for test in $spike_comparison_tests; do
  DIFF_NRN=$(diff -w -q out_nrn_${test}.spk reference/out_${test}.spk)
  if [ "$DIFF_NRN" != "" ]
  then
    echo "Test ${test} with NEURON failed"
    exit 1
  fi
  DIFF_CORENRN=$(diff -w -q out_cn_${test}.spk reference/out_${test}.spk)
  if [ "$DIFF_CORENRN" != "" ]
  then
    echo "Test ${test} with CoreNEURON failed"
    exit 1
  fi
done

# Run the direct_tests that compare internally NEURON and CoreNEURON simulations
for test in $direct_tests; do
  echo "Running neuron and coreneuron for $test"
  num_ranks=${mpi_ranks[$test]}
  mpirun -n $num_ranks ./x86_64/special -mpi -c sim_time=100 test${test}.hoc
  cat out${test}.dat | sort -k 1n,1n -k 2n,2n > out_nrn_${test}.spk
done

# Compare the spikes of the direct_tets with the reference spikes
for test in $direct_tests; do
  DIFF_NRN=$(diff -w -q out_nrn_${test}.spk reference/out_${test}.spk)
  if [ "$DIFF_NRN" != "" ]
  then
    echo "Test ${test} with NEURON/CoreNEURON failed"
    exit 1
  fi
done
