"""
For making a dictionary of the parameters and their associated values

Arguments:  parameters, a comma separated list of the parameter names
            values, an array of the parameter values

Returns:    Dictionary
"""
function getParamValueDict(parameters::String, values::Array{Float64,1})
  param_val_dict = Dict()
  sep_params = split(parameters, ",")
  num_params = length(sep_params)
  num_values = length(values)/num_params
  if isinteger(num_values)
    num_values = Int(num_values)
    reshaped_values = reshape(values, num_params, num_values)
    for i in 1:num_params
      param_val_dict[sep_params[i]] = reshaped_values[i,:]
    end
  else
    error("Number of values lust be an integer multiple of the number of parameters.", prefix=string(now(), " ERROR: "))
  end
  return param_val_dict, num_values
end
