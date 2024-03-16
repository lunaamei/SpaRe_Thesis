
cd /net/store/nbp/projects/wd_ride_village/Analysis/SpaReEEG_Luna/
savepath = '/net/store/nbp/projects/wd_ride_village/Analysis/SpaReEEG_Luna/ica_processed'
addpath = '/net/store/nbp/projects/wd_ride_village/Analysis/SpaReEEG_Luna/ica_processed'
% load EEGlab
addpath('/net/store/nbp/projects/wd_ride_village/Matlab-resources/eeglab2020_0');
addpath('/net/store/nbp/projects/wd_ride_village/Matlab-resources/preprocessing_helpers');
addpath('/net/store/nbp/projects/wd_ride_village/Matlab-resources/NoiseTools');

%addpath('/net/store/nbp/projects/EEG_Training/Analysis/eeglab14_1_1b');
addpath('/net/store/nbp/projects/wd_ride_village/Matlab-resources');
eeglab;

% Setting up filtering type and filtering frequency
filtType   ='acausal';	% how do you want to filter? Options: acausal or causal

%%

%% Preparations to load in the data

% Where is your data stored?
basepath= '/Users/lunameidoering/Uni/THESIS/feelSpacedata/preprocessing/Pilot3/';
% Where is your trigger file?
trgpath='/Users/lunameidoering/Uni/THESIS/feelSpacedata/GraphMaking/Output/'; %use the trigger file with GraphMaking info
%select data file to work on
cd(basepath)
%%
% this is for the second recording: cntfile = dir(subStr+'_v_'+'*'+'.xdf');  
% VS: Added the follwing line below to replace this for now as we have only 1 file:
cntfile = dir('sub-P003_ses-S001_task-Default_run-001_eeg.xdf'); % change for pilot 3!
cntpath = fullfile(basepath,cntfile.name);
if exist(cntpath,'file')
    [filepath,filename,ext] = fileparts(cntpath); % define variables to keep the same as the manual selection procedure
    filepath = [filepath filesep];
    filename = [filename ext];
end
%%
% Here, we create subfolder for each individual  (create a target folder)
uidname = '3'; % adjust so you don't overwrite files
mkdir(fullfile(savepath,sprintf('preprocessing_%s/',uidname)))
str = [savepath, sprintf('/preprocessing_%s/',uidname)];
savedata = join(str,''); % create new path for each individual subject  % create new path for each individual subject 

%% Loading in the XDF files
% Here, we define the Markerstreams to be excluded from loading in
excludeMrkrStrms={'BackupAlignment','GazeValidityCLR','TrialNumber','EyeTrackingPosDir','ObjectColliderBoundsCenter','TimeStampEndlsl','EyeOpennessLR','TimeStampBeginlsl','HitPointOnObject','HitObjectColliderName','Diode','PupilDiameterLR', 'openvibeMarkers', 'TimeStampGetVerboseData', 'hmdPosDirRot', 'bodyTrackerPosRot','CancelPressed', 'TriggerPressed', 'handPosDirRot'};
% Loading the XDF file from the recording
EEG = eeg_load_xdf(filename, 'streamname','openvibeSignal', 'exclude_markerstreams', excludeMrkrStrms);
%% Adjust SR (temporary solution)
% Pilot 3 SR = 1023.8
% Pilot 4 SR = 1023.975
EEG.srate = 1023.8; 

%% Correcting the channel / electrode names (double check if correct: depends on recording setup):
newchanlabels = importdata(fullfile('/Users/lunameidoering/Uni/THESIS/feelSpacedata/preprocessing/EEG-channel-names.txt'));
for n = 1:length(newchanlabels)
    EEG.chanlocs(n).labels = newchanlabels{n};
end
% Adjusting the channel locations for the specific setup we used for the recording:
EEG=pop_chanedit(EEG, 'lookup','/Users/lunameidoering/Uni/THESIS/feelSpacedata/preprocessing/standard-10-5-cap385.elp');
%% Inspect whether this worked. Compare with estimated begin and end of events
%eegplot(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event)

%% Clean empty channels - TODO exchange code - does nothing
% which channels do not contain EEG data by default?
alldel = {'BIP2' 'BIP3' 'BIP4' 'BIP5' 'BIP6' 'BIP7' 'BIP8' 'AUX1' 'AUX2' 'AUX3' 'AUX4' 'AUX5' 'AUX6' 'AUX7' 'CZ' 'IZ' 'TIME' 'L-GAZE-X' 'L-GAZE-Y' 'L-AREA' 'R-GAZE-X' 'R-GAZE-Y' 'R-AREA' 'L_GAZE_X' 'L_GAZE_Y' 'L_AREA', 'R_GAZE_X' 'R_GAZE_Y' 'R_AREA' 'INPUT' 'BIP65' 'BIP66' 'BIP67' 'BIP68'};
    
str=[];
delindex =[];
for k=1:numel(EEG.chanlocs)
    str{k}=EEG.chanlocs(k).labels;
    
    if strmatch(str{k},alldel)
        delindex(k)=1;
    else
        delindex(k)=0;
    end
