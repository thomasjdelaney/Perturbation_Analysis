##########################################################################################################
##
##  For making the figures doing analysis on the peturbation results.
##
##  python py/peturbation_analysis.py --h5_file indicator_8_2.h5 --save_ext 8_2.png --debug
##
##########################################################################################################

import os, sys, argparse, shutil
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import datetime as dt
import getopt
import h5py
import logging as lg

parser = argparse.ArgumentParser('For making the figures doing analysis on the peturbation results.')
parser.add_argument('-p', '--proj_h5_dir', help='The directory where you find the h5 files.', type=str, default=os.path.join(os.environ['HOME'], 'h5'))
parser.add_argument('-f', '--h5_file', help='The name of the h5_file.', type=str, default='indicator_8_18.h5')
parser.add_argument('-s', '--save_ext', help='File extension for saving the figures.', type=str, default='')
parser.add_argument('-o', '--optimised', help='If the training has taken place or not.', default='not_optimised', choices=['not_optimised','optimised'])
parser.add_argument('-d', '--debug', help='Enter debug mode.', default=False, action='store_true')
args = parser.parse_args()

proj_dir = os.path.join(os.environ['HOME'], 'Perturbation_Analysis')
image_dir = os.path.join(proj_dir, 'images')

def getDataKeys(h5_data):
    """
    For getting the non-info data keys.
    Arguments:  h5_data, the data from a h5 file.
    Returns:    data_keys, numpy array of strings
                num_keys, int
    """
    data_keys = np.array(list(h5_data.keys()))
    data_keys = data_keys[['info' != k for k in data_keys]]
    num_keys = data_keys.size
    return data_keys, num_keys

def extractH5Data(h5_file):
    """
    For getting the data from the h5 file
    Arguments:  h5_file, str, the name and path of the file.
    Returns:    h5_data, the data from the file
                perturbed_parameter, str, the name of the perturbed parameter
                perturbed_values, int or float, the values to which we changed the parameter.
                frequency, float, the sampling frequency?
                data_keys, numpy array of strings
                num_keys, int
    """
    h5_data = h5py.File(h5_file, 'r')
    split_file_name = h5_file.split('/')[-1].split('_')
    perturbed_parameter = split_file_name[0] if len(split_file_name) <= 4 else '_'.join(split_file_name[:4])
    perturbed_values = h5_data['info']['values'][()]
    frequency = h5_data['info']['frequency'][()]
    data_keys, num_keys = getDataKeys(h5_data)
    return h5_data, perturbed_parameter, perturbed_values, frequency, data_keys, num_keys

def makeDynamicsPlot(calcium_data, title, frequency):
    """
    Plot the Concentration over time.
    Arguments:  calcium_data, pandas DataFrame, all the Concentrations data
                title, str
                frequency, the sampling frequency
    Returns:    nothing
    """
    calcium_time = calcium_data['time']/frequency
    plt.plot(calcium_time, calcium_data['free_calcium'], color='red', label='Free Calcium')
    plt.plot(calcium_time, calcium_data['indicator_bound'], color='blue', label='Indicator Bound')
    plt.plot(calcium_time, calcium_data['endogeneous_bound'], color='grey', label='Endogeneous Bound')
    plt.plot(calcium_time, calcium_data['immobile_bound'], color='green', label='Immobile Bound')
    plt.plot(calcium_time, calcium_data['excited'], color='orange', label='Excited')
    plt.ylabel('Concentration (M)', fontsize="large")
    plt.legend(fontsize="large")
    plt.title(title, fontsize="large")
    return None

def saveOrShow(save_ext, file_prefix, image_dir):
    """
    For either saving a figure or showing it
    Arguments:  save_ext, str, the suffix or extension to the file.
                file_prefix, str
                h5_dir, str
    """
    filename = os.path.join(image_dir, file_prefix + save_ext)
    if save_ext == '':
        plt.show(block=False)
    else:
        plt.savefig(filename)
        print(dt.datetime.now().isoformat() + ' INFO: ' + 'Saved: ' + filename)
    return filename

