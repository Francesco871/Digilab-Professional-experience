library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Mix_Controller is
    generic(
        CHANNEL_LENGHT  : integer := 24;
        JOYSTICK_LENGHT  : integer := 10;
        N : integer :=6
    );
    Port (
        
            aclk			: in std_logic;
            aresetn			: in std_logic;
            
            jstck_x         : in std_logic_vector(JOYSTICK_LENGHT-1 downto 0);
            jstck_valid     : in std_logic;
    
            s_00_axis_tvalid	: in std_logic;
            s_00_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            s_00_axis_tlast    : in std_logic;
            s_00_axis_tready	: out std_logic;

            s_01_axis_tvalid	: in std_logic;
            s_01_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            s_01_axis_tlast    : in std_logic;
            s_01_axis_tready	: out std_logic;
    
            m_axis_tvalid	: out std_logic;
            m_axis_tdata	: out std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            m_axis_tlast	: out std_logic;
            m_axis_tready	: in std_logic
        );
end Mix_Controller;

architecture Behavioral of Mix_Controller is
   
    constant BALANCE_INTERVAL       : integer := 2**N;
    constant HALF_BALANCE_INTERVAL  : integer := (2**N)/2;
    constant BALANCE_LEVEL_MAX      : integer := (2**JOYSTICK_LENGHT / 2) / 2**N;

    -- FSM to handle the communication
    type state_type is (RST, RECEIVE_LEFT_00, RECEIVE_LEFT_01, RECEIVE_RIGHT_00, RECEIVE_RIGHT_01, SEND_LEFT, SEND_RIGHT);

    signal state                       : state_type := RST;

    signal left_00_reg                 : signed(CHANNEL_LENGHT-1 downto 0) := (others => '0');
    signal right_00_reg                : signed(CHANNEL_LENGHT-1 downto 0) := (others => '0');
    signal left_01_reg                 : signed(CHANNEL_LENGHT-1 downto 0) := (others => '0');
    signal right_01_reg                : signed(CHANNEL_LENGHT-1 downto 0) := (others => '0');

    signal left_sum					: signed(CHANNEL_LENGHT-1 downto 0) := (others => '0');
    signal right_sum				: signed(CHANNEL_LENGHT-1 downto 0) := (others => '0');

    signal balance_level            : integer range -BALANCE_LEVEL_MAX to BALANCE_LEVEL_MAX := 0; 
    signal balance_reg              : integer range -BALANCE_LEVEL_MAX to BALANCE_LEVEL_MAX := 0;

    signal jstck_valid_reg	     	: std_logic := '0';

    signal left_out                 : signed(CHANNEL_LENGHT-1 downto 0) := (others => '0');
    signal right_out                : signed(CHANNEL_LENGHT-1 downto 0) := (others => '0');

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

    with state select s_00_axis_tready <=
        '1' when RECEIVE_LEFT_00,
        '1' when RECEIVE_RIGHT_00,
        '0' when others;

    with state select s_01_axis_tready <=
        '1' when RECEIVE_LEFT_01,
        '1' when RECEIVE_RIGHT_01,
        '0' when others;

    -- this function (balance_level = ((balance + 32)/64) - 8     compute the balance level ( i.e. the exponent used to amplify the audio as audio*(2**balance_level) )
    balance_level <= to_integer((unsigned(jstck_x) + HALF_BALANCE_INTERVAL) / BALANCE_INTERVAL) - BALANCE_LEVEL_MAX;

    -- if eff off calculate the sum of the two channels,
    -- otherwise balance control: sum one channel to the other lowered by the balance imposed by the jstk, if no balance applied just sum the two channels
    left_sum   <= 
        left_00_reg + left_01_reg                                 when jstck_valid_reg = '0' else
        left_00_reg + shift_right(left_01_reg, -balance_reg)      when balance_reg < 0 else
        shift_right(left_00_reg, balance_reg) + left_01_reg	      when balance_reg > 0 else
        left_00_reg + left_01_reg;

    right_sum   <= 
        right_00_reg + right_01_reg                               when jstck_valid_reg = '0' else
        right_00_reg + shift_right(right_01_reg, -balance_reg)    when balance_reg < 0 else
        shift_right(right_00_reg, balance_reg) + right_01_reg	  when balance_reg > 0 else
        right_00_reg + right_01_reg;

    -- calculate the average of the two channels
    left_out <= shift_right(left_sum , 2);
    right_out <= shift_right(right_sum , 2);
        
    -- output manager
    with state select m_axis_tdata <=
        std_logic_vector(left_out)              when SEND_LEFT,
        std_logic_vector(right_out)             when SEND_RIGHT,
        (others => '-')                         when others;

    process(aclk)   -- synchronous reset
    begin

        if aresetn = '0' then

            state           <= RST;

            balance_reg     	<= 0;
            jstck_valid_reg 	<= '0';
            left_00_reg        	<= (others => '0');
            left_01_reg			<= (others => '0');
            right_00_reg       	<= (others => '0');
            right_01_reg		<= (others => '0');

        elsif rising_edge(aclk) then

            case state is

                when RST =>

                    state   <= RECEIVE_LEFT_00;

                when RECEIVE_LEFT_00 =>

                    if s_00_axis_tvalid = '1' and s_00_axis_tlast = '0' then

                        left_00_reg    <= signed(s_00_axis_tdata);

                            state       <= RECEIVE_LEFT_01;

                    end if;

                when RECEIVE_LEFT_01 =>

                        if s_01_axis_tvalid = '1' and s_01_axis_tlast = '0' then

                            left_01_reg    <= signed(s_01_axis_tdata);

                            state       <= RECEIVE_RIGHT_00;

                        end if;

                when RECEIVE_RIGHT_00 =>

                    if s_00_axis_tvalid = '1' and s_00_axis_tlast = '1' then

                        right_00_reg   <= signed(s_00_axis_tdata);

                        state       <= RECEIVE_RIGHT_01;

                    end if;

                when RECEIVE_RIGHT_01 =>

                    if s_01_axis_tvalid = '1' and s_01_axis_tlast = '1' then

                        right_01_reg   <= signed(s_01_axis_tdata);

                        balance_reg    <= balance_level;    -- refresh balance only here to be consistent on the same packet of data (L and R)

                        jstck_valid_reg <= jstck_valid;     -- refresh jstk valid (same as balance)

                        state       <= SEND_LEFT;
                        
                    end if ;

                when SEND_LEFT =>

                    if m_axis_tready = '1' then

                        state <= SEND_RIGHT;

                    end if;

                when SEND_RIGHT =>

                    if m_axis_tready = '1' then

                        state <= RECEIVE_LEFT_00;

                    end if;

                when others =>

                    state <= RST;

            end case;

        end if;

    end process;



end Behavioral;