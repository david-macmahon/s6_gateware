% This script expects a 256 sample window times 16 taps
function [ din, dout ] = run_fft_casper_test()

  % Setup simin variable
  %
  % Column  1 is `time` (can be discontinuous!)
  % Column  2 is `sync_in`
  % Column  3 is `in0`
  % Column  4 is `in1`
  ntime_expr = '2^(8-2) * 16 * 200 + 1000';
  ntime = eval(ntime_expr);
  nwin = 16*200;
  simin = zeros(ntime, 4);
  simin(:, 1) = 1:ntime;
  simin(2, 2) = 1;
  % Create nwin windows of Gaussian noise with rms=20/128.
  noise = round(20*randn(nwin*256/4, 4)) / 128;
  % Pack four samples into one value
  noise_in = noise(:,1)*2^24 + noise(:,2)*2^16 + noise(:,3)*2^8 + noise(:,4);
  simin(2+[1:length(noise_in)], 3) = noise_in;

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

  % Get first nwin windows of 256 samples from out0 (after last
  % sync) and reshape such that each window is a column.
  % The simulation sets out0 to have four columns, with each row
  % containing 4 consecutive time samples, we want 16 columes,
  % with each column being 256 continuous time samples.
  dout=reshape(out0([1:256*nwin/4]+s,:).', 256, nwin);

  % Reshape input noise to be nwin windows of 256 samples
  din = reshape(noise.', 256, nwin);

%  % Correlate input window 8 with output windows
%  w = 8
%  fw = fft(noise(:, w));
%  fww = fw.*conj(fw);
%  corr_coeff = zeros(256, 32);
%  for k = 1:32
%    fo = fft(outw(:, k));
%    foo = fo.*conj(fo);
%    corr_coeff(:,k) = fw.*conj(fo) ./ (fww.*foo).^0.5
%  end
%
%  out = corr_coeff;
end