def makeDynamicsComparisonPlot(perturbed_parameter, num_keys, data_keys, h5_data, perturbed_values, save_ext, h5_dir, frequency):
    """
    For making some kind of bad looking plot.
    Arguments:  perturbed_parameter, str, the name of the parameter
                num_keys, int
                data_keys, numpy array of strings
                h5_data, data from the h5 file.
                perturbed_values, the values that we used for the perturbed parameter
                save_ext, str
                h5_dir, str
                frequency,
    Returns:    filename str
    """
    file_prefix = '/calcium_dynamics/' + perturbed_parameter + '_peturbed_calcium_dynamics_'
    fig = plt.figure(figsize=(27,18))
    for i in range(num_keys):
        print(dt.datetime.now().isoformat() + ' INFO: ' + 'Plotting peturbation number ' + str(i) + '...')
        calcium_data = h5_data[data_keys[i]]['calcium']
        peturbed_value = perturbed_values[i]
        title = perturbed_parameter + '=' + str(perturbed_value)
        plt.subplot(num_keys, 1, i+1)
        makeDynamicsPlot(calcium_data, perturbed_parameter, perturbed_value, title, frequency)
    plt.suptitle('Dynamics Comparison', fontsize='large')
    plt.xlabel('Time (s)', fontsize='large')
    plt.tick_params(labelsize='large')
    plt.ticklabel_format(style='sci')
    filename = saveOrShow(save_ext, file_prefix, h5_dir)
    plt.close('all')
    return filename

def makeFluorescencePlot(axis, h5_data, time, data_key, colour, perturbing_factor):
    """
    For plotting some fluorescence.
    Arguments:  axis, matplotlib.pyplot axis
                h5_data, str,
                time, the experiment time (x-axis)
                data_key, for indexing into the h5_data
                colour, the colour of the plot
                perturbing_factor, the factor by which we multiply the experimental parameter value
    Returns:    nothing
    """
    model_fluoro = h5_data[data_key]['fluoro']['zscore_model'][()]
    axis.plot(time, model_fluoro, color=colour)
    perturbing_factor_str = str(perturbing_factor) if perturbing_factor < 1 else str(int(perturbing_factor))
    axis.text(x=time[-1]+1,y=0,s='x'+perturbing_factor_str, fontsize='x-large')
    (perturbing_factor == 1) and axis.set_ylabel(r'$\Delta F/F_0$', fontsize="x-large")
    axis.set_xlim((np.min(time), np.max(time)))
    axis.set_xticks([])
    axis.set_yticks([])
    [axis.spines[p].set_visible(False) for p in ['top', 'right', 'bottom', 'left']]
    return None

def makePowerPlot(h5_data, perturbed_parameter, frequencies, data_key, colour, perturbed_value):
    """
    Plotting the power Spectrum
    Arguments:  h5_data,
                perturbed_parameter, str
                frequencies, the x-axis
                data_key, the key for this particular perturbation
                colour, the colour for plotting
                perturbed_value, the value for this perturbation
    Returns:    nothing
    """
    model_power = h5_data[data_key]['power']['log_model'].value
    label = perturbed_parameter + '=' + str(perturbed_value)
    plt.plot(frequencies, model_power, color=colour, label=label)
    return None

def makeFluorescenceComparisonPlot(h5_data, num_keys, data_keys, perturbed_values, perturbed_parameter, frequency, colours, save_ext, h5_dir):
    """
    For making lots of fluorescence plots on the one figure. This will require some edits.
    Arguments:  h5_data, data from the h5 file
                num_keys, int
                data_keys, for indexing
                perturbed_values, assuming length 5, assuming middle value is experimental
                perturbed_parameter,
                frequency, sampling frequency
                colours, for plotting
                save_ext, suffix and file type for saving
                h5_dir, str
    Returns:    filename
    """
    param_to_title = {  'indicator':'Vary concentration of fluorescent indicator',
                        'immobile':'Vary concentration of slow endogeneous buffer',
                        'b_i_f_i':'Vary binding/unbinding rates of fluorescent indicator'}
    perturbed_values = perturbed_values[2*np.arange(5)] if perturbed_parameter == 'b_i_f_i' else perturbed_parameter
    spike_train = h5_data[data_keys[0]]['fluoro']['spike_train'][()]
    observed_fluoro = h5_data[data_keys[0]]['fluoro']['zscore_observed'][()]
    time = range(0, len(observed_fluoro))/frequency
    experiment_parameter_value = perturbed_values[2]
    perturbing_factors = (perturbed_values/experiment_parameter_value).round(2)
    fig, axes = plt.subplots(nrows=7, ncols=1, gridspec_kw={'height_ratios': [3,3,3,3,3,3,1],'hspace':0}, figsize=(8,5))
    plt.suptitle(param_to_title.get(perturbed_parameter), fontsize='x-large')
    axes[0].plot(time, observed_fluoro, color='green')
    axes[0].set_xlim((np.min(time), np.max(time)))
    axes[0].set_xticks([])
    axes[0].set_yticks([])
    [axes[0].spines[p].set_visible(False) for p in ['top', 'right', 'bottom', 'left']]
    axes[0].text(x=time[-1]+1,y=0,s='Data', fontsize='x-large')
    for axis, perturbing_factor, data_key, colour in zip(axes[1:-1], perturbing_factors, data_keys, colours):
        makeFluorescencePlot(axis, h5_data, time, data_key, colour, perturbing_factor)
    axes[-1].vlines(time[spike_train > 0], ymin=np.zeros(np.sum(spike_train>0)), ymax=spike_train[spike_train>0], color='blue')
    [axes[-1].spines[p].set_visible(False) for p in ['top', 'right', 'bottom', 'left']]
    axes[-1].set_xlim((np.min(time), np.max(time)))
    axes[-1].set_yticks([])
    axes[-1].set_ylabel('Spikes', fontsize='x-large')
    axes[-1].set_xlabel('Time (s)', fontsize='x-large')
    axes[-1].tick_params(axis='x', labelsize='large')
    ylims = np.array([axis.get_ylim()for axis in axes[:-1]])
    general_ylims = [ylims[:,0].min(),ylims[:,1].max()]
    [axis.set_ylim(general_ylims) for axis in axes[:-1]]
    plt.tight_layout()
    file_prefix = os.path.join('traces', perturbed_parameter, args.optimised, perturbed_parameter + '_perturbed_fluorescence_')
    filename = saveOrShow(save_ext, file_prefix, image_dir)
    plt.close('all')
    return filename

