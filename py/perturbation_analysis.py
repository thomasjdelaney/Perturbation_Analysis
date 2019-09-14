##########################################################################################################
##
##  For making the figures doing analysis on the peturbation results.
##
##  python py/peturbation_analysis.py --h5_file indicator_8_2.h5 --save_ext 8_2.png --debug
##
##########################################################################################################

import os
execfile(os.environ["PYTHONSTARTUP"])
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import getopt
import h5py
import logging as lg

lg.basicConfig(level=lg.INFO, format="%(asctime)s %(levelname)s: %(message)s", datefmt="%Y-%m-%d %H:%M:%S")

def init_params():
  proj_h5_dir = os.environ["SPACE"] + "/h5/"
  params = {  "proj_h5_dir"   :   proj_h5_dir,
              "h5_file"       :   proj_h5_dir + "indicator_8_18.h5",
              "save_ext"      :   "",
              "debug"         :   False   } # defaults
  command_line_options = ['help', 'proj_h5_dir=', 'h5_file=', 'save_ext=', 'debug']
  opts, args = getopt.getopt(sys.argv[1:], "h:p:f:t:s:d", command_line_options)
  for opt, arg in opts:
    if opt in ('h', '--help'):
      print"python py/peturbation_analysis.py --proj_h5_dir <project h5 directory> --h5_file <hdf5 file> --save_ext <filename> --debug"
      print"python py/peturbation_analysis.py --h5_file indicator_8_2.h5 --save_ext figure_name.png --debug"
      sys.exit()
    elif opt in ('-p', '--proj_h5_dir'):
      params['proj_h5_dir'] = arg
    elif opt in ('-f', '--h5_file'):
      params['h5_file'] = params['proj_h5_dir'] + arg
    elif opt in ('-s', '--save_ext'):
      params['save_ext'] = arg
    elif opt in ('-d', '--debug'):
      params['debug'] = True
  return params

def getDataKeys(h5_data):
  data_keys = np.array(h5_data.keys())
  data_keys = data_keys[['info' != k for k in data_keys]]
  num_keys = len(data_keys)
  return data_keys, num_keys

def extractH5Data(h5_file):
  h5_data = h5py.File(h5_file, 'r')
  peturbed_parameter = h5_file.split('/')[-1].split('_')[0]
  peturbed_values = h5_data['info']['values'].value
  frequency = h5_data['info']['frequency'].value
  data_keys, num_keys = getDataKeys(h5_data)
  return h5_data, peturbed_parameter, peturbed_values, frequency, data_keys, num_keys

def makeDynamicsPlot(calcium_data, peturbed_parameter, peturbed_value, title, frequency):
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

def saveOrShow(save_ext, file_prefix, h5_dir):
  filename = h5_dir.replace('h5', 'Perturbation_Analysis/images') + file_prefix + save_ext
  if save_ext == "":
    plt.show(block=False)
  else:
    plt.savefig(filename)
  return filename

def makeDynamicsComparisonPlot(peturbed_parameter, num_keys, data_keys, h5_data, peturbed_values, save_ext, h5_dir, frequency):
  file_prefix = '/calcium_dynamics/' + peturbed_parameter + '_peturbed_calcium_dynamics_'
  fig = plt.figure(figsize=(27,18))
  for i in xrange(0, num_keys):
    lg.info('plotting peturbation number ' + str(i) + '...')
    calcium_data = h5_data[data_keys[i]]['calcium']
    peturbed_value = peturbed_values[i]
    title = peturbed_parameter + "=" + str(peturbed_value)
    plt.subplot(num_keys, 1, i+1)
    makeDynamicsPlot(calcium_data, peturbed_parameter, peturbed_value, title, frequency)
  plt.suptitle("Dynamics Comparison", fontsize="large")
  plt.xlabel('Time (s)', fontsize="large")
  plt.tick_params(labelsize="large")
  plt.ticklabel_format(style="sci")
  filename = saveOrShow(save_ext, file_prefix, h5_dir)
  plt.close('all')
  return filename

def makeFluorescencePlot(h5_data, peturbed_parameter, time, data_key, colour, peturbed_value):
  model_fluoro = h5_data[data_key]['fluoro']['zscore_model'].value
  label=peturbed_parameter + '=' + str(peturbed_value)
  plt.plot(time, model_fluoro, color=colour, label=label)
  plt.ylabel(r'$\Delta F/F_0$', fontsize="large")
  plt.xlim((np.min(time), np.max(time)))
  plt.legend(fontsize="large")
  return None

