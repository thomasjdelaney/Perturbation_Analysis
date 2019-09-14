"""
Run the whole model, return two DataFrames that contain all the relevant info.

Arguments:  model_params, the model parameters
Returns:    fluoro_frame, containing fluorescence, zscored fluorescence, spike train
            power_frame, containing frequencies, spectra, smooth spectra,
              log of smooth spectra
"""
function runModelReturnAll(model_params)
  spike_train = convert(Array{Int64,1}, CSV.read(model_params["spike_file"])[model_params["colname"]])
  fluorescence, spiking_sim, spiking_sim_time = FluorescenceModel.calciumFluorescenceModel(spike_train, baseline=model_params["baseline"], calcium_rate=model_params["calcium_rate"], indicator=model_params["indicator"], endogeneous=model_params["endogeneous"], immobile=model_params["immobile"], b_i=model_params["b_i"], f_i=model_params["f_i"], b_e=model_params["b_e"], f_e=model_params["f_e"], b_im=model_params["b_im"], f_im=model_params["f_im"], excitation=model_params["excitation"], release=model_params["release"], peak=model_params["peak"], frequency=model_params["frequency"], capture_rate=model_params["capture_rate"])
  zscore_fluorescence = zscore(fluorescence)
  model_freq_array, model_power = getPowerSpectrum(zscore_fluorescence, model_params["frequency"])
  smooth_model_power = smoothen(model_power, win_length=31, win_method=1)
  log_model_power = 10*log10.(smooth_model_power[model_freq_array.<30.0])
  # Data Part
  fl_trace = CSV.read(model_params["calcium_file"])[model_params["colname"]]
  fl_trace[isnan.(fl_trace)] = 0.0
  zscore_fl = zscore(fl_trace)
  fluoro_freq_array, fluoro_power = getPowerSpectrum(zscore_fl, model_params["frequency"])
  smooth_fluoro_power = smoothen(fluoro_power, win_length=31, win_method=1)
  log_fluoro_power = 10*log10.(smooth_fluoro_power[fluoro_freq_array.<30.0]) # drop off occurs at 30Hz
  spike_train = CSV.read(model_params["spike_file"])[model_params["colname"]]
  spike_train[isnan.(spike_train)] = 0.0
  fluoro_frame = DataFrame([fluorescence fl_trace zscore_fluorescence zscore_fl spike_train])
  fluoro_names = [:model_fluorescence, :observed_fluorescence, :zscore_model, :zscore_observed, :spike_train]
  names!(fluoro_frame, fluoro_names)
  required_freqs = model_freq_array .< 30
  truncated_power = [model_freq_array model_power fluoro_power smooth_model_power smooth_fluoro_power][find(required_freqs),:]
  power_frame = DataFrame([truncated_power log_model_power log_fluoro_power])
  power_names = [:frequencies, :model_power, :fluoro_power, :smooth_model, :smooth_fluoro, :log_model, :log_fluoro]
  names!(power_frame, power_names)
  calcium_frame = DataFrame([spiking_sim spiking_sim_time])
  calcium_names = [:free_calcium, :indicator_bound, :endogeneous_bound, :immobile_bound, :excited, :time]
  names!(calcium_frame, calcium_names)
  return calcium_frame, fluoro_frame, power_frame
end
