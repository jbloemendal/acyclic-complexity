#!/usr/bin/env python3
from fractions import Fraction
import re
import argparse
import sys
import math

'''
Copyright 2018 Jannis Bloemendal

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
'''

class Unabridged(Fraction):

    numerator=0
    denominator=0
   
    def __new__(cls, numerator, denominator):
        self = super(Unabridged, cls).__new__(cls, numerator, denominator)
        self.numerator = numerator
        self.denominator = denominator
        return self

    def __repr__(self):
        return 'fraction(%s,%s)' % (self.numerator, self.denominator)

    def __str__(self):
        return 'fraction(%s,%s)' % (self.numerator, self.denominator)

class Scope:
    type = '{}' # class, function (func), flow, encapsulation ({})
    jack = ''
    height = ''
    parent = None
    childs = []

    def __init__(self, type='{}', height=0, jack=''):
        self.type = type
        self.height = height
        self.jack = jack
        self.childs = []

    def setParent(self, parent):
        self.parent = parent
        if parent:
            parent.addChild(self)

    def getParent(self):
        return self.parent

    def addChild(self, child):
        if not child in self.childs:
            self.childs.append(child)

    def isRoot(self):
        return self.parent == None

    def getChilds(self):
        return self.childs

    def isLeaf(self):
        return len(self.childs) == 0

    def __str__(self):
        return '%s %s' % (self.type, self.jack)


class Decision(Scope):

    text = '' 
    sor = '||'
    sand = '&&'
    jack = ''
    height = 0
    rise = 0
    apriori = None
    posteriori = None

    def __init__(self, jack, rise, height, text):
        self.text = text
        self.type = 'decision' # desicion \ attor, find apriori \ posteriori decision of jacketspace
        self.jack = jack
        self.rise = rise
        self.height = height
        self.childs = []

    def ands(self):
        return self.text.count(self.sand)

    def ors(self):
        return self.text.count(self.sor)

    def conditions(self):
        return 1 + self.ors() + self.ands()

    def phi(self):
        n=0
        a=0
        o=0
        r=0

        phi=[]

        #print("rise:%s, height: %s, (%s) " % (self.rise, self.height, self.text), end='')
        exerceo = re.findall(r'[&|]{2}', self.text)
        r=len(exerceo)
        n=math.ceil(r/2)

        for opero in exerceo:
            if '&&' == opero:
                a += 1
            elif '||' == opero:
                o += 1

        k=1
        for opero in exerceo:
            #print("k: %s, and:%s" % (k, dip), end='')
            if '&&' == opero:
                #print("%s/%s" % (1+o, 2*abs(n-k)+2), end=', ')
                frac = Unabridged(1+o, 2*abs(n-k)+2)
            elif '||' == opero:
                #print("%s/%s" % (1+a, 2*abs(n-k)+1), end=', ')
                frac = Unabridged(1+a, 2*abs(n-k)+1)
            phi.append(frac)
            k += 1

        #print("")
        if 0 == len(phi):
            phi = [0]

        return [self.rise, phi]

    def getHeight(self):
        return self.height

    def __str__(self):
        return '%s (%s)' % (self.jack, re.sub(r'[\s\n\t]+', ' ', self.text))

