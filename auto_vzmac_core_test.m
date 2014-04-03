% Find last sync (should be same as first sync, which should be 1).
s=find(sync, 1, 'last');
% Get first 14 vectors (each 2048 long) after last sync and
% reshape into 2048 rows by 14 columns.
z0=reshape(zin0([1:14*2048]+s),2048,[]);
% Take auto-power and sum the 14 vectors together
reexp=sum(z0.*conj(z0),2);
% Ignore initial valid pulse
vout(1:3000)=0;
errs = reexp-reout(vout==1);
nerrs = sum(abs(errs)~=0);
if nerrs
    fprintf('ERROR: %d unexpected values\n', nerrs)
else
    fprintf('OK: %d unexpected values\n', nerrs)
end