end
delindex = find(delindex);
targetchannels = str(setdiff(1:length(str),delindex));



for k=1:numel(EEG.chanlocs)
    str{k}=EEG.chanlocs(k).labels;
    
end
%% Cleaning: which channels do not contain EEG data by default?
alldel = {'BIP1' 'BIP2' 'BIP3' 'BIP4' 'BIP5' 'BIP6' 'BIP7' 'BIP8' 'AUX1' 'AUX2' 'AUX3' 'AUX4' 'AUX5' 'AUX6' 'AUX7' 'Reference' 'AUX69' 'AUX70' 'AUX71' 'AUX72' 'INPUT' 'BIP65' 'BIP66' 'BIP67' 'BIP68'};
EEG = pop_select(EEG, 'nochannel', alldel);

str=[];
delindex =[];
for k=1:numel(EEG.chanlocs)
    str{k}=EEG.chanlocs(k).labels;
    
    if strmatch(str{k},alldel)
        delindex(k)=1;
    else
        delindex(k)=0;
    end
end
delindex = find(delindex);
targetchannels = str(setdiff(1:length(str),delindex));
%%
% eegplot(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event)
%% Intermediary saving setup to be able to return to and to understand earlier steps
%path = fullfile(savedata);
EEG = eeg_checkset(EEG);
EEG = pop_editset(EEG, 'setname', sprintf('0_%s_raw_cor',uidname));
EEG = pop_saveset(EEG, 'filename', sprintf('0_%s_raw_cor',uidname), 'filepath', char(fullfile(savedata)));

%% DOWNSAMPLING %%
% lower sampling rate from default (1024Hz) to 256Hz
%sr = 255.91646499259878;
sr = 256;
EEG = pop_resample(EEG, sr);

%% IMPORTANT: Run this part after correcting for the false sampling rate (EEG)!!!
% TODO change to correct trigger file
% adjust the 'fields' -  {'latency','type','saccade_amp'}
% Importing the respective trigger file from our trgpath
%EEG = pop_importevent(EEG,'event',fullfile(trgpath,'TriggerFile_Pilot3.csv'),'fields', {'latency','type','saccade_amp'}, 'skipline', 1);

EEG = pop_importevent(EEG,'event',fullfile(trgpath,'TriggerFile_pilot3_GraphMaking.csv'),'fields', {'latency', 'type', 'in_nodeRadius', 'closest_to_nodeCentroid','time_diff_normalized', 'node_1st_half', 'num_neighbours'}, 'skipline', 1);

% eegplot(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event)
%% make EEG file that is untouched for later use
trEEG=EEG;
%% Save files again
EEG = eeg_checkset(EEG);
EEG = pop_editset(EEG, 'setname', sprintf('1_%s_import_trg',uidname));
EEG = pop_saveset(EEG, 'filename', sprintf('1_%s_import_trg',uidname), 'filepath', char(fullfile(savedata)));

%% Applying high- and low-pass filtering:
% parameters adapted from Czeszumski, 2023 (Hyperscanning Maastricht)
low_pass = 123; %was: 100, set to 1/2 SR
high_pass = .1;

EEG = pop_eegfiltnew(EEG, high_pass, []); % 0.1 is the lower edge
EEG = pop_eegfiltnew(EEG, [], low_pass); % 100 is the upper edge
eegplot(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event)
%% remove line noise with zapline
zaplineConfig=[];
zaplineConfig.noisefreqs=49.97:.01:50.03; %49.97:.01:50.03; %Alternative: 'line'
EEG = clean_data_with_zapline_plus_eeglab_wrapper(EEG, zaplineConfig); EEG.etc.zapline

full_chanlocs = EEG.chanlocs; % used for channel cleaning and interpolation
%% Save files again
EEG = eeg_checkset(EEG);
EEG = pop_editset(EEG, 'setname', sprintf('2_%s_filtered',uidname));
EEG = pop_saveset(EEG, 'filename', sprintf('2_%s_filtered',uidname), 'filepath', char(fullfile(savedata)));
%% Load data
% if you wish to load the data
EEG = pop_loadset('filename', sprintf('2_%s_filtered.set',uidname), 'filepath', char(fullfile(savedata)));
%% ASR 
% Channel cleaning/removal, Data cleaning/removal
EEG = clean_artifacts(EEG); % From documentation: Use vis_artifacts to compare the cleaned data to the original.

% eegplot(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event)

% save removed channels
removed_channels = ~ismember({full_chanlocs.labels},{EEG.chanlocs.labels});
removed_channels = {full_chanlocs(removed_channels).labels}; %Pilot4: T8
%% Save files again
EEG = eeg_checkset(EEG);
EEG = pop_editset(EEG, 'setname', sprintf('3_%s_data_chan_cleaned',uidname));
EEG = pop_saveset(EEG, 'filename', sprintf('3_%s_data_chan_cleaned',uidname), 'filepath', char(fullfile(savedata)));

%TODO: save which channels were removed:
save('removed_channels.m','removed_channels');
%%
% laod data again
EEG = pop_loadset('filename', sprintf('3_%s_data_chan_cleaned.set',uidname), 'filepath', char(fullfile(savedata)));
% plot ERP image

