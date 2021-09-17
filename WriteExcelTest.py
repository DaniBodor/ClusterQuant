# -*- coding: utf-8 -*-
"""
Created on Thu Sep 16 14:10:13 2021

@author: dani
"""

import xlwt
# create workbook
book = xlwt.Workbook()

def output(filename, sheet, headers, data):    
    '''
    filename: excel file (string)
    sheet: name of sheet (string)
    headers: list of column headers
    data: list of lists of values per column
    '''
    # create sheet
    sh = book.add_sheet(sheet)
    
    # write headers
    for col, h in enumerate (headers):
        sh.write(0, col, h)
    
    # write data
    for value in data: