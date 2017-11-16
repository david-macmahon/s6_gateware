function dout = run_transpose_core_test()

  % Get ntime
  ntime = eval(get_param('transpose_core', 'StopTime'));

  % Setup simin variable
  %
  % Column  1 is `time` (can be discontinuous!)
  % Column  2 is `sync_in`
  % Column  3 is `in0`
  % Column  4 is `in1`
  simin = zeros(ntime, 3);
  simin(:, 1) = 1:ntime;
  simin(2, 2) = 1;
  %simin(3, 3) = 8*17 * 2^32 + 9*17; % put 0000008800000099 in first word
  simin(1:2,   3) = hex2dec('E000000000000'); % invalid/don't care value
  %simin(3:end, 3) = [0:ntime-3]*2*2^32 + [0:ntime-3]*2+1;
  simin(3:end, 3) = floor([0:ntime-3]/64)*2^40 + mod([0:ntime-3],64)*2*2^32 ...
                  + floor([0:ntime-3]/64)*2^8  + mod([0:ntime-3],64)*2+1;

  % Get model workspace and assign simin
  ws = get_param('transpose_core', 'ModelWorkspace');
  ws.assignin('simin', simin);

  % Run workspace and get sim outputs
  simout = sim('transpose_core', 'ReturnWorkspaceOutputs', 'on');

  % Get output
  sync = simout.get('sync');
  out  = simout.get('out');

  % Find last sync (should be same as first sync)
  s=find(sync, 1, 'last');

  % Get 64 x 512 rows from out
  dout = out([1:64*512]+s,:);

  % Print first 4 rows of dout
  fprintf('s%03d c%03d  s%03d c%03d\n', dout(1:4,:)');
end
