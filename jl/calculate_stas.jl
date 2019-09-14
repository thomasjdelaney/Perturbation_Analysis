# Script for calculating the spike triggered averages of the buffer concentrations
# add some code for calculating the time constants too

using ArgParse
using DataFrames
using Logging
using HDF5
using LsqFit

Logging.configure(level=INFO)

function parseParams()
  s = ArgParseSettings()
  @add_arg_table s begin
  "--h5_file"
    help = "The directory containing the h5 files."
    arg_type = String
    default = "/space/td16954/h5/indicator_8_0.h5"
  "--spike_file"
    help = "The file that contains the actual spike trains."
    arg_type = String
    default = homedir() * "/Spike_finder/train/8.train.spikes.csv"
  "--debug"
    help = "Enter debug mode."
    action = :store_true
  end
  p = parse_args(s)
  return p
end

function exponentialDifferenceModel(time, params)
  # params[1] = highest point, params[2] = time constant
  return params[1] * exp.(-time .* params[2]) - (params[3] * exp.(-time .* params[4])) 
end

function mixedDecayModel(time, params)
  # params[1,3] = fast and slow highest point respectively, params[2,4] = fast and slow time constants
  return (params[1] * exp.(-time .* params[2])) + (params[3] * exp.(-time .* params[4]))
end

function getSpikeTrainFromFile(spike_file::String, h5_file::String)
  column_name = Symbol("x" * split(split(h5_file, "_")[end], ".")[1])
  return column_name, readtable(spike_file)[column_name]
end

function getSingleSpikeFrames(spike_file::String, h5_file::String)
  column_name, spike_train = getSpikeTrainFromFile(spike_file, h5_file)
  num_frames = length(spike_train)
  spike_train[isna(spike_train)] = 0.0
  spike_inds = find(spike_train)
  has_five_seconds_before = [spike_inds[1]; diff(spike_inds)] .> 500
  has_five_seconds_after = diff([spike_inds; num_frames]) .> 500
  return column_name, spike_inds[has_five_seconds_before & has_five_seconds_after]
end  

function getFrameFromH5(h5_file::String, frame_name::String, value_index::String)
  frame_names = ["calcium", "fluoro", "power"]
  frame_name in frame_names || error(" unrecognised frame provided: $frame_name")
  value_dict = h5read(h5_file, value_index)
  frame_dict = value_dict[frame_name]
  return_frame = DataFrame()
  [return_frame[Symbol(k)] = v for (k,v) in frame_dict]
  return return_frame
end

function getSpikeChangeValues(spike_ind::Int64, concentration_trace::DataArrays.DataArray{Float64,1})
  change_inds = (spike_ind*100) - 5:(spike_ind*100) + 50000
  return concentration_trace[change_inds]
end

function getSpikeInducedChange(spike_ind::Int64, concentration_trace::DataArrays.DataArray{Float64,1})
  change_values = getSpikeChangeValues(spike_ind, concentration_trace)
  return maximum(change_values) - minimum(change_values)
end

function getSpikeInducedAverages(single_spike_frames::Array{Int64,1}, calcium_frame::DataFrames.DataFrame)
  if length(single_spike_frames) > 0
    sia_indicator = mean([getSpikeInducedChange(spike_ind, calcium_frame[:indicator_bound]) for spike_ind in single_spike_frames])
    sia_endogeneous = mean([getSpikeInducedChange(spike_ind, calcium_frame[:endogeneous_bound]) for spike_ind in single_spike_frames])
    sia_immobile = mean([getSpikeInducedChange(spike_ind, calcium_frame[:immobile_bound]) for spike_ind in single_spike_frames])
    sia_excited = mean([getSpikeInducedChange(spike_ind, calcium_frame[:excited]) for spike_ind in single_spike_frames])
  else
    warn(" No single spikes found!")
    sia_indicator, sia_endogeneous, sia_immobile, sia_excited = 0.0, 0.0, 0.0, 0.0
  end
  return sia_indicator, sia_endogeneous, sia_immobile, sia_excited
end

function fitMixedDecayModel(spike_ind::Int64, concentration_trace::DataArrays.DataArray{Float64,1}, initial_params::Array{Float64,1})
  change_values = getSpikeChangeValues(spike_ind, concentration_trace)
  decay_values = convert(Array{Float64,1}, change_values[indmax(change_values):end])
  num_frames = length(decay_values)
  decay_time = range(0, 500/num_frames, num_frames)
  model_fit = curve_fit(mixedDecayModel, decay_time, decay_values, initial_params)
  return model_fit
end

