`timescale 10ns/1ns

// раскомментировать нужные строчки для верификации проекта 
// SIMPLE   - только сигналы модуля; 
// EXTENDED - все внутренние сигналы.

`define   SIMPLE_SIM
//`define   EXTENDED_SIM

// макроопределения для подсчёта количества бит адресов ведущих и ведомых и разрядности счётчика неактивных состояний

`define   MSTR_ADDR_WDTH   $clog2(MSTR_NUM + 1)
`define   SLV_ADDR_WDTH    $clog2(SLV_NUM)
`define   IDL_WDTH         $clog2(IDL_NUM)

module Syntacore_simple
#(parameter   MSTR_NUM     = 2,
              SLV_NUM      = 2,
              DATA_WDTH    = 32,
              ADDR_WDTH    = 32,
              IDL_NUM      = 5
)
(
   input                                                  i_clk,
   input                                                  rst,

   input          [(MSTR_NUM - 1)                  : 0]   i_m_s_req,
   input          [(MSTR_NUM * ADDR_WDTH - 1)      : 0]   i_m_s_addr,
   input          [(MSTR_NUM - 1)                  : 0]   i_m_s_cmd,
   input          [(MSTR_NUM * DATA_WDTH - 1)      : 0]   i_m_s_wdata,
   
   input          [(SLV_NUM - 1)                   : 0]   i_s_m_ack,
   input          [(SLV_NUM * DATA_WDTH - 1)       : 0]   i_s_m_rdata,
   
   output   reg   [(SLV_NUM - 1)                   : 0]   o_m_s_req,
   output   reg   [(SLV_NUM * ADDR_WDTH - 1)       : 0]   o_m_s_addr,
   output   reg   [(SLV_NUM - 1)                   : 0]   o_m_s_cmd,
   output   reg   [(SLV_NUM * DATA_WDTH - 1)       : 0]   o_m_s_wdata,

   output   reg   [(MSTR_NUM - 1)                  : 0]   o_s_m_ack,
   output   reg   [(MSTR_NUM * DATA_WDTH - 1)      : 0]   o_s_m_rdata
                    

	// тестовые сигналы
	
	`ifdef   SIMPLE_SIM
	
   ,
   output   reg   [(SLV_NUM * `MSTR_ADDR_WDTH -1 ) : 0]   o_slv_mstr_addr
   
   `ifdef   EXTENDED_SIM
   
	,
   output   reg   [(SLV_NUM * MSTR_NUM - 1)        : 0]   o_msk_seq,
	output   reg   [(SLV_NUM * `MSTR_ADDR_WDTH - 1) : 0]   ow_slv_mstr_addr,
	output   reg   [(SLV_NUM * MSTR_NUM - 1)        : 0]   ow_slv_dec_in, 
	output   reg   [(SLV_NUM * `IDL_WDTH - 1)       : 0]   o_idle_cnt,
                                                                                  
	output   reg   [(MSTR_NUM * ADDR_WDTH - 1)      : 0]   o_m_cb_addr,
	output   reg   [(MSTR_NUM * DATA_WDTH - 1)      : 0]   o_m_cb_wdata,
	output   reg   [(SLV_NUM * DATA_WDTH - 1)       : 0]   o_s_cb_rdata,

	output   reg   [(SLV_NUM * ADDR_WDTH - 1)       : 0]   o_cb_s_addr,
	output   reg   [(SLV_NUM * DATA_WDTH - 1)       : 0]   o_cb_s_wdata,
	output   reg   [(MSTR_NUM * DATA_WDTH - 1)      : 0]   o_cb_m_rdata,

   output   reg   [(MSTR_NUM * 3 - 1)              : 0]   o_s_m_ack_re
	
   `endif
	`endif
);

reg   [(MSTR_NUM - 1)        : 0]   r_msk_seq          [(SLV_NUM - 1)  : 0];           // маска запроса
reg   [(`MSTR_ADDR_WDTH - 1) : 0]   rw_slv_mstr_addr   [(SLV_NUM - 1)  : 0];           // небуферизованные адреса ведущих для каждого ведомого
reg   [(`MSTR_ADDR_WDTH - 1) : 0]   r_slv_mstr_addr    [(SLV_NUM - 1)  : 0];           // буферизованные адреса ведущих для каждого ведомого
reg   [(MSTR_NUM - 1)        : 0]   rw_slv_dec_in      [(SLV_NUM - 1)  : 0];           // небуферизованные итоговые запросы для каждого ведомого   

reg   [(`IDL_WDTH - 1)       : 0]   r_idle_cnt         [(SLV_NUM - 1)  : 0];           // количество неактивных тактов для каждого ведомого
                                                                                  
reg   [(ADDR_WDTH - 1)       : 0]   r_m_cb_addr        [(MSTR_NUM - 1) : 0];           // адреса отправки  ведущий->кросс-бар
reg   [(DATA_WDTH - 1)       : 0]   r_m_cb_wdata       [(MSTR_NUM - 1) : 0];           // данные записи    ведущий->кросс-бар
reg   [(DATA_WDTH - 1)       : 0]   r_s_cb_rdata       [(SLV_NUM - 1)  : 0];           // данные чтения    ведомый->кросс-бар

reg   [(ADDR_WDTH - 1)       : 0]   r_cb_s_addr        [(SLV_NUM - 1)  : 0];           // адреса отправки  кросс-бар->ведомый
reg   [(DATA_WDTH - 1)       : 0]   r_cb_s_wdata       [(SLV_NUM - 1)  : 0];           // данные записи    кросс-бар->ведомый
reg   [(DATA_WDTH - 1)       : 0]   r_cb_m_rdata       [(MSTR_NUM - 1) : 0];           // данные чтения    кросс-бар->ведущий

reg   [2                     : 0]   r_s_m_ack_re       [(MSTR_NUM - 1) : 0];           // сигналы для выделения фронтов запросов ведущих

// разборка шин для симуляции

// генерация сигналов для симуляции, количество которых зависит от количества ведущих

`ifdef   EXTENDED_SIM

genvar sim_mstr_num;

generate

   for(sim_mstr_num = 0; sim_mstr_num < MSTR_NUM; sim_mstr_num = sim_mstr_num + 1)
	
      begin: sim_mstr_bus
      
         always @*
			
            begin
               
               o_m_cb_addr    [(ADDR_WDTH * (sim_mstr_num + 1) - 1) -: ADDR_WDTH] = r_m_cb_addr     [sim_mstr_num];
               o_m_cb_wdata   [(DATA_WDTH * (sim_mstr_num + 1) - 1) -: DATA_WDTH] = r_m_cb_wdata    [sim_mstr_num];
               o_cb_m_rdata   [(DATA_WDTH * (sim_mstr_num + 1) - 1) -: DATA_WDTH] = r_cb_m_rdata    [sim_mstr_num];
               
               o_s_m_ack_re   [((sim_mstr_num + 1) * 3 - 1)         -: 3]         = r_s_m_ack_re    [sim_mstr_num]; 
               
            end
      end
		
endgenerate

`endif

// генерация сигналов для симуляции, количество которых зависит от количества ведомых

`ifdef   SIMPLE_SIM

genvar sim_slv_num;

generate

   for(sim_slv_num = 0; sim_slv_num < SLV_NUM; sim_slv_num = sim_slv_num + 1)
	
      begin: sim_slv_bus
      
         always @*
			
            begin
               
               o_slv_mstr_addr   [(`MSTR_ADDR_WDTH * (sim_slv_num + 1) - 1) -: `MSTR_ADDR_WDTH]  =  r_slv_mstr_addr  [sim_slv_num];
               
               `ifdef   EXTENDED_SIM
               
               ow_slv_mstr_addr  [(`MSTR_ADDR_WDTH * (sim_slv_num + 1) - 1) -: `MSTR_ADDR_WDTH]  =  rw_slv_mstr_addr [sim_slv_num];
               o_msk_seq         [(MSTR_NUM * (sim_slv_num + 1) - 1)        -:  MSTR_NUM]        =  r_msk_seq        [sim_slv_num];
               ow_slv_dec_in     [(MSTR_NUM * (sim_slv_num + 1) - 1)        -:  MSTR_NUM]        =  rw_slv_dec_in    [sim_slv_num];
               o_idle_cnt        [(`IDL_WDTH * (sim_slv_num + 1) - 1)       -: `IDL_WDTH]        =  r_idle_cnt       [sim_slv_num];
               
               o_s_cb_rdata      [(DATA_WDTH * (sim_slv_num + 1) - 1)       -:  DATA_WDTH]       =  r_s_cb_rdata     [sim_slv_num];  
               o_cb_s_addr       [(ADDR_WDTH * (sim_slv_num + 1) - 1)       -:  ADDR_WDTH]       =  r_cb_s_addr      [sim_slv_num];
               o_cb_s_wdata      [(DATA_WDTH * (sim_slv_num + 1) - 1)       -:  DATA_WDTH]       =  r_cb_s_wdata     [sim_slv_num];
               
               `endif
               
            end
      end
endgenerate

`endif

genvar slv_num;
genvar mstr_num;  
 
// формирование из входных и выходных сигналов шин, разрядность которых зависит от числа ведущих

generate

   for(mstr_num = 0; mstr_num < MSTR_NUM; mstr_num = mstr_num + 1)
	
      begin: mstr_bus_loop
         
         always @*
			
            begin
            
               r_m_cb_addr  [mstr_num]   =   i_m_s_addr  [((mstr_num + 1) * ADDR_WDTH - 1) -: ADDR_WDTH];
               r_m_cb_wdata [mstr_num]   =   i_m_s_wdata [((mstr_num + 1) * DATA_WDTH - 1) -: DATA_WDTH];
               
               o_s_m_rdata  [((mstr_num + 1) * DATA_WDTH - 1) -: DATA_WDTH] = r_cb_m_rdata[mstr_num];
               
            end
         
      end
endgenerate 
     
// формирование из входных и выходных сигналов шин, разрядность которых зависит от числа ведомых

generate

   for(slv_num = 0; slv_num < SLV_NUM; slv_num = slv_num + 1)
	
      begin: slv_bus_loop
         
         always @*
			
            begin
            
               r_s_cb_rdata[slv_num] = i_s_m_rdata[((slv_num + 1) * DATA_WDTH - 1) -: DATA_WDTH];
               
               o_m_s_addr  [((slv_num + 1) * ADDR_WDTH - 1) -: ADDR_WDTH]   =  r_cb_s_addr  [slv_num];
               o_m_s_wdata [((slv_num + 1) * DATA_WDTH - 1) -: DATA_WDTH]   =  r_cb_s_wdata [slv_num];
               
            end
         
      end
endgenerate 
      
// блок описания транзакции master->slave   

generate

   for(slv_num = 0; slv_num < SLV_NUM; slv_num = slv_num + 1)
	
      begin: slv_trans_loop
         
         // формирование итогового запроса для данного ведомого с учётом маски
         
         for(mstr_num = 0; mstr_num < MSTR_NUM; mstr_num = mstr_num + 1)
			
            begin: mstr_loop
               
               always @*
					
                  begin
                  
                     rw_slv_dec_in[slv_num][mstr_num] = (i_m_s_req[mstr_num] & (r_m_cb_addr[mstr_num][(ADDR_WDTH - 1) -: `SLV_ADDR_WDTH] == slv_num) 
                                                        & r_msk_seq[slv_num][mstr_num]);
                  end
                     
            end
				
            // определение адреса младшего запроса для данного ведомого (с учётом маски)
            
            always @*
				
               begin
               
                  casez(rw_slv_dec_in[slv_num])
                  
                     2'b?1:   rw_slv_mstr_addr[slv_num] = 2'b01;
                     2'b10:   rw_slv_mstr_addr[slv_num] = 2'b10;
                     default: rw_slv_mstr_addr[slv_num] = 2'b00;
                     
                  endcase
                  
               end
               
            // вычисление маски для применения ко входному запросу (обновление маски происходит только после подтверждения запроса от ведомого)
            
            always @(posedge i_clk)
               begin
               
                  if(rst | (r_idle_cnt[slv_num] == IDL_NUM))
                  
                     r_msk_seq[slv_num] <= 2'b11;
                     
                  else if((r_slv_mstr_addr[slv_num] == 2'b01) & (o_s_m_ack[r_slv_mstr_addr[slv_num] - 1]))
                  
                     r_msk_seq[slv_num] <= 2'b10;
                     
                  else if((r_slv_mstr_addr[slv_num] == 2'b10) & (o_s_m_ack[r_slv_mstr_addr[slv_num] - 1]))
                  
                     r_msk_seq[slv_num] <= 2'b01;
                     
                  else
                  
                     r_msk_seq[slv_num] <= r_msk_seq[slv_num];
                     
               end
               
				// подсчёт количества тактов, в течение которых не было запросов данному ведомому
            
				always @(posedge i_clk)
				
					begin
               
                  if(rst | (r_idle_cnt[slv_num] == IDL_NUM) | rw_slv_dec_in[slv_num])
                  
                     r_idle_cnt[slv_num] <= 0;
                     
						else
                  
							r_idle_cnt[slv_num] <= r_idle_cnt[slv_num] + 1;
                     
					end
				
            // буферизация адреса ведущего, производящего отправку данному ведомому в данном такте
            
            always @(posedge i_clk)
				
               begin
					
                  if(rst | (r_s_m_ack_re[r_slv_mstr_addr[slv_num] - 1][2] & rw_slv_dec_in[slv_num] == 0))
                  
                     r_slv_mstr_addr[slv_num] <= 0;
                     
                  else if(rw_slv_dec_in[slv_num] != 0)	
                  
                     r_slv_mstr_addr[slv_num] <= rw_slv_mstr_addr[slv_num];
                     
                  else
                  
                     r_slv_mstr_addr[slv_num] <= r_slv_mstr_addr[slv_num];
                     
               end
            
            // отправка данных данному ведомому от нужного ведущего
            
            always @(posedge i_clk)
				
               begin
					
                  if(rst | !rw_slv_mstr_addr[slv_num] | !rw_slv_dec_in[slv_num][rw_slv_mstr_addr[slv_num] - 1] | o_s_m_ack[rw_slv_mstr_addr[slv_num] - 1])
						
                     begin
                     
                        o_m_s_req    [slv_num]   <= 0;
                        r_cb_s_addr  [slv_num]   <= 0;
                        o_m_s_cmd    [slv_num]   <= 0;
                        r_cb_s_wdata [slv_num]   <= 0;
                     
                     end
							
                  else
						
                     begin
                     
                        o_m_s_req    [slv_num]   <= rw_slv_dec_in [slv_num][rw_slv_mstr_addr[slv_num] - 1];
                        r_cb_s_addr  [slv_num]   <= r_m_cb_addr   [rw_slv_mstr_addr[slv_num] - 1];
                        o_m_s_cmd    [slv_num]   <= i_m_s_cmd     [rw_slv_mstr_addr[slv_num] - 1];
                        r_cb_s_wdata [slv_num]   <= r_m_cb_wdata  [rw_slv_mstr_addr[slv_num] - 1];
                        
                     end
                     
               end
      end
   
endgenerate

// блок описания транзакции slave->master

generate

   for(mstr_num = 0; mstr_num < MSTR_NUM; mstr_num = mstr_num + 1)
	
      begin: mstr_gen_loop
      
         // коммутация сигнала подтверждения ведомого нужному ведущему
			
         always @*
			
            begin
            
               if((r_slv_mstr_addr[r_m_cb_addr[mstr_num][(ADDR_WDTH - 1) -: `SLV_ADDR_WDTH]] - 1) == mstr_num)
               
                  o_s_m_ack[mstr_num]  = i_s_m_ack[r_m_cb_addr[mstr_num][(ADDR_WDTH - 1) -: `SLV_ADDR_WDTH]];
                  
               else
					
                  o_s_m_ack[mstr_num]  = 0;
                  
            end
            
         // передача данных чтения на следующий такт после подтверждения транзакции
			
         always @*
			
            begin
               
					if(rst | !r_s_m_ack_re[mstr_num][2] | i_m_s_cmd[mstr_num])
					
						r_cb_m_rdata[mstr_num] = 0;
						
               else
					
                  r_cb_m_rdata[mstr_num] = r_s_cb_rdata[r_m_cb_addr[mstr_num][(ADDR_WDTH - 1) -: `SLV_ADDR_WDTH]];
                  
            end 
               
         // выделение фронта сигнала подтверждения запроса
			
         always @(posedge i_clk)
			
            begin
               
               r_s_m_ack_re[mstr_num][0] <= o_s_m_ack[mstr_num];
               r_s_m_ack_re[mstr_num][1] <= r_s_m_ack_re[mstr_num][0];
               
            end
         
         always @*
			
            begin
            
               r_s_m_ack_re[mstr_num][2] = ~r_s_m_ack_re[mstr_num][1] & r_s_m_ack_re[mstr_num][0];  
               
            end
            
      end
      
endgenerate 
     
endmodule
