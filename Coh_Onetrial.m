
% quick script to display coherence between button press data and time-domain EEG
% for one example participant, and block.
cd('/Users/MattDavidson')
ippant = 1; % participant to consider
dayis= 1; %day of experimentation to consider.
iblock = 1; % block to consider.

% set up directories;
% change working directory to home
try cd('/Volumes/TOSHIBA EXT/XM_Project');
catch
    cd('Desktop/XM_Project');
end
homedir = pwd; % current location
behavdata = [pwd filesep 'DATA_newhope']; % behavioural data directory.
blockEEGdata = [pwd filesep 'EEGData' filesep 'DATA' filesep ...
    'Processed' filesep 'EEG_from_Attention_XmodalEXP' filesep...
     'pre NYE break j2_AllchanEpoched']; % eeg data dir.


% loop through

% for ippant = 1
cd(homedir);

%% collect behavioural data
cd(behavdata); 

%all participants folders this directory:
ppantdirs = dir([pwd filesep '*Day' num2str(dayis) '_Attn' '*']);

%look at first participant folder,
ppantbehdir = ppantdirs(ippant).name;
cd(ppantbehdir);

%Grab participant initials to be sure we have correct EEG
pinitials = ppantbehdir(1:2);

%find relevant block data
tmp_blockdata = dir([pwd filesep 'Block' num2str(iblock) 'Exp' '*.mat']);
%load data for this file
load(tmp_blockdata.name, 'blockout');
%
rivalrydata = blockout.rivTrackingData(:,1:2); % 3rd column is timestamps
rivalrytrace = rivalrydata(:,2) - rivalrydata(:,1);

%so now we have the rivalry data for this participant. 
%-1 is left button pressed, +1 = right button pressed.
%For all trials, left button for participants = green colour. To know
%whether this was also the low frequency, check the block data.
Lefteyecond = blockout.LeftEyeSpeed;
 
%'L' for low flicker.

%% collect EEG data:
cd(blockEEGdata)
%find relevant participant folder
ppantEEGdir = dir([pwd filesep 'ppant*' pinitials]);
cd(ppantEEGdir.name)
%load correct EEG data.
tmp_eegdata= dir([pwd filesep 'BLOCK(' num2str(iblock) ')_day' num2str(dayis) '*.mat']);
%load data
load(tmp_eegdata.name);

%NB:
%the EEG data for all channels is in:
%'allchanseachblock_ds'. This has 68 channels (first 64 are eeg). last 4
%are photodiodes and physical stimulus, capturing the tones themselves.
%sampling rate is 250 Hz.
Fs=250;

%if you want to look at the data in a specific frequency band, download the
%chronux toolbox: chronux.org.

%Thenyou can look at the spectrogram of this channel:
paramsforspectrogram.Fs=Fs;
paramsforspectrogram.tapers = [1,1];
paramsforspectrogram.pad=0;
movingwin = [2, .5]; % in seconds.

%note that first 5 seconds of data are pre-experiment.
startat = [0:1/250:5]; %i.e. 180 seconds of EEG data, but blocks were 175 seconds.

%to view the time-domain data for a single channel:
lookatchannel = 64; %PO8
singlechan=squeeze(allchanseachblock_ds(lookatchannel,length(startat):end));



[spec_TF, time_TF, freq_TF] = mtspecgramc(singlechan, movingwin, paramsforspectrogram);

logspec= log(spec_TF);
%% %%%%%%%% 
% %%%%%%%% 
% %%%%%%%%              PLOTTING 
% %%%%%%%% 


% See the behavioural rivalry data this trial:
figure(1);subplot(411);
xaxis_beh = blockout.rivTrackingData(:,3);
plot(xaxis_beh, rivalrytrace); 
ylim([-1.5 1.5]); 
xlim([0 180])
xlabel('seconds');
title(['Particpant ' pinitials ', day ' num2str(dayis) ' block ' num2str(iblock) ', button press data']) 
set(gca, 'ytick', [-1 1], 'yticklabels',{['Flicker speed =' Lefteyecond], 'Other eye'})



figure(1);subplot(412);
xaxis_eeg = [1:length(singlechan)] /Fs;
plot(xaxis_eeg, singlechan);
xlim([0 180]);
xlabel('seconds')
title(['EEG at channel ' num2str(lookatchannel) ' (time-domain)'])


%we can plot the time-frequency representation:
subplot(413);
imagesc(time_TF, freq_TF, logspec');
c=colorbar;
ylabel(c, 'power')
caxis([0 5])
colormap('viridis')
axis xy
ylim([0 25]); 
ylabel('Frequency [Hz]')
xlabel('seconds')
title( ['EEG at channel ' num2str(lookatchannel) ' (time-freq)'])

%or just spectrum (averaged over all time points)
meanspec =squeeze(nanmean(logspec,1));
subplot(414)
plot(freq_TF, meanspec);
xlabel('Frequency [Hz]')
ylim([2 6])
xlim([0 55])

%adding labels to the frequency tags:
fid=dsearchn(freq_TF', [4.5, 20, 50]');
labelas={'F1', 'F2', 'linenoise'};
for findex=1:3
    hold on
    text(freq_TF(fid(findex)), meanspec(fid(findex))+.1, labelas{findex})
end
title(['EEG at channel ' num2str(lookatchannel) ' (spectrum)'])

%% From here. Look at the coherence between EEG data and the behavioural data.
%resample entire data to same length:

%resample to 250 Hz (for both)
resamp_Fs= 250; % hz


%Behaviour:
% linspX= linspace(0,1,length(rivalrytrace));
linspX= 0:length(rivalrytrace); 
rs_beh = resample(rivalrytrace, linspX, resamp_Fs*length(linspX))'; 

%EEG (already at 250 Hz).
% linspX= linspace(0,1,length(singlechan));
% rs_EEG = resample(singlechan, linspX, resamp_Fs); 

% now we can plot both together:
figure(2); 
subplot(211)
plot(rs_beh, 'b'); title('resampled behaviour')
subplot(212)
hold on
plot(rs_EEG, 'r'); title('resampled EEG')

%% check coherence between signals.
paramsare.Fs=1000;
paramsare.tapers = [5 ,9];
[C,phi, S12, S1, S2, f ]= coherencyc(rs_beh, rs_EEG, paramsare);
%%
%sorry I'm out of time - shoot me or Nao an email if you get stuck at this
%stage! 
%type 'help coherencyc' for using this function (chronux toolbox also).
