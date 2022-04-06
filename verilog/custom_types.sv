// custom defined types for the CNN
// Author: Cheryl (Yingqiu) Cao
// Date: 2021-12-28
// updated on: 2022-01-2


// states for the ifmap input FSM
typedef enum logic [2:0]
{
  RESET = 3'b000, CONFIG, INPUT_CHAINING, RESET_CHAINING,
  WRITE_BANK_COUNT, SWITCH, WAIT
} ifmap_input_state_t;




// states for simple_read_FSM
typedef enum logic [2:0]
{
  RESET = 3'b000, CONFIG, WAIT, READ, READ_BANK_COUNT
   
} simple_read_state_t;

// states for simple_main_FSM
typedef enum logic [2:0]
{
  RESET = 3'b000, CONFIG, WAIT, SWITCH,
  START_W, START_RW, START_R, END
  } simple_main_state_t;


