import src/concretesmartdequeues
export smartdequeues
import strformat
import std/[os]
import options
import random

type MockStruct = object
    elem: int
    pk: int
    sku: string

var mock1 = newSmartDeque[MockStruct](10)
mock1.clear()
mock1.initStorage()

proc th1() {.thread, gcsafe.} =
    while true:
        {.cast(gcsafe).}:
            randomize()
            let r = rand(100) 
            if mock1.isFull():
                echo "### IS FULL!"
            else:
                let o = mock1.push(MockStruct(elem: r, pk: r, sku: $r))
                if o.isSome:
                    echo fmt"--> push {o}"
        sleep(500)

proc th2() {.thread, gcsafe.} =
    while true:
        {.cast(gcsafe).}:
            echo $mock1
            let o = mock1.pop()
            if o.isSome:
                echo fmt"--> pop {o}"
        sleep(2000)

var t1: Thread[void]
var t2: Thread[void]
createThread(t1, th1)
createThread(t2, th2)
joinThreads(t1, t2)

