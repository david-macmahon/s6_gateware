% This script expects a 256 sample window times 16 taps
function out = run_pfb_fir_core_test()

  % Setup simin variable
  %
  % Column  1 is `time` (can be discontinuous!)
  % Column  2 is `sync_in`
  % Column  3 is `in0`
  % Column  4 is `in1`
  ntime_expr = '2^(8-2) * 16 + 100';
  ntime = eval(ntime_expr);
  simin = zeros(ntime, 4);
  simin(:, 1) = 1:ntime;
  simin(2, 2) = 1;
  simin(2+[1:2^(8-2)], 3) = 127*hex2dec('01010101');

  % Get model workspace and assign simin
  set_param('pfb_fir_core', 'StopTime', ntime_expr);
  ws = get_param('pfb_fir_core', 'ModelWorkspace');
  ws.assignin('simin', simin);

  % Run workspace and get sim outputs
  simout = sim('pfb_fir_core', 'ReturnWorkspaceOutputs', 'on');

  % Get output
  sync = simout.get('sync');
  out0 = simout.get('out0');

  % Find last sync (should be same as first sync, which should be 1).
  s=find(sync, 1, 'last');

  % Sync goes high just before last window, so subtract T-1 windows
  % to get back to the start of the output.
  s = s - 256/4 * (16-1);

  % Get first 16 windows of 256 samples from out0 (after last
  % sync) and reshape such that each window is a column.
  % The simulation sets out0 to have four columns, with each row
  % containing 4 consecutive time samples, we want 16 columes,
  % with each column being 256 continuous time samples.
  out=reshape(out0([1:256*16/4]+s,:).',256,16);

  % Reverse the order of each time window to get back to original
  % coefficients ordering (basically, un-reverse the convolution ordering).
  % then rearrange into a single dimension.
  out = reshape(flipud(out), 1, []);

  % Plot the output
  plot(out);
end
