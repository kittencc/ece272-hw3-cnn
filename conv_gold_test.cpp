#include <fstream>
#include <iostream>
#include <string>

//#include "conv_gold.cpp"
#include "conv_gold_tiled.cpp"

using namespace std;

template <int OFMAP_HEIGHT, 
          int OFMAP_WIDTH, 
          int OFMAP_CHANNELS, 
          int IFMAP_CHANNELS, 
          int FILTER_SIZE, 
          int STRIDE>
void run_layer(string layer_name){
    std::cout << "Running: " << layer_name << std::endl;
    
    std::ifstream ifmap_file("data/" + layer_name + "_ifmap.txt", ios::in);
    int16_t ifmap[(OFMAP_HEIGHT-1)*STRIDE+FILTER_SIZE][(OFMAP_WIDTH-1)*STRIDE+FILTER_SIZE][IFMAP_CHANNELS];
    for(int i = 0; i < (OFMAP_HEIGHT-1)*STRIDE+FILTER_SIZE; i++){
        for(int j = 0; j < (OFMAP_WIDTH-1)*STRIDE+FILTER_SIZE; j++){
            for(int k = 0; k < IFMAP_CHANNELS; k++){
                ifmap_file >> ifmap[i][j][k];
            }
        }
    }
    ifmap_file.close();

    std::ifstream weights_file;
    weights_file.open("data/" + layer_name + "_weights.txt");
    int16_t weights[FILTER_SIZE][FILTER_SIZE][IFMAP_CHANNELS][OFMAP_CHANNELS];
    for(int i = 0; i < FILTER_SIZE; i++){
        for(int j = 0; j < FILTER_SIZE; j++){
            for(int k = 0; k < IFMAP_CHANNELS; k++){
                for(int l = 0; l < OFMAP_CHANNELS; l++){
                    weights_file >> weights[i][j][k][l];
                }
            }
        }
    }

    int32_t ofmap[OFMAP_HEIGHT][OFMAP_WIDTH][OFMAP_CHANNELS];
    conv_gold<OFMAP_HEIGHT, OFMAP_WIDTH, OFMAP_CHANNELS, IFMAP_CHANNELS, FILTER_SIZE, STRIDE>(ifmap, weights, ofmap);

    std::ofstream ofmap_file;
    ofmap_file.open("data/" + layer_name + "_ofmap.txt");
    for(int i = 0; i < OFMAP_HEIGHT; i++){
        for(int j = 0; j < OFMAP_WIDTH; j++){
            for(int k = 0; k < OFMAP_CHANNELS; k++){
                ofmap_file << ofmap[i][j][k] << "\n";
            }
        }
    }
    ofmap_file.close();

    
    std::ifstream gold_ofmap_file;
    gold_ofmap_file.open("data/" + layer_name + "_gold_ofmap.txt");
    for(int i = 0; i < OFMAP_HEIGHT; i++){
        for(int j = 0; j < OFMAP_WIDTH; j++){
            for(int k = 0; k < OFMAP_CHANNELS; k++){
                int32_t tmp;
                gold_ofmap_file >> tmp;

                if(tmp != ofmap[i][j][k]){
                    std::cout << "Error! Output does not match gold at i = " << i << " j = " << j << " k = " << k << " gold = " << tmp << " output = "  << ofmap[i][j][k] << std::endl;
                    //return;
                }
            }
        }
    }

    std::cout << "No errors found!" << std::endl;
}

/* template <int OFMAP_HEIGHT, 
          int OFMAP_WIDTH, 
          int OFMAP_CHANNELS, 
          int IFMAP_CHANNELS, 
          int FILTER_SIZE, 
          int STRIDE>

 */

// OY0 = OX0 = 4;  ifmap_cycle_count = 4*4 = 16;
// OC0 = IC0 = 4;  mac_cycle_count = 4 + 4 + 1 = 9;

int main(){
  //run_layer<112, 112, 64, 3, 7, 2>("layer1");   // OX = OY = 112, OC = 64, IC = 3, Fx = Fy = 7, stride = 2
  run_layer<56, 56, 64, 64, 3, 1>("layer2");      // OX = OY = 56, OC = 64, IC = 64, FX = FY = 3, stride = 1
  run_layer<28, 28, 128, 128, 3, 1>("layer3");    // OX = OY = 28, OC = 128, IC = 128, FX = FY = 3, stride = 1
}
