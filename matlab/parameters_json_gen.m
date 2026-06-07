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
apptainer run --bind /share/software/user/restricted/matlab/R2023b:/opt/matlab_runtime \
bombcell_pipeline.sif \
'/scratch/users/rufeili/KS4_Output_Done/catgt_20251231_670-2L_d1_g3' \
'/home/groups/giocomo/rufeili/useful_files/bombcell_config_20260606.json'