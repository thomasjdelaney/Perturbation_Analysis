"""
Perturb a model parameter and evaluate the model under that perturbation
Arguments:  params, Dict, the parameters of the model
            parameter, the parameter to change
            values, the values to use for the parameter
            plot_func, the function to use to plot.
            frame_keys, the keys to use on the DataFrames, called for plot_func
            use_frame, either :trace, or :power
            unit = String, the unit of the parameter,
            title,
            headings,
            will_save
Returns:    filename
"""

function perturbParamTraces(params, parameter, values, plot_func, frame_keys, use_frame, unit, title, headings, will_save=false)
  fig = PyPlot.figure(figsize=(27,27))
  to_be_converted = ["baseline", "indicator", "endogeneous", "immobile"]
  forwrd_rates = ["f_i", "f_e", "f_im"]
  cell_volume = sphereVolume(params["cell_radius"])
  n = length(values)
  for i in 1:n
    v = values[i]
    if parameter in to_be_converted; v = FluorescenceModel.molarsToMolecules(v, cell_volume); end
    if parameter in forwrd_rates; v = FluorescenceModel.perMolarToPerMolecule(v, cell_volume); end
    params[parameter] = v
    fl, p = runModelReturnAll(params)
    frame = use_frame == :power ? p : fl
    PyPlot.subplot(n+1, 1, i+1)
    map(plot_func, [frame[frame_keys[1]]], [frame[frame_keys[2]]])
    PyPlot.title(headings[i], fontsize="28")
    PyPlot.xticks(fontsize="28"); PyPlot.yticks(fontsize="28");
    if i < n
      PyPlot.xlabel("")
    end
    if i==1
      PyPlot.subplot(n+1, 1, 1)
      map(plot_func, [frame[frame_keys[3]]], [frame[frame_keys[2]]])
      PyPlot.title("Observed fluorescence", y=1.08, fontsize="28")
      PyPlot.suptitle(getSupTitle(params["spike_file"], params["colname"]), fontsize="28")
      PyPlot.xlabel("")
      PyPlot.xticks(fontsize="28"); PyPlot.yticks(fontsize="28");
    end
  end
  filename = string(pwd(), "/images/", replace(title, " ", "_"), ".png")
  PyPlot.savefig(filename)
  return filename
end
