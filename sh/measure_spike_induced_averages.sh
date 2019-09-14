#!/bin/bash

# For measuring the spike induced averages from all of the unperturbed traces and putting
# them into a csv

# ./sh/measure_spike_induced_averages.sh spike_induced_averages.csv

proj_dir=$SPACE/Perturbation_Analysis/
csv_dir=$proj_dir/csv/
h5_dir=$SPACE/h5/
file_to_make=$csv_dir/$1

echo "trace_number,sia_indicator,sia_endogeneous,sia_immobile,sia_excited,fast_indicator_tc_mean,fast_indicator_tc_std,slow_indicator_tc_mean,slow_indicator_tc_std,fast_indicator_error_mean,slow_indicator_error_mean,fast_endogeneous_tc_mean,fast_endogeneous_tc_std,slow_endogeneous_tc_mean,slow_endogeneous_tc_std,fast_endogeneous_error_mean,slow_endogeneous_error_mean,fast_immobile_tc_mean,fast_immobile_tc_std,slow_immobile_tc_mean,slow_immobile_tc_std,fast_immobile_error_mean,slow_immobile_error_mean,excited_growth_tc_mean,excited_growth_tc_std,excited_decay_tc_mean,excited_growth_tc_std,excited_growth_error_mean,excited_decay_error_mean" > $file_to_make

for f in `ls -tr $h5_dir`
do
  full_f=$h5_dir/$f
  echo `date +"%Y.%m.%d %T"` "processing $full_f..."
  trace_spike_induced_averages=`$SPACE/julia/julia $proj_dir/jl/calculate_stas.jl --h5_file $full_f`
  echo $trace_spike_induced_averages >> $file_to_make
done

echo "Done: $file_to_make"


