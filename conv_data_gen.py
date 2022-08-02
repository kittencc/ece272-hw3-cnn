# Description:
# - ramdomly generates data for ifmap, weights
# - computes ofmap
# - orders ifmap/weight/ofmap according to tiling
# - saves ifmap/weight/ofmap data to files
# Author: Cheryl (Yingqiu) Cao
# Date: 2022-07-04
# Updated on: 2022-07-10
# Updated on: 2022-07-24

import os
import numpy
from numpy import random

# cnn parameters
OY0 = 3
OX0 = 3
OC0 = 4
IC0 = 4
Stride = 1

# parameters on: input data dimensions
OY = 12
OX = 12
OC = 16
IC = 8
FY = 3
FX = 3

# derived parameters
OY1 = OY / OY0
OX1 = OX / OX0
OC1 = OC / OC0
IC1 = IC / IC0
IX = (OX - 1) * Stride + FX
IY = (OY - 1) * Stride + FY
IX0 = (OX0 - 1) * Stride + FX
IY0 = (OY0 - 1) * Stride + FY


# for layer4 data
## generate ifmap array with integers smaller than 10
#ifmap = random.randint( 10, size = (IX, IY, IC))
# print(ifmap)

## generate weight array with integers smaller than 10
#weight = random.randint( 10, size = (FX, FY, IC, OC))
# print(weight)

# for layer5 data
# generate ifmap array with integers from [-10, 10]
ifmap = random.randint( -10, 10, size = (IX, IY, IC))

# generate weight array with integers from [-10, 10]
weight = random.randint( -10, 10, size = (FX, FY, IC, OC))
# print(weight)


# initialize ofmap array with zeros
ofmap = numpy.zeros((OX, OY, OC), dtype = int)
# print(ofmap)



# computes ofmap( ox, oy, oc)
for oy1 in range(OY1):
  for ox1 in range(OX1):
    # fouble buffer level below:
    for oc1 in range(OC1):
      for ic1 in range(IC1):
        for fy in range(FY):
          for fx in range(FX):
            for oy0 in range(OY0):
              for ox0 in range(OX0):
                # RF level below:
                for oc0 in range(OC0):
                  for ic0 in range(IC0):

                    ox = ox1 * OX0 + ox0
                    oy = oy1 * OY0 + oy0

                    ix = ox * Stride + fx
                    iy = oy * Stride + fy

                    ic = ic1 * IC0 + ic0
                    oc = oc1 * OC1 + oc0

                    ofmap[ox][oy][oc] = ofmap[ox][oy][oc] + ifmap[ix][iy][ic] * weight[fx][fy][ic][oc]

# print(ofmap)


#################################################
###   orders ifmap data in tilting order    #####
#################################################
# clean up pre-existing data failes
if os.path.exists("data/layer6_ifmap.txt"):
  os.remove("data/layer6_ifmap.txt")
# saves the ifmap data in "layer5_ifmap.txt"
f = open("data/layer6_ifmap.txt", "a")

# ordering ifmap data
# each ifmap bank dimension [ic1, iy0, ix0] chained over ic0
# a total of OY1 * OX1 = 1 bank
for oy1 in range(OY1):
  for ox1 in range(OX1):
#    for oc1 in range(OC1):  // OC1 does not affect ifmap indexing
    for ic1 in range(IC1):
      for iy0 in range(IY0):
        for ix0 in range(IX0):
          for ic0 in range(IC0):     # OC0 does not affect ifmap indexng

            ix = ix0 + ox1 * OX0 * Stride     # IMPORTANT!
            iy = iy0 + oy1 * OY0 * Stride
            ic = ic0 + ic1 * IC0
            ifmap_data = ifmap[ix][iy][ic]
            f.write("{}\n".format(ifmap_data))

f.close()

print("IX0 = {}".format(IX0))
print("IC0 = {}".format(IC0))


#################################################
###   saves ifmap data in .mem for tesebench    #####
#################################################
# clean up pre-existing data failes
if os.path.exists("data/layer6_ifmap.mem"):
  os.remove("data/layer6_ifmap.mem")
# saves the ifmap data in "layer6_ifmap.txt"
f = open("data/layer6_ifmap.mem", "a")

