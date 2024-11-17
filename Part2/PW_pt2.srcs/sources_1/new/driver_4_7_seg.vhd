library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity driver_4_7seg is
    Generic(
        mux_time_ms: positive:=1;
        clock_period_ns: positive :=10
    );
    Port ( 
        clk : in STD_LOGIC;
        reset: in STD_LOGIC;
        num1, num2, num3, num4: in STD_LOGIC_VECTOR(3 downto 0);
        en1, en2, en3, en4: in STD_LOGIC;
        an: out STD_LOGIC_VECTOR(3 downto 0);
        seg: out STD_LOGIC_VECTOR(0 to 6);
        dp: out STD_LOGIC
        );
end driver_4_7seg;

architecture Behavioral of driver_4_7seg is

    constant cycles_per_mux : integer := (mux_time_ms * 1_000_000) / (clock_period_ns);

    signal mux_counter : integer := 0; -- counter used to count clk cycles
    signal digit_counter : integer := 0; -- counter used to index the digits
    signal num_reg : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin

    with num_reg select seg <=
        "0000001" when "0000",
        "1001111" when "0001",
        "0010010" when "0010",
        "0000110" when "0011",
        "1001100" when "0100",
        "0100100" when "0101",
        "0100000" when "0110",
        "0001111" when "0111",
        "0000000" when "1000",
        "0000100" when "1001",
        "0001000" when "1010",
        "1100000" when "1011",
        "0110001" when "1100",
        "1000010" when "1101",
        "0110000" when "1110",
        "0111000" when "1111",
        "1111111" when others;

    dp <= '1'; -- I never have a decimal number => always keep the dot off

    process(clk)
    begin
        if reset = '1' then

            mux_counter <= 0;
            digit_counter <= 0;
            an          <= "1111";

        elsif rising_edge(clk) then

            if mux_counter = cycles_per_mux then -- when I reach "cycles_per_mux" clk cycles I refres

                mux_counter <= 0; -- reset clk cycles counter
                digit_counter <= digit_counter + 1; -- increase the digit index
                
                case digit_counter is -- multiplex which digit to refresh
                    when 0 =>

                        if en1 = '0' then
                            num_reg <= "0000";
                            an <= "1111";
                        else
                            num_reg <= num1;
                            an <= "1110";
                        end if;

                    when 1 =>

                        if en2 = '0' then
                            num_reg <= "0000";
                            an <= "1111";
                        else
                            num_reg <= num2;
                            an <= "1101";
                        end if;

                    when 2 =>

                        if en3 = '0' then
                            num_reg <= "0000";
                            an <= "1111";
                        else
                            num_reg <= num3;
                            an <= "1011";
                        end if;

                    when 3 =>

                        digit_counter <= 0;

                        if en4 = '0' then
                            num_reg <= "0000";
                            an <= "1111";
                        else
                            num_reg <= num4;
                            an <= "0111";
                        end if;

                    when others =>

                        num_reg <= "0000";
                        an <= "1111";
                end case;
            else

                mux_counter <= mux_counter + 1; -- updare clk cycles counter

            end if;
        end if;
    end process;

end Behavioral;
