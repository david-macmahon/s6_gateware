function fx = wincorr(a, b, n)
  wsize = size(a, 1);
  faa = zeros(1, wsize);
  fbb = zeros(1, wsize);
  fab = zeros(1, wsize);

  for k = n:size(b,2)-1
    fa = fft(a(:, k-n+1));
    fb = fft(b(:, k+1));
    faa = faa + abs(fa).^2;
    fbb = fbb + abs(fb).^2;
    fab = fab + (fa .* conj(fb));
  end

  fx = fab ./ (faa*fbb).^0.5;
end