# ordering ifmap data
# each ifmap bank dimension [ic1, iy0, ix0] chained over ic0
# a total of OY1 * OX1 = 1 bank
for oy1 in range(OY1):
  for ox1 in range(OX1):
#    for oc1 in range(OC1):  // OC1 does not affect ifmap indexing
    for ic1 in range(IC1):
      for iy0 in range(IY0):
        for ix0 in range(IX0):
          for ic0 in range(IC0):     # OC0 does not affect ifmap indexng

            ix = ix0 + ox1 * OX0 * Stride     # IMPORTANT!
            iy = iy0 + oy1 * OY0 * Stride
            ic = ic0 + ic1 * IC0
            ifmap_data = ifmap[ix][iy][ic]
            # {0:08x}
            # first 0 is the index of the actual value getting loaded for
            # formatting.
            # 08x, left fill with zeros, data is 8 in width, each digit is
            # in hex form
            # & oxffff converts ifmap_data into a 16-bit wide  2's
            # complement, for negative input data
            f.write("{0:x}\n".format(ifmap_data & 0xffff))

            # f.write("{0:x}\n".format(ifmap_data))  # works w/ positive
            # integer input data



f.close()






#################################################
###   orders weights data in tilting order   #####
#################################################
# clean up pre-existing data failes
if os.path.exists("data/layer6_weights.txt"):
  os.remove("data/layer6_weights.txt")
# saves the ifmap data in "layer6_ifmap.txt"
f = open("data/layer6_weights.txt", "a")

# ordering weight data
# each weight bank dimension [oc1, ic1, fy, fx, ic0] chained over oc0
# a total of 1 bank 
for oc1 in range(OC1):
  for ic1 in range(IC1):
    for fy in range(FY):
      for fx in range(FX):
        for ic0 in range(IC0):
          for oc0 in range(OC0):
            
            ic = ic1 * IC0 + ic0
            oc = oc1 * OC1 + oc0
            weight_data = weight[fx][fy][ic][oc]
            f.write("{}\n".format(weight_data))

f.close()

print("IC = {}".format(IC))
print("OC = {}".format(OC))
print("FX = {}".format(FX))


#################################################
###   saves weights data in .mem for tesebench #####
#################################################
# clean up pre-existing data failes
if os.path.exists("data/layer6_weights.mem"):
  os.remove("data/layer6_weights.mem")
# saves the ifmap data in "layer6_.mem"
f = open("data/layer6_weights.mem", "a")

# ordering weight data
# each weight bank dimension [oc1, ic1, fy, fx, ic0] chained over oc0
# a total of 1 bank 
for oc1 in range(OC1):
  for ic1 in range(IC1):
    for fy in range(FY):
      for fx in range(FX):
        for ic0 in range(IC0):
          for oc0 in range(OC0):
            
            ic = ic1 * IC0 + ic0
            oc = oc1 * OC1 + oc0
            weight_data = weight[fx][fy][ic][oc]
            # {0:08x}
            # first 0 is the index of the actual value getting loaded for
            # formatting.
            # 08x, left fill with zeros, data is 8 in width, each digit is
            # in hex form
            f.write("{0:x}\n".format(weight_data & 0xffff))

f.close()



#################################################
###   orders ofmap data in tilting order    #####
#################################################
# clean up pre-existing data failes
if os.path.exists("data/layer6_ofmap.txt"):
  os.remove("data/layer6_ofmap.txt")
# saves the ifmap data in "layer6_ifmap.txt"
f = open("data/layer6_ofmap.txt", "a")

# ordering ofmap data
# each ofmap bank dimension [oc1, oy0, ox0, oc0] 
# a total of OY1 * OX1 = 1 bank
for oy1 in range(OY1):
  for ox1 in range(OX1):
    # fouble buffer level below:
    for oc1 in range(OC1):
      for oy0 in range(OY0):
        for ox0 in range(OX0):
          # RF level below:
          for oc0 in range(OC0):
            
            ox = ox1 * OX0 + ox0
            oy = oy1 * OY0 + oy0
            oc = oc1 * OC1 + oc0

            ofmap_data = ofmap[ox][oy][oc] 
            f.write("{}\n".format(ofmap_data))

f.close()

print("OC = {}".format(OC))
print("OX = {}".format(OX))


