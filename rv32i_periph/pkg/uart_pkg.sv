package uart_pkg;
//  localparam int SYS_FREQUENCY = 100_000_000;
 localparam int OSR = 16;
 localparam int DATALEN = 8;

  typedef enum {
    IDLE,
    START,
    DATA,
    STOP
  } states_e;

endpackage

package cnt_pkg;
  // `ifdef SIM
  localparam int DIV = 1_000;
  localparam int MAX_COUNT = 10;
  localparam int DIV_1KHZ = 100;  // for fnd scanning
  // `else
  // parameter int DIV = 10_000_000;
  // parameter int MAX_COUNT = 10_000;
  // parameter int DIV_1KHZ = 100_000;  // for fnd scanning
  // `endif
  parameter int WIDTH_COUNTER = $clog2(DIV);
endpackage