'''
C style scope parser
if (o>0 && u>0 && i>0) {
    for (int i=1; i<o; i++) {
        while (u>o) {
            o++;
        }
    }
}
'''
class Clue:

    text = ''
    spaces = []
    height = 0
    sumphi = 0
    phi = []

    def __init__(self, text):
        self.spaces = []
        self.text = text

    def parse(self):
        self.spaces = self.scopes()
        return self.spaces

    def ramify(self, rise, height, text):

        mif = re.search(r'\s*if\s*\((.*)\)\s*$', text, re.DOTALL)
        mwhile = re.search(r'\s*while\s*\((.*)\)\s*$', text, re.DOTALL)
        mfor = re.search(r'\s*for\s*\((.*?)\)\s*$', text, re.DOTALL)
        mfunction = re.search(r'\s*([a-zA-Z0-9_]+\(.*\))\s*$', text, re.DOTALL)

        if mif:
            d = Decision('if', rise, height, mif.group(1))
            return d
        elif mfor:
            d = Decision('for', rise, height, mfor.group(1))
            return d
        elif mwhile:
            d = Decision('while', rise, height, mwhile.group(1))
            return d

        return Scope()

    def squiggleL(self, rise, height):
        pattern = re.compile('^([^{}]*){')
        match = pattern.match(self.text)
        if match:
            scope = self.ramify(rise, height, match.group(1))
            self.text = self.text[len(match.group(0)):]
            return scope
        return None


    def squiggleR(self):
        pattern = re.compile('^([^}]*)}')
        match = pattern.match(self.text)

        if match:
            self.text = self.text[len(match.group(0)):]
            return True

        return False

    def scopes(self, parent=None, height=1):
        scOpes = []
        rise = 1
        s = self.scope(parent, rise, height)
        while s:
            scOpes.append(s)
            rise = rise + 1
            s = self.scope(parent, rise, height)
        return scOpes

    def scope(self, parent=None, rise=1, height=1):
        scOpe = self.squiggleL(rise, height)
        if not scOpe:
            return None

        scOpe.setParent(parent)
        if type(scOpe) is Decision:
            height += 1 + scOpe.conditions()-1
            if (height > self.height):
                self.height = height

        self.scopes(scOpe, height)

        self.squiggleR()
        return scOpe

    def clue(self):
        def dux(scope):
            clue=[0,0]
            if scope:
                for child in scope.getChilds():
                    duxed = dux(child)
                    clue[0] += duxed[0]
                    clue[1] += duxed[1]
                if 'decision' == scope.type: #attcupor decision
                    phi = scope.phi()
                    clue[0] += phi[0]
                    clue[1] += sum(phi[1])
            return clue

        clue=[0, 0]
        for space in self.spaces:
            duxed = dux(space)
            clue[0] += duxed[0]
            clue[1] += duxed[1]
        return clue

    def cluepath(self):
        self.phi=[]

        def dux(scope):
            if scope:
                if 'decision' == scope.type:
                    #print(scope.rate())
                    self.phi.append(scope.phi())
                for child in scope.getChilds():
                    dux(child)

        for space in self.spaces:
            dux(space)
        
        return self.phi

    def verify(self):
        self.sumphi=[0,0]
        def dux(scope):
            if scope:
                if 'decision' == scope.type:
                    phi = scope.phi()
                    rsum = sum(phi[1])
                    phi = [phi[0], rsum]
                    self.sumphi[0] += phi[0]
                    self.sumphi[1] += phi[1]
                    print(str(scope)+' '+u'\u03C6'+str(phi)+ ' { ', end='')
                for child in scope.getChilds():
                    dux(child)
                if 'decsision' == scope.type:
                    print('} ', end='')
                    if scope.isRoot():
                        print('')

        for pace in self.spaces:
            dux(pace)
        print(u'\u03BE=%s' % self.sumphi)
        return self.sumphi

    def cabe(self):
        def dux(scope):
            m=0
            if scope:
                if 'decision' == scope.type:
                    m += scope.conditions()
                for child in scope.getChilds():
                    m += dux(child)
            return m

        m=0
        for pace in self.spaces:
              m += dux(pace)
        return m + 1

    def subPaths(self, scope=None):
        if not scope:
            q = 1
            for space in self.spaces:
                q = q*self.subPaths(space)
            return q
        else:
            q = 1
            if 'decision' == scope.type:
                q = scope.ors()+1 # scope entrances
            for child in scope.getChilds():
                q = q*self.subPaths(child)
            if 'decision' == scope.type:
                q += scope.ands()+1 # False exits
            return q
        return 0

    def subPathConjecture(self, scope=None):
        if not scope:
            q = 0
            for space in self.spaces:
                v = self.subPathConjecture(space)
                q = q+v
            return q
        else:
            q = 0
            # print('scope %s, or %s, and %s, leaf: %s' % (scope.text, scope.ors(), scope.ands(), scope.isLeaf()))
            if 'decision' == scope.type:
                if scope.isLeaf():
                    q += (scope.conditions()-1)*2+1
                else:
                    q += scope.conditions() * 2
            for child in scope.getChilds():
                q += self.subPathConjecture(child)

            return q
        return 0


if __name__ == '__main__':


    argparser = argparse.ArgumentParser(description='Static code complexity analyser for c-family syntax (C, C++, Java, ECMAScript, C#, ...), it quantifies a standard data input stream (stdin) for an absolute number.')
    argparser.add_argument('-c', action='store_true', help='cyclomatic complexity, condition count, O(n)')
    argparser.add_argument('-f', '--file', type=argparse.FileType('r'), help='read one or more newline separated lines from file')
    argparser.add_argument('-g', action='store_true', help='control flow conjecture O(2n)')
    argparser.add_argument('-p', action='store_true', help='clue path vector')
    argparser.add_argument('-q', action='store_true', help='all sub paths, O(2^n)')
    argparser.add_argument('-v', action='store_true', help='verify condition path')
    argparser.add_argument('-k', action='store_true', help='clue path complexity, regards nested formations, O(n^2)')
    args = argparser.parse_args()

    data=''
    if args.file:
        for line in args.file:
            data += line
    else:
        for line in sys.stdin:
            data += line

    clue=Clue(data)
    clue.parse()

    if args.v:
        clue.verify()
    elif args.p:
        print(clue.cluepath())
    elif args.q:
        print(clue.subPaths())
    elif args.g:
        print(clue.subPathConjecture())
    elif args.c:
        print(clue.cabe())
    else:
        print(clue.clue())