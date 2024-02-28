//  pug_rvc.v
//  Markku-Juhani O. Saarinen <mjos@iki.fi>.  See LICENSE.

//  === Decode compressed (RV32C) instructions (combinatorial logic)

`include    "config.vh"

`ifdef  CORE_COMPRESSED

module pug_rvc(
    input   wire [15:0] c,
    output  wire [31:0] out
);

    assign out =

        c[1:0] == 2'b00 ? (                             //  == quadrant 0 ==
            c[15:13] == 3'b000 ?                        //  c.addi4spn
                { 2'b00, c[10:7], c[12:11], c[5], c[6], 12'b000001000001,
                    c[4:2], 7'b0010011 } :
`ifdef CORE_FPU
            c[15:13] == 3'b001 ?                        //  c.fld
                { 4'b0000, c[6:5], c[12:10], 5'b00001, c[9:7], 5'b01101,
                    c[4:2], 7'b0000111 } :
`endif
            c[15:14] == 2'b01 ?                         //  c.lw c.flw
                { 5'b00000, c[5], c[12:10], c[6], 4'b0001, c[9:7],
                    5'b01001, c[4:2], 4'b0000, c[13], 2'b11 } :
`ifdef CORE_FPU
            c[15:13] == 3'b101 ?                        //  c.fsd
                { 4'b0000, c[6:5], c[12], 2'b01, c[4:2], 2'b01, c[9:7],
                    3'b011, c[11:10], 10'b0000100111 } :
`endif
            c[15:14] == 2'b11 ?                         //  c.sw c.fsw
                { 5'b00000, c[5], c[12], 2'b01, c[4:2], 2'b01, c[9:7],
                    3'b010, c[11:10], c[6], 6'b000100, c[13], 2'b11 } : 0 ) :

        c[1:0] == 2'b01 ? (                             //  == quadrant 1 ==
            c[15:13] == 3'b000 ?                        //  c.addi
                { {7{c[12]}}, c[6:2], c[11:7], 3'b000, c[11:7], 7'b0010011 } :
            c[14:13] == 2'b01 ?                         //  c.jal c.j
                { c[12], c[8], c[10:9], c[6], c[7], c[2], c[11], c[5], c[4:3],
                    {9{c[12]}}, 4'b0000, !c[15], 7'b1101111 } :
            c[15:13] == 3'b011 && c[11:7] == 5'b00010 ? //  c.addi16sp
                { {3{c[12]}}, c[4:3], c[5], c[2], c[6],
                     24'b000000010000000100010011 } :
            c[15:13] == 3'b010 ?                        //  c.li
                { {7{c[12]}}, c[6:2], 8'b00000000, c[11:7], 7'b0010011 } :
            c[15:13] == 3'b011 ?                        //  c.lui
                { {15{c[12]}}, c[6:2], c[11:7], 7'b0110111 } :
            c[15:13] == 3'b100 && c[10] == 1'b0 ?       //  c.srli c.andi
                { {7{c[12]}}, c[6:2], 2'b01, c[9:7], 1'b1, c[11], 3'b101,
                    c[9:7], 7'b0010011 } :
            c[15:10] == 6'b100001 ?                     //  c.srai
                { 7'b0100000, c[6:2], 2'b01, c[9:7], 5'b10101, c[9:7],
                    7'b0010011 } :
            c[15:10] == 6'b100011 && c[6] == 1'b0 ?     //  c.sub c.xor
                { 1'b0, !c[5], 7'b0000001, c[4:2], 2'b01, c[9:7], c[5],
                    4'b0001, c[9:7], 7'b0110011 } :
            c[15:10] == 6'b100011 && c[6] == 1'b1 ?     //  c.or c.and
                { 9'b000000001, c[4:2], 2'b01, c[9:7], 2'b11, c[5], 2'b01,
                    c[9:7], 7'b0110011 } :
            c[15:14] == 2'b11 ?                         //  c.beqz c.bnez
                { {4{c[12]}}, c[6:5], c[2], 7'b0000001, c[9:7], 2'b00,
                    c[13], c[11:10], c[4:3], c[12], 7'b1100011 } : 0 ) :

        c[1:0] == 2'b10 ? (                             //  == quadrant 2 ==
`ifdef CORE_FPU
            c[15:13] == 3'b001 ?                        //  c.fldsp
                { 3'b000, c[4:2], c[12], c[6:5], 11'b00000010011, c[11:7],
                    7'b0000111 } :
`endif
            c[15:12] == 4'b0000 ?                       //  c.slli
                { 7'b0000000, c[6:2], c[11:7], 3'b001, c[11:7], 7'b0010011 } :
            c[15:14] == 2'b01 ?                         //  c.lwsp c.flwsp
                { 4'b0000, c[3:2], c[12], c[6:4], 10'b0000010010, c[11:7],
                    4'b0000, c[13], 2'b11 } :
            c[15:0] == 16'b1001000000000010 ?           //  c.ebreak
                { 32'b00000000000100000000000001110011 } :
            c[15:13] == 3'b100 && c[6:2] == 5'b00000 ?  //  c.jalr c.jr
                { 12'b000000000000, c[11:7], 7'b0000000, c[12], 7'b1100111 } :
            c[15:12] == 4'b1000 ?                       //  c.mv c.jr
                { 12'b000000000000, c[6:2], 3'b000, c[11:7], 7'b0010011 } :
            c[15:12] == 4'b1001 ?                       //  c.add c.jalr
                { 7'b0000000, c[6:2], c[11:7], 3'b000, c[11:7], 7'b0110011 } :
`ifdef CORE_FPU
            c[15:13] == 3'b101 ?                        //  c.fsdsp
                { 3'b000, c[9:7], c[12], c[6:2], 8'b00010011, c[11:10],
                    10'b0000100111 } :
`endif
            c[15:14] == 2'b11 ?                         //  c.swsp c.fswsp
                { 4'b0000, c[8:7], c[12], c[6:2], 8'b00010010, c[11:9],
                    6'b000100, c[13], 2'b11 } : 0 ) :

            0;                                          //  == quadrant 3 ==

endmodule

`endif
