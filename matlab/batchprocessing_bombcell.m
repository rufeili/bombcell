%% Batch processing KS output via Bombcell
% baseDir = 'C:\Users\RufeiLi\Documents\KS_output\'; % The root folder containing all sessions
baseDir = 'C:\Users\RufeiLi\Documents\KS_output\'
sessions = dir(fullfile(baseDir, 'catgt_*')); % Adjust wildcard to match your folder naming
%%
for i = 1:length(sessions)
    try
        % 1. Build paths for this specific session
        sessionPath = fullfile(sessions(i).folder, sessions(i).name);
        
        % Identify imec0_ks4 folder
        ephysKilosortPath = fullfile(sessionPath, [sessions(i).name(7:end), '_imec0'], 'imec0_ks4');
        
        % Check if path exists before proceeding
        if ~exist(ephysKilosortPath, 'dir')
            fprintf('Skipping %s: Kilosort path not found.\n', sessions(i).name);
            continue; 
        end
        
        % Identify Raw Binary and Meta Files
        rawFileStruct = dir(fullfile(sessionPath, [sessions(i).name(7:end), '_imec0'], '*tcat.imec0.ap.bin'));
        metaFileStruct = dir(fullfile(sessionPath, [sessions(i).name(7:end), '_imec0'], '*ap*.*meta'));
        
        if isempty(rawFileStruct) || isempty(metaFileStruct)
            fprintf('Skipping %s: Missing .bin or .meta files.\n', sessions(i).name);
            continue;
        end
        
        ephysRawFile = fullfile(rawFileStruct.folder, rawFileStruct.name);
        savePath = fullfile(ephysKilosortPath, 'bombcell_MAT');
        
        fprintf('Processing: %s\n', sessions(i).name);

        % 2. Load Data
        kilosortVersion = 4;
        gain_to_uV = NaN;
        [spikeTimes_samples, spikeClusters, templateWaveforms, templateAmplitudes, pcFeatures, ...
            pcFeatureIdx, channelPositions] = bc.load.loadEphysData(ephysKilosortPath, savePath);

        % 3. Set Parameters
        param = bc.qm.qualityParamValues(metaFileStruct, ephysRawFile, ephysKilosortPath, gain_to_uV, kilosortVersion);
        
        % Extract channel counts from Meta
        meta = bc.dependencies.SGLX_readMeta.ReadMeta(metaFileStruct.name, metaFileStruct.folder);
        [AP, ~, SY] = bc.dependencies.SGLX_readMeta.ChannelCountsIM(meta);
        param.nChannels = AP + SY;
        param.nSyncChannels = SY;
        param.ephys_sample_rate = 30000; 

        param.plotGlobal = 0;
        param.maxRPVviolations = 0.2;
        param.minNumSpikes = 100;

        % 4. Run Quality Metrics
        [qMetric, unitType] = bc.qm.runAllQualityMetrics(param, spikeTimes_samples, spikeClusters, ...
                templateWaveforms, templateAmplitudes, pcFeatures, pcFeatureIdx, channelPositions, savePath);
            
        fprintf('Successfully saved metrics to: %s\n', savePath);

    catch ME
        fprintf('Error processing session %s: %s\n', sessions(i).name, ME.message);
    end
end


%%
ephysKilosortPath = 'C:\Users\RufeiLi\Documents\KS_output\sorting_results_nblocks_redo\sorter_output'
ephysRawFile = "C:\Users\RufeiLi\Documents\KS_output\catgt_20260101_670-1L_d1_g0\20260101_670-1L_d1_g0_imec0\20260101_670-1L_d1_g0_tcat.imec0.ap.bin"; % path to your raw .bin or .dat data
ephysMetaDir = dir(['C:\Users\RufeiLi\Documents\KS_output\catgt_20260101_670-1L_d1_g0\20260101_670-1L_d1_g0_imec0\' '*ap*.*meta']); % path to your .meta or .oebin meta file
savePath = [ephysKilosortPath  filesep 'bombcell_MAT']; % where you want to save the quality metrics 

kilosortVersion = 4; % if using kilosort4, you need to have this value kilosertVersion=4. Otherwise it does not matter. 
gain_to_uV = NaN;

[spikeTimes_samples, spikeClusters, templateWaveforms, templateAmplitudes, pcFeatures, ...
    pcFeatureIdx, channelPositions] = bc.load.loadEphysData(ephysKilosortPath, savePath);

param = bc.qm.qualityParamValues(ephysMetaDir, ephysRawFile, ephysKilosortPath, gain_to_uV, kilosortVersion);

% param.nChannels = 385;
% param.nSyncChannels = 1;

% if using SpikeGLX, you can use this function: 
if ~isempty(ephysMetaDir)
    if endsWith(ephysMetaDir.name, '.ap.meta') %spikeGLX file-naming convention
        meta = bc.dependencies.SGLX_readMeta.ReadMeta(ephysMetaDir.name, ephysMetaDir.folder);
        [AP, ~, SY] = bc.dependencies.SGLX_readMeta.ChannelCountsIM(meta);
        param.nChannels = AP + SY;
        param.nSyncChannels = SY;
    end
end

param.plotGlobal = 0;
param.maxRPVviolations = 0.1;
param.minNumSpikes = 100;

% additionally, if you are using non-neuropixels probe, check the ephys
% sampling rate if correct:
param.ephys_sample_rate = 30000; % default, 30000 samples / s. 

[qMetric, unitType] = bc.qm.runAllQualityMetrics(param, spikeTimes_samples, spikeClusters, ...
        templateWaveforms, templateAmplitudes, pcFeatures, pcFeatureIdx, channelPositions, savePath);
