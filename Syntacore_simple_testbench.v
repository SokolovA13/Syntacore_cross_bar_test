`timescale 10ns/1ns

`include "Syntacore_cross_bar_simple.v"

// раскомментировать нужную строчку для выбора количества ведущих
`define   MSTR_2
//`define   MSTR_4
//`define   MSTR_8

// раскомментировать нужную строчку для выбора количества ведомых
`define   SLV_2
//`define   SLV_4
//`define   SLV_8

// определения для запроса

`ifdef   MSTR_2

   `define   REQ_1        1'b0
   `define   REQ_2        1'b1
   
`endif

`ifdef   MSTR_4

   `define   REQ_1        2'b00
   `define   REQ_2        2'b01
   `define   REQ_3        2'b10
   `define   REQ_4        2'b11
   
`endif

`ifdef   MSTR_8

   `define   REQ_1        3'b000
   `define   REQ_2        3'b001
   `define   REQ_3        3'b010
   `define   REQ_4        3'b011
   `define   REQ_5        3'b100
   `define   REQ_6        3'b101
   `define   REQ_7        3'b110
   `define   REQ_8        3'b111

`endif

// определения для адреса

`ifdef   SLV_2

   `define   ADDR_1       32'h40000000
   `define   ADDR_2       32'hc0000000
   
`endif

`ifdef   SLV_4

   `define   ADDR_1       32'h20000000
   `define   ADDR_2       32'h60000000
   `define   ADDR_3       32'ha0000000
   `define   ADDR_4       32'he0000000
   
`endif

`ifdef   SLV_8

   `define   ADDR_1       32'h10000000
   `define   ADDR_2       32'h30000000
   `define   ADDR_3       32'h50000000
   `define   ADDR_4       32'h70000000
   `define   ADDR_5       32'h90000000
   `define   ADDR_6       32'hb0000000
   `define   ADDR_7       32'hd0000000
   `define   ADDR_8       32'hf0000000
   
`endif

// определения для режима работы
`define   OPT            1'b1
`define   IDL            1'b0

// определения для типа команды
`define   WR             1'b1
`define   RD             1'b0

// определение для данных
`define   DATA_0         32'h00000000

// макроподстановки для улучшения читаемости кода
`define   MSTR_ADDR      o_slv_mstr_addr[((address[31] + 1) * MSTR_ADDR_WDTH - 1) -: MSTR_ADDR_WDTH] - 1

module Syntacore_simple_testbench;

localparam   MSTR_NUM     = 2,
             SLV_NUM      = 2,
             DATA_WDTH    = 32,
             ADDR_WDTH    = 32,
             IDL_NUM      = 5;

localparam   MSTR_REQ_WDTH   =  $clog2(MSTR_NUM),
             MSTR_ADDR_WDTH  =  $clog2(MSTR_NUM + 1),
             SLV_ADDR_WDTH   =  $clog2(SLV_NUM),
             IDL_WDTH        =  $clog2(IDL_NUM);             
             
reg                                           i_clk;
reg                                           rst;
             
reg    [(MSTR_NUM - 1)                 : 0]   i_m_s_req;
reg    [(MSTR_NUM * ADDR_WDTH - 1)     : 0]   i_m_s_addr;
reg    [(MSTR_NUM - 1)                 : 0]   i_m_s_cmd;
reg    [(MSTR_NUM * DATA_WDTH - 1)     : 0]   i_m_s_wdata;
   
reg    [(SLV_NUM - 1)                  : 0]   i_s_m_ack;
reg    [(SLV_NUM * DATA_WDTH - 1)      : 0]   i_s_m_rdata;
   
wire   [(SLV_NUM - 1)                  : 0]   o_m_s_req;
wire   [(SLV_NUM * ADDR_WDTH - 1)      : 0]   o_m_s_addr;
wire   [(SLV_NUM - 1)                  : 0]   o_m_s_cmd;
wire   [(SLV_NUM * DATA_WDTH - 1)      : 0]   o_m_s_wdata;

wire   [(MSTR_NUM - 1)                 : 0]   o_s_m_ack;
wire   [(MSTR_NUM * DATA_WDTH - 1)     : 0]   o_s_m_rdata; 

// тестовые сигналы

`ifdef   SIMPLE_SIM

wire   [(SLV_NUM * MSTR_ADDR_WDTH - 1) : 0]   o_slv_mstr_addr;             

`ifdef   EXTENDED_SIM

