%% Optimized Batch processing KS output via Bombcell using Parallel Pools
baseDir = 'C:\Users\RufeiLi\Documents\KS_output\'; 
sessions = dir(fullfile(baseDir, 'catgt_*')); 

% 1. Automatically start or check your local parallel pool
currentPool = gcp('nocreate');
if isempty(currentPool)
    % Dynamically starts a pool matching your local machine's core capabilities
    parpool('local'); 
end

%% Run the pipeline across sessions in parallel
% Changed 'for' to 'parfor' to distribute sessions across workers
parfor i = 1:length(sessions)
    try
        % Extract current session properties into local variables (Sliced variables)
        currentSessionName = sessions(i).name;
        currentSessionFolder = sessions(i).folder;
        
        % 1. Build paths for this specific session
        sessionPath = fullfile(currentSessionFolder, currentSessionName);
        
        % Identify imec0_ks4 folder
        ephysKilosortPath = fullfile(sessionPath, [currentSessionName(7:end), '_imec0'], 'imec0_ks4');
        
        % Replaced 'continue' statements with nested 'if' blocks
        if exist(ephysKilosortPath, 'dir')
            
            % Identify Raw Binary and Meta Files
            rawFileStruct = dir(fullfile(sessionPath, [currentSessionName(7:end), '_imec0'], '*tcat.imec0.ap.bin'));
            metaFileStruct = dir(fullfile(sessionPath, [currentSessionName(7:end), '_imec0'], '*ap*.*meta'));
            
            if ~isempty(rawFileStruct) && ~isempty(metaFileStruct)
                
                ephysRawFile = fullfile(rawFileStruct(1).folder, rawFileStruct(1).name);
                savePath = fullfile(ephysKilosortPath, 'bombcell_MAT');
                
                fprintf('Starting Parallel Processing on: %s\n', currentSessionName);
                
                % 2. Load Data
                kilosortVersion = 4;
                gain_to_uV = NaN;
                [spikeTimes_samples, spikeClusters, templateWaveforms, templateAmplitudes, pcFeatures, ...
                    pcFeatureIdx, channelPositions] = bc.load.loadEphysData(ephysKilosortPath, savePath);
                
                % 3. Set Parameters
                param = bc.qm.qualityParamValues(metaFileStruct(1), ephysRawFile, ephysKilosortPath, gain_to_uV, kilosortVersion);
                
                % Extract channel counts from Meta
                meta = bc.dependencies.SGLX_readMeta.ReadMeta(metaFileStruct(1).name, metaFileStruct(1).folder);
                [AP, ~, SY] = bc.dependencies.SGLX_readMeta.ChannelCountsIM(meta);
                
                % Create a unique, local parameter structure for this specific worker
                localParam = param;
                localParam.nChannels = AP + SY;
                localParam.nSyncChannels = SY;
                localParam.ephys_sample_rate = 30000; 
                localParam.plotGlobal = 0;
                localParam.maxRPVviolations = 0.2;
                localParam.minNumSpikes = 100;
                
                % 4. Run Quality Metrics
                [qMetric, unitType] = bc.qm.runAllQualityMetrics(localParam, spikeTimes_samples, spikeClusters, ...
                        templateWaveforms, templateAmplitudes, pcFeatures, pcFeatureIdx, channelPositions, savePath);
                    
                fprintf('Successfully saved metrics to: %s\n', savePath);
            else
                fprintf('Skipping %s: Missing .bin or .meta files.\n', currentSessionName);
            end
        else
            fprintf('Skipping %s: Kilosort path not found.\n', currentSessionName);
        end
        
    catch ME
        % In parfor, errors are captured locally without crashing the entire batch
        fprintf('Error processing session %s: %s\n', sessions(i).name, ME.message);
    end
end