%% ICA 
% high pass 2 Hz for data used for ICA calculations
eeg_tmp = pop_eegfiltnew(EEG, 2, []);   % highpass  2 Hz to not include slow drifts

%% create amica folder
% Old implementation
mkdir(fullfile(savedata,sprintf('ICA_amica_%s',uidname)))
addpath(fullfile(savedata,sprintf('ICA_amica_%s',uidname)))
outDir = fullfile(savedata, sprintf('ICA_amica_%s',uidname));
% Arturs implementation:
%cd '/Users/schmi/Documents/PhD_Osnabruck_University/SpaRe-VR/Spare-VR-EEG/Processed_automatic_Pipeline/preprocessed' % VS: hardcoded to first subject folder, needs to be adjusted for loop 
%mkdir(sprintf('ICA_amica_%s_%d',EEG.setname, sub))
%outDir = what(sprintf('ICA_amica_%s_%d',EEG.setname,sub));
%% Run ICA - takes a long time!!!
dataRank = rank(double(eeg_tmp.data'));
runamica15(eeg_tmp.data, 'num_chans', eeg_tmp.nbchan,'outdir', outDir,...
'numprocs', 1,...  % # nodes. When set to > 1, RUN_LOCALLY is set to 0
'max_threads', 3,... % Higher numbers appear to rather decrease the performance. Try 2 (default), 3 or 4 and see what predicts to finish fastest. For us 3 was working the most efficiently
'pcakeep', dataRank, 'num_models', 1);%,...
%'do_reject', 1, 'numrej', 15, 'rejsig', 3, 'rejint', 1);
%% Apply the ICA results
%load ICA results
%outDir = 'D:\Vincent_Workspace\matlab_processed\preprocessing_eeglab_pilot4_23_11_23';
mod = loadmodout15(outDir);

ica_path = '/Users/lunameidoering/Uni/THESIS/feelSpacedata/preprocessing/matlab_processed/preprocessing_3/ICA_amica_3'
       
%apply ICA weights to data
EEG.icasphere = mod.S;
EEG.icaweights = mod.W;
EEG = eeg_checkset(EEG);
% save again 
EEG = eeg_checkset(EEG);
EEG = pop_editset(EEG, 'setname', sprintf('4b_%s_ica',uidname));
EEG = pop_saveset(EEG, 'filename', sprintf('4b_%s_ica',uidname), 'filepath', char(fullfile(savedata)));


%%
% laod data again
uidname = '3'
savedata = '/net/store/nbp/projects/wd_ride_village/Analysis/SpaReEEG_Luna/preprocessing_3/'
EEG = pop_loadset('filename', sprintf('4b_%s_ica.set',uidname), 'filepath', char(fullfile(savedata)));


%% Reject noisy components
% calculate iclabel classification
EEG = iclabel(EEG);
pop_viewprops(EEG,0)
% list components that should be rejected
components_to_remove = [];
number_components = size(EEG.icaact,1);
%%        
for component = 1:number_components
    % muscle
    if EEG.etc.ic_classification.ICLabel.classifications(component,2) > .80
        components_to_remove = [components_to_remove component];
    end
    % eye
    if EEG.etc.ic_classification.ICLabel.classifications(component,3) > .9
        components_to_remove = [components_to_remove component];
    end
    % heart
    if EEG.etc.ic_classification.ICLabel.classifications(component,4) > .9
        components_to_remove = [components_to_remove component];
    end
    % line noise
    if EEG.etc.ic_classification.ICLabel.classifications(component,5) > .9
        components_to_remove = [components_to_remove component];
    end
    % channel noise
    if EEG.etc.ic_classification.ICLabel.classifications(component,6) > .9
        components_to_remove = [components_to_remove component];
    end
end
        
% remove components
EEG = pop_subcomp(EEG, components_to_remove, 0);
% save removed components in struct
removed_components = components_to_remove;
%% Save files again
EEG = eeg_checkset(EEG);
EEG = pop_editset(EEG, 'setname', sprintf('4_%s_ica',uidname));
EEG = pop_saveset(EEG, 'filename', sprintf('4_%s_ica',uidname), 'filepath', char(fullfile(savedata)));

%TODO: save which components were removed:
save('removed_components.m','removed_components');        
%% interpolate removed channels
EEG = pop_interp(EEG, full_chanlocs,'spherical');
%% Save files again
EEG = eeg_checkset(EEG);
EEG = pop_editset(EEG, 'setname', sprintf('5_%s_interpolation',uidname));
EEG = pop_saveset(EEG, 'filename', sprintf('5_%s_interpolation',uidname), 'filepath', char(fullfile(savedata)));
%%
function pluginpath = activate_matconvnet()
% get path information
pluginpath = fileparts(which('pop_iclabel'));
if ~exist(['vl_nnconv.', mexext()], 'file')
    addpath(fullfile(pluginpath, 'matconvnet', 'matlab'));
    vl_setupnn();
end
end

%%
% pop_erpimage(EEG.data,'srate',EEG.srate,'eloc_file',EEG.chanlocs,'events',EEG.event)