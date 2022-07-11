# Description:
# - ramdomly generates data for ifmap, weights
# - computes ofmap
# - orders ifmap/weight/ofmap according to tiling
# - saves ifmap/weight/ofmap data to files
# Author: Cheryl (Yingqiu) Cao
# Date: 2022-07-04
# Updated on: 2022-07-10

import os
import numpy
from numpy import random

# cnn parameters
OY0 = 3
OX0 = 3
OC0 = 2
IC0 = 2
Stride = 1

# parameters on: input data dimensions
OY = 3
OX = 3
OC = 2
IC = 2
FY = 2
FX = 2

# derived parameters
OY1 = OY / OY0
OX1 = OX / OX0
OC1 = OC / OC0
IC1 = IC / IC0
IX = (OX - 1) * Stride + FX
IY = (OY - 1) * Stride + FY
IX0 = (OX0 - 1) * Stride + FX
IY0 = (OY0 - 1) * Stride + FY


# generate ifmap array with integers smaller than 10
ifmap = random.randint( 10, size = (IX, IY, IC))
# print(ifmap)


# generate weight array with integers smaller than 10
weight = random.randint( 10, size = (FX, FY, IC, OC))
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
if os.path.exists("data/layer4_ifmap.txt"):
  os.remove("data/layer4_ifmap.txt")
# saves the ifmap data in "layer4_ifmap.txt"
f = open("data/layer4_ifmap.txt", "a")

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
###   orders weights data in tilting order   #####
#################################################
# clean up pre-existing data failes
if os.path.exists("data/layer4_weights.txt"):
  os.remove("data/layer4_weights.txt")
# saves the ifmap data in "layer4_ifmap.txt"
f = open("data/layer4_weights.txt", "a")

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
###   orders ifmap data in tilting order    #####
#################################################
# clean up pre-existing data failes
if os.path.exists("data/layer4_ofmap.txt"):
  os.remove("data/layer4_ofmap.txt")
# saves the ifmap data in "layer4_ifmap.txt"
f = open("data/layer4_ofmap.txt", "a")

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


