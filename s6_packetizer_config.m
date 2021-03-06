
function s6_packetizer_config(this_block)

  % Revision History:
  %
  %   17-Feb-2014  (09:34 hours):
  %     Original code was machine generated by Xilinx's System Generator after parsing
  %     /tools/designs/CASPER/projects/leda/davidm/adc16/s6_gateware/verilog/s6_packetizer.v
  %
  %

  this_block.setTopLevelLanguage('Verilog');

  this_block.setEntityName('s6_packetizer');

  this_block.addSimulinkInport('sync');
  this_block.addSimulinkInport('din');
  this_block.addSimulinkInport('start_word');
  this_block.addSimulinkInport('nwords_per_pkt');
  this_block.addSimulinkInport('src_id');

  this_block.addSimulinkOutport('dout');
  this_block.addSimulinkOutport('dv');
  this_block.addSimulinkOutport('dst');
  this_block.addSimulinkOutport('eof');

  dout_port = this_block.port('dout');
  dout_port.setType('UFix_64_0');
  dv_port = this_block.port('dv');
  dv_port.setType('Bool');
  dv_port.useHDLVector(false);
  dst_port = this_block.port('dst');
  dst_port.setType('UFix_4_0');
  eof_port = this_block.port('eof');
  eof_port.setType('Bool');
  eof_port.useHDLVector(false);

  % -----------------------------
  if (this_block.inputTypesKnown)
    % do input type checking, dynamic output type and generic setup in this code block.

    if (this_block.port('sync').width ~= 1);
      this_block.setError('Input data type for port "sync" must have width=1.');
    end

    this_block.port('sync').useHDLVector(false);

    if (this_block.port('din').width ~= 64);
      this_block.setError('Input data type for port "din" must have width=64.');
    end

    % Port 'start_word' has dynamic type in the HDL -- please add type checking as appropriate;
    if (this_block.port('start_word').width ~= nextpow2(2048));
      this_block.setError('Input data type for port "start_word" must have width=11.');
    end

    % Port 'nwords_per_pkt' has dynamic type in the HDL -- please add type checking as appropriate;
    if (this_block.port('nwords_per_pkt').width ~= nextpow2(2048));
      this_block.setError('Input data type for port "nwords_per_pkt" must have width=11.');
    end

    if (this_block.port('src_id').width ~= 4);
      this_block.setError('Input data type for port "src_id" must have width=4.');
    end

  end  % if(inputTypesKnown)
  % -----------------------------

  % -----------------------------
   if (this_block.inputRatesKnown)
     setup_as_single_rate(this_block,'clk','ce')
   end  % if(inputRatesKnown)
  % -----------------------------

    % Set the inout port rate to be the same as the first input 
    % rate. Change the following code if this is untrue.
    uniqueInputRates = unique(this_block.getInputRates);

  % Custimize the following generic settings as appropriate. If any settings depend
  % on input types, make the settings in the "inputTypesKnown" code block.
  % The addGeneric function takes  3 parameters, generic name, type and constant value.
  % Supported types are boolean, real, integer and string.
  this_block.addGeneric('NWORDS','integer','2048');

  % Add addtional source files as needed.
  %  |-------------
  %  | Add files in the order in which they should be compiled.
  %  | If two files "a.vhd" and "b.vhd" contain the entities
  %  | entity_a and entity_b, and entity_a contains a
  %  | component of type entity_b, the correct sequence of
  %  | addFile() calls would be:
  %  |    this_block.addFile('b.vhd');
  %  |    this_block.addFile('a.vhd');
  %  |-------------

  %    this_block.addFile('');
  %    this_block.addFile('');
  this_block.addFile('verilog/s6_packetizer.v');
  this_block.addFile('verilog/crc32x64.v');
  this_block.addFile('verilog/crclut.v');

return;


% ------------------------------------------------------------

function setup_as_single_rate(block,clkname,cename) 
  inputRates = block.inputRates; 
  uniqueInputRates = unique(inputRates); 
  if (length(uniqueInputRates)==1 & uniqueInputRates(1)==Inf) 
    block.addError('The inputs to this block cannot all be constant.'); 
    return; 
  end 
  if (uniqueInputRates(end) == Inf) 
     hasConstantInput = true; 
     uniqueInputRates = uniqueInputRates(1:end-1); 
  end 
  if (length(uniqueInputRates) ~= 1) 
    block.addError('The inputs to this block must run at a single rate.'); 
    return; 
  end 
  theInputRate = uniqueInputRates(1); 
  for i = 1:block.numSimulinkOutports 
     block.outport(i).setRate(theInputRate); 
  end 
  block.addClkCEPair(clkname,cename,theInputRate); 
  return; 

% ------------------------------------------------------------

