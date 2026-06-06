% 1. Define your parameters in a struct
userParams.maxRPVviolations = 0.2;
userParams.plotGlobal = 0;
userParams.minNumSpikes = 100;
userParams.ephys_sample_rate = 30000;

% 2. Convert the struct to a formatted JSON string
jsonText = jsonencode(userParams, 'PrettyPrint', true);

% 3. Save it directly to your desired folder
savePath = 'C:\Users\RufeiLi\Documents\MATLAB\bombcell\matlab\bombcell_config_20260606.json';
fid = fopen(savePath, 'w');
fwrite(fid, jsonText, 'char');
fclose(fid);

fprintf('JSON config safely created at: %s\n', savePath);

% Forcing the compiler to explicitly include an entire folder just in case
mcc -m run_bombcell_single.m -d 'C:\Users\RufeiLi\Documents\Bombcell_MAT_compiled' -a C:\path\to\bombcell\folder