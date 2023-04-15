`timescale 1ns / 1ps
module qpsk_mod
	(
		input wire 			clk		,
		input wire 			rst_n	,
		input wire 	[39:0]	para_in	,
		
		output wire [32:0] 	qpsk	
    );
	
	wire 	ser_data	;
	
	wire 		clk_500k	; 
	
	wire [1:0]	I			;
	wire [1:0]	Q			;
	wire [23:0]	I_filtered	;
	wire [23:0]	Q_filtered	;
	wire [7:0] 	carry_sin	;
	wire [7:0] 	carry_cos	;	
	wire [31:0] qpsk_i		;
	wire [31:0] qpsk_q		;
	
	//产生500kHz采样时钟
	sam_clk_gen sam_clk_gen_inst(
			.clk		(clk	),  //50MHz
			.rst_n		(rst_n	),

			.clk_o	    (clk_500k)
		);
	
	
	
	//串并转换
	para2ser 
	#(.DIV(14'd10000))
	para2ser_inst
	(
		.clk			(clk		),
		.rst_n			(rst_n		),
		.para_i			(para_in	),

		.ser_o		    (ser_data	)
    );
	
	//I/Q分流
	iq_div
	#(	.IQ_DIV_MAX(8'd100), //采样速率为clk/IQ_DIV_MAX
		.BIT_SAMPLE(8'd100)  //每个bit采样点数
	)
	iq_div_inst
	(
		.clk		(clk		),
		.rst_n		(rst_n		),
		.ser_i		(ser_data	),

		.I			(I		), //有符号双极性输出
		.Q	        (Q	    )
    );
	
	//I路成形滤波
	rcosfilter rcosfilter_I (
		.aclk(clk_500k),                            // input wire aclk
		.s_axis_data_tvalid(rst_n),  				// input wire s_axis_data_tvalid
		.s_axis_data_tready(),  // output wire s_axis_data_tready
		.s_axis_data_tdata({{6{I[1]}},I}),    // input wire [7 : 0] s_axis_data_tdata
		.m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
		.m_axis_data_tdata(I_filtered)    // output wire [23 : 0] m_axis_data_tdata
	);

	//Q路成形滤波
	rcosfilter rcosfilter_Q (
		.aclk(clk_500k),                            // input wire aclk
		.s_axis_data_tvalid(rst_n),  				// input wire s_axis_data_tvalid
		.s_axis_data_tready(),  // output wire s_axis_data_tready
		.s_axis_data_tdata({{6{Q[1]}},Q}),    // input wire [7 : 0] s_axis_data_tdata
		.m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
		.m_axis_data_tdata(Q_filtered)    // output wire [23 : 0] m_axis_data_tdata
	);	
	
	//产生sin波形
	dds_sin dds_sin_inst(
		.aclk(clk_500k),                                // input wire aclk
		.aresetn(rst_n),                          // input wire aresetn
		.m_axis_data_tvalid(),    // output wire m_axis_data_tvalid
		.m_axis_data_tdata(carry_sin),      // output wire [7 : 0] m_axis_data_tdata
		.m_axis_phase_tvalid(),  // output wire m_axis_phase_tvalid
		.m_axis_phase_tdata()    // output wire [23 : 0] m_axis_phase_tdata
	);
	
	//产生cos波形
	dds_cos dds_cos_inst(
		.aclk(clk_500k),                                // input wire aclk
		.aresetn(rst_n),                          // input wire aresetn
		.m_axis_data_tvalid(),    // output wire m_axis_data_tvalid
		.m_axis_data_tdata(carry_cos),      // output wire [7 : 0] m_axis_data_tdata
		.m_axis_phase_tvalid(),  // output wire m_axis_phase_tvalid
		.m_axis_phase_tdata()    // output wire [23 : 0] m_axis_phase_tdata
	);
	
	//I路滤波后与cos载波相乘
	mul_mod mul_mod_I
	(
		.CLK(clk_500k),  // input wire CLK
		.A(I_filtered),      // input wire [23 : 0] A
		.B(carry_cos),      // input wire [7 : 0] B
		.P(qpsk_i)      // output wire [31 : 0] P
	);
	
	//Q路滤波后与sin载波相乘
	mul_mod mul_mod_Q
	(
		.CLK(clk_500k),  // input wire CLK
		.A(Q_filtered),      // input wire [23 : 0] A
		.B(carry_sin),      // input wire [7 : 0] B
		.P(qpsk_q)      // output wire [31 : 0] P
	);	
	
	//IQ两路信号叠加
	assign qpsk = {qpsk_i[31],qpsk_i} + {qpsk_q[31],qpsk_q};
	
	
endmodule
