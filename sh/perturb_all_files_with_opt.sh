#!/bin/bash
# for running the perturbation analysis on all the files in a given dataset

# ./sh/perturb_all_files_with_opt.sh indicator,immobile 100e-7,7.87e-6:100e-6,7.87e-5:100e-5,7.87e-4 8
# ./sh/perturb_all_files_with_opt.sh b_i,f_i 1.60,7.767e6:16.0,7.767e7:160.0,7.767e8:1600.0,7.767e9:16000.0,7.767e10 8

julia_dir=$SPACE/julia/bin/
proj_dir=$SPACE/Perturbation_Analysis/
opt_dir=$SPACE/optimisation_csvs/
fluorescence_modelling_dir=$HOME/Fluorescence_Modelling
perturb_params=$1
under_perturb_params=${perturb_params/,/_}
perturb_value_groups=`echo $2 | sed "s/:/ /g"` # perturb values should be comma separated
perturb_value_commas=`echo $2 | sed "s/:/,/g"`
perturb_value_spaces=`echo $perturb_value_commas | sed "s/,/ /g"`
dataset=$3
spike_file=$HOME/Spike_finder/train/"$dataset".train.spikes.csv
calc_file=$HOME/Spike_finder/train/"$dataset".train.calcium.csv
first_line=$(head -n 1 $calc_file)
for i in $(echo $first_line | sed "s/,/ /g")
do
  echo `date +"%Y.%m.%d %T"` Processing trace number "$i"...
  opt_files=""
  # optimisation starts here
  for perturb_value_group in $perturb_value_groups
  do
    under_perturb_values=${perturb_value_group/,/_}
    opt_file_name=opt_"$dataset"_"$i"_300_"$under_perturb_params"_"$under_perturb_values".csv
    if [ -f "$opt_dir$opt_file_name" ]
    then
      echo `date +"%Y.%m.%d %T"` Optimisation file already exists.
    else
      echo `date +"%Y.%m.%d %T"` creating "$opt_dir$opt_file_name"...
      IFS=',' read -r -a sep_perturb_params <<< $perturb_params
      IFS=',' read -r -a sep_perturb_values <<< $perturb_value_group
      perturb_param_command_line_options=" "
      for ((n=0;n<${#sep_perturb_params[@]};++n))
      do
        perturb_param_command_line_options=$perturb_param_command_line_options"--"${sep_perturb_params[n]}" "${sep_perturb_values[n]}" "
      done
      $julia_dir/julia $fluorescence_modelling_dir/jl/fluorescence_training.jl --spike_file $spike_file --calcium_file $calc_file --frequency 100.0 --colname $i --title $opt_file_name --opt_params calcium_rate,excitation,release,capture_rate $perturb_param_command_line_options
    fi
    opt_files=$opt_files$opt_dir$opt_file_name" "
  done
  # perturbation starts here
  echo `date +"%Y.%m.%d %T"` starting perturbation...
  save_name=$SPACE/h5/"$under_perturb_params"_"$dataset"_"$i"_optimised.h5
  colname="$i"
  opt_files=`echo $opt_files | sed "s/ /,/g"`
  $julia_dir/julia $proj_dir/jl/perturbation_analysis.jl --perturb_params $perturb_params --perturb_values $perturb_value_spaces --save_name $save_name --colname $colname --opt_files $opt_files
done