def makePowerPlot(h5_data, peturbed_parameter, frequencies, data_key, colour, peturbed_value):
  model_power = h5_data[data_key]['power']['log_model'].value
  label = peturbed_parameter + '=' + str(peturbed_value)
  plt.plot(frequencies, model_power, color=colour, label=label)
  return None

def makeFluorescenceComparisonPlot(h5_data, num_keys, data_keys, peturbed_values, peturbed_parameter, frequency, colours, save_ext, h5_dir):
  spike_train = h5_data[data_keys[0]]['fluoro']['spike_train'].value
  observed_fluoro = h5_data[data_keys[0]]['fluoro']['zscore_observed'].value
  time = range(0, len(observed_fluoro))/frequency
  fig = plt.figure(figsize=(27,21))
  plt.subplot(num_keys+1, 1, 1)
  plt.title('Fluorescence Comparison', fontsize="large")
  plt.plot(time, spike_train-2, color='black', label='Spike Train')
  plt.plot(time, observed_fluoro, color='violet', label='Observed Fluorescence')
  plt.ylabel(r'$\Delta F/F_0$', fontsize="large")
  plt.xlim((np.min(time), np.max(time)))
  plt.legend(fontsize="large")
  for k, c, v, p in zip(data_keys, colours, peturbed_values, range(2, num_keys+2)):
    plt.subplot(num_keys+1, 1, p)
    plt.plot(time, spike_train-2, color='black', label='Action Potentials')
    makeFluorescencePlot(h5_data, peturbed_parameter, time, k, c, v)
  plt.xlabel('Time (s)', fontsize="large")
  plt.legend(fontsize="large")
  file_prefix = '/traces/' + peturbed_parameter + '_peturbed_fluorescence_'
  filename = saveOrShow(save_ext, file_prefix, h5_dir)
  plt.close('all')
  return filename

def makePowerComparisonPlot(h5_data, data_keys, peturbed_values, peturbed_parameter, colours, save_ext, h5_dir):
  observed_power = h5_data[data_keys[0]]['power']['log_model'].value
  frequencies = h5_data[data_keys[0]]['power']['frequencies'].value
  fig = plt.figure(figsize=(18,7))
  plt.plot(frequencies, observed_power, color='violet', label='Observed Power Spectrum')
  for k, c, v in zip(data_keys, colours, peturbed_values):
    makePowerPlot(h5_data, peturbed_parameter, frequencies, k, c, v)
  plt.xlabel('Frequency (Hz)', fontsize="large")
  plt.ylabel('Power (dB)', fontsize="large")
  plt.title('Power Spectrum Comparison', fontsize="large")
  plt.legend(fontsize="large")
  file_prefix = '/power/' + peturbed_parameter + '_perturbed_power_'
  filename = saveOrShow(save_ext, file_prefix, h5_dir)
  plt.close('all')
  return filename

def main():
  lg.info('Starting main function...')
  params = init_params()
  if params['debug']:
    lg.info('Entering debug mode.')
    return None
  lg.info('extracting data from h5_file: ' + params['h5_file'] + '...')
  h5_data, peturbed_parameter, peturbed_values, frequency, data_keys, num_keys = extractH5Data(params['h5_file'])
  lg.info('making dynamics comparison plot...')
  filename = makeDynamicsComparisonPlot(peturbed_parameter, num_keys, data_keys, h5_data, peturbed_values, params['save_ext'],params['proj_h5_dir'], frequency) 
  lg.info('Calcium Dynamics image saved: ' + filename)
  colours = ['aqua', 'mediumaquamarine', 'green', 'lime', 'yellow']
  lg.info('making fluorescence comparison figure...')
  filename = makeFluorescenceComparisonPlot(h5_data, num_keys, data_keys, peturbed_values, peturbed_parameter, frequency, colours, params['save_ext'], params['proj_h5_dir'])
  lg.info('Fluorescence image saved: ' + filename)
  lg.info('making power comparison figure...')
  filename = makePowerComparisonPlot(h5_data, data_keys, peturbed_values, peturbed_parameter, colours, params['save_ext'], params['proj_h5_dir'])
  lg.info('Power image saved: ' + filename)
  lg.info('Done')
  return None

if __name__ == "__main__":
  main()

