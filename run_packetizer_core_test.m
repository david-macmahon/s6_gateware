function run_packetizer_core_test()

  % Get ntime
  ntime = eval(get_param('packetizer_core', 'StopTime'));

  % Setup simin variable
  %
  % Column  1 is `time` (can be discontinuous!)
  % Column  2 is `sync_in`
  % Column  3 is `tx_enable`
  % Column  4 is `din`
  simin = zeros(ntime, 3);
  simin(:, 1) = 1:ntime;
  simin(2, 2) = 1;
  simin(8:end, 3) = 1;
  simin(1:2,   4) = hex2dec('E000000000000'); % invalid/don't care value
  simin(3:end, 4) = (mod([0:ntime-3],256)*2  )*2^40 + mod(floor([0:ntime-3]/256),128)*2^32 ...
                  + (mod([0:ntime-3],256)*2+1)*2^8  + mod(floor([0:ntime-3]/256),128);

  % Setup dstin variable
  %
  % Column 1 in `time`
  % Column 2 through 33 are dest_ip addresses
  dstin = zeros(1, 33);
  dstin(2:33) = hex2dec('0a0a0a00') + [1:32];
  dstin(3) = 0;

  % Get model workspace and assign simin
  ws = get_param('packetizer_core', 'ModelWorkspace');
  ws.assignin('simin', simin);
  ws.assignin('dstin', dstin);

  % Run workspace and get sim outputs
  simout = sim('packetizer_core', 'ReturnWorkspaceOutputs', 'on');

  %% Get output
  %dout0 = simout.get('dout0');
  %dv0   = simout.get('dv0');

  %% Find first dv0
  %s=find(dv0, 1,);

  %% Get 64 x 512 rows from out
  %dout = out([1:64*512]+s,:);

  %% Print first 4 rows of dout
  %fprintf('s%03d c%03d  s%03d c%03d\n', dout(1:4,:)');
end
