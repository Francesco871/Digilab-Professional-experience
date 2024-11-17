library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity packetizer is
	Generic (
		HEADER				: std_logic_vector(7 downto 0) := x"c0";
		FOOTER				: std_logic_vector(7 downto 0) := x"51";
		SAMPLES_PER_PACKET	: positive := 16
	);
	Port (
		aclk			: in std_logic;
		aresetn			: in std_logic;

		s_axis_tvalid	: in std_logic;
		s_axis_tdata	: in std_logic_vector(23 downto 0);
		s_axis_tlast	: in std_logic;
		s_axis_tready	: out std_logic;

		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(7 downto 0);
		m_axis_tready	: in std_logic
	);
end packetizer;

architecture Behavioral of packetizer is

	constant TDATA_WIDTH       : integer := 24;
	constant UART_WIDTH        : integer := 8;

    type state_type is (RST, SEND_HEADER, RECEIVE_LEFT, RECEIVE_RIGHT, SEND_FIRST_LEFT, SEND_SECOND_LEFT, SEND_FIRST_RIGHT, SEND_SECOND_RIGHT, SEND_FOOTER);

	signal state                    : state_type := RST;

	signal left_reg                 : std_logic_vector(TDATA_WIDTH-1 downto 0) := (others => '0');
	signal right_reg                : std_logic_vector(TDATA_WIDTH-1 downto 0) := (others => '0');

	signal packet_counter : positive range 0 to SAMPLES_PER_PACKET := 0;  -- counter to count samples (LLRR) received

begin

    -- mux to manage correctly AXIS protocol
    with state select m_axis_tvalid <=
    	'1' when SEND_HEADER,
        '1' when SEND_FIRST_LEFT,
        '1' when SEND_SECOND_LEFT,
        '1' when SEND_FIRST_RIGHT,
        '1' when SEND_SECOND_RIGHT,
        '1' when SEND_FOOTER,
        '0' when others;

    with state select s_axis_tready <=
        '1' when RECEIVE_LEFT,
        '1' when RECEIVE_RIGHT,
        '0' when others;
        
    -- output manager
    with state select m_axis_tdata <=
    	HEADER 			  		                                  when SEND_HEADER,
        left_reg(SAMPLES_PER_PACKET-1 downto UART_WIDTH)          when SEND_FIRST_LEFT,
        left_reg(TDATA_WIDTH-1 downto SAMPLES_PER_PACKET)		  when SEND_SECOND_LEFT,
        right_reg(SAMPLES_PER_PACKET-1 downto UART_WIDTH)         when SEND_FIRST_RIGHT,
        right_reg(TDATA_WIDTH-1 downto SAMPLES_PER_PACKET)		  when SEND_SECOND_RIGHT,
        FOOTER 			  		                                  when SEND_FOOTER,
        (others => '-') 		                                  when others;

    process(aclk)   -- synchronous reset
    begin

        if aresetn = '0' then

            state          <= RST;

            left_reg       <= (others => '0');
            right_reg      <= (others => '0');

            packet_counter <= 0;

        elsif rising_edge(aclk) then

            case state is

                when RST =>

                    state <= RECEIVE_LEFT;

                when RECEIVE_LEFT =>

                	if s_axis_tvalid = '1' and s_axis_tlast = '0' then

                        left_reg        <= s_axis_tdata;

                        state           <= RECEIVE_RIGHT;

                    end if;

                when RECEIVE_RIGHT =>

                    if s_axis_tvalid = '1' and s_axis_tlast = '1' then

                        right_reg       <= s_axis_tdata;

                        if packet_counter = 0 then -- if I'm sending a new packet send header first, instead start sending first L

                            state          <= SEND_HEADER;
                        else
                            
                            state          <= SEND_FIRST_LEFT;

                        end if;

                    end if;

                when SEND_HEADER  =>

                    if m_axis_tready = '1' then

                        state           <= SEND_FIRST_LEFT;

                    end if;

                when SEND_FIRST_LEFT =>

                    if m_axis_tready = '1' then

                        packet_counter <= packet_counter+1; -- I'm sending a new sample

                        state           <= SEND_SECOND_LEFT;

                    end if;

                when SEND_SECOND_LEFT =>

                    if m_axis_tready = '1' then

                        state           <= SEND_FIRST_RIGHT;

                    end if;

                when SEND_FIRST_RIGHT =>

                    if m_axis_tready = '1' then

                        state           <= SEND_SECOND_RIGHT;

                    end if;

                when SEND_SECOND_RIGHT =>

                    if m_axis_tready = '1' then

                        if packet_counter = SAMPLES_PER_PACKET then -- when I sent a full packet (16 samples) reset counter and send footer

                            packet_counter <= 0;

                            state <= SEND_FOOTER;

                        else

                            state           <= RECEIVE_LEFT;

                        end if;

                    end if;

                when SEND_FOOTER =>

                    if m_axis_tready = '1' then

                        state           <= RECEIVE_LEFT;

                    end if;

                when others =>

                    state               <= RST;

            end case;

        end if;

    end process;

end Behavioral;

