library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity depacketizer is
	Generic (
		HEADER				: std_logic_vector(7 downto 0) := x"c0";
		FOOTER				: std_logic_vector(7 downto 0) := x"51";
		SAMPLES_PER_PACKET	: positive := 16
	);
	Port (
		aclk			: in std_logic;
		aresetn			: in std_logic;

		s_axis_tvalid	: in std_logic;
		s_axis_tdata	: in std_logic_vector(7 downto 0);
		s_axis_tready	: out std_logic;

		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(23 downto 0);
		m_axis_tlast	: out std_logic;
		m_axis_tready	: in std_logic
	);
end depacketizer;

architecture Behavioral of depacketizer is

	constant TDATA_WIDTH       : integer := 24;
	constant UART_WIDTH        : integer := 8;

    type state_type is (RST, LOOK_FOR_HEADER, RECEIVE_FIRST_LEFT, RECEIVE_SECOND_LEFT, RECEIVE_FIRST_RIGHT, RECEIVE_SECOND_RIGHT, SEND_LEFT, SEND_RIGHT);

	signal state                    : state_type := RST;

	signal first_left_reg                 : std_logic_vector(UART_WIDTH-1 downto 0) := (others => '0');
	signal first_right_reg                : std_logic_vector(UART_WIDTH-1 downto 0) := (others => '0');
	signal second_left_reg                : std_logic_vector(UART_WIDTH-1 downto 0) := (others => '0');
	signal second_right_reg               : std_logic_vector(UART_WIDTH-1 downto 0) := (others => '0');

	signal zero : std_logic_vector(UART_WIDTH-1 downto 0) := (Others => '0');

    signal packet_counter : positive range 0 to SAMPLES_PER_PACKET := 0; -- counter to count samples (LLRR) received

begin

    -- mux to manage correctly AXIS protocol
    with state select m_axis_tvalid <=
        '1' when SEND_LEFT,
        '1' when SEND_RIGHT,
        '0' when others;

    with state select m_axis_tlast <=
        '0' when SEND_LEFT,
        '1' when SEND_RIGHT,
        '-' when others;

    with state select s_axis_tready <=
        '1' when LOOK_FOR_HEADER,
        '1' when RECEIVE_FIRST_LEFT,
        '1' when RECEIVE_SECOND_LEFT,
        '1' when RECEIVE_FIRST_RIGHT,
        '1' when RECEIVE_SECOND_RIGHT,
        '0' when others;
        
    -- output manager, I send data made of LL or RR + zero padding to send full 24bits
    with state select m_axis_tdata <=
        second_left_reg & first_left_reg & zero           when SEND_LEFT,
        second_right_reg & first_right_reg & zero         when SEND_RIGHT,
        (others => '-')                                   when others;

    process(aclk)   -- synchronous reset
    begin

        if aresetn = '0' then

            state           	  <= RST;

            first_left_reg        <= (others => '0');
            second_left_reg       <= (others => '0');
            first_right_reg       <= (others => '0');
            second_right_reg      <= (others => '0');

            packet_counter <= 0;

        elsif rising_edge(aclk) then

            case state is

                when RST =>

                    state <= LOOK_FOR_HEADER;

                when LOOK_FOR_HEADER =>

					if s_axis_tvalid = '1' and s_axis_tdata = HEADER then

						state <= RECEIVE_FIRST_LEFT;

					end if;

                when RECEIVE_FIRST_LEFT =>

                    if s_axis_tvalid = '1' then

                        if packet_counter = SAMPLES_PER_PACKET then -- when I received 16 samples the packet is over => look for footer

                            if s_axis_tdata = FOOTER then

                                packet_counter <= 0;  -- reset counter and start to look for header of a new packet

                                state <= LOOK_FOR_HEADER;

                            end if;

                        else

                            packet_counter <= packet_counter+1; -- I'm receiving a new sample

							first_left_reg  <= s_axis_tdata;

                        	state           <= RECEIVE_SECOND_LEFT;

                        end if;

				    end if;

                when RECEIVE_SECOND_LEFT =>

                    if s_axis_tvalid = '1' then

                        second_left_reg  <= s_axis_tdata;

                        state           <= RECEIVE_FIRST_RIGHT;

                    end if;

                when RECEIVE_FIRST_RIGHT =>

                    if s_axis_tvalid = '1' then

                        first_right_reg       <= s_axis_tdata;

                        state           <= RECEIVE_SECOND_RIGHT;

                    end if;

                when RECEIVE_SECOND_RIGHT =>

                    if s_axis_tvalid = '1' then

                        second_right_reg       <= s_axis_tdata;

                        state           <= SEND_LEFT;

                    end if;

                when SEND_LEFT =>

                    if m_axis_tready = '1' then

                        state           <= SEND_RIGHT;

                    end if;

                when SEND_RIGHT =>

                    if m_axis_tready = '1' then

                        state           <= RECEIVE_FIRST_LEFT;

                    end if;

                when others =>

                    state               <= RST;

            end case;

        end if;

    end process;

end Behavioral;
