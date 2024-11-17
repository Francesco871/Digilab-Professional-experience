----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.09.2021 17:01:05
-- Design Name: 
-- Module Name: Led_Controller - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Led_Controller is
Port ( 
    led_b 			:  OUT STD_LOGIC_VECTOR ( 7 downto 0 );
	led_g 			: OUT STD_LOGIC_VECTOR ( 7 downto 0 );
	led_r 			: OUT STD_LOGIC_VECTOR ( 7 downto 0 );
    muted           : IN STD_LOGIC;
    filter_enabled  :IN STD_LOGIC
);
end Led_Controller;

architecture Behavioral of Led_Controller is

begin
    process(muted, filter_enabled)

    begin
        if muted='1' then
            led_r<=(others => '1');
            led_b<=(others => '0');
            led_g<=(others => '0');
        elsif filter_enabled='1' then
            led_r<=(others => '0');
            led_b<=(others => '1');
            led_g<=(others => '0');
        else
            led_r<=(others => '0');
            led_b<=(others => '0');
            led_g<=(others => '1');
        end if;
             
    end process;

end Behavioral;
