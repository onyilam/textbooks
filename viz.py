# -*- coding: utf-8 -*-
import os
import sys
import csv
import numpy as np
from tsne import tsne
import matplotlib.pyplot as plt
from matplotlib import rcParams

rcParams['font.family'] = 'Hiragino Sans GB'

def build(src_filename, delimiter=',', header=True, quoting=csv.QUOTE_MINIMAL):
    fp=open(src_filename,'r')
    mat = []
    rownames = []
    word_dim=0
    for line in fp:
        word_info=line.split()
        if (len(word_info)==2):
            print ' Number of words and dimension as follows '
            print line
            word_freq=word_info[0]
            word_dim=word_info[1]
            #print word_freq
            #print word_dim

        else:
            if len(word_info)< int(word_dim):
                    #print word_info
                print len(word_info),' ',word_dim
            else:
                rownames.append(word_info[0])
                mat.append(np.array(map(float, word_info[1: ])))

    return (mat, rownames)





def tsne_viz(
        mat=None,
        title='hk',
        rownames=None,
        indices=None,
        colors=None,
        output_filename=None,
        figheight=40,
        figwidth=50,
        display_progress=False):
    if not colors:
        colors = ['black' for i in range(len(mat))]
    temp = sys.stdout
    if not display_progress:
        # Redirect stdout so that tsne doesn't fill the screen with its iteration info:
        f = open(os.devnull, 'w')
        sys.stdout = f
    tsnemat = tsne(mat)
    sys.stdout = temp
    # print tsnemat
    # Plot coordinates:
    if not indices:
        indices = range(len(mat))
    vocab = np.array(rownames)[indices]
    xvals = tsnemat[indices, 0]
    yvals = tsnemat[indices, 1]
    # Plotting:
    fig, ax = plt.subplots(nrows=1, ncols=1)
    fig.set_figheight(800)
    fig.set_figwidth(800)
    ax.plot(xvals, yvals, marker='', linestyle='')
    ax.set_xticks([])
    ax.set_yticks([])
    ax.set_title(title)
    # Text labels:
    # words_of_interest = [u'蒋介石', u'毛泽东', u'孙中山', u'国民党', u'共产党', u'马克思']
    words_of_interest = [u'蒋中正', u'毛泽东', u'孙中山', u'国民党', u'共产党', u'马克思']
    chi2eng = {u'蒋中正': 'Chiang Kai-shek', u'毛泽东':'Mao Zedong' , u'孙中山':'Sun Yat-sen', u'国民党': 'KMT', u'共产党': 'CPC', u'马克思': 'Max'}
    for word, x, y, color in zip(vocab, xvals, yvals, colors):
        if word.decode('utf-8') in words_of_interest:
            #ax.annotate(word.decode('utf-8'), (x, y), fontsize=18, color='red')
            ax.annotate(chi2eng[unicode(word, 'utf-8')], (x, y), fontsize=18, color='red')
        else:
            ax.annotate(word.decode('utf-8'), (x, y), fontsize=14, color=color)

    print "Output:"
    if output_filename:
        plt.savefig(output_filename, bbox_inches='tight')
    else:
        plt.show()


if __name__ == "__main__":
    title = raw_input("Input hk, tw or ma: ")
    src_dir= title + '.txt'
    wv = build(src_dir, delimiter=' ', header=True, quoting=csv.QUOTE_NONE)
    tsne_viz(mat=np.array(wv[0]),title=title,rownames=wv[1])


