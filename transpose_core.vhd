library IEEE;
use IEEE.std_logic_1164.all;

entity transpose_core is
  port (
    ce : in std_logic;
    din : in std_logic_vector( 63 downto 0 );
    sync_in : in std_logic;
    clk : in std_logic;
    dout : out std_logic_vector( 63 downto 0 );
    sync_out : out std_logic
  );
end transpose_core;

architecture structural of transpose_core is
begin
end structural;