wire   [(SLV_NUM * MSTR_NUM - 1)       : 0]   o_msk_seq;
wire   [(SLV_NUM * MSTR_ADDR_WDTH - 1) : 0]   ow_slv_mstr_addr;
wire   [(SLV_NUM * MSTR_NUM - 1)       : 0]   ow_slv_dec_in; 
wire   [(SLV_NUM * IDL_WDTH - 1)       : 0]   o_idle_cnt;
                                                                                  
wire   [(MSTR_NUM * ADDR_WDTH - 1)     : 0]   o_m_cb_addr;
wire   [(MSTR_NUM * DATA_WDTH - 1)     : 0]   o_m_cb_wdata;
wire   [(SLV_NUM * DATA_WDTH - 1)      : 0]   o_s_cb_rdata;

wire   [(SLV_NUM * ADDR_WDTH - 1)      : 0]   o_cb_s_addr;
wire   [(SLV_NUM * DATA_WDTH - 1)      : 0]   o_cb_s_wdata;
wire   [(MSTR_NUM * DATA_WDTH - 1)     : 0]   o_cb_m_rdata; 

wire   [(MSTR_NUM * 3 - 1)             : 0]   o_s_m_ack_re;   

`endif
`endif

Syntacore_simple 
#(
   .MSTR_NUM            ( MSTR_NUM    ), 
   .SLV_NUM             ( SLV_NUM     ),
   .DATA_WDTH           ( DATA_WDTH   ),
   .ADDR_WDTH           ( ADDR_WDTH   ),
   .IDL_NUM             ( IDL_NUM     )
)  
   scb
(
   .i_clk               ( i_clk       ),
   .rst                 ( rst         ),

   .i_m_s_req           ( i_m_s_req   ),
   .i_m_s_addr          ( i_m_s_addr  ),
   .i_m_s_cmd           ( i_m_s_cmd   ),
   .i_m_s_wdata         ( i_m_s_wdata ),
   
   .i_s_m_ack           ( i_s_m_ack   ),
   .i_s_m_rdata         ( i_s_m_rdata ),
   
   .o_m_s_req           ( o_m_s_req   ),
   .o_m_s_addr          ( o_m_s_addr  ),
   .o_m_s_cmd           ( o_m_s_cmd   ),
   .o_m_s_wdata         ( o_m_s_wdata ),

   .o_s_m_ack           ( o_s_m_ack   ),
   .o_s_m_rdata         ( o_s_m_rdata )
   
   
   // тестовые сигналы
   
   `ifdef   SIMPLE_SIM
   
   ,
	.o_slv_mstr_addr     ( o_slv_mstr_addr )
   
   `ifdef   EXTENDED_SIM

   ,
   .o_msk_seq           ( o_msk_seq ),
	.ow_slv_mstr_addr    ( ow_slv_mstr_addr ),
	.ow_slv_dec_in       ( ow_slv_dec_in ), 
	.o_idle_cnt          ( o_idle_cnt ),
                                                                                  
	.o_m_cb_addr         ( o_m_cb_addr ),
	.o_m_cb_wdata        ( o_m_cb_wdata ),
	.o_s_cb_rdata        ( o_s_cb_rdata ),

	.o_cb_s_addr         ( o_cb_s_addr ),
	.o_cb_s_wdata        ( o_cb_s_wdata ),
	.o_cb_m_rdata        ( o_cb_m_rdata ),
   
   .o_s_m_ack_re        ( o_s_m_ack_re )
   
   `endif
   `endif
);

integer error_cnt = 0;

integer oper   [(MSTR_NUM - 1):0];
integer type   [(MSTR_NUM - 1):0];
integer addr   [(MSTR_NUM - 1):0];
integer w_data [(MSTR_NUM - 1):0];
integer r_data [(MSTR_NUM - 1):0];

// генерация тактового сигнала

initial

   begin
   
      i_clk = 0;
      
      forever
      
         #1 i_clk = ~i_clk;
      
   end
   
// задание входных воздействий

initial

   begin:test
      
      initialization;
   
      #4;
      
      repeat(1000)
      
         begin: repeat_loop
            
            integer i;
            
            for(i = 0; i < MSTR_NUM; i = i + 1)
            
               begin
               
                  rand_input_gen(i, $urandom(i), $urandom(i), $urandom(i));
                  
               end
            
            write_read({oper[1][0], oper[0][0]}, {type[1][0], type[0][0]}, {addr[1], addr[0]}, {w_data[1], w_data[0]}, {r_data[1], r_data[0]});
            
         end
      
      // вывод сообщения о количестве ошибок
      
      #10;
      
      if(!error_cnt)
         
         $display("There are no errors in the design. Well done!");
         
      else
         
         $display("There are %d errors in the design.", error_cnt);
      
      #1  $stop;
      
   end

