
function auto_vzmac_core_config(this_block)

  % Revision History:
  %
  %   23-May-2014  (12:50 hours):
  %     Original code was machine generated by Xilinx's System Generator after parsing
  %     /tools/designs/CASPER/projects/leda/davidm/adc16/s6_gateware/auto_vzmac_core.vhd
  %
  %

  this_block.setTopLevelLanguage('VHDL');

  this_block.setEntityName('auto_vzmac_core');

  this_block.addSimulinkInport('sync');
  this_block.addSimulinkInport('re0');
  this_block.addSimulinkInport('im0');

  this_block.addSimulinkOutport('valid');
  this_block.addSimulinkOutport('re');

  valid_port = this_block.port('valid');
  valid_port.setType('Bool');
  valid_port.useHDLVector(false);
  re_port = this_block.port('re');
  re_port.setType('UFix_20_14');

  % -----------------------------
  if (this_block.inputTypesKnown)
    % do input type checking, dynamic output type and generic setup in this code block.

    if (this_block.port('im0').width ~= 8);
      this_block.setError('Input data type for port "im0" must have width=8.');
    end

    if (this_block.port('re0').width ~= 8);
      this_block.setError('Input data type for port "re0" must have width=8.');
    end

    if (this_block.port('sync').width ~= 1);
      this_block.setError('Input data type for port "sync" must have width=1.');
    end

    this_block.port('sync').useHDLVector(false);

  end  % if(inputTypesKnown)
  % -----------------------------

  % -----------------------------
   if (this_block.inputRatesKnown)
     setup_as_single_rate(this_block,'clk_1','ce_1')
   end  % if(inputRatesKnown)
  % -----------------------------

    % (!) Set the inout port rate to be the same as the first input
    %     rate. Change the following code if this is untrue.
    uniqueInputRates = unique(this_block.getInputRates);


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
  this_block.addFile('auto_vzmac_core.vhd');

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

