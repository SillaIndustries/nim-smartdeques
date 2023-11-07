import ../src/concretesmartdeques
import strformat
import std/[os]
import options
import random
import unittest

type MockStruct = object
    elem: int
    pk: int
    sku: string

suite "Smart deques thread tests":

    test "Basic test":
        const dequeLength = 10
        var count {.threadvar.}: int
        var mock1 = newSmartDeque[MockStruct](dequeLength)
        mock1.clear()
        mock1.initStorage()

        proc th1() {.thread, gcsafe.} =
            count = 0
            while true:
                {.cast(gcsafe).}:
                    randomize()
                    let r = rand(100)
                    if mock1.isFull():
                        check mock1.len == dequeLength
                        count = count + 1
                        echo "### IS FULL!"
                    else:
                        let o = mock1.push(MockStruct(elem: r, pk: r, sku: $r))
                        if o.isSome:
                            echo fmt"--> push {o}"
                    if count > 3:
                        echo "# -> out th1"
                        break
                sleep(500)

        proc th2() {.thread, gcsafe.} =
            count = 0
            while true:
                {.cast(gcsafe).}:
                    let o = mock1.pop()
                    if o.isSome:
                        echo fmt"<-- pop {o}"
                    count = count + 1
                    if count > dequeLength + 3:
                        echo "# -> out th2"
                        break
                sleep(1000)

        var t1: Thread[void]
        var t2: Thread[void]
        createThread(t1, th1)
        createThread(t2, th2)
        joinThreads(t1, t2)
    
    test "Savage calls":

        const dequeLength = 20000
        var count {.threadvar.}: int
        var mock1 = newSmartDeque[MockStruct](dequeLength)
        mock1.clear()
        mock1.initStorage()

        proc th1() {.thread, gcsafe.} =
            while true:
                {.cast(gcsafe).}:
                    randomize()
                    let r = rand(100)
                    if mock1.isFull():
                        check mock1.len == dequeLength
                        break
                    else:
                        let o = mock1.push(MockStruct(elem: r, pk: r, sku: $r))
                        if o.isSome:
                            echo fmt"--> push {o}"

        proc th2() {.thread, gcsafe.} =
            while true:
                {.cast(gcsafe).}:
                    if mock1.isFull():
                        check mock1.len == dequeLength
                        break
                    let o = mock1.pop()
                    if o.isSome:
                        echo fmt"<-- pop {o}"
                    sleep(10)

        var t1: Thread[void]
        var t2: Thread[void]
        createThread(t1, th1)
        createThread(t2, th2)
        joinThreads(t1, t2)
