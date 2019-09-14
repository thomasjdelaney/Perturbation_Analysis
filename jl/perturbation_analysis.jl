########################################################################################################
##
##  For running the perturbation analysis on the Calcium fluorescence model.
##
##  julia -i perturbation_analysis.jl --perturb_params indicator,immobile --perturb_values 100e-5 100e-6 
##    100e-7 7.87e-4 7.87e-5 7.87e-6 --save_name file_to_save.png --colname 2 
##    --opt_file $HOME/Spike_finder/train/optimised_2.csv --debug
##
########################################################################################################

push!(LOAD_PATH, "/space/td16954/Perturbation_Analysis/jl")
using PerturbationAnalysis
using CSV
using DataFrames
using HDF5
using JuliaUtils: rms

function main()
  info("Starting main function...", prefix=string(now(), " INFO: "))
  params = parseParams()
  if params["debug"]; info("Entering debug mode.", prefix=string(now(), " INFO: ")); return nothing; end
  fid = h5open(params["save_name"], "w")
  param_val_dict, num_perturb_values = getParamValueDict(params["perturb_params"], params["perturb_values"])
  write(fid, "info/values", params["perturb_values"])
  write(fid, "info/frequency", params["frequency"])
  for i in 1:num_perturb_values
    info("processing value number $i...", prefix=string(now(), " INFO: "))
    iter_param_val_dict = Dict(k => param_val_dict[k][i] for k in keys(param_val_dict))
    opt_file = params["opt_files"][i]
    optimised_params = getOptimisedDict(opt_file)
    all_params = getAllParams(optimised_params, params)
    model_params = copy(all_params)
    model_params = merge(model_params, iter_param_val_dict)
    calcium_frame, fluoro_frame, power_frame = runModelReturnAll(model_params)
    frames = [calcium_frame, fluoro_frame, power_frame]
    name_frames = ["calcium", "fluoro", "power"]
    num_frames = length(frames)
    for j in 1:num_frames
      frame = frames[j]
      frame_name = name_frames[j]
      for col in names(frame)
        write(fid, "$i/$frame_name/$col", frame[col])
      end
    end
    root_mean_squared = rms(power_frame[:log_model] - power_frame[:log_fluoro]) + rms(fluoro_frame[:zscore_model] - fluoro_frame[:zscore_observed])
    write(fid, "$i/root_mean_squared", root_mean_squared)
  end
  close(fid)
  info("File saved: " * params["save_name"], prefix=string(now(), " INFO: "))
end

main()