function fitDifferenceModel(spike_ind::Int64, concentration_trace::DataArrays.DataArray{Float64,1}, initial_params::Array{Float64,1})
  change_values = getSpikeChangeValues(spike_ind, concentration_trace)
  grow_decay_values = convert(Array{Float64,1}, change_values[5:end])
  num_frames = length(grow_decay_values)
  decay_time = range(0, 500/num_frames, num_frames) 
  model_fit = curve_fit(exponentialDifferenceModel, decay_time, grow_decay_values, initial_params)
  return model_fit
end

function getAverageTimeConstant(single_spike_frames::Array{Int64,1}, calcium_frame::DataFrames.DataFrame, column::Symbol, fitting_function::Function, initial_params::Array{Float64,1})
  concentration_trace = calcium_frame[column]
  num_single_spikes = length(single_spike_frames)
  all_time_constants = zeros(Float64, (num_single_spikes, 2))
  all_errors = zeros(Float64, (num_single_spikes, 2))
  if num_single_spikes == 0
    warn(" No single spikes found!")
    return mean_and_std(all_time_constants, 1)
  else
    for i in 1:num_single_spikes
      fitted_model = fitting_function(single_spike_frames[i], concentration_trace, initial_params)
      all_time_constants[i,:] = fitted_model.param[[2,4]]
      all_errors[i,:] = try 
        estimate_errors(fitted_model, 0.95)[[2,4]]
      catch
        [0,0]
      end
    end
  end
  fast, slow = mean_and_std(all_time_constants, 1)
  fast_error, slow_error = mean_and_std(all_errors, 1)
  return fast[1], fast[2], slow[1], slow[2], fast_error[1], slow_error[1]
end

function main()
  info(" Starting main function...")
  params = parseParams()
  if params["debug"]; info(" Entering debug mode."); return nothing; end
  column_name, single_spike_frames = getSingleSpikeFrames(params["spike_file"], params["h5_file"])
  column_number = replace(string(column_name), "x", "")
  calcium_frame = getFrameFromH5(params["h5_file"], "calcium", "3")
  sia_indicator, sia_endogeneous, sia_immobile, sia_excited = getSpikeInducedAverages(single_spike_frames, calcium_frame)
  fast_indicator_tc_mean, fast_indicator_tc_std, slow_indicator_tc_mean, slow_indicator_tc_std, fast_indicator_error_mean, slow_indicator_error_mean = getAverageTimeConstant(single_spike_frames, calcium_frame, :indicator_bound, fitMixedDecayModel, [4e5, 1.0, 3e5, 0.003])
  fast_endogeneous_tc_mean, fast_endogeneous_tc_std, slow_endogeneous_tc_mean, slow_endogeneous_tc_std, fast_endogeneous_error_mean, slow_endogeneous_error_mean = getAverageTimeConstant(single_spike_frames, calcium_frame, :endogeneous_bound, fitMixedDecayModel, [4e5, 1.0, 3e5, 0.003])
  fast_immobile_tc_mean, fast_immobile_tc_std, slow_immobile_tc_mean, slow_immobile_tc_std, fast_immobile_error_mean, slow_immobile_error_mean = getAverageTimeConstant(single_spike_frames, calcium_frame, :immobile_bound, fitMixedDecayModel, [4e5, 1.0, 3e5, 0.003])
  excited_growth_tc_mean, excited_growth_tc_std, excited_decay_tc_mean, excited_growth_tc_std, excited_growth_error_mean, excited_decay_error_mean = getAverageTimeConstant(single_spike_frames, calcium_frame, :excited, fitDifferenceModel, [42000, 0.003, 42000, 2])
  return print("$column_number,$sia_indicator,$sia_endogeneous,$sia_immobile,$sia_excited,$fast_indicator_tc_mean,$fast_indicator_tc_std,$slow_indicator_tc_mean,$slow_indicator_tc_std,$fast_indicator_error_mean,$slow_indicator_error_mean,$fast_endogeneous_tc_mean,$fast_endogeneous_tc_std,$slow_endogeneous_tc_mean,$slow_endogeneous_tc_std,$fast_endogeneous_error_mean,$slow_endogeneous_error_mean,$fast_immobile_tc_mean,$fast_immobile_tc_std,$slow_immobile_tc_mean,$slow_immobile_tc_std,$fast_immobile_error_mean,$slow_immobile_error_mean,$excited_growth_tc_mean,$excited_growth_tc_std,$excited_decay_tc_mean,$excited_growth_tc_std,$excited_growth_error_mean,$excited_decay_error_mean")
end

main()



