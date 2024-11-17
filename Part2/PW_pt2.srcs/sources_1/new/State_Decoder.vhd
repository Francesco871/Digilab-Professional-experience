library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity State_Decoder is
    Port ( 
        ch0_in, ch1_in: in STD_LOGIC;
        eff_in : in STD_LOGIC;
        jstk_valid : in STD_LOGIC;
        num1, num2, num3, num4: out STD_LOGIC_VECTOR(3 downto 0);
        en1, en2, en3, en4: out STD_LOGIC;
        ch0, ch1, eff_out: out STD_LOGIC
    );
end State_Decoder;

architecture Behavioral of State_Decoder is

begin

    with jstk_valid select eff_out <=
        '0'     when '0',
        eff_in  when '1',
        '0'     when others;

    with jstk_valid select ch0 <=
        '0'     when '0',
        ch0_in  when '1',
        '0'     when others;

    with jstk_valid select ch1 <=
        '0'     when '0',
        ch1_in  when '1',
        '0'     when others;

    en1   <= 
        '1'   when eff_in = '1' else
        '1'   when ch0_in = '1' else
        '0'   when ch1_in = '1' else
        '0';

    en2   <= 
        '1'   when eff_in = '1' else
        '1'   when ch0_in = '1' else
        '0'   when ch1_in = '1' else
        '0';

    en3   <= 
        '1'   when eff_in = '1' else
        '1'   when ch1_in = '1' else
        '0'   when ch0_in = '1' else
        '0';

    en4   <= 
        '0'   when eff_in = '1' else
        '1'   when ch1_in = '1' else
        '0'   when ch0_in = '1' else
        '0';

    num1   <= 
        x"F"                  when eff_in = '1' else
        x"0"                  when ch0_in = '1' else
        (others => '-')       when ch1_in = '1' else
        (others => '-');

    num2   <= 
        x"F"                  when eff_in = '1' else
        x"C"                  when ch0_in = '1' else
        (others => '-')       when ch1_in = '1' else
        (others => '-');

    num3   <= 
        x"E"                  when eff_in = '1' else
        x"1"                  when ch1_in = '1' else
        (others => '-')       when ch0_in = '1' else
        (others => '-');

    num4   <= 
        (others => '-')       when eff_in = '1' else
        x"C"                  when ch1_in = '1' else
        (others => '-')       when ch0_in = '1' else
        (others => '-');

end Behavioral;
