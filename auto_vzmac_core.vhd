library IEEE;
use IEEE.std_logic_1164.all;

entity auto_vzmac_core is
  port (
    ce : in std_logic;
    im0 : in std_logic_vector( 7 downto 0 );
    re0 : in std_logic_vector( 7 downto 0 );
    sync : in std_logic;
    clk : in std_logic;
    re : out std_logic_vector( 19 downto 0 );
    valid : out std_logic
  );
end auto_vzmac_core;

architecture structural of auto_vzmac_core is
begin
end structural;

