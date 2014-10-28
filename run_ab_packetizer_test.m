% Find index of EOF samples
eof_idx=find(eof&dv);

% Start of frame (packet)
current_sof = 1;
for pkt_num = 1:length(eof_idx)
    current_eof = eof_idx(pkt_num);

    % Find index of second packet samples
    % (first packet is known invalid)
    pkt_idx=find(dv(current_sof:current_eof)) + current_sof - 1;

    % Make sure pkt_idx is correct length
    if length(pkt_idx) ~= 1024+2
      fprintf('packet %2d len BAD (%d)\n', pkt_num, length(pkt_idx));
    else
      fprintf('packet %2d len ok\n', pkt_num);
    end

    % Get packet data
    pkt_data=[dhi(pkt_idx) dlo(pkt_idx)]';
    %fprintf('packet %2d first word = %d\n', pkt_num, pkt_data(2))

    % Get temp file name
    tempname = tempname();
    tempname = sprintf('pkt%d.dat', pkt_num);

    % Open file for Writing Binary, Big-endian data
    fid = fopen(tempname,'wb','b');
    % Write packet data as uint32 values
    fwrite(fid, pkt_data, 'uint32');
    fclose(fid);

    % Check CRC
    if system(['ruby -r zlib -e ''exit Zlib.crc32(File.read("' tempname '"))==0xffff_ffff'''])
      fprintf('packet %2d crc BAD\n', pkt_num);
    else
      fprintf('packet %2d crc ok\n', pkt_num);
    end

    % Delete temp file
    %delete(tempname);

    % Setup for next iteration
    current_sof = current_eof + 1;
end
