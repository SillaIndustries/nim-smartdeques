import unittest
import options
import os
import ../src/concretesmartdequeues
import strutils

const fileStorage = "/tmp/.smarttests"
const fileStorageResource1 = "./tests/resources/smartdequesmock"

type MockClass = object
    pk: int
    name: string
    height: float

const m = MockClass(pk: 3, name: "silla", height: 4.3)
const m1 = MockClass(pk: 4, name: "silla1", height: 7.8)
const m2 = MockClass(pk: 5, name: "silla2", height: 10.0)

const mockRes1 = ["""{"pk":10,"name":"silla10","height":23.2}""","""{"pk":11,"name":"silla11","height":10.2}""","""{"pk":12,"name":"silla12","height":-230.0}"""]


suite "Smart deques tests":

    test "Initialization":
        var p = newSmartDeque[MockClass](100, some(fileStorage))
        check p.len == 0
    
    test "Push element and pop":
        var p = newSmartDeque[MockClass](100, some(fileStorage))
        p.clear()
        p.initStorage()
        p.push(m)
        check p.len == 1
        check p.peek().get().name == m.name
        var fileContent = readFile(fileStorage)
        var splitLines = fileContent.splitLines()[0 .. ^2]
        check splitLines.len == 1
        let o = p.pop()
        check o.get().name == m.name
        fileContent = readFile(fileStorage)
        splitLines = fileContent.splitLines()[0 .. ^2]
        check splitLines.len == 0
    
    test "Nilpotence property":
        var p = newSmartDeque[MockClass](100, some(fileStorage))
        p.clear()
        p.initStorage()
        p.push(m)
        p.push(p.pop().get())
        let res = p.pop()
        check res.get().name == m.name

    test "Full queue case":
        var p = newSmartDeque[MockClass](2, some(fileStorage))
        p.clear()
        p.initStorage()
        p.push(m)
        p.push(m1)
        check p.isFull
        let res = p.push(m2)
        check res.isNone == true
        check p.isFull
        var fileContent = readFile(fileStorage)
        var splitLines = fileContent.splitLines()[0 .. ^2]
        check splitLines.len == p.len
    
    test "Empty case":
        var p = newSmartDeque[MockClass](2, some(fileStorage))
        p.clear()
        p.initStorage()
        let res = p.pop()
        check res.isNone == true
        var fileContent = readFile(fileStorage)
        var splitLines = fileContent.splitLines()[0 .. ^2]
        check splitLines.len == 0
    
    test "Deserialize and load storage":
        var p = newSmartDeque[MockClass](3, some(fileStorage))
        p.clear()
        p.initStorage()
        p.push(m)
        p.push(m1)
        p.push(m2)
        var p1 = newSmartDeque[MockClass](3, some(fileStorage))
        p1.initStorage()
        # check p1.isFull
        let mo1 = p.pop()
        let mo2 = p.pop()
        let mo3 = p.pop()
        check m.name == mo1.get().name
        check m1.name == mo2.get().name
        check m2.name == mo3.get().name
    
    