# -*- coding: utf-8 -*-
"""
Created on Mon Mar  9 14:13:59 2020

@author: dani
"""

import pandas as pd
import itertools
import sys
import os
from datetime import datetime
import matplotlib.pyplot as plt
from random import seed as rseed
from pathlib import Path

starttime = datetime.now()
rseed(22)

filename = 'Log_2003091404.txt'

data = os.path.abspath(os.path.join(os.getcwd(), os.pardir, 'results', 'output', filename))

print(data)