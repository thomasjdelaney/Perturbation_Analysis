#!/bin/bash
# for running the perturbation analysis on all the files in a given dataset

# ./sh/perturb_all_files.sh indicator,immobile 100e-5,100e-6,100e-7,7.87e-4,7.87e-5,7.87e-6 8

julia_dir=$SPACE/julia_v0.6.1/bin/
proj_dir=$SPACE/Perturbation_Analysis/
opt_dir=$SPACE/optimisation_csvs/
perturb_params=$1
under_perturb_params=${perturb_params/,/_}
perturb_values=`echo $2 | sed "s/:/,/g"` # perturb values should be comma separated
perturb_values=`echo $perturb_values | sed "s/,/ /g"`
dataset=$3
calc_file=$HOME/Spike_finder/train/"$dataset".train.spikes.csv
first_line=$(head -n 1 $calc_file)
for i in $(echo $first_line | sed "s/,/ /g")
do
  save_name=$SPACE/h5/"$under_perturb_params"_"$dataset"_"$i".h5
  opt_file=$opt_dir/comp_opt_"$dataset"_"$i"_2e-2.csv
  $julia_dir/julia $proj_dir/jl/perturbation_analysis.jl --perturb_params $perturb_params --perturb_values $perturb_values --save_name $save_name --colname "$i" --opt_file $opt_file
done