def makePowerComparisonPlot(h5_data, data_keys, perturbed_values, perturbed_parameter, colours, save_ext, h5_dir):
    """
    Make plot for comparing the power spectrum.
    Arguments:  h5_data, the data from the h5 file
                data_keys, for indexing in to the h5_data
                perturbed_values, the value for these perturbations
                perturbed_parameter, the paramter we perturbed
                colours, for plotting
                save_ext, file suffix and extension for saving
                h5_dir, str
    Returns:    filename
    """
    observed_power = h5_data[data_keys[0]]['power']['log_model'].value
    frequencies = h5_data[data_keys[0]]['power']['frequencies'].value
    fig = plt.figure(figsize=(18,7))
    plt.plot(frequencies, observed_power, color='green', label='Observed Power Spectrum')
    for k, c, v in zip(data_keys, colours, peturbed_values):
        makePowerPlot(h5_data, perturbed_parameter, frequencies, k, c, v)
    plt.xlabel('Frequency (Hz)', fontsize="large")
    plt.ylabel('Power (dB)', fontsize="large")
    plt.title('Power Spectrum Comparison', fontsize="large")
    plt.legend(fontsize="large")
    file_prefix = '/power/' + perturbed_parameter + '_perturbed_power_'
    filename = saveOrShow(save_ext, file_prefix, h5_dir)
    plt.close('all')
    return filename

def main():
    print(dt.datetime.now().isoformat() + ' INFO: ' + 'Starting main function...')
    print(dt.datetime.now().isoformat() + ' INFO: ' + 'Extracting data from h5_file: ' + args.h5_file + '...')
    h5_file = os.path.join(args.proj_h5_dir, args.h5_file)
    h5_data, perturbed_parameter, perturbed_values, frequency, data_keys, num_keys = extractH5Data(h5_file)
    # print(dt.datetime.now().isoformat() + ' INFO: ' + 'Making dynamics comparison plot...')
    # filename = makeDynamicsComparisonPlot(perturbed_parameter, num_keys, data_keys, h5_data, perturbed_values, args.save_ext, args.proj_h5_dir, frequency)
    # print(dt.datetime.now().isoformat() + ' INFO: ' + 'Calcium Dynamics image saved: ' + filename)
    colours = ['red', 'orangered', 'orange', 'gold', 'yellow']
    print(dt.datetime.now().isoformat() + ' INFO: ' + 'making fluorescence comparison figure...')
    filename = makeFluorescenceComparisonPlot(h5_data, num_keys, data_keys, perturbed_values, perturbed_parameter, frequency, colours, args.save_ext, args.proj_h5_dir)
    print(dt.datetime.now().isoformat() + ' INFO: ' + 'Fluorescence image saved: ' + filename)
    # print(dt.datetime.now().isoformat() + ' INFO: ' + 'making power comparison figure...')
    # filename = makePowerComparisonPlot(h5_data, data_keys, perturbed_values, perturbed_parameter, colours, args.save_ext, args.proj_h5_dir)
    # print(dt.datetime.now().isoformat() + ' INFO: ' + 'Power image saved: ' + filename)
    print(dt.datetime.now().isoformat() + ' INFO: ' + 'Done.')
    return None

if (__name__ == "__main__") & (not args.debug):
  main()
