`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module pong (
        input wire pixel_clk,
        input wire rst,
        input wire [1:0] control,
        input wire [3:0] puck_speed,
        input wire [3:0] paddle_speed,
        input wire new_frame,
        input wire [10:0] h_count,
        input wire [9:0] v_count,
        output logic [7:0] pixel_red,
        output logic [7:0] pixel_green,
        output logic [7:0] pixel_blue
    );

    //use these params!
    localparam PADDLE_WIDTH = 16;
    localparam PADDLE_HEIGHT = 128;
    localparam PUCK_WIDTH = 128;
    localparam PUCK_HEIGHT = 128;
    localparam GAME_WIDTH = 1280;
    localparam GAME_HEIGHT = 720;

    logic [10:0] puck_x, paddle_x; //puck x location, paddle x location
    logic [9:0] puck_y, paddle_y; //puck y location, paddle y location
    logic [7:0] puck_r,puck_g,puck_b; //puck red, green, blue (from block sprite)
    logic [7:0] paddle_r,paddle_g,paddle_b; //paddle colors from its block sprite)

    logic dir_x, dir_y; //use for direction of movement: 1 going positive, 0 going negative


    logic up, down; //up down from buttons
    logic game_over; //signal to indicate game over (0 on game reset, 1 during play)
    assign up = control[1]; //up control
    assign down = control[0]; //down control

    block_sprite #(.WIDTH(PADDLE_WIDTH), .HEIGHT(PADDLE_HEIGHT))
    paddle(
        .h_count(h_count),
        .v_count(v_count),
        .x(paddle_x),
        .y(paddle_y),
        .pixel_red(paddle_r),
        .pixel_green(paddle_g),
        .pixel_blue(paddle_b)
    );

    block_sprite #(.WIDTH(PUCK_WIDTH), .HEIGHT(PUCK_HEIGHT))
    puck(
      .h_count(h_count),
      .v_count(v_count),
      .x(puck_x),
      .y(puck_y),
      .pixel_red(puck_r),
      .pixel_green(puck_g),
      .pixel_blue(puck_b)
    );

    assign pixel_red = puck_r | paddle_r; //merge color contributions from puck and paddle
    assign pixel_green =  puck_g | paddle_g; //merge color contribuations from puck and paddle
    assign pixel_blue = puck_b | paddle_b; //merge color contributsion from puck and paddle

    logic puck_overlap; //one bit signal indicating if puck and paddle overlap
    //this signal should be one when puck is red in the video included in lab.
    //make signal be derived combinationally. you will need to figure this out
    //remember numbers are not signed here...so there's no such thing as negative

    logic puck_hit_or_miss;

    logic out_of_bounds_x;
    logic out_of_bounds_y;

    logic [10:0] next_puck_x;
    logic [9:0] next_puck_y;
    logic [9:0] next_paddle_y;

    logic puck_out_of_bounds_x;
    logic puck_out_of_bounds_y;

    logic new_dir_x;
    logic new_dir_y;

    always_comb begin
        // puck_overlap check
        puck_overlap = (
                    (puck_y + PUCK_HEIGHT >= paddle_y) && // top
                    (puck_y <= paddle_y + PADDLE_HEIGHT-1)); // bottom

        //puck out of bounds check
        puck_out_of_bounds_x = (puck_x + PUCK_WIDTH >= GAME_WIDTH - 1);
        puck_out_of_bounds_y = ( 
                            (puck_y <= 1) ||
                            (puck_y + PUCK_HEIGHT >= GAME_HEIGHT - 1)
                            );

        // check if puck might hit paddle
        puck_hit_or_miss = (puck_x <= 1 + paddle_x + PADDLE_WIDTH);

        // update dir_x and dir_y
        new_dir_x = (puck_out_of_bounds_x || (puck_hit_or_miss && puck_overlap)) ? ~dir_x : dir_x;
        new_dir_y = (puck_out_of_bounds_y) ? ~dir_y : dir_y;

        // next puck coords
        next_puck_x = (new_dir_x) ? puck_x + puck_speed : puck_x - puck_speed;
        next_puck_y = (new_dir_y) ? puck_y + puck_speed : puck_y - puck_speed;

        // next paddle coords
        next_paddle_y = (up && !down) ? paddle_y - paddle_speed : paddle_y;
        next_paddle_y = (down && !up) ? paddle_y + paddle_speed : next_paddle_y;

        // check paddle out of bounds
        next_paddle_y = (
                up && !down && (paddle_y <= GAME_HEIGHT / 2) && (next_paddle_y >= GAME_HEIGHT/2)
                ) ? 0 : next_paddle_y;
        next_paddle_y = (next_paddle_y + PADDLE_HEIGHT >= GAME_HEIGHT-1) ? GAME_HEIGHT - PADDLE_HEIGHT-1 : next_paddle_y;
    end


    always_ff @(posedge pixel_clk)begin
        if (rst)begin
            //start puck in center of screen (you need to change!):
            puck_x <= GAME_WIDTH / 2; //change me
            puck_y <= GAME_HEIGHT / 2; //change me
            dir_x <= h_count[0]; //start at pseudorandom direction
            dir_y <= h_count[1]; //start with pseudorandom direction
            //start paddle in center of left half of screen (you need to change)
            paddle_x <= 0; //change me (maybe...or maybe not..?)
            paddle_y <= GAME_HEIGHT / 2; //change me
            game_over <= 0;
        end else begin
            if (new_frame) begin

            if (~game_over) begin

                //puck movement
                puck_x <= next_puck_x;
                puck_y <= next_puck_y;

                // update puck_dir
                dir_x <= new_dir_x;
                dir_y <= new_dir_y;

                game_over <= (puck_hit_or_miss && !puck_overlap);

                end
            paddle_y <= next_paddle_y;
            end


        end

    end
endmodule
`default_nettype wire