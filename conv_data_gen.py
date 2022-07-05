# Description:
# - ramdomly generates data for ifmap, weights
# - computes ofmap
# - orders ifmap/weight/ofmap according to tiling
# - saves ifmap/weight/ofmap data to files
# Author: Cheryl (Yingqiu) Cao
# Date: 2022-04-04

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


