"""
For taking the parameter dictionaries from perturbation analysis, and optimisation
and returning a parameter dictionary suitable to run the fluorescence model.

Arguments:  optimised_params, dictionary, parameters from optimisation
            perturbed_params, dictionary, parameters from perturbation

Returns:    model_params, dictionary
"""
function getAllParams(optimised_params, perturbed_params)
  model_params = merge(getDefaultFluorescenceModelParams(), optimised_params)
  return merge(model_params, perturbed_params)
end
