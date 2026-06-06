function run_bombcell_single(sessionPath, configFilePath)
    % Convert inputs from terminal strings
    if ischar(sessionPath) || isstring(sessionPath)
        sessionPath = char(sessionPath);
    end
    if ischar(configFilePath) || isstring(configFilePath)
        configFilePath = char(configFilePath);
    end
    
    fprintf('Starting Bombcell Processing for: %s\n', sessionPath);
    fprintf('Loading parameters from: %s\n', configFilePath);
    
    % Read and decode the JSON configuration file
    rawText = fileread(configFilePath);
    userParams = jsondecode(rawText);
    
    % Identify imec0_ks4 folder
    [~, sessionName, ~] = fileparts(sessionPath);
    ephysKilosortPath = fullfile(sessionPath, [sessionName(7:end), '_imec0'], 'imec0_ks4');
    
    if ~exist(ephysKilosortPath, 'dir')
        error('Kilosort path not found: %s', ephysKilosortPath);
    end
    
    % Identify Raw Binary and Meta Files
    rawFileStruct = dir(fullfile(sessionPath, [sessionName(7:end), '_imec0'], '*tcat.imec0.ap.bin'));
    metaFileStruct = dir(fullfile(sessionPath, [sessionName(7:end), '_imec0'], '*ap*.*meta'));
    
    if isempty(rawFileStruct) || isempty(metaFileStruct)
        error('Missing .bin or .meta files in: %s', sessionPath);
    end
    
    ephysRawFile = fullfile(rawFileStruct(1).folder, rawFileStruct(1).name);
    savePath = fullfile(ephysKilosortPath, 'bombcell_MAT');
    
    % Ensure the save directory exists so we can save the config file into it
    if ~exist(savePath, 'dir')
        mkdir(savePath);
    end
    
    % --- SAVE CONFIGURATION BACKUP ---
    % Copy the JSON file directly into the output folder for reproducibility
    backupConfigPath = fullfile(savePath, 'run_config.json');
    copyfile(configFilePath, backupConfigPath);
    fprintf('Saved configuration backup to: %s\n', backupConfigPath);

    % Load Data
    kilosortVersion = 4;
    gain_to_uV = NaN;
    [spikeTimes_samples, spikeClusters, templateWaveforms, templateAmplitudes, pcFeatures, ...
        pcFeatureIdx, channelPositions] = bc.load.loadEphysData(ephysKilosortPath, savePath);
    
    % Set Base Parameters
    param = bc.qm.qualityParamValues(metaFileStruct(1), ephysRawFile, ephysKilosortPath, gain_to_uV, kilosortVersion);
    meta = bc.dependencies.SGLX_readMeta.ReadMeta(metaFileStruct(1).name, metaFileStruct(1).folder);
    [AP, ~, SY] = bc.dependencies.SGLX_readMeta.ChannelCountsIM(meta);
    
    % Inject Hardware Constants
    param.nChannels = AP + SY;
    param.nSyncChannels = SY;
    
    % --- INJECT DYNAMIC JSON PARAMETERS ---
    % Overwrite default parameters with the ones provided in your config file
    param.maxRPVviolations = userParams.maxRPVviolations;
    param.minNumSpikes = userParams.minNumSpikes;
    param.plotGlobal = userParams.plotGlobal;
    param.ephys_sample_rate = userParams.ephys_sample_rate;
    
    % Run Quality Metrics
    [qMetric, unitType] = bc.qm.runAllQualityMetrics(param, spikeTimes_samples, spikeClusters, ...
            templateWaveforms, templateAmplitudes, pcFeatures, pcFeatureIdx, channelPositions, savePath);
        
    fprintf('Successfully completed. Metrics saved to: %s\n', savePath);
end