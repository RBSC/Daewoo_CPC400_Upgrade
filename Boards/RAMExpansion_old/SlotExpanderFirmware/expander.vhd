-- Copyright (C) 1991-2013 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- Daewoo Slot Expander Firmware v1.00
-- Created by Wierzbowsky [RBSC] and Max Vlasov (Meteor_M)
-- (c) RBSC 2025 and Meteor_M
-- Last modified: 18.10.2025

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity expander is
    port ( D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR (15 downto 0);
           RD_N : in  STD_LOGIC;
           WR_N : in  STD_LOGIC;
           RFSH_N : in  STD_LOGIC;
           RST_N  : in  STD_LOGIC;
           CLK1 : in  STD_LOGIC;
           CLK2 : in  STD_LOGIC;
			  MERQ_N : in  STD_LOGIC;
			  M1_N   : in  STD_LOGIC;
			  IORQ_N : in  STD_LOGIC;
           SLTSEL_N  : in  STD_LOGIC;
           SLTSELO_N : out  STD_LOGIC_VECTOR (2 downto 0);
           BUSDIRI_N : in  STD_LOGIC_VECTOR (1 downto 0);
           BUSDIR_N  : out  STD_LOGIC);
end expander;

architecture rtl of expander is

	signal	reg_subslt	:	STD_LOGIC_VECTOR (7 downto 0);	-- Slot register
	signal	flag_regrd	:	STD_LOGIC;
	signal	flag_regwr	:	STD_LOGIC;

	signal	f4_read	:	STD_LOGIC;
	signal	f4_write	:	STD_LOGIC;
	signal	f4_bit   :	STD_LOGIC := '1';

begin

	--------------------
	-- Expander logic --
	--------------------

	-- SLOT SELECTION REGISTER INTERNAL LOGIC --
	flag_regwr <= '1' when (WR_N = '0' and RD_N = '1' and RFSH_N = '1' and SLTSEL_N = '0' and A = x"FFFF") else '0';	
	flag_regrd <= '1' when (WR_N = '1' and RD_N = '0' and RFSH_N = '1' and SLTSEL_N = '0' and A = x"FFFF") else '0';		
		
		
	process (flag_regwr, RST_N)
		begin
   		if (RST_N = '0') then
			reg_subslt <= (others => '0');
		elsif (flag_regwr'event and flag_regwr = '1') then
			reg_subslt <= D;
		end if;
	end process;		

	
	D <= not reg_subslt when (flag_regrd='1') else
         (others => 'Z');


	-- SLOT SELECT LOGIC --
	SLTSELO_N(0) <= '0' when (SLTSEL_N='0' and (
											(A(15 downto 14)="00" and reg_subslt(1 downto 0)="00") 
										or (A(15 downto 14)="01" and reg_subslt(3 downto 2)="00") 
										or (A(15 downto 14)="10" and reg_subslt(5 downto 4)="00") 
										or (A(15 downto 14)="11" and reg_subslt(7 downto 6)="00" and A(13 downto 0)/="11111111111111"))) else '1';

	SLTSELO_N(1) <= '0' when (SLTSEL_N='0' and (
											(A(15 downto 14)="00" and reg_subslt(1 downto 0)="01") 
										or (A(15 downto 14)="01" and reg_subslt(3 downto 2)="01") 
										or (A(15 downto 14)="10" and reg_subslt(5 downto 4)="01") 
										or (A(15 downto 14)="11" and reg_subslt(7 downto 6)="01" and A(13 downto 0)/="11111111111111"))) else '1';

	SLTSELO_N(2) <= '0' when (SLTSEL_N='0' and (
											(A(15 downto 14)="00" and reg_subslt(1 downto 0)="10") 
										or (A(15 downto 14)="01" and reg_subslt(3 downto 2)="10") 
										or (A(15 downto 14)="10" and reg_subslt(5 downto 4)="10") 
										or (A(15 downto 14)="11" and reg_subslt(7 downto 6)="10" and A(13 downto 0)/="11111111111111"))) else '1';


	-- BUSDIR logic for subslots (if devices there have capability)
	--BUSDIR_N <= '0' when (BUSDIRI_N(1 downto 0)/="11") else '1';

	-- The below code is a fix for the v1.0 of the Daewoo RAM module that doesn't have BUSDIR functionality
	-- Uncomment the above statement and comment the below statement if used with v1.1 of RAM expander
	BUSDIR_N <= '0' when (BUSDIRI_N(1 downto 0)/="11") or (M1_N = '1' and IORQ_N = '0' and RD_N = '0' and A(7 downto 2) = "111111")
										or (M1_N = '1' and IORQ_N = '0' and RD_N = '0' and A(7 downto 4) = "1111" and A(3) = '0' and A(2) = '1' and A(1 downto 0) = "00" ) else '1';


	-------------------
	-- Port F4 logic --
	-------------------

	-- Read/write conditions
	f4_read <= '1' when (A(7 downto 4) = "1111" and A(3) = '0' and A(2) = '1' and A(1 downto 0) = "00" and IORQ_N = '0' and RD_N = '0' and WR_N = '1' and M1_N = '1') else '0';
	f4_write <= '1' when (A(7 downto 4) = "1111" and A(3) = '0' and A(2) = '1' and A(1 downto 0) = "00" and IORQ_N = '0' and WR_N = '0' and RD_N = '1') else '0';
	
	-- Preserve bit
	process(f4_write)
		begin
			if (f4_write'event and f4_write = '1') then
				f4_bit <= D(7);
			end if;
	end process;
	
	-- Output bit
	D(7) <= f4_bit when (f4_read = '1') else 'Z';

end rtl;