task initialization;

   begin
   
      rst = 1;
      
      i_m_s_req    = 0;
      i_m_s_addr   = 0;
      i_m_s_cmd    = 0;
      i_m_s_wdata  = 0;

      i_s_m_ack    = 0;
      i_s_m_rdata  = 0;
      
      #4 rst       = 0;
   
   end
   
endtask

task automatic mstr_req_send;

input   [(MSTR_NUM - 1)              : 0]     request   ;
input   [(MSTR_NUM - 1)              : 0]     command   ;
input   [(MSTR_NUM * ADDR_WDTH - 1)  : 0]     address   ;
input   [(MSTR_NUM * DATA_WDTH - 1)  : 0]     w_data    ;

begin: mstr_request

   integer i;
   
   @(posedge i_clk);
      
   // отправка запросов ведущих 
            
   for(i = 0; i < MSTR_NUM; i = i + 1)
      
      begin
                        
         i_m_s_req   [i]                                       =  request [i]                                      ;
         i_m_s_addr  [(ADDR_WDTH * (i + 1) - 1) -: ADDR_WDTH]  =  address [(ADDR_WDTH * (i + 1) - 1) -: ADDR_WDTH] ;
         i_m_s_cmd   [i]                                       =  command [i]                                      ;
         i_m_s_wdata [(DATA_WDTH * (i + 1) - 1) -: DATA_WDTH]  =  w_data  [(DATA_WDTH * (i + 1) - 1) -: DATA_WDTH] ; 
                           
      end
      
end
      
endtask

task automatic slv_resp;

input   [(ADDR_WDTH - 1)             : 0]     address   ;
input   [(MSTR_NUM - 1)              : 0]     command   ;
input   [(MSTR_NUM * DATA_WDTH - 1)  : 0]     w_data    ;

begin

   // дожидаемся получения запроса ведомым
                  
   wait(o_m_s_req[address[31]]);         
                     
   fork
                  
      // выполняем проверку того, что коммутация входного запроса произошла правильно;
      // если происходит ошибка, делается вывод соответствующей информации в консоли и счётчик ошибок увеличивается на 1
                     
      begin
                        
         // проверку осуществляем через полтакта после коммутации входного запроса
                        
         @(negedge i_clk);
                           
         if(o_m_s_addr  [((address[31] + 1) * ADDR_WDTH - 1) -: ADDR_WDTH] != address  [31 : 0])  
                        
            begin
                           
               error_cnt = error_cnt + 1;
               $display("addr error at %d ns", ($time * 10)); 
                              
            end
                           
         if(o_m_s_cmd   [address[31]] != command  [`MSTR_ADDR])  
                        
            begin
                           
               error_cnt = error_cnt + 1;
               $display("cmd error at %d ns", ($time * 10));
                              
            end
                           
         if(o_m_s_wdata [((address[31] + 1) * DATA_WDTH - 1) -: DATA_WDTH] != w_data[(DATA_WDTH * (`MSTR_ADDR + 1) - 1) -: DATA_WDTH])  
                        
            begin
                           
               error_cnt = error_cnt + 1;
               $display("w_data error at %d ns", ($time * 10));
                              
            end
                           
      end
                     
      // на следующий такт после получения запроса ведомым выставляем бит подтверждения в высокий уровень
                     
      begin
                        
         @(posedge i_clk);
                           
         begin
                  
            i_s_m_ack[address[31]] = 1;
               
         end
                           
      end
                     
   join 

end

endtask

task automatic ack_receive_r_data_send;

input   [(ADDR_WDTH - 1)             : 0]     address   ;
input   [(MSTR_NUM * DATA_WDTH - 1)  : 0]     r_data    ;

begin

   // дожидаемся получения подтверждения ведущим
                  
   wait(o_s_m_ack[`MSTR_ADDR]);
                  
   // на следующий такт после получения подтверждения снимаем запрос и сигнал подтверждения
   
   @(posedge i_clk);
                  
   begin
         
      i_m_s_req [`MSTR_ADDR]   = 0;
      i_s_m_ack [address[31]]  = 0;
                     
      // в случае операции чтения передаём необходимые данные
                     
      if(!i_m_s_cmd[`MSTR_ADDR])
                     
         begin
                  
            i_s_m_rdata[(ADDR_WDTH * (address[31] + 1) - 1) -: ADDR_WDTH]  =  r_data[(DATA_WDTH * (`MSTR_ADDR + 1) - 1) -: DATA_WDTH];
                     
            // выполняем проверку того, что ведущему пришли правильные данные с ведомого, через полтакта после отправки
            
            @(negedge i_clk);
            
            if(o_s_m_rdata [(DATA_WDTH * (`MSTR_ADDR + 1) - 1) -: DATA_WDTH] != r_data[(DATA_WDTH * (`MSTR_ADDR + 1) - 1) -: DATA_WDTH]) 
                  
               begin
                        
                  error_cnt = error_cnt + 1;
                  $display("r_data error at %d ns", ($time * 10));
                        
               end
                           
         end
                        
      else
                     
         begin
                  
            i_s_m_rdata[(ADDR_WDTH * (address[31] + 1) - 1) -: ADDR_WDTH]  =  0;
                           
            @(negedge i_clk);
                                                
         end
                           
   end

end

endtask

task automatic rand_input_gen;

input mstr_num;
input w_data_rand;
input rand;
input r_data_rand;

begin

   w_data[mstr_num] = $urandom($time + w_data_rand);

   case($urandom($time + rand)%4)
                        
      0: begin
                           
         oper[mstr_num]  = `IDL;
         type[mstr_num]  = `WR;
         addr[mstr_num]  = `ADDR_1;
                           
      end
                           
      1: begin
                           
         oper[mstr_num]  = `OPT;
         type[mstr_num]  = `WR;
         addr[mstr_num]  = `ADDR_1;
                           
      end
                           
      2: begin
                           
         oper[mstr_num]  = `OPT;
         type[mstr_num]  = `WR;
         addr[mstr_num]  = `ADDR_2;
                           
      end
                           
      3: begin
                           
         oper[mstr_num]  = `OPT;
         type[mstr_num]  = `RD;
         addr[mstr_num]  = `ADDR_1;
                    
      end
                           
      4: begin
                           
         oper[mstr_num]  = `OPT;
         type[mstr_num]  = `RD;
         addr[mstr_num]  = `ADDR_2;
                           
      end
                           
   endcase

   case(type[0])
            
      0: r_data[mstr_num] = $urandom($time + r_data_rand);
      1: r_data[mstr_num] = `DATA_0;
               
   endcase
            
end

endtask

task automatic write_read;

input   [(MSTR_NUM - 1)              : 0]     request   ;
input   [(MSTR_NUM - 1)              : 0]     command   ;
input   [(MSTR_NUM * ADDR_WDTH - 1)  : 0]     address   ;
input   [(MSTR_NUM * DATA_WDTH - 1)  : 0]     w_data    ;
input   [(MSTR_NUM * DATA_WDTH - 1)  : 0]     r_data    ;

   begin: transfer     
      
      mstr_req_send(request, command, address, w_data);
            
      // проверка получения запросов ведомыми и отправка подтверждений
      
      // случай двойного запроса к одному ведомому
      
      if((request[1] & request[0]) & (address[63] == address[31]))
      
         begin
            
            // повторяем код два раза для каждого из ведущих
            
            repeat(2)
            
               begin
                  
                  slv_resp                (address[31:0], command, w_data);
                  ack_receive_r_data_send (address[31:0], r_data);
               
               end
                  
         end
      
      // случай двойного запроса к разным ведомым
         
      else if((request[1] & request[0]) & (address[63] != address[31]))
         
         // параллельно выполняем оба запроса
         
         fork
            
            // работаем с первым ведущим
            
            begin
               
               slv_resp                (address[31:0], command, w_data);
               ack_receive_r_data_send (address[31:0], r_data);
               
            end
            
            // работаем со вторым ведущим
            
            begin
               
               slv_resp                (address[63:32], command, w_data);
               ack_receive_r_data_send (address[63:32], r_data);
            
            end
            
         join
      
      // случай запроса только вторым ведущим
      
      else if((request[1] & !request[0]))
      
         begin
            
            slv_resp                (address[63:32], command, w_data);
            ack_receive_r_data_send (address[63:32], r_data);
            
         end
      
      // случай запроса только первым ведущим
      
      else if((request[0] & !request[1]))
               
         begin
            
            slv_resp                (address[31:0], command, w_data);
            ack_receive_r_data_send (address[31:0], r_data);
  
         end  

   end
   
endtask
   

task automatic idle;

input [7:0] delay;

repeat(delay) #2;

endtask

endmodule
